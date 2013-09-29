# Usage: coffee server.coffee
# TODO: add syslog drains
# TODO: implement toobusy
# TODO: minify pngs (PNGCrush/OptiPNG -> PNGOUT/pngquant)
# TODO: implement s3 and request timeouts
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
knox = require 'knox'
mongo = require('mongodb').MongoClient
memjs = require 'memjs'
request = require 'request'
md5 = require('blueimp-md5').md5
_ = require 'underscore'

# Internal dependencies
path = require 'path'
fs = require 'fs'

# Local dependencies
Common = require './app/lib/common.coffee'
makeChart = require './app/lib/makechart.coffee'
config = require './app/config.coffee'

# Set clients
app = express()
mc = memjs.Client.create()
s3 = knox.createClient
  key: process.env.AWS_ACCESS_KEY_ID
  secret: process.env.AWS_SECRET_ACCESS_KEY
  bucket: process.env.S3_BUCKET_NAME or 'ongeza'
  region: 'eu-west-1'

logger = new winston.Logger
  transports: [
    new winston.transports.Console(),
    new winston.transports.File {filename: 'server.log', maxsize: 2097152}]

# Set variables
debug_s3 = false
debug_mongo = true
debug_memcache = true
uploads = 'uploads'
days = 2
maxCacheAge = days * 24 * 60 * 60 * 1000
api_expires = 60 * 15  # 15 min (in seconds)
rep_expires = 60 * 60  # 1 hour (in seconds)
s3_expires = 60 * 60 * 24 * 15  # 15 days (in seconds)
fs_expires = 60 * 60 * 24  # 1 day (in seconds)
selector = Common.getSelection()
port = process.env.PORT or config.port
datafile = path.join 'public', uploads, 'data.json'
active = false
queue = []
queued_files = []

# middleware
# pipe web server logs through winston
winstonStream = {write: (message, encoding) -> logger.info message}
app.use express.logger {stream: winstonStream}
app.use express.bodyParser()
app.use express.compress()
app.use express.static __dirname + '/public', {maxAge: maxCacheAge}

# CORS support
configCORS = (req, res, next) ->
  logger.info "Configuring CORS"
  if not req.get('Origin') then return next()
  res.set 'Access-Control-Allow-Origin', '*'
  res.set 'Access-Control-Allow-Methods', 'GET, POST'
  res.set 'Access-Control-Allow-Headers', 'X-Requested-With, Content-Type'
  if 'OPTIONS' is req.method then return res.send 200
  next()

# pushState hack
configPush = (req, res, next) ->
  if uploads in req.url.split('/') then return next()
  newUrl = req.protocol + '://' + req.get('Host') + '/#' + req.url
  res.redirect newUrl

# utility functions
cb = (err, success, type='create') ->
  logger.error "for #{type} cache key #{err.message}" if err
  logger.info "successfully #{type}d cache key!" if success

getS3List = (callback) ->
  mc.get 's3List', (err, buffer) ->
    logger.error "getS3List get s3list #{err.message}" if err
    if (config.dev and not debug_memcache) or not buffer
      s3.list {}, (err, data) ->
        if err then callback err, false
        else
          s3List = _.pluck data.Contents, 'Key'
          callback false, s3List
          logger.info "setting s3List for getS3List"
          mc.set 's3List', JSON.stringify(s3List), cb, 60
    else
      logger.info "s3List found in cache"
      callback false, JSON.parse buffer.toString()

fileExists = (filename, callback) ->
  filepath = path.join 'public', uploads, filename
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
      do (callback) -> getS3List (err, s3Files) ->
        if err
          logger.error 'getS3List ' + err.message
          callback false, false
        else if filename in s3Files then callback true, false
        else callback false, false
    else
      logger.info "#{filename} found in cache"
      callback true, true

