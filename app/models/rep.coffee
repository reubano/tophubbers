Model = require 'models/base/model'
Common = require 'lib/common'
config = require 'config'
utils = require 'lib/utils'

module.exports = class Rep extends Model
  url: => "https://api.github.com/users/#{@get 'login'}?access_token=#{config.api_token}"

  sync: (method, model, options) =>
    @server = method is 'read'
    utils.log "#{model.get 'login'}'s sync method is #{method}"
    utils.log "sync #{model.get 'login'} to server: #{@server}"
    Backbone.sync(method, model, options)

  initialize: =>
    super
    @login = @get 'login'
    utils.log "initialize #{@login}'s model"
    @set created: new Date().toString() if @isNew() or not @has 'created'
    ss = if @has 'score_sort' then @get 'score_sort' else @get 'followers'
    @set score_sort: ss

  toggle: ->
    @set called: if @has('called') then not @get('called') else true
    @set score_sort: if @get('called') then 0 else @get 'followers'
    utils.log 'called: ' + @get 'called'
    utils.log 'score: ' + @get 'score'
    utils.log 'score sort: ' + @get 'score_sort'

  failWhale: (res, textStatus, err) =>
    utils.log "failed to fetch #{@login}'s data"
    utils.log "error: #{err} with #{@login}", 'error' if err

  setScoreSort: =>
    utils.log 'setting score sort'
    @set score_sort: @get 'followers'
    @set called: false
    @save patch: true

  setActivity: (data) =>
    @set config.data_attr, data
    @save patch: true
    @saveTstamp config.data_attr

  getActivity: =>
    utils.log "fetching #{@login}'s #{config.data_attr}"
    url = "https://api.github.com/users/#{@login}/events"
    data = {access_token: "#{config.api_token}"}

    # post url to 'api/fetch' to fetch rep data serverside
    if config.svg
      utils.log "fetching #{url} client side"
      do (model = @) -> $.get(url, data)
        .done(model.setActivity).fail(model.failWhale)
    else
      utils.log "fetching #{url} server side"
      do (model = @) -> $.post(config.api_fetch, url: url)
        .done(model.setActivity).fail(model.failWhale)

  fetchFunc: (force, type) =>
    if @cacheExpired(config.data_attr) or force
      utils.log "fetching new data"
      if type is 'chart' then @getActivity().done(@setChart)
      else if type is 'progress' then @setProgress()
      else if type is 'score' then @setScoreSort()
    else
      utils.log "using cached data"
      if type is 'chart' and @cacheExpired config.chart_attr then @setChart()
      else if type is 'progress' and @cacheExpired config.prgrs_attr
        @setProgress()
      else if type is 'score' and @cacheExpired config.info_attr
        @setScoreSort()

  fetchData: (force=false, type=false) =>
    if force or not @has('login') or @cacheExpired config.info_attr
      utils.log "fetching #{@login}'s #{config.info_attr} data"
      do (force, type) => @promize()
        .done((model) -> model.saveTstamp config.info_attr)
        .done((model) -> model.fetchFunc(force, type))
        .fail(@failWhale)
    else
      utils.log "using cached #{config.info_attr} data"
      @fetchFunc false, type

    utils.log @, false

  setProgress: =>
    utils.log 'setting progress data'
    if @get config.data_attr
      target = 100
      max = 20000
      pts = @get('followers') / max * 100

      utils.log "calculating #{@login}'s missing progress data"

      pre = Math.min(pts, target) - 1
      to_date = if (pts >= target) then 0 else target - pre - 1
      post = if (pts > target) then pts - pre - 1 else 0
      gap = target - (pre + to_date + post) - 1
      end = if pts >= target then 0 else 1

      @save
        pts: pts, pre: pre, to_date: to_date, post: post, gap: gap, end: end
        patch: true

      @saveTstamp config.prgrs_attr
    else utils.log "#{config.data_attr} not present"

  setChart: =>
    return utils.log "#svg rendering not detected" if config.canvas
    utils.log 'setting chart data'
    if @get config.data_attr
      utils.log "calculating #{@login}'s missing chart data"
      data = Common.convertData @get(config.data_attr), @login
      utils.log data, false
      @set config.chart_attr, JSON.stringify data
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
