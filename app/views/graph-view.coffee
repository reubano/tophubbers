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
		@ignore_svg = options.ignore_svg
		@id = @model.get 'id'
		@changed = false
		utils.log 'initialize graph-view for ' + @id
		utils.log options, false

		data_attrs = config.data_attrs
		changes = ('change:' + attr + @chart_suffix for attr in data_attrs)

		@listenTo @model, changes[0], ->
			utils.log 'graph-view heard ' + changes[0]
			@changed = true
			@unsetSVG data_attrs[0]
			@render() if data_attrs[0] in @attrs

		@listenTo @model, changes[1], ->
			utils.log 'graph-view heard ' + changes[1]
			@changed = true
			@unsetSVG data_attrs[1]
			@render() if data_attrs[1] in @attrs

	render: =>
		super
		utils.log 'rendering graph-view for ' + @id
		@attach()
		_.defer @getChartScript, @ignore_svg

	visibilityChangeAlert: ->
		utils.log 'graph-view heard visibilityChange'

	addedToParentAlert: ->
		utils.log 'graph-view heard addedToParent'

	getChartScript: (ignore_svg) =>
		utils.log 'getting chart script for ' + @id
		# utils.log @model.get 'chart'

		for attr in @attrs
			@attr = attr
			utils.log 'setting variables for ' + @attr
			@options = {attr: attr, id: @id}
			selection = Common.getSelection @options
			@parent = Common.getParent @options
			@text = "#{@id} #{@attr}"
			svg_attr = attr + config.svg_suffix
			chart_attr = attr + @chart_suffix
			chart_json = @model.get chart_attr
			name = @model.get 'first_name'
			svg = if @model.has svg_attr then @model.get svg_attr else null

			if config.mobile
				utils.log "getting #{@text} png from server"
				$.post(config.api_upload, @options).done(@success).fail(@failWhale)
			else if svg and not @changed and not ignore_svg
				utils.log "drawing #{@text} chart from cache"
				@$(@parent).html svg
				@pubRender()
			else if chart_json and name
				utils.log "#{@text} has svg: #{svg?}"
				utils.log "#{@text} ignore svg: #{ignore_svg}"
				utils.log "#{@text} has changed: #{@changed}"
				utils.log "getting #{@text} script"
				chart_data = JSON.parse chart_json
				_.defer makeChart, chart_data, selection, @changed
				_.defer @setSVG
				_.defer @pubRender
			else
				utils.log "#{@id} has no #{chart_attr} or no name"

	pubRender: =>
		@publishEvent 'rendered:' + @attr
		utils.log 'published rendered:' + @attr

	unsetSVG: (attr) =>
		svg_attr = attr + config.svg_suffix
		utils.log 'unsetting ' + svg_attr
		@model.unset svg_attr
		@model.save()

	setSVG: =>
		html = @$(@parent).html()
		bad = 'opacity: 0.000001;'

		if html and html.indexOf(bad) < 0 and html.length > 40
			svg_attr = attr + config.svg_suffix
			utils.log "setting #{@text} svg"
			svg = html.replace(/\"/g, '\'')
			@model.set svg_attr, svg
			@model.save()
		else
			utils.log 'html blank or malformed for ' + @parent

	success: (data, resp, options) =>
		utils.log "successfully fetched png for #{@id}!"
		url = "uploads/#{data.hash}.png"
		utils.log "setting html for #{@parent} to #{url}"
		@$(@parent).html "<img src=#{url}>"
		@pubRender()

	failWhale: (data, xhr, options) =>
		utils.log "failed to fetch png for #{@id}."
		console.log data
		console.log xhr
		console.log options
