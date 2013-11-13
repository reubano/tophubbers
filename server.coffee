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
encoding = {encoding: 'utf-8'}
debug_s3 = true
debug_mongo = true
debug_memcache = true
debug_toobusy = true
days = 2
maxCacheAge = days * 24 * 60 * 60 * 1000
api_expires = 15 * 60 # 15 min (in seconds) work_data
rep_expires = 60 * 60  # 1 hour (in seconds)
s3_expires = 15 * 24 * 60 * 60 # 15 days (in seconds)
s3List_expires = 30 * 60  # 30 minutes (in seconds)
fs_expires = 24 * 60 * 60  # 1 day (in seconds)
ph_start_expires = 10 * 60  # 10 minutes (in seconds)
wait_expires = 10 * 60  # 10 minutes (in seconds)
rq_timeout = 20 * 1000 # request timeout (in milliseconds)
sv_timeout = 25 * 1000 # server timeout (in milliseconds)
ph_timeout = 2 * 60 * 1000 # phantomjs rendering timeout (in milliseconds)
wait_timeout = 5 * 60 * 1000 # timeout to start rendering from queue (in milliseconds)
sv_retry_after = 5 * 1000 # toobusy wait time between requests (in milliseconds)
selector = Common.getSelection()
datafile = path.join 'public', 'uploads', 'data.json'
port = process.env.PORT or 3333
active = false
graph = false
queue = []
queued_hashes = []

handleError = (err, res, src, code=500, error=true) ->
  logFun = if error then logger.error else logger.warn
  logFun "#{src} #{err.message}"
  return logger.error "#{src} headers already sent" if res.headersSent
  res.send code, {error: err.message}

# middleware
# pipe web server logs through winston
winstonStream = {write: (message, encoding) -> logger.info message}
app.use express.logger {stream: winstonStream}
app.use express.bodyParser()
app.use express.compress()
app.use express.timeout sv_timeout
app.use express.static __dirname + '/public', {maxAge: maxCacheAge}
app.use (req, res, next) ->
  return next() if not toobusy() or (config.dev and not debug_toobusy)
  res.setHeader 'Retry-After', sv_retry_after
  if 'progress' in req.url.split('/') then res.location req.url
  else res.location "attr=#{req.body.attr}&hash=#{req.body.hash}&id=#{req.body.id}"
  err = {message: "server too busy. try again later."}
  handleError err, res, 'app', 503, false

# CORS support
configCORS = (req, res, next) ->
  # logger.info "Configuring CORS"
  if not req.get 'Origin' then return next()
  res.setHeader 'Access-Control-Allow-Origin', '*'
  res.setHeader 'Access-Control-Allow-Methods', 'GET, POST'
  res.setHeader 'Access-Control-Allow-Headers', 'X-Requested-With, Content-Type'
  if 'OPTIONS' is req.method then return res.send 200
  next()

# pushState hack
configPush = (req, res, next) ->
  if 'api' in req.url.split('/') then return next()
  newUrl = req.protocol + '://' + req.get('Host') + '/#' + req.url
  res.redirect newUrl

setKey = (key, value, expires) ->
  # logger.info "setting #{key}..."
  cb = (err, success) ->
    logger.error "#{err.message} setting #{key}" if err
    logger.info "successfully set #{key}!" if success

  mc.set key, value, cb, expires

delKey = (key) ->
  # logger.info "deleting #{key}..."
  mc.delete key, (err, success) ->
    logger.error "#{err.message} deleting #{key}" if err
    logger.info "successfully deleted #{key}!" if success

handleSuccess = (res, message, code=200) ->
  logger.info message
  return logger.error 'handleSuccess headers already sent' if res.headersSent
  res.send code, message

