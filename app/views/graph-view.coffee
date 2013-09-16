View = require 'views/base/view'
Common = require 'lib/common'
makeChart = require 'lib/makechart'
config = require 'config'
template = require 'views/templates/graph'
utils = require 'lib/utils'

module.exports = class GraphView extends View
	template: template
#	listen:
#		addedToParent: 'getChartScript'
#		addedToParent: 'addedToParentAlert'
#		visibilityChange: 'visibilityChangeAlert'

	initialize: (options) =>
		super
		@attrs = options.attrs
		@chart_suffix = config.chart_suffix
		@ignore_cache = options.ignore_cache
		@id = @model.get 'id'
		@changed = false
		@mobile = config.mobile
		utils.log 'initialize graph-view for ' + @id
		utils.log options, false

		listen_attrs = if @mobile then config.data_attrs else config.hash_attrs
		changes = ('change:' + attr + @chart_suffix for attr in listen_attrs)

		@listenTo @model, changes[0], ->
			utils.log 'graph-view heard ' + changes[0]
			@changed = true
			@unsetCache listen_attrs[0]
			@render() if listen_attrs[0] in @attrs

		@listenTo @model, changes[1], ->
			utils.log 'graph-view heard ' + changes[1]
			@changed = true
			@unsetCache listen_attrs[1]
			@render() if listen_attrs[1] in @attrs

	render: =>
		super
		utils.log 'rendering graph-view for ' + @id
		@attach()
		_.defer @getChartScript, @ignore_cache

	visibilityChangeAlert: ->
		utils.log 'graph-view heard visibilityChange'

	addedToParentAlert: ->
		utils.log 'graph-view heard addedToParent'

	getChartScript: (ignore_cache) =>
		utils.log 'getting chart script for ' + @id

		for attr in @attrs
			@attr = attr
			utils.log 'setting variables for ' + @attr
			@options = {attr: attr, id: @id}
			selection = Common.getSelection @options
			@parent = Common.getParent @options
			@text = "#{@id} #{@attr}"
			@svg_attr = attr + config.svg_suffix
			@img_attr = attr + config.img_suffix
			chart_attr = attr + @chart_suffix
			chart_json = @model.get chart_attr
			name = @model.get 'first_name'
			svg = if @model.has @svg_attr then @model.get @svg_attr else null
			img = if @model.has @img_attr then @model.get @img_attr else null

			if @mobile and img and not @changed and not ignore_cache
				utils.log "fetching #{@text} png from cache"
				utils.log img
				@$(@parent).html img
				@pubRender @attr
			else if @mobile and name
				utils.log "getting #{@text} png from server"
				$.post(config.api_upload, @options).done(@gvSuccess).fail(@gvFailWhale)
			else if svg and not @changed and not ignore_cache
				utils.log "drawing #{@text} chart from cache"
				@$(@parent).html svg
				@pubRender @attr
			else if chart_json and name
				utils.log "#{@text} has svg: #{svg?}"
				utils.log "#{@text} ignore svg: #{ignore_cache}"
				utils.log "#{@text} has changed: #{@changed}"
				utils.log "getting #{@text} script"
				chart_data = JSON.parse chart_json
				_.defer makeChart, chart_data, selection, @changed
				_.defer @unsetCache, @attr
				_.defer @setSVG, @options
				_.defer @pubRender, @attr
			else
				utils.log "#{@id} has no #{chart_attr} or no name"

	pubRender: (attr) =>
		@publishEvent 'rendered:' + attr
		utils.log 'published rendered:' + attr

	unsetCache: (attr) =>
		utils.log "unsetting #{attr} cache"
		suffix = if @mobile then 'img_suffix' else 'svg_suffix'
		@model.unset attr + config[suffix]
		@model.save()

	setImg: (options) =>
		parent = Common.getParent options
		html = @$(parent).html()

		if html and html.length is 57
			utils.log "setting #{options.id} #{options.attr} img"
			img = html.replace(/\"/g, '\'')
			@model.set options.attr + config.img_suffix, img
			@model.save()
		else
			utils.log 'html blank or malformed for ' + parent

	setSVG: (options) =>
		parent = Common.getParent options
		html = @$(parent).html()
		bad = 'opacity: 0.000001;'

		if html and html.indexOf(bad) < 0 and html.length > 40
			utils.log "setting #{options.id} #{options.attr} svg"
			svg = html.replace(/\"/g, '\'')
			@model.set options.attr + config.svg_suffix, svg
			@model.save()
		else
			utils.log 'html blank or malformed for ' + parent

	gvSuccess: (data, resp, options) =>
		parent = Common.getParent data
		utils.log "successfully fetched png for #{data.id}!"
		url = "/uploads/#{data.hash}.png"
		utils.log "setting html for #{parent} to #{url}"
		@$(parent).html "<img src=#{url}>"
		_.defer @setImg, data
		@pubRender data.attr

	gvFailWhale: (data, xhr, options) =>
		utils.log "failed to fetch png for #{data}."
