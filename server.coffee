# Usage: coffee server.coffee
# TODO: add node cluster
# TODO: migrate to EU region
# TODO: setup nodetime
# TODO: try base64 uri encoding

# nodetime
if process.env.NODETIME_ACCOUNT_KEY
  require('nodetime').profile
    accountKey: process.env.NODETIME_ACCOUNT_KEY
    appName: 'Ongeza'

# External dependencies
express = require 'express'
phantom = require 'phantom'
winston = require 'winston'
through = require 'through'
knox = require 'knox'
mongo = require('mongodb').MongoClient
memjs = require 'memjs'
papertrail = require('winston-papertrail').Papertrail
toobusy = require 'toobusy'
toobusy.maxLag(100)
request = require 'request'
streamifier = require 'streamifier'
s3Lister = require 's3-lister'
JSONStream = require 'JSONStream'
pngquant = require 'pngquant'
md5 = require('blueimp-md5').md5
es = require 'event-stream'
_ = require 'underscore'

# Internal dependencies
path = require 'path'
fs = require 'fs'

# Local dependencies
Common = require './app/lib/common.coffee'
makeChart = require './app/lib/makechart.coffee'
config = require './app/config.coffee'

# Set clients
transports = []
app = express()
mc = memjs.Client.create()
s3 = knox.createClient
  key: process.env.AWS_ACCESS_KEY_ID
  secret: process.env.AWS_SECRET_ACCESS_KEY
  bucket: process.env.S3_BUCKET_NAME or 'ongeza'
  region: 'eu-west-1'

if config.dev
  transports.push new winston.transports.Console {colorize: true}
  options = {filename: 'server.log', maxsize: 2097152}
  transports.push new winston.transports.File options
else
  host = 'logs.papertrailapp.com'
  options = {handleExceptions: true, host: host, port: 55976, colorize: true}
  transports.push new papertrail options

logger = new winston.Logger {transports: transports}

# Set variables
lister = new s3Lister s3
encoding = {encoding: 'utf-8'}
debug_s3 = false
debug_mongo = true
debug_memcache = true
debug_toobusy = false
days = 2
maxCacheAge = days * 24 * 60 * 60 * 1000
api_expires = 15 * 60 # 15 min (in seconds) work_data
rep_expires = 60 * 60  # 1 hour (in seconds)
s3_expires = 15 * 24 * 60 * 60 # 15 days (in seconds)
s3List_expires = 5 * 60  # 5 minutes (in seconds)
fs_expires = 24 * 60 * 60  # 1 day (in seconds)
ph_start_expires = 10 * 60  # 10 minutes (in seconds)
wait_expires = 10 * 60  # 10 minutes (in seconds)
rq_timeout = 20 * 1000 # request timeout (in milliseconds)
sv_timeout = 25 * 1000 # server timeout (in milliseconds)
ph_timeout = 4 * 1000 # phantomjs rendering timeout (in milliseconds)
wait_timeout = ph_timeout * 12 # timeout to start rendering from queue (in milliseconds)
retry_after = 3 * 1000 # phantomjs wait time between checking progress (in milliseconds)
selector = Common.getSelection()
datafile = path.join 'public', 'uploads', 'data.json'
port = process.env.PORT or 3333
active = false
graph = false
queue = []
queued_hashes = []

# middleware
# pipe web server logs through winston
winstonStream = {write: (message, encoding) -> logger.info message}
app.use express.logger {stream: winstonStream}
app.use express.bodyParser()
app.use express.compress()
app.use express.timeout sv_timeout
app.use express.static __dirname + '/public', {maxAge: maxCacheAge}
app.use (req, res, next) ->
  if not toobusy() then next()
  else
    logger.warn 'server too busy'
    return next() if config.dev and not debug_toobusy
    res.set 'Retry-After', retry_after
    res.location req.url
    res.send 503, "I'm busy right now. Try again later." # find right response code

# CORS support
configCORS = (req, res, next) ->
  # logger.info "Configuring CORS"
  if not req.get('Origin') then return next()
  res.set 'Access-Control-Allow-Origin', '*'
  res.set 'Access-Control-Allow-Methods', 'GET, POST'
  res.set 'Access-Control-Allow-Headers', 'X-Requested-With, Content-Type'
  if 'OPTIONS' is req.method then return res.send 200
  next()

# pushState hack
configPush = (req, res, next) ->
  if 'api' in req.url.split('/') then return next()
  newUrl = req.protocol + '://' + req.get('Host') + '/#' + req.url
  res.redirect newUrl

