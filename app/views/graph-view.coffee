View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	autoRender: true
	template: template

	initialize: =>
		super
		@listenTo @model, 'change:prev_work_chart_data', @drawChart
		@listenTo @model, 'change', @drawChart
		@listenTo @model, 'change', @render

	render: =>
		super
		@drawChart()

	drawChart: =>
		attr = 'prev_work'
		chart_data = @model.get attr + '_chart_data'
		name = @model.get 'first_name'
		id = @model.get 'id'

		if chart_data and name
			console.log @model.get('id') + ' has ' + attr + '_chart_data'
			@model.setChartData(attr)
			script = "<script>makeChart(#{chart_data}, #{id});</script>"
			@$('#draw').html script
		else
			console.log @model.get('id') + ' has no ' + attr + '_chart_data' +
				' or no name'
