View = require 'views/base/view'
Common = require 'lib/common'
makeChart = require 'lib/makechart'
config = require 'config'
template = require 'views/templates/graph'
utils = require 'lib/utils'

module.exports = class GraphView extends View
  autoRender: false
  autoAttach: false
  template: template
#   listen:
#     'all': (event) -> utils.log "heard #{event}"
#     addedToParent: -> utils.log 'graph-view heard addedToParent'
#     visibilityChange: -> utils.log 'graph-view heard visibilityChange'

  initialize: (options) =>
    super
    @model = options.model
    @refresh = options.refresh
    @ignore_cache = options.ignore_cache
    @login = @model.get 'login'
    @has_svg = config.svg
    @canvas = config.canvas
    @rendered = false
    @changed = false

    utils.log "initialize graph-view for #{@login}"
    utils.log options, false

    @listenTo @model, "change:#{config.chart_attr}", =>
      utils.log "graph-view heard #{@login}'s change:#{config.chart_attr}"
      @changed = true
      @unsetCache @model
      _.defer @getChartScript, @model

    @model.fetchData(@refresh, 'chart').done (model) =>
      _.defer @getChartScript, model

  render: =>
    super
    utils.log "rendering graph-view for #{@login}"
    @attach()
    @rendered = true
    @pubRender "#{@login}-view"

  getChartScript: (model) =>
    login = model.get 'login'
    parent = Common.getParent login

    if $(parent)?.html()?.length > 20 and not @changed and not @ignore_cache
      return utils.log 'getChartScript requirements not met'

    utils.log "getting chart for #{login}"
    @unsetCache model if @ignore_cache
    @text = if @has_svg then "#{login} #{config.svg_attr}" else "#{login} #{config.img_attr}"
    chart_json = model.has config.chart_attr
    name = model.get 'name'
    hash = model.get config.hash_attr
    svg = model.get config.svg_attr
    img = model.get config.img_attr

    if @canvas and img and not @changed and not @ignore_cache
      utils.log "fetching #{@text} from cache"
      $(parent).html img
      @pubRender config.img_attr
    else if @canvas and hash
      utils.log "fetching #{@text} from server"
      string = model.get config.chart_attr
      utils.sessionStorage login, string
      publish = => @pubRender config.img_attr
      @getImg(login, hash).done(@setImg, publish).fail(@gvFailWhale)
    else if svg and not @changed and not @ignore_cache
      utils.log "drawing #{@text} from cache"
      $(parent).html svg
      @pubRender config.svg_attr
    else if chart_json and name
      selection = Common.getSelection login
      utils.log "#{login} has svg: #{svg?}"
      utils.log "#{login} ignore svg: #{@ignore_cache}"
      utils.log "fetching script for #{selection}"
      chart_data = JSON.parse model.get config.chart_attr
      do (login, parent, model) =>
        nv.addGraph makeChart(chart_data, selection, @changed, true), =>
          @setSVG login, parent, model
          @pubRender config.svg_attr
    else utils.log "#{login} has no #{config.chart_attr} or hash or name"

  pubRender: (attr) =>
    @publishEvent 'rendered:' + attr
    utils.log 'published rendered:' + attr

  unsetCache: (model) =>
    attr = if @has_svg then config.svg_attr else config.img_attr
    utils.log "unsetting #{model.get 'login'} #{attr}"
    model.unset attr
    model.save()

  setImg: (model, parent) =>
    html = $(parent).html()
    login = model.get 'login'

    if html?.length > 50
      img = html.replace(/\"/g, '\'')
      utils.log "setting #{login} #{config.img_attr}"
      model.set config.img_attr, img
      model.save()
    else utils.log "html appears blank for #{login}: #{html.length}"

  setSVG: (login, parent, model) =>
    html = $(parent).html()
    bad = ['opacity: 0.0', 'opacity: 0.1', 'opacity: 0.2', 'opacity: 0.3',
      'opacity: 0.4', 'opacity: 0.5', 'opacity: 0.6']

    if html and (html.indexOf(b) < 0 for b in bad) and html.length > 40
      svg = html.replace(/\"/g, '\'')
      utils.log "setting #{login} #{config.svg_attr}"
      model.set config.svg_attr, svg
      model.save()
    else utils.log "html blank or malformed for #{login} with length #{html.length}"

  getImg: (login, hash) => $.Deferred((deferred) =>
    parent = Common.getParent login
    data = {login: login, hash: hash}
    res = {location: "#{config.api_render}?#{JSON.stringify data}", status: 417}
    model = @model

    if $(parent)
      url = "#{config.api_uploads}/#{login}/#{hash}"
      utils.log "setting html for #{parent} to #{url}"

      $(parent).html "<img src=#{url}>"
      $("#{parent} img").one 'error', -> deferred.reject res
      $("#{parent} img").one 'load', -> deferred.resolve model, parent
    else
      utils.log "selection #{parent} doesn't exist", 'error'
      deferred.reject res).promise()

  gvSuccess: (data, textStatus, res) =>
    utils.log 'enter gvSuccess'
    loc = res.getResponseHeader 'Location'

    if data?.login? and data?.hash?
      utils.log "getting #{data.login}'s image"
      @getImg(data.login, data.hash).done(@setImg).fail(@gvFailWhale)
    else if loc
      splits1 = loc.split('/')
      splits2 = loc.split('?')

      if 'progress' in splits1
        wait = parseInt res.getResponseHeader 'Retry-After'
        utils.log "checking progress: #{loc} in #{wait/1000}s"
        _.delay (=> $.get(loc).done(@gvSuccess).fail(@gvFailWhale)), wait
      else if splits2.length > 1
        url = splits[0]
        data = JSON.parse splits[1]
        data.string = utils.sessionStorage data.login if data.data
        utils.log "posting data to #{url}"
        $.post(url, data).done(@gvSuccess).fail(@gvFailWhale)
      else utils.log "error parsing location #{loc}", 'error'
    else utils.log "Location header not found", 'error'

  gvFailWhale: (res, textStatus, err) =>
    utils.log 'enter gvFailWhale'
    if res.status is 503
      wait = parseInt res.getResponseHeader 'Retry-After'
      utils.log "retrying #{res.getResponseHeader 'Location'} in #{wait/1000}s"
      do (res) => _.delay @gvSuccess, wait, {}, 'OK', res
    else if res.status is 417
      loc = res.location ? res.getResponseHeader('Location')
      splits = loc?.split('?') ? false
      return utils.log "Location header not found", 'error' if not loc
      url = splits[0]
      data = JSON.parse splits[1]
      data.string = utils.sessionStorage data.login
      utils.log "posting data to #{url}"
      $.post(url, data).done(@gvSuccess).fail(@gvFailWhale)
    else
      try
        error = JSON.parse(res.responseText).error
      catch error
        error = res.responseText
      utils.log "failed to fetch png: #{error}.", 'error'
