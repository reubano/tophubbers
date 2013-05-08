var myFormat, dateFormat, formatMinutes, formatDates, isBetween, minTime, maxTime, maxDur, chartRange, tickInterval, data, selection, string, chart, date, month, year, startDate, endDate, allDates, dateRange;

myFormat = d3.time.format("%Y-%m-%d %X");
dateFormat = d3.time.format("%m/%d/%y");
minTime = 7.5;
maxTime = 18.5;
maxDur = 4 * 60;
chartRange = [minTime * 60, maxTime * 60];
tickInterval = [];
string = 'MM/DD/YY';
date = moment();
// month = date.month();
year = date.year();
month = 1;
startDate = moment([year, month, 1]);
endDate = startDate.add('m', 1).subtract('d', 1);

formatMinutes = function(d) {
	var time = d3.time.format("%I:%M %p")(new Date(2013, 0, 1, 0, d));
	return time.substr(0,1) == '0' ? time.substr(1) : time;
},

dateRange = function(startDate, endDate) {
	var newDate, _results;

	newDate = startDate;
	_results = [];

	while (newDate <= endDate) {
		_results.push(moment(newDate));
		newDate.add('d', 1);
	}

	return _results;
};

formatData = function(d) {
	var dur, duration, start, startDate;

	startDate = d3.time.format("%m/%d/%y")(myFormat.parse(d.START));
	dur = (myFormat.parse(d.END) - myFormat.parse(d.START)) / (1000 * 60)
	start = (myFormat.parse(d.START) - dateFormat.parse(startDate)) / (1000 * 60);
	duration = dur > 0 && dur < maxDur ? dur : 0;

	return {
		date: startDate,
		employee: d.EMPLOYEE_ID,
		start: start,
		duration: duration
	};
};

formatDates = function(d) {
	return d.format(string);
};

allDates = _.map(dateRange(startDate, endDate), formatDates);

loadCSV = function() {
	d3.json('http://ongeza-api.herokuapp.com/data/', groupData);
	d3.json('http://127.0.0.1:5000/missing_reps/', makeBlank);
}

groupData = function(json) {
	var grouped, rows;

	rows = json.data.map(formatData);
	grouped = _.groupBy(rows, 'employee');
	_.each(grouped, formatGrouped);
}

makeBlank = function(json) {
	_.each(json.data, function(id) {
		formatted = {id: id, rows: false, missing: allDates};
		loadData(formatted);
	});
};

formatGrouped = function(obj, i) {
	var missing, myDates, formatted;

	myDates = _.pluck(obj, 'date');
	missing = _.difference(allDates, myDates);
	formatted = {id: i, rows: obj, missing: missing};
	loadData(formatted);
};

loadData = function(chart_data) {
	var id, rows, missing, endValues = [], durValues = [];
	id = chart_data.id;
	rows = chart_data.rows;
	missing = chart_data.missing;

	_.each(rows, function(obj, i) {
		endValues.push({"label": obj.date, "value": obj.start});
		durValues.push({"label": obj.date, "value": obj.duration});
	})

	_.each(missing, function(obj, i) {
		endValues.push({"label": obj, "value": 0});
		durValues.push({"label": obj, "value": 0});
	})

	endValues = _.sortBy(endValues, 'label')
	durValues = _.sortBy(durValues, 'label')

	data = [
		{key: 'End', values: endValues},
		{key: 'Duration', values: durValues},
	];

	// alert(JSON.stringify(data, null, 4));
	// alert(data);

	makeChart(id, data);
}

makeChart = function(id, data) {
	var i;

	selection = '#' + id +'.view .chart svg';

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

	for (i = 0; i < maxTime - 1; i++) {
		tickInterval[i] = (minTime + i + 1) * 60;
	}

	chart.yAxis
		.tickValues(tickInterval)
		.tickFormat(formatMinutes)

	d3.select(selection)
		.datum(data)
		.transition().duration(0)
		.call(chart);

	nv.utils.windowResize(chart.update);

	chart.dispatch.on('stateChange', function(e) {
		nv.log('New State:', JSON.stringify(e));
	});

	chart.multibar.yScale().clamp(true)
	nv.addGraph(chart);
}

loadCSV();
