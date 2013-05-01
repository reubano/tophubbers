var myFormat = d3.time.format("%b %d, %Y %X %p"),
    dateFormat = d3.time.format("%m/%d/%y"),
    formatMinutes = function(d) {
        var time = d3.time.format("%I:%M %p")(new Date(2013, 0, 1, 0, d));
        return time.substr(0,1) == '0' ? time.substr(1) : time;
    },
    minTime = 7.5,
    maxTime = 18.5,
    maxDur = 4 * 60,
    chartRange = [minTime * 60, maxTime * 60],
    tickInterval = [],
    data,
    selection,
    chart;

loadCSV();

function dateRange(startDate, endDate) {
    var newDate = startDate,
        range = [];

    while (newDate <= endDate) {
        range.push(moment(newDate));
        newDate.add('d', 1);
    }

    return range;
}

function loadCSV() {
    d3.csv("db/sales.csv", function(data) {
        var rows = data.map(function(d) {
            var startDate = d3.time.format("%m/%d/%y")(myFormat.parse(d.start)),
                dur = (myFormat.parse(d.end) - myFormat.parse(d.start)) / (1000 * 60);

            return {
                date: startDate,
                employee: d.employee_id,
                start: (myFormat.parse(d.start) - dateFormat.parse(startDate)) / (1000 * 60),
                duration: (dur > 0 && dur < maxDur) ? dur : 0
            };
        });

        var grouped = _.groupBy(rows, 'employee');
// 			alert(JSON.stringify(rows, null, 4));
//			alert(JSON.stringify(grouped, null, 4));
        _.each(grouped, function(obj, i) {
//				alert(JSON.stringify(obj, null, 4));
//				alert(i);
            var string = 'MM/DD/YY',
                date = moment(obj[0].date, string),
                month = date.month(),
                year = date.year(),
                startDate = moment([year, month, 1]),
                endDate = moment([year, month, 0]).add('M', 1),
                allDates = _.map(
                    dateRange(startDate, endDate),
                    function(d) { return d.format(string)}
                ),
                myDates = _.pluck(obj, 'date')
                missing = _.difference(allDates, myDates);

            loadData(i, obj, missing);
        })
    });
}

function loadData(title, rows, missing) {
    var endValues = [], durValues = []

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
//		alert(JSON.stringify(data, null, 4));
// 		alert(data);
    graph(title, data);
}

function graph(title, data) {
    nv.addGraph(function() {
        selection = '#' + title +'.view .chart svg'
        alert(selection);

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
//				.orient('top')
            .tickValues(tickInterval)
            .tickFormat(formatMinutes);

        d3.select(selection)
            .datum(data)
            .transition().duration(0)
            .call(chart);

        nv.utils.windowResize(chart.update);

        chart.dispatch.on('stateChange', function(e) {
            nv.log('New State:', JSON.stringify(e));
        });

        chart.multibar.yScale().clamp(true)
        return chart;
    });
}
