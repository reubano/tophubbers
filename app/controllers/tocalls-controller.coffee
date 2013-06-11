Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/tocalls-view'

module.exports = class Controller extends Controller
	adjustTitle: 'Ongeza Call List'
	res: ['rep_info', 'score']
	collection: Chaplin.mediator.reps

	initialize: =>
		console.log 'initialize tocalls-controller'

		if @collection.length is 0
			console.log 'no collection so fetching all data...'
			@fetchData(@res)
		else
			console.log 'fetching expired data...'
			@fetchExpiredData(@res)

	comparator: (model) ->
		- model.get 'score_sort'

	index: =>
		@collection.comparator = @comparator
		@view = new View {@collection}

	refresh: =>
		console.log 'refreshing data...'
		@redirectToRoute 'tocalls#index'
		@fetchData(@res)

