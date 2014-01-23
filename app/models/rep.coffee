Model = require 'models/base/model'
Common = require 'lib/common'
config = require 'config'
utils = require 'lib/utils'

module.exports = class Rep extends Model
  url: => "https://api.github.com/users/#{@get 'login'}?access_token=#{config.api_token}"

  initialize: =>
    super
    @login = @get 'login'
    utils.log "initialize #{@login}'s model"
    @set created: new Date().toString() if @isNew() or not @has 'created'
    if @has('score_sort') or @has('score')
      ss = if @has 'score_sort' then @get 'score_sort' else @get 'score'
      @set score_sort: ss

  toggle: ->
    @set called: if @has('called') then not @get('called') else true
    @set score_sort: if @get('called') then 0 else @get 'score'
    utils.log 'called: ' + @get 'called'
    utils.log 'score: ' + @get 'score'
    utils.log 'score sort: ' + @get 'score_sort'

  failWhale: (res, textStatus, err) =>
    utils.log "failed to fetch #{@login}'s event data"
    utils.log "error: #{err} with #{@login}", 'error' if err

  setActivity: (data, textStatus, res) =>
    @set config.data_attr, data
    @saveTstamp config.data_attr
    @setChart()

  getActivity: =>
    url = "https://api.github.com/users/#{@login}/events"
    data = {access_token: "#{config.api_token}"}
    # post url to 'api/fetch' to fetch rep data serverside
    if config.mobile
      utils.log "fetching #{url} server side"
      $.post(config.api_fetch, url: url).done(@setActivity).fail(@failWhale)
    else $.get(url, data).done(@setActivity).fail(@failWhale)

  fetchData: (force=false) =>
    utils.log "fetching #{@login}'s #{config.data_attr}"
    if @cacheExpired "#{config.data_attr}_tstamp"
      utils.log "#{config.data_attr} cache not found or expired"
      @getActivity()
    else if force
      utils.log "refresh forced"
      @getActivity()
    else
      utils.log "using cached #{config.data_attr}"
      utils.log @, false
      @setChart()

  setChart: =>
    return utils.log "#mobile svg rendering disabled" if config.mobile
    utils.log 'setting chart data'
    chart_attr = config.data_attr + config.parsed_suffix
    if @get config.data_attr
      utils.log "fetching #{@login}'s missing chart data"
      data = Common.convertData @get(config.data_attr), @login
      utils.log data, false
      @set chart_attr, JSON.stringify data
      @save {patch: true}
    else utils.log "#{config.data_attr} not present"

  cacheExpired: (attr) =>
    utils.log "checking #{@login}'s #{attr}"
    tstamp = @get attr

    if tstamp
      string = 'ddd MMM DD YYYY HH:mm:ss [GMT]ZZ'
      mstamp = moment(tstamp, string)
      age = Math.abs mstamp.diff(moment(), 'hours')
      utils.log attr + ' age: ' + mstamp.fromNow(true)
      age >= config.max_age
    else
      utils.log 'no ' + attr + ' found'
