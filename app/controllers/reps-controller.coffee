config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
RepView = require 'views/rep-view'
GraphsView = require 'views/graphs-view'

module.exports = class Controller extends Controller
	collection: Chaplin.mediator.reps
	parser: document.createElement('a')
	to_chart: 'work_data'
	res: ['rep_info', 'work_data', 'feedback_data', 'progress_data', 'score']

	getResList: =>
		(item: i, tstamp: i + '_tstamp', url: config.api + i for i in @res)

	getData: (url) ->
		console.log 'fetching ' + url
		$.ajax
			url: url
			type: 'get'
			dataType: 'json'
			beforeSend: (jqXHR, settings) -> jqXHR.url = settings.url

	fetchAllData: =>
		for r in @getResList()
			@getData(r.url).done(@setReps).done(@setCharts).fail(@failWhale)

	fetchExpiredData: =>
		for r in @getResList()
			if (@cacheExpired r.tstamp)
				console.log r.item + ' cache not found or expired'
				@getData(r.url).done(@setReps).done(@setCharts).fail(@failWhale)
			else
				console.log 'using cached ' + r.item + ' data'
				@setCharts 'HTTP 200', 'success', url: r.url

	failWhale: (jqXHR, textStatus, errorThrown) =>
		@parser.href = jqXHR.url
		console.log 'failed to fetch ' + jqXHR.url
		console.log 'error: ' + errorThrown if errorThrown

	resetReps: (response, textStatus, jqXHR) =>
		@parser.href = jqXHR.url
		attr = @parser.pathname.replace /\//g, ''
		console.log 'resetting collection for ' + attr
		(@collection.create rep for rep in response.data)
		console.log 'collection length: ' + @collection.length
		console.log @collection.at(1).getAttributes()

	setReps: (response, textStatus, jqXHR) =>
		@parser.href = jqXHR.url
		attr = (@parser.pathname.replace /\//g, '')
		tstamp = attr + '_tstamp'
		console.log 'setting collection with ' + attr
		console.log response.data
		@collection.set response.data, remove: false
		@collection.at(1).set tstamp, new Date().toString()
		(model.save {patch: true} for model in @collection.models)
		console.log 'collection length: ' + @collection.length
		console.log @collection.at(1).getAttributes()

	setCharts: (response, textStatus, jqXHR) =>
		@parser.href = jqXHR.url
		source = (@parser.pathname.replace /\//g, '')

		if source == @to_chart
			console.log 'setting chart data for ' + source
		else
			console.log source + ' not chartable'
			return

		data_attrs = ['cur_work_data', 'prev_work_data']

		for model in @collection.models
			for attr in data_attrs
				# if (model.get(attr) and model.hasChanged(attr))
				if model.get(attr)
					chart_attr = attr + config.chart_suffix
					console.log model.get('id') + ': fetching missing chart data'
					data = model.getChartData attr
					console.log JSON.parse data
					model.set chart_attr, data
					model.save {patch: true}
				else
					console.log model.get('id') + ': chart data unchanged'

		console.log @collection

	cacheExpired: (attr) =>
		# check if the cache has expired
		console.log 'checking ' + attr
		tstamp = @collection.at(1).get attr

		if tstamp
			string = 'ddd MMM DD YYYY HH:mm:ss [GMT]ZZ'
			mstamp = moment(tstamp, string)
			age = mstamp.diff(moment(), 'hours')
			console.log attr + ' age: ' + mstamp.fromNow(true)
			age >= config.max_age
		else
			console.log 'no ' + attr + ' found'
			true

	repListDiffers: (reps) =>
		# check if the current rep list differs from the server
		curCol = @collection.pluck 'id'
		newCol = _.pluck reps, 'id'
		diff1 = _.difference curCol, newCol
		diff2 = _.difference newCol, curCol
		diff1 != [] or diff2 != []

	initialize: =>
		console.log 'initialize reps-controller'

		if @collection.length is 0
			console.log 'no collection so fetching all data...'
			# @publishEvent 'graphs:clear'
			@fetchAllData()
		else
			console.log 'fetching expired data...'
			@fetchExpiredData()

	show: (params) =>
		@model = @collection.get params.id
		@view = new RepView
			model: @model
			chart: 'prev_work_data'
			change: 'change:prev_work_data_c'

	index: (params) =>
		@view = new GraphsView
			collection: @collection
			chart: 'prev_work_data'
			change: 'change:prev_work_data_c'

	refresh: (params) =>
		console.log 'refreshing data...'
		@fetchAllData()
		@redirectToRoute 'reps#index'

