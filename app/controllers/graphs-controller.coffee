config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
RepGraphView = require 'views/rep-graph-view'
GraphsView = require 'views/graphs-view'

module.exports = class Controller extends Controller
	adjustTitle: 'Graph list'
	collection: Chaplin.mediator.graphs

	logCollection: =>
		console.log('this collection')
		console.log(@collection)

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
		if @collection.length == 0
			console.log 'before fetching graphs'
			console.log @collection
			console.log 'after fetching graphs'
			@collection.fetch({success: @logCollection})
		else if @cacheExpired()
			console.log 'clearing and fetching graphs'
			# @publishEvent 'graphs:clear'
			@collection.fetch({reset: true, success: @logCollection})

	index: (params) =>
		console.log 'rendering graphs view'
		@view = new GraphsView {@collection}

	show: (params) =>
		console.log 'rendering rep graph view'
		@model = @collection.get(params.id)
		@view = new RepGraphView {@model}
