View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template

	initialize: (options) =>
		super
		@listenTo @model, options.change, ->
			@render options.chart

	render: (attr) =>
		super
		@drawChart()

	drawChart: (attr) =>
		attr = 'prev_work'
		chart_data = @model.get attr + '_chart_data'
		name = @model.get 'first_name'
		id = @model.get 'id'

		if chart_data and name
			console.log id + ' has ' + attr + '_chart_data'
			script = "<script>makeChart(#{chart_data}, #{id});</script>"
			@$('#draw').html script
		else
			console.log id + ' has no ' + attr + '_chart_data or no name'
