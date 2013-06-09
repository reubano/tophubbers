var chartRange, maxTime, minTime, tickInterval, id, selection;

minTime = 7.5;
maxTime = 18.5;
chartRange = [minTime * 60, maxTime * 60];
tickInterval = [];

formatMinutes = function(d) {
	var time = d3.time.format("%I:%M %p")(new Date(2013, 0, 1, 0, d));
	return time.substr(0,1) == '0' ? time.substr(1) : time;
};

makeChart = function(data, div) {
	id = div.id
	selection = '#' + id +'.view .chart svg';
	console.log('making chart ' + id);

	chart = nv.models.multiBarHorizontalChart()
		.x(function(d) {return d.label})
		.y(function(d) {return d.value})
		.forceY(chartRange)
		.yDomain(chartRange)
		.margin({top: 0, right: 110, bottom: 30, left: 80})
		//.showValues(true)
		//.tooltips(false)
		.stacked(true)
		.showLegend(false)
		.barColor([d3.rgb('steelblue')])
		.showControls(false)
		;

	for (var i = 0; i < maxTime - 1; i++) {
		tickInterval[i] = (minTime + i + 1) * 60;
	}

	chart.yAxis
		.tickValues(tickInterval)
		.tickFormat(formatMinutes)

	chart.multibar.yScale().clamp(true);

	d3.select(selection)
		.datum(data)
		.transition().duration(100)
		.call(chart);

	// nv.utils.windowResize(chart.update);

	chart.dispatch.on('stateChange', function(e) {
		nv.log('New State:', JSON.stringify(e));
	});

	nv.addGraph(chart);
};