# utility functions
cb = (err, success, type='create') ->
  logger.error "for #{type} cache key #{err.message}" if err
  logger.info "successfully #{type}d cache key!" if success
setKey = (key, value, expires) ->
  logger.info "setting #{key}..."
  cb = (err, success) ->
    logger.error "#{err.message} creating #{key}" if err
    logger.info "successfully created #{key}!" if success

  mc.set key, value, cb, expires

delKey = (key) ->
  logger.info "deleting #{key}..."
  mc.delete key, (err, success) ->
    logger.error "#{err.message} creating #{key}" if err
    logger.info "successfully deleted #{key}!" if success

handleError = (err, res, src, code=500, error=true) ->
  logFun = if error then logger.error else logger.warn
  logFun "#{src} #{err.message}"
  res.send code, {error: err.message}

handleSuccess = (res, message, code=200) ->
  logger.info message
  res.send code, message

getS3List = es.map (tmp, callback) ->
  mc.get 's3List', (err, buffer) ->
    logger.error "getS3List get s3list #{err.message}" if err
    if (config.dev and not debug_memcache) or not buffer
      stringify = JSONStream.stringify()
      setMC = es.mapSync (string) -> mc.set 's3List', string, cb, s3List_expires
      lister.pipe(stringify).pipe(setMC)
      callback null, lister
    else
      logger.info "s3List found in cache"
      stream = streamifier.createReadStream buffer
      convert = es.map (buffer, callback) -> callback null, buffer.toString()
      callback null, stream.pipe(convert)

fileExists = (filename, callback) ->
  filepath = path.join 'public', 'uploads', filename
  mc.get "local:#{filename}", (err, cached) ->
    logger.error "fileExists get local:#{filename} #{err.message}" if err
    if (config.dev and not debug_memcache) or not cached
      logger.info "Checking filesystem for #{filepath}..."
      fs.exists filepath, (exists) -> callback exists, false
    else
      logger.info "#{filepath} found in cache"
      callback true, true

s3Exists = (filename, callback) ->
  mc.get "s3:#{filename}", (err, cached) ->
    logger.error "s3Exists get s3:#{filename} #{err.message}" if err
    if (config.dev and not debug_memcache) or not cached
      logger.info "Checking s3 for #{filename}..."

      do (callback) -> getS3List()
        .on('error', (err) ->
          logger.error 'getS3List ' + err.message
          callback false, false)
        .pipe es.mapSync (s3List) ->
          if filename in s3List then callback true, false
          else callback false, false
    else
      logger.info "#{filename} found in cache"
      callback true, true

# routing functions
getProgress = (req, res) ->
  handleTimeout = (timeout, opts, wait_time, render_time) ->
    if not timeout
      do (opts, wait_time, render_time) -> mc.get "#{opts.hash}:#{opts.id}:#{opts.attr}", (err, buffer) ->
        if err
          handleError err, opts.res, 'handleTimeout', 504
        else if not buffer
          err = {message: "#{opts.hash}:#{opts.id}:#{opts.attr} not found in memcache"}
          handleError err, opts.res, 'handleTimeout', 404
        else
          opts.res.location buffer.toString()
          opts.res.set 'Retry-After', retry_after
          logger.info "wait time: #{wait_time}ms" if wait_time
          logger.info "render time: #{render_time}ms" if render_time
          err = {message: "still rendering #{opts.hash}, try again later"}
          handleError err, opts.res, 'handleTimeout', 503, false
    else
      logger.info "wait time: #{wait_time}"
      logger.info "render time: #{render_time}"
      err = {message: "Phantomjs render timed out on #{opts.filename}"}
      handleError err, opts.res, 'handleTimeout', 504

  handleStart = (err, buffer, opts) ->
    logger.error "handleStart get start_ph #{err.message}" if err
    now = (new Date()).getTime()

    if not buffer
      do (opts) -> mc.get "#{opts.hash}:wait_ph", (err, buffer) ->
        logger.error "getProgress get wait_ph #{err.message}" if err
        if not buffer then setKey "#{opts.hash}:wait_ph", now, wait_expires
        else waiting = now - parseInt buffer.toString()
        wait_time = waiting ? 0
        handleTimeout wait_time > wait_timeout, opts, wait_time, 0
    else
      render_time = now - parseInt buffer.toString()
      handleTimeout render_time > ph_timeout, opts, 0, render_time

  handleExists = (exists, cached, opts) ->
  # http://big-elephants.com/2012-12/pdf-rendering-with-phantomjs
    if exists
      value = {hash: opts.hash, id: opts.id, attr: opts.attr}
      handleSuccess opts.res, value
    else if (opts.hash not in queued_hashes)
      err = {message: "#{opts.filename} doesn't exist in #{opts.src} and #{opts.hash} not enqueued"}
      handleError err, opts.res, 'handleExists', 404
    else if (config.dev and not debug_memcache)
      err = {message: "#{opts.filename} doesn't exist in #{opts.src} and memcache not enabled"}
      handleError err, opts.res, 'handleExists', 404
    else do (opts) -> mc.get "#{opts.hash}:start_ph", (err, buffer) ->
      handleStart err, buffer, opts

  opts =
    res: res
    hash: req.params.hash
    filename: "#{req.params.hash}.png"
    attr: req.params.attr
    id: req.params.id

  do (opts) -> if config.dev and not debug_s3
    opts.src = 'filesystem'
    fileExists opts.filename, (exists, cached) -> handleExists exists, cached, opts
  else
    opts.src = 's3'
    s3Exists opts.filename, (exists, cached) -> handleExists exists, cached, opts