# routing functions
handleGet = (req, res) ->
  return logger.warn 'handleGet headers already sent' if res.headerSent
  res.set 'Cache-Control', 'public, max-age=60'

  handleResp = (err, resp, id, res) ->
    if err
      logger.error 'handleResp ' + err.message
      res.send 500, {error: err.message}
    else if resp.statusCode isnt 200
      logger.error "Image #{id}.png doesn't exist at s3."
      res.send 404, "Sorry! Image #{id}.png doesn't exist at s3."
    else
      res.set 'Content-Length', resp.headers['content-length']
      res.set 'Content-Type', resp.headers['content-type']
      # res.set 'Last-Modified', ...
      res.set 'ETag', id
      return res.send 304 if req.fresh
      return res.send 200 if req.method is 'HEAD'
      logger.info "Image #{id}.png exists on s3! Streaming to page."
      resp.pipe(res)

  sendfile = (exists, filepath, id, res) ->
    if exists
      logger.info "Image #{id}.png exists on file! Serving to page."
      res.sendfile filepath
    else
      logger.error "Image #{id}.png doesn't exist on file."
      res.send 404, "Sorry! Image #{id}.png doesn't exist on file."

  id = req.params.id
  filename = "#{id}.png"

  if config.dev and not debug_s3
    filepath = path.join 'public', uploads, filename
    do (filepath, id, res) ->
      fs.exists filepath, (exists) -> sendfile exists, filepath, id, res
  else
    do (id, res) ->
      s3.getFile "/#{filename}", (err, resp) -> handleResp err, resp, id, res

handleFlush = (req, res) ->
  id = req.body.id
  flushCB = (err, success, res) ->
    if err
      logger.error "Flush #{err.message}"
      res.send 500, {error: err.message}
    if success
      logger.info 'Flush complete!'
      res.send 200, 'Flush complete!' # not sure why 204 doesn't work

  deleteCB = (err, resp, res) ->
    if err
      logger.error "s3.deleteMultiple #{err.message}"
      res.send 500, {error: err.message}
    else
      logger.info 'Successfully deleted s3 files!'
      queued_files = []
      mc.delete 's3List', (err, success) -> cb err, success, 'delete'
      do (res) -> mc.flush (err, success) -> flushCB err, success, res
      resp.resume() if not err

  getCB = (err, files, res) ->
    if err
      logger.error 'getS3List ' + err.message
      res.send 500, {error: err.message}
    else do (res) ->
      s3.deleteMultiple files, (err, resp) -> deleteCB err, resp, res

  if id is 'cache'
    # won't work for multi-server environments
    do (res) -> mc.flush (err, success) -> flushCB err, success, res
  else if id is 's3'
    do (res) -> s3.list {}, (err, data) ->
      if err
        logger.error "s3.list #{err.message}"
        res.send 500, {error: err.message}
      else do (res) -> getS3List (err, s3Files) -> getCB err, s3Files, res
  else res.send 404, 'command not supported'

getStatus = (req, res) ->
  mc.stats (err, server, status) ->
    if err
      logger.error "Status #{err.message}"
      res.send 500, {error: err.message}
    else if server and status
      logger.info 'Got memcache status!'
      res.send 200, {server: server, status: status}

getList = (req, res) ->
  getS3List (err, s3Files) ->
    if err
      logger.error 'getS3List ' + err.message
      res.send 500, {error: err.message}
    else
      logger.info 'Got memcache status!'
      res.send 200, {files: s3Files}

