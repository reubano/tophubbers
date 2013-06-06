View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template

	initialize: (options) =>
		super
		@options = options
		@listenTo @model, options.change, @render

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
		selection = '#' + id + '.view .chart svg';

		if chart_data and name
			console.log id + ' has ' + attr + '_chart_data'
			script = "<script>makeChart(#{chart_data}, #{id});</script>"
			@$('#draw').html script
			@setHTML selection
		else
			console.log id + ' has no ' + attr + '_chart_data or no name'

	setHTML: (selection) =>
		console.log 'setting chart html for ' + selection
		console.log $(selection).html
		@model.set chart: JSON.stringify $(selection).html
		@model.save()