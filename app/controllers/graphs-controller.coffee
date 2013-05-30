config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
RepView = require 'views/rep-view'
GraphsView = require 'views/graphs-view'

module.exports = class Controller extends Controller
	mediator = Chaplin.mediator

	adjustTitle: 'Graph list'
	collection: mediator.graphs
	url: config.api + 'info'

	getGraphs: (callback) ->
		$.ajax url: @url, type: 'get', dataType: 'json', success: callback

	resetGraphs: (response) =>
		console.log 'resetting collection'
		mediator.graphs.set response.data
		console.log mediator.graphs
		@collection.reset(response.data)

	cacheExpired: =>
		# check if the cache has expired
		ages = @collection.pluck 'age'
		now = (new Date).getTime() / 3600000
		(now - Math.min.apply null, ages) > config.max_age

	repListDiffers: (reps) =>
		# check if the current rep list differs from the server
		curCol = @collection.pluck 'id'
		newCol = _.pluck reps, 'id'
		diff1 = _.difference curCol, newCol
		diff2 = _.difference newCol, curCol
		diff1 != [] or diff2 != []

	initialize: =>
		if (@collection.length == 0 or @cacheExpired())
			console.log 'collection length: ' + Chaplin.mediator.graphs.length
			console.log 'cacheExpired: ' + @cacheExpired()
			console.log 'fetching graphs'
			@publishEvent 'graphs:clear'
			@getGraphs(@resetGraphs)
		else
			console.log 'collection length: ' + Chaplin.mediator.graphs.length
			console.log 'cacheExpired: ' + @cacheExpired()
			console.log 'using cached graphs'

	index: (params) =>
		console.log 'rendering graphs view'
		@view = new GraphsView {@collection}

	show: (params) =>
		console.log 'rendering rep graph view'
		@model = @collection.get(params.id)
		@view = new RepView {@model}
