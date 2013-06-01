config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
RepView = require 'views/rep-view'
GraphsView = require 'views/graphs-view'

module.exports = class Controller extends Controller
	collection: Chaplin.mediator.reps
	res: ['rep_info', 'prev_work', 'cur_feedback']
	charts: ['cur_work', 'prev_work', 'cur_progress']
	parser: document.createElement('a')
	# res: ['rep_info', 'cur_work', 'cur_feedback', 'cur_progress']

	getData: (url) ->
		console.log 'fetching ' + url
		$.ajax url: url, type: 'get', dataType: 'json', beforeSend: (jqXHR, settings) -> jqXHR.url = settings.url

	failWhale: (jqXHR, textStatus, errorThrown) =>
		@parser.href = jqXHR.url
		attr = @parser.pathname.replace /\//g, ''
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
		console.log 'setting collection for ' + attr
		@collection.set response.data, remove: false
		@collection.at(1).set tstamp, new Date().toString()
		(model.save {patch: true} for model in @collection.models)
		console.log 'collection length: ' + @collection.length
		console.log @collection.at(1).getAttributes()

	setCharts: (response, textStatus, jqXHR) =>
		@parser.href = jqXHR.url
		attr = (@parser.pathname.replace /\//g, '')

		if attr in @charts
			console.log 'setting chart data for ' + attr
		else
			return

		data_attr = attr + '_data'
		chart_attr = attr + '_chart_data'

		for model in @collection.models
			if not model.get(chart_attr) and model.get(data_attr)
				# console.log model.get('id') + ': fetching missing chart data'
				chart = model.getChartData attr
				model.set chart_attr, chart
				model.save {patch: true}

		console.log @collection.at(1).getAttributes()

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

		res_list = (item: i, tstamp: i + '_tstamp', url: config.api + i for i in @res)

		if @collection.length is 0
			console.log 'no collection so fetching graphs'
			# @publishEvent 'graphs:clear'

			for r in res_list
				@getData(r.url).done(@setReps).done(@setCharts).fail(@failWhale)
		else
			for r in res_list
				if (@cacheExpired r.tstamp)
					console.log r.item + ' cache not found or expired'
					@getData(r.url).done(@setReps).done(@setCharts).fail(@failWhale)
				else
					console.log 'using cached ' + r.item + ' data'
					@setCharts 'HTTP 200', 'success', url: r.url

	show: (params) =>
		@model = @collection.get params.id
		@view = new RepView {@model}

	index: (params) =>
		@view = new GraphsView {@collection}