getUploads = (req, res) ->
  return logger.warn 'getUploads headers already sent' if res.headerSent
  res.set 'Cache-Control', 'public, max-age=60'

  handleResp = (err, resp, hash, res) ->
    if err then handleError err, res, 'handleResp'
    else if resp.statusCode isnt 200
      err = {message: "statusCode is #{resp.statusCode}"}
      handleError err, res, 'handleResp', 404
    else
      res.set 'Content-Length', resp.headers['content-length']
      res.set 'Content-Type', resp.headers['content-type']
      # res.set 'Last-Modified', ...
      res.set 'ETag', hash
      return res.send 304 if req.fresh
      return res.send 200 if req.method is 'HEAD'
      logger.info "#{filename} exists on s3! Streaming to page."
      resp.pipe(res)

  sendfile = (filepath, res) ->
    stream = fs.createReadStream filepath
    res.setHeader 'Content-Type', 'image/png'
    do (res) -> stream
      .on('error', (err) -> handleError err, res, 'sendfile', 404)
      .pipe(new pngquant [4, '--ordered']).pipe(res)

  hash = req.params.hash
  filename = "#{hash}.png"

  if config.dev and not debug_s3
    filepath = path.join 'public', 'uploads', filename
    sendfile filepath, res
  else do (hash, res) ->
    s3.getFile "/#{filename}", (err, resp) -> handleResp err, resp, hash, res

handleFlush = (req, res) ->
  id = req.body.id
  flushCB = (err, success, res) ->
    if err then handleError err, res, 'Flush'
    if success then handleSuccess res, 'Flush complete!' # why 204 doesn't work?

  flushQueues = ->
    queue = []
    queued_hashes = []

  if id is 'cache'
    # won't work for multi-server environments
    do (res) -> mc.flush (err, success) -> flushCB err, success, res
    flushQueues()
  else if id is 's3'
    deleteCB = (err, resp, res) ->
      if err then handleError err, res, 's3.deleteMultiple'
      else
        logger.info 'Successfully deleted s3 files!'
        delKey 's3List'
        flushQueues()
        do (res) -> mc.flush (err, success) -> flushCB err, success, res
        resp.resume() if not err

    do (res) -> getS3List()
      .on('error', (err) -> handleError err, res, 'getS3List')
      .pipe es.mapSync (s3List) -> do (res) ->
        s3.deleteMultiple s3List, (err, resp) -> deleteCB err, resp, res
  else res.send 404, 'command not supported'

getStatus = (req, res) -> mc.stats (err, server, status) ->
  if err then handleError err, res, 'Status'
  else if server and status
    handleSuccess res, {server: server, status: status}
  else handleError {message: "#{server} status is #{status}"}, res, 'Status'

handleList = (req, res) ->
  do (res) -> getS3List()
    .on('error', (err) -> handleError err, res, 'getS3List')
    .pipe(res)

