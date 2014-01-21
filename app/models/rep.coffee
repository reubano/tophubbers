Model = require 'models/base/model'
Common = require 'lib/common'
config = require 'config'
utils = require 'lib/utils'

module.exports = class Rep extends Model
  url: => "https://api.github.com/users/#{@get 'login'}?access_token=#{config.api_token}"

  initialize: =>
    super
    @login = @get 'login'
    utils.log "initialize rep #{@login} model"
    @set created: new Date().toString() if @isNew() or not @has 'created'
    @saveTstamp 'info'
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
    @parser.href = res.url
    utils.log "failed to fetch #{res.url}"
    utils.log "error: #{err} with #{res.url}", 'error' if err

  setActivity: (data, textStatus, res) =>
    @set config.data_attr, data
    @saveTstamp config.data_attr
    @setChart()

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

  getActivity: =>
    loc = "https://api.github.com/users/#{@login}/events"
    data = {access_token: "#{config.api_token}"}
    $.get(loc, data).done(@setActivity).fail(@failWhale)

  fetchData: (onlyIfExpired=false) =>
    utils.log "fetching #{@login}'s data"
    if @cacheExpired "#{config.data_attr}_tstamp"
      utils.log "#{config.data_attr} cache not found or expired"
      @getActivity()
    else if not onlyIfExpired
      utils.log "refresh forced"
      @getActivity()
    else
      utils.log "using cached #{config.data_attr} data"
      utils.log @, false
      @setChart()

  setChart: =>
    return utils.log "#mobile svg rendering disabled" if config.mobile
    utils.log 'setting chart data'
    chart_attr = config.data_attr + config.parsed_suffix
    if @get config.data_attr
      utils.log "fetching #{@login}'s missing chart data"
      data = @convertData @get config.data_attr
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
