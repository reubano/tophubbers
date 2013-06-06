View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template

	initialize: (options) =>
		super
		@options = options
		@listenTo @model, options.change, @render
		# @subscribeEvent 'dispatcher:dispatch', @setHTML

	render: =>
		super
		@drawChart()

	drawChart: =>
		console.log 'chart html'
		console.log @model.get 'chart'
		attr = @options.chart

		if not attr
			console.log 'options not set'
			return

		chart_data = @model.get attr + '_chart_data'
		name = @model.get 'first_name'
		id = @model.get 'id'

		if chart_data and name
			console.log id + ' has ' + attr + '_chart_data'
			script = "<script>makeChart(#{chart_data}, #{id});</script>"
			@$('#draw').html script
			@setHTML()
		else
			console.log id + ' has no ' + attr + '_chart_data or no name'

	setHTML: =>
		selection = '#' + @model.get('id') + '.view .chart svg';
		console.log 'setting chart html for ' + selection
		console.log $('#E0022.view .chart svg').html()
		@model.set chart: JSON.stringify $(selection).html()
		@model.save()