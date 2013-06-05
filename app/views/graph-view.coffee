View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template

	initialize: =>
		super
		@listenTo @model, 'change', @render
		@subscribeEvent 'render:graph', @drawChart

	render: =>
		super
		@publishEvent 'render:graph'

	drawChart: (attr) =>
		attr = 'prev_work'
		chart_data = @model.get attr + '_chart_data'

		if chart_data
			@model.setChartData(attr)
			# @$('#draw').html script