# phantomjs
processPage = (page, ph, reps) ->
  logger.info 'Processing phantom page'

  handleRender = (req, res) ->
    sendRes = (opts) ->
      unless config.dev and not debug_memcache
        setKey "#{opts.hash}:#{opts.id}:#{opts.attr}", opts.progress, rep_expires
      opts.res.location opts.progress
      handleSuccess opts.res, opts.progress

    send2fs = (opts) ->
      unless config.dev and not debug_memcache
        setKey "#{opts.prefix}:#{opts.filename}", true, fs_expires

    send2s3 = (opts) ->
      callback = (err, opts) ->
        if err then handleError err, res, 'send2s3'
        else
          unless config.dev and not debug_memcache
            logger.info "setting #{opts.prefix}:#{opts.filename}"
            mc.set "#{opts.prefix}:#{opts.filename}", true, cb, s3_expires
            do (opts) -> getS3List()
              .on('error', (err) -> logger.error 'getS3List ' + err.message)
              .pipe es.mapSync (s3List) ->
                s3List.push opts.filename
                mc.set 's3List', JSON.stringify(s3List), cb, s3List_expires

      logger.info "Sending #{opts.filename} to s3..."
      hdr = {'x-amz-acl': 'public-read'}

      do (opts) ->
        quantizer = new pngquant [4, '--ordered']
        stream = fs.createReadStream(opts.filepath).pipe(quantizer)
        s3.putStream stream, "/#{opts.filename}", hdr, (err, resp) ->
          callback err, opts
          resp.resume() if not err

    renderPage = ->
      active = true
      graph = queue[0]
      queue.splice(0, 1)
      logger.info "pulling #{graph.opts.filename} from queue: #{queue.length}"
      graph.generate graph.opts

    addGraph = (opts) ->
      logger.info "starting addGraph for #{opts.filename}"
      func = (opts) ->
        renderCB = (opts) ->
          opts.sendFunc opts
          if queue.length then renderPage() else active = false

        evalCB = do (opts) -> (result) ->
          logger.info "rendering #{opts.filename}"
          setKey "#{opts.hash}:start_ph", (new Date()).getTime(), ph_start_expires
          do (opts) -> opts.page.render opts.filepath, -> renderCB opts

        opts.page.evaluate makeChart, evalCB, opts.chart_data, selector

      # look into nodejs.org/api/timers.html#timers_setimmediate_callback_arg
      if opts.hash in queued_hashes
        logger.info "#{opts.hash} already in queue. Not adding."
      else
        queue.push {generate: func, opts: opts}
        queued_hashes.push opts.hash
        logger.info "adding hash: #{opts.hash} to queue: #{queue.length}"
        renderPage() if not active

    hash = req.body.hash
    id = req.body.id
    attr = req.body.attr
    filename = "#{hash}.png"
    filepath = path.join 'public', 'uploads', filename

    if config.dev and not debug_s3
      existsFunc = fileExists
      sendFunc = send2fs
      prefix = 'local'
    else
      existsFunc = s3Exists
      sendFunc = send2s3
      prefix = 's3'

    if not (hash and attr and id)
      err = {message: 'post data is missing an entry'}
      return handleError err, res, 'handleRender'

    progress = "/api/progress/#{hash}/#{id}/#{attr}"
    [w, h] = req.body?.size?.split('x').map((v) -> parseInt v) or [950, 550]
    keys = ['hash', 'filename', 'filepath', 'attr', 'id', 'progress', 'res', 'page', 'w', 'h', 'prefix','existsFunc', 'sendFunc']
    values = [hash, filename, filepath, attr, id, progress, res, page, w, h, prefix, existsFunc, sendFunc]
    opts = _.object(keys, values)

    do (opts) -> mc.get "#{hash}:#{id}:#{attr}", (err, buffer) ->
      logger.error "handleRender get #{opts.hash} #{err.message}" if err

      if (config.dev and not debug_memcache) or not buffer
        opts.page.set 'viewportSize', {width: opts.w, height: opts.h}

        mergeData = through (chart_data) ->
          # logger.info 'mergeData'
          _.extend opts, {chart_data: chart_data}

          do (opts) -> opts.existsFunc opts.filename, (exists, cached) ->
            if exists
              logger.info "#{opts.prefix}:#{opts.filename} exists."
              setKey "#{opts.prefix}:#{opts.filename}", true, fs_expires if not cached
            else
              logger.info "#{opts.prefix}:#{opts.filename} doesn't exist in cache."
              addGraph opts

            sendRes opts

        if config.dev and not debug_mongo
          logger.info "streaming #{opts.hash} data from json file"
          stream = fs.createReadStream datafile, {encoding: 'utf8'}
          parse = JSONStream.parse opts.hash
          do (opts) -> stream
            .on('error', (err) -> handleError err, opts.res, 'handleRender: fs')
            .pipe(parse)
            .on('error', (err) -> handleError err, opts.res, 'handleRender: parse')
            .pipe(mergeData)
        else
          logger.info "streaming #{opts.hash} data from mongodb"
          parse = JSONStream.parse 'data'

          do (opts) -> reps.findOne {hash: opts.hash}, {raw: false}, (err, raw) ->
            # figure out how to parse raw buffer
            if err or not raw
              err = err ? {message: "#{opts.hash} has null entry"}
              handleError err, opts.res, 'handleRender: mongodb'
            else
              data = JSON.stringify raw
              streamifier.createReadStream(data, encoding)
                .pipe(parse)
                .on('error', (err) -> handleError err, opts.res, 'handleRender: parse')
                .pipe(mergeData)
      else
        opts.res.location opts.progress
        handleSuccess opts.res, opts.progress

  handleFetch = (req, res) ->
    return logger.warn 'handleFetch headers already sent' if res.headerSent
    key = 'fetch'

    handleJSONSuccess = (json, res, key) ->
      logger.info 'handleJSONSuccess'
      postWrite = (err, hash_list, key, result=false) ->
        if err then handleError err, res, 'postWrite'
        else
          logger.info 'Wrote hash list'
          value = {data: hash_list}
          unless config.dev and not debug_memcache
            setKey key, JSON.stringify(value), api_expires
          res.send 201, value

      data_list = []
      hash_list = []
      data_obj = {}

      for rep in json.data
        raw = (JSON.parse Common.getChartData a, rep[a], rep.id for a in config.data_attrs)
        hashes = (md5 JSON.stringify r for r in raw)
        hash_obj = _.object config.hash_attrs, hashes
        hash_obj.id = rep.id
        hash_list.push hash_obj
        _.extend data_obj, _.object hashes, raw

      keys = _.uniq _.keys data_obj
      (data_list.push {hash: k, data: data_obj[k]} for k in keys)

      do (hash_list) -> if not data_list
        handleError {message: 'chart data is blank'}, res, 'handleJSONSuccess'
      else if config.dev and not debug_mongo
        logger.info 'writing data to json file'
        fs.writeFile datafile, JSON.stringify(data_obj), (err, result) ->
          postWrite err, hash_list, key, result
      else
        logger.info 'writing data to mongodb'
        reps.remove {}, {w:1}, (err, num_removed) ->
          if err then handleError err, res, 'handleJSONSuccess remove reps'
          else do (hash_list) -> reps.insert data_list, {w:1}, (err, result) ->
            postWrite err, hash_list, key, result

    do (key) -> mc.get key, (err, buffer) ->
      logger.error "handleFetch get #{key} #{err.message}" if err

      if (config.dev and not debug_memcache) or not buffer
        options = {timeout: rq_timeout, url: req.body.url, json: true}
        do (res) -> request options, (err, resp, json) ->
          if err then handleError err, res, 'handleFetch'
          else if resp.statusCode is 200 then handleJSONSuccess json, res, key
          else
            err = {message: "#{options.url} returned #{resp.statusCode}"}
            handleError err, res, 'handleFetch', 417
      else
        logger.info 'Hash list found! Streaming value from memcache.'
        res.type 'application/json'
        stream = streamifier.createReadStream buffer
        convert = es.map (buffer, callback) -> callback null, buffer.toString()
        stream.pipe(convert).pipe(res)

  # create server routes
  app.all '*', configCORS
  app.get '*', configPush
  app.get "/api/uploads/:hash", getUploads
  app.get "/api/progress/:hash/:id/:attr", getProgress
  app.get "/api/stats", getStatus
  app.post "/api/flush", handleFlush
  app.post "/api/list", handleList
  app.post '/api/fetch', handleFetch
  app.post '/api/render', handleRender

  # timeout err handler
  app.use (err, req, res, next) -> handleError err, res, 'app', 504

  # start server
  server = app.listen port, ->
    suffix = if config.dev then "localhost:#{port}" else 'ongeza.herokuapp.com'
    home = "http://#{suffix}"

    logger.info "Listening on port #{port}"
    logger.info "debug s3: #{debug_s3}"
    logger.info "debug mongodb: #{debug_mongo}"
    logger.info "debug memcache: #{debug_memcache}"
    logger.info "Try curl #{home}#{config.api_fetch} -H 'Accept: */*' --data 'url=#{config.api_get}work_data'"
    logger.info "Then curl #{home}#{config.api_render} -H 'Accept: */*' --data 'hash=<hash>&id=E0018&attr=cur_work_hash'"
    logger.info "Then curl #{home}/api/progress/<hash>/E0018/cur_work_hash"
    logger.info "Then curl #{home}#{config.api_uploads}/<hash>"

  process.on 'SIGINT', ->
    server.close()
    toobusy.shutdown()
    process.exit()

