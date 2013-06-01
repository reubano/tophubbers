Model = require 'models/base/model'

module.exports = class Graph extends Model
	minTime = 7.5
	maxTime = 18.5
	chartRange = [minTime * 60, maxTime * 60]
	tickInterval = []

	initialize: ->
		super
		@set 'created', new Date().toString() if @isNew() or not @get 'created'

	nvlog: (e) -> nv.log 'New State:', JSON.stringify(e)
	retLab: (d) -> d.label
	retVal: (d) -> d.value

	drawChart: (attr) =>
		nv.addGraph @get attr

	setChart: (attr) =>
		d = @get attr
		endValues = (label: obj.date, value: obj.start for obj in d.rows)
		endValues.push(label: obj, value: 0 for obj in d.missing)
		endValues = _.sortBy endValues, 'label'

		durValues = (label: obj.date, value: obj.duration for obj in d.rows)
		durValues.push(label: obj, value: 0 for obj in d.missing)
		durValues = _.sortBy durValues, 'label'

		data[0] = key: 'End', values: endValues
		data[1] = key: 'Duration', values: durValues
		@makeChart data, attr

	makeChart: (data, attr) =>
		selection = '#' + @get 'id' + '.view .chart svg'
		# alert(selection)

		chart = nv.models.multiBarHorizontalChart()
			.x @retLab
			.y @retVal
			.forceY chartRange
			.yDomain chartRange
			.margin {top: 0, right: 110, bottom: 30, left: 80}
			#.showValues true
			#.tooltips false
			.stacked true
			.showLegend false
			.barColor [d3.rgb('steelblue')]
			.showControls false

		i = maxTime - 1
		tickInterval = while i -= 1
			(minTime + i + 1) * 60

		chart.yAxis
			.tickValues tickInterval
			.tickFormat formatMinutes

		chart.multibar.yScale().clamp true

		d3.select(selection)
			.datum data
			.transition().duration 100
			.call chart

		# nv.utils.windowResize chart.update
		chart.dispatch.on 'stateChange', @nvlog e
		attr.replace /data/g, 'chart'
		@set attr, chart
