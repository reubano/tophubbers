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
		change = 'change:' + attr

		for attr in @attrs
			@listenTo @model, change, @render
			@listenTo @model, change, @modelChangeAlert
		# @listenTo @model, 'change', ->
		# 	console.log 'caught collection change'
		# @subscribeEvent 'dispatcher:dispatch', ->
		# 	console.log 'graph-view caught dispatcher event'

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

	getChartScript: (force=false) =>
		# console.log 'chart html'
		# console.log @model.get 'chart'

		for attr in @attrs
			chart_class = 'chart-' + attr[0..2]
			selection = '#' + @id + '.view .' + chart_class + ' svg'
			svg_attr = attr + config.svg_suffix
			svg = if @model.get svg_attr then @model.get svg_attr else false
			rendered = if @$(selection).html() then true else false
			changed = @model.hasChanged attr
			text = @id + ' ' + attr + ' '

			console.log text + 'is rendered: ' + rendered
			console.log text + 'has changed: ' + changed
			console.log text + 'has cached svg: ' + if svg then 'true' else 'false'

			if (rendered and not changed and not force)
				console.log @id + ' ' + attr + " hasn't changed and already rendered"
			else if (svg and not changed)
				@$(selection).parent().html svg
			else
				draw = @$ '#draw-' + chart_class
				chart_attr = attr + config.chart_suffix
				chart_data = JSON.parse @model.get chart_attr
				name = @model.get 'first_name'
				console.log 'getting chart script for ' + @id

				if chart_data and name
					console.log @id + ' has ' + chart_attr
					nvd3 = new nvd3util chart_data, selection, draw
					nvd3.init()
					@model.set svg_attr, nvd3.svg()
					# tab = '#' + chart_class + '-tab'
					# @$(tab).click()
				else
					console.log @id + ' has no ' + chart_attr + ' or no name'

	setHTML: =>
		html = @$('#svg').html()
		console.log 'getting chart html for ' + @id

		if html
			console.log html
			@model.set chart: html
			@model.save()
		else
			console.log 'no html found'
