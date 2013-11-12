config = require 'config'
Chaplin = require 'chaplin'
SiteView = require 'views/site-view'
NavbarView = require 'views/navbar-view'
utils = require 'lib/utils'

module.exports = class Controller extends Chaplin.Controller
  model: Chaplin.mediator.navbar
  collection: Chaplin.mediator.reps

  beforeAction: (params, route) =>
    @compose 'site', SiteView
    utils.log 'beforeAction'
    @publishEvent 'clearView'
    @compose 'auth', ->
      SessionController = require 'controllers/session-controller'
      @controller = new SessionController params

    @compose 'navbar', => @view = new NavbarView {@model}

  parser: document.createElement('a')

  getResList: (list) =>
    (item: i, tstamp: i + '_tstamp', url: config.api_get + i for i in list)

  getData: (url) ->
    # add logic to fetch png if on mobile and 'work_data' is in url
    # post url to 'api/fetch' to fetch rep data serverside
    if config.mobile and (/work_data/).test url
      utils.log "fetching #{url} server side"
      $.ajax
        url: config.api_fetch
        data: {url: url}
        type: 'post'
        dataType: 'json'
        beforeSend: (res, settings) -> res.url = settings.url
    else
      utils.log "fetching #{url} client side"
      $.ajax
        url: url
        type: 'get'
        dataType: 'json'
        beforeSend: (res, settings) -> res.url = settings.url

  fetchData: (list=false, id=false, attrs=false) =>
    @id = id
    @attrs = attrs
    list = list or config.res

    for r in @getResList(list)
      @getData(r.url).done(@setReps, @setCharts).fail(@failWhale)

  fetchExpiredData: (list=false, id=false, attrs=false) =>
    @id = id
    @attrs = attrs
    list = list or config.res

    for r in @getResList(list)
      if (@cacheExpired r.tstamp)
        utils.log r.item + ' cache not found or expired'
        @getData(r.url).done(@setReps, @setCharts).fail(@failWhale)
      else
        utils.log 'using cached ' + r.item + ' data'
        @displayCollection()
        @setCharts 'HTTP 200', 'success', url: r.url

  failWhale: (res, textStatus, err) =>
    @parser.href = res.url
    utils.log 'failed to fetch ' + res.url
    utils.log "error: #{err}", 'error' if err
    $.get config.api_get + 'reset'

  saveCollection: =>
    utils.log 'saving collection'
    (model.save {patch: true} for model in @collection.models)

  displayCollection: =>
    utils.log @collection, false
    utils.log @collection.get('E0008').getAttributes(), false

  saveTstamp: (tstamp) =>
    utils.log 'saving ' + tstamp
    date = new Date().toString()
    (model.set tstamp, date for model in @collection.models)

  setReps: (data, textStatus, res) =>
    if data?.data?
      @parser.href = res.url
      attr = (@parser.pathname.replace /\//g, '')
      tstamp = attr + '_tstamp'
      utils.log 'setting collection with ' + attr
      utils.log data.data, false
      @collection.set data.data, remove: false
      @saveTstamp(tstamp)
      @saveCollection()
      @publishEvent 'repsSet'
      utils.log 'published repsSet'
      utils.log 'collection length: ' + @collection.length
      @displayCollection()

  setCharts: (data, textStatus, res) =>
    @parser.href = res.url
    source = (@parser.pathname.replace /\//g, '')
    chartable = source is config.to_chart

    if chartable and not config.mobile
      utils.log 'setting chart data for ' + source

      models = if @id then [@collection.get(@id)] else @collection.models
      attrs = @attrs or config.data_attrs

      for model in models
        for attr in attrs
          chart_attr = attr + config.parsed_suffix
          id = model.get 'id'

          # if (not model.get(chart_attr) or model.hasChanged(attr))
          if model.get(attr)
            utils.log id + ': fetching missing chart data'
            data = model.getChartData attr
            utils.log JSON.parse(data), false
            model.set chart_attr, data
            model.save {patch: true}
          else
            utils.log attr + ' not present'
            # text = id + ': ' + chart_attr + ' present and '
            # utils.log text + attr + ' unchanged'
    else if chartable and config.mobile
      utils.log "#{source} svg rendering disabled on mobile"
    else utils.log source + ' not chartable'

  cacheExpired: (attr) =>
    # check if the cache has expired
    utils.log 'checking ' + attr
    tstamp = @collection.at(1).get attr

    if tstamp
      string = 'ddd MMM DD YYYY HH:mm:ss [GMT]ZZ'
      mstamp = moment(tstamp, string)
      age = Math.abs mstamp.diff(moment(), 'hours')
      utils.log attr + ' age: ' + mstamp.fromNow(true)
      age >= config.max_age
    else
      utils.log 'no ' + attr + ' found'
      true