# phantomjs
processPage = (page, ph, reps) ->
  logger.info 'Processing phantom page'

  handleUpload = (req, res) ->
    # return logger.warn 'handleUpload headers already sent' if res.headerSent

    sendRes = (opts, type='cached') ->
      logger.info "Sending image hash for #{opts.id} #{opts.attr}: #{opts.hash}."
      value = {hash: opts.hash, type: type, id: opts.id, attr: opts.attr}
      unless config.dev and not debug_memcache
        logger.info "setting #{opts.key} for sendRes"
        mc.set opts.key, JSON.stringify(value), cb, rep_expires  # individual rep data
      opts.res.send 200, value

    send2fs = (opts) ->
      unless config.dev and not debug_memcache
        logger.info "setting #{opts.prefix}:#{opts.filename}"
        mc.set "#{opts.prefix}:#{opts.filename}", true, cb, fs_expires
      sendRes opts, 'new'

    send2s3 = (opts) ->
      callback = (err, opts) ->
        if err
          logger.error 'send2s3 ' + err.message
          opts.res.send 500, {error: err.message}
        else
          unless config.dev and not debug_memcache
            logger.info "setting #{opts.prefix}:#{opts.filename}"
            mc.set "#{opts.prefix}:#{opts.filename}", true, cb, s3_expires
          sendRes opts, 'new'

      logger.info "Sending #{opts.filename} to s3..."
      hdr = {'x-amz-acl': 'public-read'}

      do (opts) ->
        s3.putFile opts.filepath, "/#{opts.filename}", hdr, (err, resp) ->
          callback err, opts
          resp.resume() if not err

    renderPage = ->
      active = true
      graph = queue[0]
      queue.splice(0, 1)

      _render = (graph) ->
        logger.info "pulling #{graph.opts.filename} from queue: #{queue.length}"
        graph.generate graph.callback, graph.opts, queue.length

      if graph.isDupe
        opts = graph.opts
        logger.info "Repeating search for #{opts.filename} before rendering..."
        do (graph) -> opts.existsFunc opts.filename, (exists, cached) ->
          sendRes(graph.opts) and active = queue.length if exists
          renderPage() if exists and queue.length
          _render graph if not exists
      else _render graph

    addGraph = (callback, opts) ->
      func = (callback, opts, repeat=false) ->
        do (opts) ->
          evalCB = (result) ->
            logger.info "pre rendering #{opts.filename}"
            opts.page.render opts.filepath, ->
              # logger.info "post rendering #{opts.filename}"
              callback opts
              if repeat then renderPage() else active = false
          opts.page.evaluate makeChart, evalCB, opts.chart_data, selector

      dupe = opts.filename in queued_files
      queue.push {generate: func, callback: callback, opts: opts, isDupe: dupe}
      queued_files.push opts.filename
      logger.info "adding #{opts.filename} to queue: #{queue.length}"
      renderPage() if not active

    readJSON = (err, raw, opts) ->
      if err
        logger.error 'readJSON ' + err.message
        return opts.res.send 500, {error: err.message}
      else if not raw
        logger.error 'raw data is blank'
        return opts.res.send 417, {error: 'raw data is blank'}

      logger.info "parsing #{opts.id} #{opts.attr}'s json"

      try
        chart_data = JSON.parse(raw)[opts.id][opts.attr]
      catch error
        chart_data = raw[opts.attr]

      hash = md5 JSON.stringify chart_data
      filename = "#{hash}.png"
      filepath = path.join 'public', uploads, filename

      if config.dev and not debug_s3
        existsFunc = fileExists
        sendFunc = send2fs
        prefix = 'local'
      else
        existsFunc = s3Exists
        sendFunc = send2s3
        prefix = 's3'

      keys = ['chart_data', 'hash', 'filename', 'filepath', 'prefix', 'existsFunc']
      values = [chart_data, hash, filename, filepath, prefix, existsFunc]
      extra = _.object(keys, values)
      _.extend opts, extra

      do (opts) -> existsFunc filename, (exists, cached) ->
        if exists
          logger.info "File #{opts.filename} exists."
          sendRes opts
          logger.info "setting #{opts.prefix}:#{opts.filename} for readJSON"
          mc.set "#{opts.prefix}:#{opts.filename}", true, cb, fs_expires if not cached
        else
          logger.info "File #{opts.prefix}:#{opts.filename} doesn't exist in cache."
          addGraph sendFunc, opts

    id = req.body?.id or 'E0008'
    attr = req.body?.attr or 'cur_work_hash'
    [w, h] = req.body?.size?.split('x').map((v) -> parseInt v) or [950, 550]
    key = "#{id}:#{attr}"
    keys = ['id', 'attr', 'key', 'res', 'page']
    values = [id, attr, key, res, page]
    opts = _.object(keys, values)

    mc.get key, (err, buffer) ->
      logger.error "handleUpload get #{key} #{err.message}" if err
      if (config.dev and not debug_memcache) or not buffer
        page.set 'viewportSize', {width: w, height: h}
        if config.dev and not debug_mongo
          logger.info "reading #{id} #{attr} data from json file"
          do (opts) -> fs.readFile datafile, 'utf8', (err, raw) ->
              readJSON err, raw, opts
        else
          logger.info "reading #{id} #{attr} data from mongodb"
          do (opts) -> reps.findOne {id: id}, (err, raw) ->
              readJSON err, raw, opts
      else
        value = JSON.parse buffer.toString()
        logger.info "#{id} #{attr} hash found on memcache: #{value.hash}."
        opts.res.send 201, value

  handleFetch = (req, res) ->
    return logger.warn 'handleFetch headers already sent' if res.headerSent
    key = 'fetch'

    handleSuccess = (json, res) ->
      logger.info 'handleSuccess'
      postWrite = (err, result=false) ->
        if err
          logger.error 'postWrite ' + err.message
          res.send 500, {error: err.message}
        else
          logger.info 'Wrote data'
          value = JSON.stringify hash_list
          unless config.dev and not debug_memcache
            logger.info "setting #{key} for postWrite"
            mc.set key, value, cb, api_expires  # api work_data
          res.send 201, {data: hash_list}

      data_list = []
      hash_list = []

      for rep in json.data
        raw = (JSON.parse Common.getChartData a, rep[a], rep.id for a in config.data_attrs)
        hashes = (md5 JSON.stringify r for r in raw)
        data_obj = _.object config.hash_attrs, raw
        hash_obj = _.object config.hash_attrs, hashes
        data_obj.id = hash_obj.id = rep.id
        data_list.push data_obj
        hash_list.push hash_obj

      if not data_list
        logger.error 'data_list is blank'
        res.send 500, {error: 'data_list is blank'}
      else if config.dev and not debug_mongo
        logger.info 'writing data to json file'
        data = JSON.stringify _.object _.pluck(data_list, 'id'), data_list
        fs.writeFile datafile, data, postWrite
      else
        logger.info 'writing data to mongodb'
        reps.remove {}, {w:1}, (err, num_removed) ->
          if err
            logger.error 'handleSuccess remove reps ' + err.message
            res.send 500, {error: err.message}
          else reps.insert data_list, {w:1}, postWrite

    mc.get key, (err, buffer) ->
      logger.error "handleFetch get #{key} #{err.message}" if err

      if (config.dev and not debug_memcache) or not buffer
        do (res) -> request {url: req.body.url, json: true}, (err, resp, json) ->
          if err
            logger.error 'handleFetch ' + err.message
            res.send 500, {error: err.message}
          else if resp.statusCode is 200 then handleSuccess json, res
          else logger.error('handleFetch') and res.send 417
      else
        logger.info 'Hash list found! Fetching value from memcache.'
        value = JSON.parse buffer.toString()
        res.send 201, {data: value}

  # create server routes
  app.all '*', configCORS
  app.get '*', configPush
  app.get "/#{uploads}/:id", handleGet
  app.post "/api/flush", handleFlush
  app.post "/api/stats", getStatus
  app.post "/api/list", getList
  app.post '/api/fetch', handleFetch
  app.post '/api/upload', handleUpload

  # start server
  app.listen port, ->
    logger.info "Listening on port #{port}"
    logger.info """
      debug s3: #{debug_s3}
      debug mongodb: #{debug_mongo}
      debug memcache: #{debug_memcache}
      Try curl #{config.api_fetch} -H 'Accept: */*' --data 'url=#{config.api_get}work_data'
      Then curl #{config.api_upload} -H 'Accept: */*' --data 'id=E0018&attr=cur_work_hash'
      Then go to #{config.api_fetch[..-10]}#{uploads}/<hash>"""

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
      if err
        logger.error 'mongodb ' + err.message
      else
        logger.info 'Connected to mongodb'
        page.injectJs 'vendor/scripts/nvd3/d3.v3.js', ->
          page.injectJs 'vendor/scripts/nvd3/nv.d3.js', ->
            processPage page, ph, db.collection 'reps'
