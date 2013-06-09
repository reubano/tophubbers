config = require 'config'
# nvd3util = require 'lib/nvd3util'
View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template
# 	listen:
# 		addedToParent: 'getChartScript'
# 		addedToParent: 'addedToParentAlert'
# 		visibilityChange: 'visibilityChangeAlert'

	initialize: (options) =>
		super
		@options = options
		@listenTo @model, options.change, @render
		# @subscribeEvent 'dispatcher:dispatch', ->
		# 	console.log 'graph-view caught dispatcher event'

	render: =>
		console.log 'rendering graph view'
		super
		@attach()
		_.defer @getChartScript
		# @getChartScript()

	visibilityChangeAlert: ->
		console.log 'graph-view heard visibilityChange'

	addedToParentAlert: ->
		console.log 'graph-view heard addedToParent'

	getChartScript: =>
		# console.log 'chart html'
		# console.log @model.get 'chart'
		attr = @options.chart

		if not attr
			console.log 'options not set'
			return

		chart_attr = attr + config.chart_suffix
		chart_data = @model.get chart_attr
		name = @model.get 'first_name'
		id = @model.get 'id'
		console.log 'getting chart script for ' + id

		if chart_data and name
			classes = @options.classes
			chart_class = classes[0]
			console.log id + ' has ' + chart_attr
			options = [chart_data, id]
			script = "<script>_.defer(makeChart, #{options});</script>"
			selection = '#draw-' + chart_class
			@$(selection).html script
		else
			console.log id + ' has no ' + chart_attr + ' or no name'

	setHTML: =>
		id = @model.get 'id'
		html = @$('#svg').html()
		console.log 'getting chart html for ' + id

		if html
			console.log html
			@model.set chart: html
			@model.save()
		else
			console.log 'no html found'
