Model = require 'models/base/model'

module.exports = class Graph extends Model
	minTime = 7.5
	maxTime = 18.5
	chartRange = [minTime * 60, maxTime * 60]
	tickInterval = []
	nvlog: (e) -> nv.log 'New State:', JSON.stringify(e)
	retLab: (d) -> d.label
	retVal: (d) -> d.value

	formatMinutes: (d) ->
		time = d3.time.format("%I:%M %p")(new Date(2013, 0, 1, 0, d))
		if time.substr(0,1) == '0' then time.substr(1) else time

	initialize: ->
		super
		@set 'created', new Date().toString() if @isNew() or not @get 'created'
		# @set 'first_name', 'Name not found in database' if not @get 'first_name'
		# @set 'airtel', 'N/A' if not @get 'airtel'
		# @set 'ward', 'N/A' if not @get 'ward'

	getChartData: (attr) =>
		d = @get attr + '_data'

		if not d
			console.log 'no ' + attr + '_data found for ' + @get('id')
			# endValues = [{label: '2013-05-01', value: 0}, {label: '2013-05-02', value: 0}]
			return

		console.log @get('id') + ': setting ' + attr + ' chart data'
		if d.rows
			endValues = (label: obj.date, value: obj.start for obj in d.rows)
			durValues = (label: obj.date, value: obj.duration for obj in d.rows)
			endValues.push(label: obj, value: 0 for obj in d.missing)
			durValues.push(label: obj, value: 0 for obj in d.missing)
		else
			endValues = (label: obj, value: 0 for obj in d.missing)
			durValues = (label: obj, value: 0 for obj in d.missing)

		endValues = _.sortBy endValues, 'label'
		durValues = _.sortBy durValues, 'label'

		data = [
			{key: 'End', values: endValues},
			{key: 'Duration', values: durValues}]

		# escape inline quotes
		# http://stackoverflow.com/questions/7921164/syntax-error-when-parsing-json-string
		JSON.stringify(data).replace(/\\"/g, '\\\\"')

	setChartData: (attr) =>
		chart_data = @get attr + '_chart_data'

		if chart_data
			console.log 'setting ' + @get('id') + ' data to:'
			console.log JSON.parse chart_data
			@set data: chart_data
		else
			console.log 'no ' + attr + '_chart_data for ' + @get('id')

	drawChart: (attr) =>
		console.log 'drawing ' + attr + ' chart ' + @get 'id'
		chart_data = @get attr + '_chart_data'

		if not chart_data
			return console.log 'no data for ' + attr + ' chart ' + @get 'id'

		data = JSON.parse @get attr + '_chart_data'
		selection = '#' + @get('id') + '.view .chart svg'
		# alert(selection)

		chart = nv.models.multiBarHorizontalChart()
			.x(@retLab)
			.y(@retVal)
			.forceY(chartRange)
			.yDomain(chartRange)
			.margin(top: 0, right: 110, bottom: 30, left: 80)
			#.showValues(true)
			#.tooltips(false)
			.stacked(true)
			.showLegend(false)
			.barColor([d3.rgb('steelblue')])
			.showControls(false)

		i = 0

		while i < maxTime - 1
			tickInterval[i] = (minTime + i + 1) * 60
			i++

		chart.yAxis
			.tickValues(tickInterval)
			.tickFormat(@formatMinutes)

		chart.multibar.yScale().clamp true

		d3.select(selection)
			.datum(data)
			.transition().duration(100)
			.call(chart)

		# nv.utils.windowResize chart.update
		chart.dispatch.on 'stateChange', @nvlog
		nv.addGraph chart
