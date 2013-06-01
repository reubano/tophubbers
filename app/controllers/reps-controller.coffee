config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
RepView = require 'views/rep-view'
GraphsView = require 'views/graphs-view'

module.exports = class Controller extends Controller
	collection: Chaplin.mediator.reps
	res: ['rep_info', 'cur_work']
	# res: ['rep_info', 'cur_work', 'cur_feedback', 'cur_progress']

	getData: (url) ->
		console.log 'fetching ' + url
		$.ajax url: url, type: 'get', dataType: 'json', beforeSend: (jqXHR, settings) -> jqXHR.url = settings.url

	resetReps: (response) =>
		console.log 'resetting collection'
		(@collection.create rep for rep in response.data)
		console.log 'collection length: ' + @collection.length
		console.log @collection.at(1).getAttributes()

	setReps: (response, textStatus, jqXHR) =>
		console.log 'setting collection'
		parser = document.createElement('a')
		parser.href = jqXHR.url
		attr = (@parser.pathname.replace /\//g, '')
		tstamp = attr + '_tstamp'
		@collection.set response.data, remove: false
		_.map(@collection.models, (model) -> model.save({patch: true}))
		@collection.at(1).set tstamp, new Date().toString()
		console.log 'collection length: ' + @collection.length
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
		res_list = (item: i, attr: i + '_age', url: config.api + i for i in @res)

		if @collection.length == 0
			console.log 'no collection so fetching graphs'
			# @publishEvent 'graphs:clear'

			for r in res_list
				@getData(r.url).done(@setReps)
		else
			for r in res_list
				if (@cacheExpired r.attr)
					console.log r.attr + 'cache expired'
					@getData(r.url).done(@setReps)
				else
					console.log 'using cached ' + r.item + ' data'

	show: (params) =>
		console.log 'rendering rep view'
		@model = @collection.get params.id
		@view = new RepView {@model}

	index: (params) =>
		console.log 'rendering graphs view'
		@view = new GraphsView {@collection}
