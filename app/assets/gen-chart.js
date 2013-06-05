var myFormat, dateFormat, formatMinutes, formatDates, isBetween, minTime, maxTime, maxDur, chartRange, tickInterval, data, selection, string, chart, date, month, year, currStart, currEnd, allDates, dateRange, cache, maxCacheAge, results;

myFormat = d3.time.format("%Y-%m-%d %X");
dateFormat = d3.time.format("%m/%d/%y");
minTime = 7.5;
maxTime = 18.5;
maxDur = 4 * 60;
chartRange = [minTime * 60, maxTime * 60];
tickInterval = [];
string = 'MM/DD/YY';
date = moment();
month = date.month();
// month = 1;
year = date.year();
currStart = moment([year, month, 1]);
currEnd = moment(currStart).endOf('month');
maxCacheAge = 24;
api_base = 'http://ongeza-api.herokuapp.com/'
// api_base = 'http://localhost:5000/'

Storage.prototype.setObject = function(key, value) {
	this.setItem(key, JSON.stringify(value));
};

Storage.prototype.getObject = function(key) {
	var value = this.getItem(key);
	return value && JSON.parse(value);
};

formatMinutes = function(d) {
	var time = d3.time.format("%I:%M %p")(new Date(2013, 0, 1, 0, d));
	return time.substr(0,1) == '0' ? time.substr(1) : time;
};

dateRange = function(startDate, endDate) {
	var newDate, _results;

	newDate = startDate.clone();
	_results = [];

	while (newDate <= endDate) {
		_results.push(moment(newDate));
		newDate.add('d', 1);
	}

	return _results;
};

formatData = function(d) {
	var diff, duration, startTime, startDate;

	startDate = d3.time.format("%m/%d/%y")(myFormat.parse(d.START));
	diff = (myFormat.parse(d.END) - myFormat.parse(d.START)) / 60000;
	startTime = (myFormat.parse(d.START) - dateFormat.parse(startDate)) / 60000;
	duration = diff > 0 && diff < maxDur ? diff : 0;

	return {
		date: startDate,
		employee: d.EMPLOYEE_ID,
		start: startTime,
		duration: duration
	};
};

formatDates = function(d) {
	return d.format(string);
};

allDates = _.map(dateRange(currStart, currEnd), formatDates);

loadCSV = function() {
	d3.json(api_base + 'cur_data/', groupData);
	d3.json(api_base + 'missing_reps/', makeBlank);
};

groupData = function(json) {
	var grouped, rows;

	rows = json.data.map(formatData);
	grouped = _.groupBy(rows, 'employee');
	_.each(grouped, formatGrouped);
};

makeBlank = function(json) {
	var formatted;

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

loadData = function(d) {
	var endValues = [], durValues = [];

	_.each(d.rows, function(obj, i) {
		endValues.push({"label": obj.date, "value": obj.start});
		durValues.push({"label": obj.date, "value": obj.duration});
	})

	_.each(d.missing, function(obj, i) {
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

	makeChart({id: d.id, data: data});
};

makeChart = function(result) {
	$(document).ready(function(){
		var i;

		selection = '#' + result.id +'.view .chart svg';

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

		chart.multibar.yScale().clamp(true);

		d3.select(selection)
			.datum(result.data)
			.transition().duration(100)
			.call(chart);

		// nv.utils.windowResize(chart.update);

		chart.dispatch.on('stateChange', function(e) {
			nv.log('New State:', JSON.stringify(e));
		});

		nv.addGraph(chart);
	});
};
