Model = require 'models/base/model'
config = require 'config'
utils = require 'lib/utils'

module.exports = class Rep extends Model
  url: => "#{config.rep_url}#{@get 'login'}?access_token=#{config.api_token}"

  sync: (method, model, options) =>
    @local = -> method isnt 'read'
    model.collection.local = @local
    options.add = method is 'read'
    utils.log "#{model.get 'login'}'s sync method is #{method}"
    utils.log "sync #{model.get 'login'} to server: #{not @local()}"
    Backbone.sync(method, model, options)

  initialize: =>
    super
    @login = @get 'login'
    utils.log "initialize #{@login}'s model"
    @set created: new Date().toString() if @isNew() or not @has 'created'

  toggle: ->
    @set called: if @has('called') then not @get('called') else true
    @set score_sort: if @get('called') then 0 else @get 'followers'
    utils.log 'called: ' + @get 'called'
    utils.log 'followers: ' + @get 'followers'
    utils.log 'score sort: ' + @get 'score_sort'

  failWhale: (res, textStatus, err) =>
    utils.log "failed to fetch #{@login}'s data"
    utils.log "error: #{err} with #{@login}", 'error' if err

  setScoreSort: =>
    utils.log 'setting score data'
    @set score_sort: @get 'followers'
    utils.log 'score sort: ' + @get 'score_sort'
    @set called: false
    @saveTstamp config.score_attr
    @save patch: true

  setActivity: (data) =>
    @set config.data_attr, data
    @save patch: true
    @saveTstamp config.data_attr

  getActivity: =>
    utils.log "fetching #{@login}'s #{config.data_attr}"
    base = "https://api.github.com/users/#{@login}/events"
    url = "#{base}?access_token=#{config.api_token}"
    promise = $.get url
    do (model = @) -> promise.done(model.setActivity).fail(model.failWhale)

  fetchFunc: (force, type) =>
    return utils.log 'No name!', 'error' if not @has 'name'
    if force and type is 'score' then @setScoreSort()
    else if (type isnt 'score') and (force or @cacheExpired config.data_attr)
      utils.log "fetching new #{config.data_attr} data"
      if type is 'chart' then @getActivity().done(@setChart)
    else if type is 'score' and @cacheExpired config.score_attr
      @setScoreSort()
    else if type in ['chart', 'all'] and @cacheExpired config.chart_attr
      @setChart()
    else
      utils.log "model up to date with force: #{force} and type: #{type}"

  fetchData: (force=false, type=false) => $.Deferred((deferred) =>
    if force or not @has('name') or @cacheExpired config.info_attr
      utils.log "fetching #{@login}'s #{config.info_attr} data"
      saveTs = (model) -> model.saveTstamp config.info_attr
      fetch = (model) -> model.fetchFunc force, type
      resolve = (model) -> deferred.resolve model
      @modelFetch()
        .done(saveTs, fetch, resolve)
        .fail(@failWhale, deferred.reject)
    else
      deferred.resolve @
      utils.log "using cached #{config.info_attr} data"
      @fetchFunc false, type

    @display()).promise()

  convertData: (raw) ->
    endRows = []
    durRows = []
    dur_val = 5

    _.each raw, (model) ->
      created = model['created_at']
      date = moment(created).format('MM-DD-YYYY')
      time = moment(created).format('HH:mm:ss').split(':')
      start = (time[0] * 60) + (time[1] * 1) + (time[2] / 60)
      end_val = parseFloat start.toFixed(3)
      endRows.push {label: date, value: end_val}
      durRows.push {label: date, value: dur_val}

    data = [{key: 'End', values: endRows}, {key: 'Duration', values: durRows}]

  setChart: =>
    utils.log 'setting chart data'
    if @get config.data_attr
      utils.log "calculating #{@login}'s missing chart data"
      data = JSON.stringify @convertData @get(config.data_attr)
      # utils.log data, false
      @set config.chart_attr, data
      @set config.hash_attr, md5 data
      @saveTstamp config.chart_attr
      @save patch: true
    else utils.log "#{config.data_attr} not present"

  cacheExpired: (attr) =>
    utils.log "checking #{@login}'s #{attr} timestamp"
    tstamp = @get "#{attr}_tstamp"

    if tstamp
      string = 'ddd MMM DD YYYY HH:mm:ss [GMT]ZZ'
      mstamp = moment(tstamp, string)
      age = Math.abs mstamp.diff(moment(), 'hours')
      utils.log "#{attr} age: #{mstamp.fromNow(true)}"
      age >= config.max_age
    else
      utils.log "no #{attr} timestamp found"
      true