getS3List = (onerr, pipe) ->
  mc.get 's3List', (err, buffer) ->
    return onerr err if err

    if (config.dev and not debug_memcache) or not buffer
      logger.info "s3List doesn't exist in cache"
      s3.list (err, data) ->
        return onerr err if err
        s3List = JSON.stringify(file.Key for file in data.Contents)
        setKey 's3List', s3List, s3List_expires
        streamifier.createReadStream(s3List, encoding)
          .on('error', onerr).pipe(pipe)
    else
      logger.info "s3List found in cache"
      stream = streamifier.createReadStream buffer
      convert = es.map (buffer, callback) -> callback null, buffer.toString()
      stream.pipe(convert).on('error', onerr).pipe(pipe)

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

      onerr = (err) ->
        logger.error 'getS3List ' + err.message
        callback false, false
      pipe = es.mapSync (s3List) ->
        s3List = JSON.parse s3List
        if filename in s3List then callback true, false
        else callback false, false

      getS3List onerr, pipe
    else
      logger.info "#{filename} found in cache"
      callback true, true

# routing functions
getProgress = (req, res) ->
  handleTimeout = (timeout, opts, wait_time, render_time) ->
    if not timeout then do (opts, wait_time, render_time) ->
      mc.get "#{opts.hash}:#{opts.id}:#{opts.attr}", (err, buffer) ->
        if err
          handleError err, opts.res, 'handleTimeout', 504
        else if not buffer
          err = {message: "#{opts.hash}:#{opts.id}:#{opts.attr} doesn't exist in memcache"}
          handleError err, opts.res, 'handleTimeout', 404
        else
          opts.res.location buffer.toString()
          # phantomjs wait time between requests (in milliseconds)
          ph_retry_after = 10 * 1000 * if queue.length then queue.length else 1
          opts.res.setHeader 'Retry-After', ph_retry_after
          if wait_time then m = "waiting to render #{opts.hash}: #{wait_time}ms, try again later"
          else if render_time then m = "still rendering #{opts.hash}: #{render_time}ms, try again later"
          else m = "#{opts.hash} render just started, try again later"
          handleError {message: m}, opts.res, 'handleTimeout', 503, false
    else
      logger.info "wait time: #{wait_time}ms"
      logger.info "render time: #{render_time}ms"
      err = {message: "Phantomjs render timed out on #{opts.filename}"}
      handleError err, opts.res, 'handleTimeout', 504

  handleStart = (err, buffer, opts) ->
    logger.error "handleStart get start_ph #{err.message}" if err
    now = (new Date()).getTime()

    if not buffer then do (opts) ->
      mc.get "#{opts.hash}:wait_ph", (err, buffer) ->
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
    setRes = (opts) ->
      delKey "#{opts.hash}:#{opts.id}:#{opts.attr}"
      opts.res.location "hash=#{opts.hash}&id=#{opts.id}&attr=#{opts.attr}"
      opts.res.setHeader 'Retry-After', sv_retry_after

    if exists
      value = {hash: opts.hash, id: opts.id, attr: opts.attr}
      handleSuccess opts.res, value
    else if (opts.hash not in queued_hashes)
      setRes opts
      m = "#{opts.filename} doesn't exist in #{opts.src} and not enqueued"
      handleError {message: m}, opts.res, 'handleExists', 503
    else if (config.dev and not debug_memcache)
      m = "#{opts.filename} doesn't exist in #{opts.src} and memcache not enabled"
      handleError {message: m}, opts.res, 'handleExists', 404
    else if queue.length or active
      do (opts) -> mc.get "#{opts.hash}:start_ph", (err, buffer) ->
        handleStart err, buffer, opts
    else
      setRes opts
      m = "#{opts.filename} enqueued but wasn't uploaded"
      queued_hashes = []
      handleError {message: m}, opts.res, 'handleExists', 503

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
  return logger.warn 'getUploads headers already sent' if res.headersSent
  res.setHeader 'Cache-Control', 'public, max-age=60'

  handleResp = (err, resp, hash, res) ->
    resp.resume() if (err or resp.statusCode isnt 200 or res.headersSent) and resp

    if res.headersSent then logger.error 'handleResp headers already sent'
    else if err then handleError err, res, 'handleResp'
    else if resp.statusCode isnt 200
      # delKey 's3List' if resp.statusCode is 404
      err = {message: "statusCode is #{resp.statusCode}"}
      handleError err, res, 'handleResp', 404
    else
      res.set 'Content-Length', resp.headers['content-length']
      res.set 'Content-Type', resp.headers['content-type']
      # res.setHeader 'Last-Modified', ...
      res.setHeader 'ETag', hash
      return res.send 304 if req.fresh
      return res.send 200 if req.method is 'HEAD'
      logger.info "#{filename} exists on s3! Streaming to page."
      resp.pipe(res)

  sendfile = (filepath, res) ->
    res.setHeader 'Content-Type', 'image/png'
    do (res) -> fs.createReadStream(filepath)
      .on('error', (err) -> handleError err, res, 'sendfile', 404).pipe(res)

  hash = req.params.hash
  filename = "#{hash}.png"

  if config.dev and not debug_s3
    filepath = path.join 'public', 'uploads', filename
    sendfile filepath, res
  else do (hash, res) ->
    s3.getFile "/#{filename}", (err, resp) -> handleResp err, resp, hash, res

