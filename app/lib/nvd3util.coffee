module.exports = class nvd3util
	constructor: (data, selection, draw, resize=false) ->
		@data = data
		@selection = selection
		@draw = draw
		@resize = resize

	nvlog: (e) -> nv.log 'New State:', JSON.stringify(e)
	retLab: (data) -> data.label
	retVal: (data) -> data.value

	svg: =>
		$(@selection).parent().html()

	init: =>
		@draw.html @makeChart()
		# nv.addGraph chart

	formatMinutes: (d) ->
		time = d3.time.format("%I:%M %p")(new Date(2013, 0, 1, 0, d))
		if time.substr(0,1) == '0' then time.substr(1) else time

	makeChart: =>
		console.log 'making ' + @selection

		i = 0
		minTime = 7.5
		maxTime = 18.5
		chartRange = [minTime * 60, maxTime * 60]
		tickInterval = []

		while i < maxTime - 1
			tickInterval[i] = (minTime + i + 1) * 60
			i++

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

		chart.yAxis
			.tickValues(tickInterval)
			.tickFormat(@formatMinutes)

		chart.multibar.yScale().clamp true

		d3.select(@selection)
			.datum(@data)
			.transition().duration(100)
			.call(chart)

		nv.utils.windowResize(chart.update) if @resize
		chart.dispatch.on 'stateChange', @nvlog
		chart
