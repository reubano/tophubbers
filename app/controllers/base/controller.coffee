config = require 'config'
Chaplin = require 'chaplin'
SiteView = require 'views/site-view'
NavbarView = require 'views/navbar-view'

module.exports = class Controller extends Chaplin.Controller
	model: Chaplin.mediator.navbar
	collection: Chaplin.mediator.reps

	beforeAction: (params, route) =>
		@compose 'site', SiteView
		console.log 'beforeAction'
		@compose 'auth', ->
			SessionController = require 'controllers/session-controller'
			@controller = new SessionController params

		@compose 'navbar', =>
			@view = new NavbarView {@model}

	parser: document.createElement('a')

	getResList: (list) =>
		(item: i, tstamp: i + '_tstamp', url: config.api + i for i in list)

	getData: (url) ->
		console.log 'fetching ' + url
		$.ajax
			url: url
			type: 'get'
			dataType: 'json'
			beforeSend: (jqXHR, settings) -> jqXHR.url = settings.url

	fetchData: (list=false, id=false, data_attrs=false) =>
		@id = id
		@data_attrs = data_attrs
		list = if list then list else config.res

		for r in @getResList(list)
			@getData(r.url).done(@setReps, @setCharts).fail(@failWhale)

	fetchExpiredData: (list=false, id=false, data_attrs=false) =>
		@id = id
		@data_attrs = data_attrs
		list = if list then list else config.res

		for r in @getResList(list)
			if (@cacheExpired r.tstamp)
				console.log r.item + ' cache not found or expired'
				@getData(r.url).done(@setReps, @setCharts).fail(@failWhale)
			else
				console.log 'using cached ' + r.item + ' data'
				@setCharts 'HTTP 200', 'success', url: r.url

	failWhale: (jqXHR, textStatus, errorThrown) =>
		@parser.href = jqXHR.url
		console.log 'failed to fetch ' + jqXHR.url
		console.log 'error: ' + errorThrown if errorThrown
		$.get config.api + 'reset'

	saveCollection: =>
		console.log 'saving collection'
		(model.save {patch: true} for model in @collection.models)

	displayCollection: =>
		console.log @collection
		console.log @collection.at(1).getAttributes()

	saveTstamp: (tstamp) =>
		console.log 'saving ' + tstamp
		date = new Date().toString()
		(model.set tstamp, date for model in @collection.models)

	setReps: (response, textStatus, jqXHR) =>
		@parser.href = jqXHR.url
		attr = (@parser.pathname.replace /\//g, '')
		tstamp = attr + '_tstamp'
		console.log 'setting collection with ' + attr
		console.log response.data
		@collection.set response.data, remove: false
		@saveTstamp(tstamp)
		@saveCollection()
		@publishEvent 'repsSet'
		console.log 'collection length: ' + @collection.length
		@displayCollection()

	setCharts: (response, textStatus, jqXHR) =>
		@parser.href = jqXHR.url
		source = (@parser.pathname.replace /\//g, '')

		if source == config.to_chart
			console.log 'setting chart data for ' + source

			models = if @id then [@collection.get(@id)] else @collection.models
			data_attrs = if @data_attrs then @data_attrs else config.data_attrs

			for model in models
				for attr in data_attrs
					chart_attr = attr + config.chart_suffix
					id = model.get 'id'

					# if (not model.get(chart_attr) or model.hasChanged(attr))
					if model.get(attr)
						console.log id + ': fetching missing chart data'
						data = model.getChartData attr
						console.log JSON.parse data
						model.set chart_attr, data
						model.save {patch: true}
					else
						console.log attr + 'not present'
						# text = id + ': ' + chart_attr + ' present and '
						# console.log text + attr + ' unchanged'
		else
			console.log source + ' not chartable'

		@displayCollection()

	cacheExpired: (attr) =>
		# check if the cache has expired
		console.log 'checking ' + attr
		tstamp = @collection.at(1).get attr

		if tstamp
			string = 'ddd MMM DD YYYY HH:mm:ss [GMT]ZZ'
			mstamp = moment(tstamp, string)
			age = Math.abs mstamp.diff(moment(), 'hours')
			console.log attr + ' age: ' + mstamp.fromNow(true)
			age >= config.max_age
		else
			console.log 'no ' + attr + ' found'
			true