handleFlush = (req, res) ->
  id = req.body.id
  flushCB = do (res) -> (err, success) ->
    if err then handleError err, res, 'Flush'
    if success then handleSuccess res, 'Flush complete!' # why 204 doesn't work?

  # won't work for multi-server environments
  flushQueues = ->
    queue = []
    queued_hashes = []
    logger.info 'Successfully deleted queues'

  if id is 'cache'
    mc.flush(flushCB)
    flushQueues()
  else if id is 's3'
    deleteCB = (err, resp) ->
      return handleError err, res, 's3.deleteMultiple' if err
      logger.info 'Successfully deleted s3 files!'
      mc.flush(flushCB)
      flushQueues()
      resp.resume()

    onerr = do (res) -> (err) -> handleError err, res, 'getS3List'
    pipe = es.mapSync (s3List) ->
      s3List = JSON.parse s3List
      s3.deleteMultiple s3List, deleteCB
    getS3List onerr, pipe
  else res.send 404, 'command not supported'

getStatus = (req, res) -> mc.stats (err, server, status) ->
  if err then handleError err, res, 'Status'
  else if server and status
    handleSuccess res, {server: server, status: status}
  else handleError {message: "#{server} status is #{status}"}, res, 'Status'

handleList = (req, res) ->
  onerr = (err) -> handleError err, res, 'getS3List'
  getS3List onerr, res

