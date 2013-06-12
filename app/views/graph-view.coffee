config = require 'config'
nvd3util = require 'lib/nvd3util'
View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template
#  	listen:
# 		addedToParent: 'getChartScript'
# 		addedToParent: 'addedToParentAlert'
# 		visibilityChange: 'visibilityChangeAlert'

	initialize: (options) =>
		super
		console.log 'initialize graph-view'
		@attrs = options.attrs
		@id = @model.get 'id'

		for attr in @attrs
			change = 'change:' + attr + config.chart_suffix
			@listenTo @model, change, @render
			@listenTo @model, change, @modelChangeAlert
			# @subscribeEvent 'dispatcher:dispatch', ->
			#	console.log 'graph-view caught dispatcher event'

	render: =>
		super
		console.log 'rendering graph view for ' + @id
		@attach()
		_.defer @getChartScript

	modelChangeAlert: ->
		console.log 'graph-view heard modelChange'

	visibilityChangeAlert: ->
		console.log 'graph-view heard visibilityChange'

	addedToParentAlert: ->
		console.log 'graph-view heard addedToParent'

	getChartScript: (ignore_svg=false, force=false) =>
		# console.log 'chart html'
		# console.log @model.get 'chart'

		for attr in @attrs
			chart_class = 'chart-' + attr[0..2]
			selection = '#' + @id + '.view .' + chart_class + ' svg'
			parent = '#' + @id + '.view .' + chart_class
			svg_attr = attr + config.svg_suffix
			chart_attr = attr + config.chart_suffix
			chart_json = @model.get chart_attr
			name = @model.get 'first_name'
			svg = if @model.get svg_attr then @model.get svg_attr else false
			rendered = if @$(selection).html() then true else false
			changed = @model.hasChanged attr
			text = @id + ' ' + attr + ' '

			# console.log text + 'is rendered: ' + rendered
			# console.log text + 'has changed: ' + changed
			# console.log text + 'has cached svg: ' + if svg then 'true' else 'false'

			if (rendered and not changed and not force)
				console.log text + "hasn't changed and already rendered"
			else if (svg and not changed and not ignore_svg)
				console.log 'drawing ' + text + 'chart from cache'
				@$(parent).html svg
			else if chart_json and name
				console.log 'getting ' + text + 'script'
				draw = @$ '#draw-' + chart_class
				chart_data = JSON.parse chart_json
				nvd3 = new nvd3util chart_data, selection, draw
				nvd3.init()
				_.defer @setSVG
			else
				console.log @id + ' has no ' + chart_attr + ' or no name'

	setSVG: =>
		for attr in @attrs
			chart_class = 'chart-' + attr[0..2]
			parent = '#' + @id + '.view .' + chart_class
			svg_attr = attr + config.svg_suffix
			text = ' ' + @id + ' ' + attr + ' '
			console.log 'setting' + text + 'svg'
			@model.set svg_attr, @$(parent).html().replace(/\"/g, '\'')
			@model.save()
