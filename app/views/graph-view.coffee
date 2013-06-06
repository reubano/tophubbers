View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	autoRender: true
	template: template

	initialize: (options) =>
		super
		@listenTo @model, options.change, ->
			@drawChart options.chart

		@listenTo @model, 'change', ->
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

# 	nvlog: (e) -> nv.log 'New State:', JSON.stringify(e)
# 	retLab: (d) -> d.label
# 	retVal: (d) ->	d.value
#
# 	formatMinutes: (d) ->
# 		time = d3.time.format("%I:%M %p")(new Date(2013, 0, 1, 0, d))
# 		if time.substr(0,1) == '0' then time.substr(1) else time
#
# 	getChart: (attr) =>
# 		chart_data = @model.get attr + '_chart_data'
# 		id = @model.get 'id'
#
# 		if not chart_data
# 			console.log 'no data for ' + attr + ' chart ' + id
# 		else
# 			i = 0
# 			minTime = 7.5
# 			maxTime = 18.5
# 			chartRange = [minTime * 60, maxTime * 60]
# 			tickInterval = []
# 			data = JSON.parse chart_data
# 			selection = '#' + id + '.view .chart svg'
#
# 			while i < maxTime - 1
# 				tickInterval[i] = (minTime + i + 1) * 60
# 				i++
#
# 			chart = nv.models.multiBarHorizontalChart()
# 				.x(@retLab)
# 				.y(@retVal)
# 				.forceY(chartRange)
# 				.yDomain(chartRange)
# 				.margin(top: 0, right: 110, bottom: 30, left: 80)
# 				#.showValues(true)
# 				#.tooltips(false)
# 				.stacked(true)
# 				.showLegend(false)
# 				.barColor([d3.rgb('steelblue')])
# 				.showControls(false)
#
# 			chart.yAxis
# 				.tickValues(tickInterval)
# 				.tickFormat(@formatMinutes)
#
# 			chart.multibar.yScale().clamp true
#
# 			d3.select(selection)
# 				.datum(data)
# 				.transition().duration(100)
# 				.call(chart)
#
# 			# nv.utils.windowResize chart.update
# 			chart.dispatch.on 'stateChange', @nvlog
# 			chart
