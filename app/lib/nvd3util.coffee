Chaplin = require 'chaplin'
nvd3util = Chaplin.utils.beget Chaplin.utils

_(nvd3util).extend
	nvlog: (e) -> nv.log 'New State:', JSON.stringify(e)
	retLab: (d) -> d.label
	retVal: (d) ->	d.value

	formatMinutes: (d) ->
		time = d3.time.format("%I:%M %p")(new Date(2013, 0, 1, 0, d))
		if time.substr(0,1) == '0' then time.substr(1) else time

	makeChart: (data, id) =>
		if not data
			console.log 'no data for ' + attr + ' chart ' + id
		else
			console.log 'making chart ' + id

			i = 0
			minTime = 7.5
			maxTime = 18.5
			chartRange = [minTime * 60, maxTime * 60]
			tickInterval = []
			selection = '#' + id + '.view .chart svg'

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

			d3.select(selection)
				.datum(data)
				.transition().duration(100)
				.call(chart)

			# nv.utils.windowResize chart.update
			chart.dispatch.on 'stateChange', @nvlog
			nv.addGraph chart

module.exports = nvd3util