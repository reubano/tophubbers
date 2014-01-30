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
#     addedToParent: 'getChartScript'
#     addedToParent: 'addedToParentAlert'
#     visibilityChange: 'visibilityChangeAlert'

  initialize: (options) =>
#     console.log options
    super
    @attr = options.attr
    @refresh = options.refresh
    @ignore_cache = options.ignore_cache
    @id = @model.get('id')
    @location = @model.get('location')
    @login = @model.get('login')
    @mobile = config.mobile
    @listen_suffix = if @mobile then '' else config.parsed_suffix
    @changed = false

    utils.log "initialize graph-view for #{@login}"
    utils.log options, false

    @listen_attr = if @mobile then config.hash_attr else config.data_attr
    @chart_attr = @attr + @listen_suffix
    changes = 'change:' + @listen_attr + @listen_suffix

    @listenTo @model, changes, =>
      utils.log 'graph-view heard ' + changes
      @changed = @listen_attr
      @unsetCache @changed
      @render() if @changed is @attr

    @model.fetchData @refresh, 'chart'

  render: =>
    super
    utils.log "rendering graph-view for #{@login}"
    @attach()
    _.defer @getChartScript, @ignore_cache

  visibilityChangeAlert: ->
    utils.log 'graph-view heard visibilityChange'

  addedToParentAlert: ->
    utils.log 'graph-view heard addedToParent'

  getChartScript: (ignore_cache) =>
    utils.log "getting chart for #{@login}"
    @unsetCache @listen_attr if ignore_cache
    utils.log 'setting variables for ' + @attr
    @options = {attr: @attr, id: @id}
    @parent = Common.getParent @login
    console.log "parent is #{@parent}"
    @svg_attr = @attr + config.svg_suffix
    @img_attr = @attr + config.img_suffix
    @text = if @mobile then "#{@login} #{@img_attr}" else "#{@login} #{@svg_attr}"
    chart_json = @model.has @chart_attr
    name = @model.get 'name'
    svg = if @model.has @svg_attr then @model.get @svg_attr else null
    img = if @model.has @img_attr then @model.get @img_attr else null

    if @mobile and img and not @changed and not ignore_cache
      utils.log "fetching #{@text} from cache"
      utils.log img
      @$(@parent).html img
      @pubRender @attr
    else if @mobile and name
      utils.log "fetching #{@text} from server"
      data = {hash: @model.get @attr}
      _.extend data, @options
      $.post(config.api_render, data).done(@gvSuccess).fail(@gvFailWhale)
    else if svg and not @changed and not ignore_cache
      utils.log "drawing #{@text} from cache"
      @$(@parent).html svg
      @pubRender @attr
    else if chart_json and name
      selection = Common.getSelection @login
      utils.log "#{@login} #{@attr} has svg: #{svg?}"
      utils.log "#{@login} #{@attr} ignore svg: #{ignore_cache}"
      utils.log "fetching script for #{selection}"
      chart_data = JSON.parse @model.get @chart_attr
      do (@login, @attr) =>
        nv.addGraph makeChart(chart_data, selection, @changed), =>
          @setSVG @login
          @pubRender @attr
    else utils.log "#{@login} has no #{@chart_attr} or no name"

  pubRender: (attr) =>
    @publishEvent 'rendered:' + attr
    utils.log 'published rendered:' + attr

  unsetCache: (prefix) =>
    suffix = if @mobile then 'img_suffix' else 'svg_suffix'
    attr = prefix + config[suffix]
    utils.log "unsetting #{@login} #{attr}"
    @model.unset attr
    @model.save()

  setImg: (login) =>
    parent = Common.getParent login
    html = $(parent).html()

    if html and html.length is 57
      img = html.replace(/\"/g, '\'')
      attr = "chart#{config.img_suffix}"
      utils.log "setting #{login} #{attr}"
      @model.set attr, img
      @model.save()
    else
      utils.log 'html blank or malformed for ' + parent

  setSVG: (login) =>
    parent = Common.getParent login
    html = @$(parent).html()
    bad = ['opacity: 0.0', 'opacity: 0.1', 'opacity: 0.2', 'opacity: 0.3',
      'opacity: 0.4', 'opacity: 0.5', 'opacity: 0.6']

    if html and (html.indexOf(b) < 0 for b in bad) and html.length > 40
      svg = html.replace(/\"/g, '\'')
      attr = @attr + config.svg_suffix
      utils.log "setting #{login} #{attr}"
      @model.set attr, svg
      @model.save()
    else
      utils.log 'html blank or malformed for ' + parent

  gvSuccess: (data, textStatus, res) =>
    if data?.login?
      login = data.login
      parent = Common.getParent login
      utils.log "successfully fetched png for #{login}!"

      if $(parent)
        url = "#{config.api_uploads}/#{data.hash}"
        utils.log "setting html for #{parent} to #{url}"
        $(parent).html "<img src=#{url}>"
        @setImg login
        @pubRender data.attr
      else utils.log "selection #{parent} doesn't exist", 'error'
    else
      loc = res.getResponseHeader 'Location'

      try
        splits = loc.split('/') if loc else false
      catch TypeError
        splits = false

      if 'progress' in splits
        utils.log "trying to get progress: #{loc}", false
        $.get(loc).done(@gvSuccess).fail(@gvFailWhale)
      else if splits
        utils.log "trying to post render: #{splits[1]}", false
        $.post(config.api_render, splits[1]).done(@gvSuccess).fail(@gvFailWhale)
      else utils.log "Location header not found", 'error'

  gvFailWhale: (res, textStatus, err) =>
    if res.status is 503
      wait = parseInt res.getResponseHeader 'Retry-After'
      console.log "retrying #{res.getResponseHeader 'Location'} in #{wait/1000}s"
      do (res) => _.delay @gvSuccess, wait, {}, 'OK', res
    else
      try
        error = JSON.parse(res.responseText).error
      catch error
        error = res.responseText
      utils.log "failed to fetch png: #{error}.", 'error'