# phantomjs
processPage = (page, ph, reps) ->
  logger.info 'Processing phantom page'

  handleRender = (req, res) ->
    sendRes = (opts) ->
      return logger.error 'sendRes headers already sent' if opts.res.headersSent
      unless config.dev and not debug_memcache
        setKey "#{opts.hash}:#{opts.id}:#{opts.attr}", opts.progress, rep_expires
      opts.res.location opts.progress
      handleSuccess opts.res, "Check #{opts.progress}"

    send2fs = (opts) ->
      unless config.dev and not debug_memcache
        setKey "#{opts.prefix}:#{opts.filename}", true, fs_expires

    send2s3 = (opts) ->
      putCB = (resp, opts) ->
        logger.info "successfully uploaded #{opts.filename}!"
        resp.resume()
        return if config.dev and not debug_memcache
        setKey "#{opts.prefix}:#{opts.filename}", true, s3_expires
        onerr = (err) -> logger.error 'getS3List ' + err.message
        pipe = do (opts) -> es.mapSync (s3List) ->
          s3List = JSON.parse s3List
          s3List.push opts.filename
          setKey 's3List', JSON.stringify(s3List), s3List_expires

        getS3List onerr, pipe

      do (opts) -> fs.stat opts.filepath, (err, stat) ->
        return handleError err, opts.res, 'send2s3' if err

        hdr =
          'x-amz-acl': 'public-read'
          'Content-Length': stat.size
          'Content-Type': 'image/png'

        req = s3.put "/#{opts.filename}", hdr

        do (opts) -> fs.createReadStream(opts.filepath)
          .on('error', (err) -> handleError err, opts.res, 'read')
          .pipe(req).on('error', (err) -> handleError err, opts.res, 'req')

        logger.info "uploading #{opts.filename} to s3..."
        do (opts) -> req.on 'response', (resp) -> putCB resp, opts

    renderPage = ->
      active = true
      graph = queue[0]
      queue.splice(0, 1)
      logger.info "pulling #{graph.opts.filename} from queue: #{queue.length}"
      graph.generate graph.opts

    addGraph = (opts) ->
      logger.info "starting addGraph for #{opts.filename}"
      func = (opts) ->
        tmpFilepath = path.join 'public', 'uploads', "#{opts.hash}_tmp.png"

        renderCB = (opts) ->
          do (opts) -> fs.createReadStream(tmpFilepath)
            .on('error', (err) -> handleError err, opts.res, 'read')
            .pipe(new pngquant [4, '--ordered'])
            .on('error', (err) -> handleError err, opts.res, 'quantizer')
            .pipe(fs.createWriteStream opts.filepath)
            .on('error', (err) -> handleError err, opts.res, 'write')
            .on('finish', -> opts.sendFunc opts)

          if queue.length then renderPage() else active = false

        evalCB = do (opts) -> (result) ->
          logger.info "rendering #{opts.filename}"
          setKey "#{opts.hash}:start_ph", (new Date()).getTime(), ph_start_expires
          do (opts) -> opts.page.render tmpFilepath, -> renderCB opts

        opts.page.evaluate makeChart, evalCB, opts.chart_data, selector

      # look into nodejs.org/api/timers.html#timers_setimmediate_callback_arg
      if opts.hash in queued_hashes
        logger.info "#{opts.hash} already queued. Not adding."
      else
        queue.push {generate: func, opts: opts}
        queued_hashes.push opts.hash
        logger.info "adding hash #{opts.hash} to queue: #{queue.length}"
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
    keys = [
      'hash', 'filename', 'filepath', 'attr', 'id', 'progress', 'res', 'page',
      'w', 'h', 'prefix','existsFunc', 'sendFunc']
    values = [
      hash, filename, filepath, attr, id, progress, res, page, w, h, prefix,
      existsFunc, sendFunc]
    opts = _.object(keys, values)

    do (opts) -> mc.get "#{hash}:#{id}:#{attr}", (err, buffer) ->
      logger.error "handleRender get #{opts.hash} #{err.message}" if err

      if (config.dev and not debug_memcache) or not buffer
        logger.info "#{hash}:#{id}:#{attr} doesn't exist in cache"
        opts.page.set 'viewportSize', {width: opts.w, height: opts.h}

        mergeData = through (chart_data) ->
          # logger.info 'mergeData'
          _.extend opts, {chart_data: chart_data}

          do (opts) -> opts.existsFunc opts.filename, (exists, cached) ->
            if exists
              logger.info "#{opts.prefix}:#{opts.filename} exists!"
              key = "#{opts.prefix}:#{opts.filename}"
              setKey key, true, fs_expires if not cached
            else
              logger.info "#{opts.prefix}:#{opts.filename} doesn't exist."
              addGraph opts

            sendRes opts

        if config.dev and not debug_mongo
          logger.info "streaming #{opts.hash} data from json file"

          do (opts) -> fs.createReadStream(datafile, {encoding: 'utf8'})
            .on('error', (err) -> handleError err, opts.res, 'handleRender: fs')
            .pipe(JSONStream.parse opts.hash)
            .on('error', (err) -> handleError err, opts.res, 'handleRender: parse')
            .pipe(mergeData)
        else
          logger.info "streaming #{opts.hash} data from mongodb"

          do (opts) -> reps.findOne {hash: opts.hash}, {raw: false}, (err, raw) ->
            # figure out how to parse raw buffer
            if err then handleError err, opts.res, 'handleRender: mongodb'
            else if not raw
              err = {message: "#{opts.hash} has null db entry. Try again later"}
              opts.res.location "hash=#{opts.hash}&id=#{opts.id}&attr=#{opts.attr}"
              handleError err, opts.res, 'handleRender: mongodb', 503, false
            else
              data = JSON.stringify raw
              streamifier.createReadStream(data, encoding)
                .pipe(JSONStream.parse 'data')
                .on('error', (err) -> handleError err, opts.res, 'handleRender: parse')
                .pipe(mergeData)
      else
        logger.info "#{hash}:#{id}:#{attr} found in cache"
        opts.res.location opts.progress
        handleSuccess opts.res, "Check #{opts.progress}"

  handleFetch = (req, res) ->
    return logger.warn 'handleFetch headers already sent' if res.headersSent
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