phantom.create (ph) ->
  logger.info 'Creating phantom page'
  ph.createPage (page) ->
    page.set 'content', """
      <html>
        <head>
          <style media='screen' type='text/css'>
            .chartWrap {margin: 0; padding: 0; overflow: hidden;}
            g.nv-group.nv-series-0 {fill-opacity: 0 !important;}
            g.nv-group.nv-series-1 {overflow: hidden;}
            svg {-webkit-touch-callout: none;-webkit-user-select: none;-khtml-user-select: none;-moz-user-select: none;-ms-user-select: none;user-select: none;display: block;width:100%;height:100%;}
            svg text {font: normal 12px Arial;}
            svg .title {font: bold 14px Arial;}
            .nvd3 .nv-background {fill: white;fill-opacity: 0;}
            .nvd3.nv-noData {font-size: 18px;font-weight: bold;}
            .nvd3 .nv-axis path {fill: none;stroke: #000;stroke-opacity: .75;shape-rendering: crispEdges;}
            .nvd3 .nv-axis path.domain {stroke-opacity: .75;}
            .nvd3 .nv-axis.nv-x path.domain {stroke-opacity: 0;}
            .nvd3 .nv-axis line {fill: none;stroke: #000;stroke-opacity: .25;shape-rendering: crispEdges;}
            .nvd3 .nv-axis line.zero {stroke-opacity: .75;}
            .nvd3 .nv-axis .nv-axisMaxMin text {font-weight: bold;}
            .nvd3 .x  .nv-axis .nv-axisMaxMin text,
            .nvd3 .x2 .nv-axis .nv-axisMaxMin text,
            .nvd3 .x3 .nv-axis .nv-axisMaxMin text {text-anchor: middle}
            .nvd3 .nv-bars .negative rect {  zfill: brown;}
            .nvd3 .nv-bars rect {zfill: steelblue;fill-opacity: .75;
            transition: fill-opacity 250ms linear;-moz-transition: fill-opacity 250ms linear;-webkit-transition: fill-opacity 250ms linear;}
            .nvd3 .nv-bars rect:hover {fill-opacity: 1;}
            .nvd3 .nv-bars .hover rect {fill: lightblue;}
            .nvd3 .nv-bars text {fill: rgba(0,0,0,0);}
            .nvd3 .nv-bars .hover text {fill: rgba(0,0,0,1);}
            .nvd3 .nv-multibar .nv-groups rect,
            .nvd3 .nv-multibarHorizontal .nv-groups rect,
            .nvd3 .nv-discretebar .nv-groups rect {stroke-opacity: 0;
            transition: fill-opacity 250ms linear;-moz-transition: fill-opacity 250ms linear;-webkit-transition: fill-opacity 250ms linear;}
            .nvd3 .nv-multibar .nv-groups rect:hover,
            .nvd3 .nv-multibarHorizontal .nv-groups rect:hover,
            .nvd3 .nv-discretebar .nv-groups rect:hover {fill-opacity: 1;}
            .nvd3 .nv-discretebar .nv-groups text,
            .nvd3 .nv-multibarHorizontal .nv-groups text {font-weight: bold;fill: rgba(0,0,0,1);stroke: rgba(0,0,0,0);}
          </style>
        </head>
        <body>
          <div id='id' class='view'>
            <div class='chart chart-att'><svg id='svg'></svg></div>
          </div>
        </body>
      </html>"""

    mongo.connect process.env.MONGOHQ_URL, (err, db) ->
      if err and (not config.dev or debug_mongo)
        logger.error 'mongodb ' + err.message
        process.exit()
      else if err and config.dev and not debug_mongo then reps = {}
      else
        logger.info 'Connected to mongodb'
        reps = db.collection 'reps'

      page.injectJs 'vendor/scripts/nvd3/d3.v3.js', ->
        page.injectJs 'vendor/scripts/nvd3/nv.d3.js', ->
          processPage page, ph, reps
