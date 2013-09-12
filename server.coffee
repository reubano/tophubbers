# Usage: coffee server.coffee

# External dependencies
express = require 'express'
phantom = require 'phantom'
winston = require 'winston'
rest = require 'restler'
# murmur = require 'murmurhash-js'
# crypto = require('crypto').createHash('md5')
blueimp = require('blueimp-md5').md5
d3 = require 'd3'
_ = require 'underscore'

# Internal dependencies
path = require 'path'
fs = require 'fs'

# Local dependencies
Common = require './app/lib/common.coffee'
makeChart = require './app/lib/makechart.coffee'
config = require './app/config.coffee'

# Set variables
app = express()
uploads = 'uploads'
oneDay = 86400000
selector = Common.getSelection()
attrs = config.data_attrs
port = process.env.PORT or 3333
datafile = path.join 'public', uploads, 'data.json'
logger = new winston.Logger
  transports: [
    new winston.transports.Console(),
    new winston.transports.File {filename: 'server.log', maxsize: 2097152}]

# CORS support
configCORS = (req, res, next) ->
  logger.info "Configing CORS"
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

# serve images
handleGet = (req, res) ->
  id = req.params.id
  filename = path.join 'public', uploads, "#{id}.png"
  fs.exists filename, (exists) ->
    if exists
      logger.info "Image #{id}.png exists! Serving to page."
      res.sendfile filename
    else
      logger.warning "Image #{id}.png doesn't exist."
      res.send 404, "Sorry! Image #{id}.png doesn't exist."

# middleware
# pipe web server logs through winston
winstonStream = {write: (message, encoding) -> logger.info message}
app.use express.logger {stream:winstonStream}
app.use express.bodyParser()
app.use express.compress()
app.use express.static __dirname + '/public', {maxAge: oneDay}

# phantomjs
processPage = (page, ph) ->
  logger.info 'Processing phantom page'

  handleUpload = (req, res) ->
    sendHash = (result) ->
      data = JSON.stringify result.container.__data__
      # hash = murmur.murmur3 data, 5
      hash = blueimp data
      # hash = crypto.update(data).digest 'hex'
      # logger.info "hash #{hash}, data #{data}"
      filename = path.join 'public', uploads, "#{hash}.png"
      fs.exists filename, (exists) ->
        if exists
          logger.info "File #{filename} exists. Sending image hash."
          res.send 201, {hash: hash, type: 'cached'}
        else
          # need to figure out how to delete old photos
          logger.info "File #{filename} doesn't exist. Creating new image."
          # page.renderBase64 'png', (str) -> res.send 201, {uri: str}
          page.render filename, -> res.send 201, {hash: hash, type: 'new'}

    id = req.body?.id or 'E0008'
    attr = req.body?.attr or 'cur_work_data'
    [w, h] = req.body?.size?.split('x').map((v) -> parseInt v) or [950, 550]
    page.set 'viewportSize', {width: w, height: h}

    fs.readFile datafile, 'utf8', (err, raw) ->
      if err
        res.send 404, {error: err.message}
      else
        data = JSON.parse raw
        page.injectJs 'vendor/scripts/nvd3/d3.v3.js', ->
          page.injectJs 'vendor/scripts/nvd3/nv.d3.js', ->
            page.evaluate makeChart, sendHash, data[id][attr], selector

  handleFetch = (req, res) ->
    handleSuccess = (json, response) ->
      list = []
      for rep in json.data
        raw = (JSON.parse Common.getChartData a, rep[a], rep.id for a in attrs)
        list.push _.object attrs, raw

      data = JSON.stringify _.object (rep.id for rep in json.data), list

      fs.writeFile datafile, data, (err) ->
        if err
          res.send 500, {status: response.statusCode, error: err.message}
        else
          res.send 201, {hash: blueimp data}

    handleFailure = (data, response) ->
      res.send 417, {status: response.statusCode, response: data}

    handleError = (err, response) ->
      res.send 500, {status: response.statusCode, error: err.message}

    logger.info 'running restler'
    rest.get(req.body.url)
      .on('success', handleSuccess)
      .on('fail', handleFailure)
      .on('error', handleError)

  # create server routes
  app.all '*', configCORS
  app.get '*', configPush
  app.get "/#{uploads}/:id", handleGet
  app.post '/api/fetch', handleFetch
  app.post '/api/upload', handleUpload

  # start server
  app.listen port, ->
    logger.info "Listening on #{port}"
    logger.info """
      Try curl --data 'url=http://localhost:5000/work_data' http://localhost:#{port}/api/fetch
      Then curl --data 'id=E0018&attr=prev_work_data' http://localhost:#{port}/api/upload
      Then go to http://localhost:#{port}/#{uploads}/<hash>"""

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
    processPage page, ph
