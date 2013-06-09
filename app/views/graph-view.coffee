config = require 'config'
nvd3util = require 'lib/nvd3util'
View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template
	listen:
		addedToParent: 'drawChart'
		visibilityChange: 'visibilityChangeAlert'

	initialize: (options) =>
		super
		@options = options
		@listenTo @model, options.change, @render
		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'graph-view caught dispatcher event'
		@subscribeEvent 'addedToParent', ->
			console.log 'graph-view caught addedToParent event'
		# @subscribeEvent 'addedToParent', @drawChart

	render: =>
		super
		@attach()
		# _.defer @drawChart
		# @drawChart()

	visibilityChangeAlert: ->
		console.log 'graph-view heard visibilityChange'

	alertChart: ->
		console.log 'graph-view heard addedToDOM'

	drawChart: =>
		console.log 'graph-view heard addedToParent'
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

		if chart_data and name
			console.log id + ' has ' + chart_attr
			nvd3util.makeChart chart_data, id
			# script = "<script>#{func};</script>"
			# options = [chart_data, id]
			# script = "<script>_.defer(makeChart, #{options});</script>"
			# script = "<script>makeChart(#{chart_data}, #{id});</script>"
			# @$('#draw').html script
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
