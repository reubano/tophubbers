Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/progresses-view'

module.exports = class ProgressesController extends Controller
	adjustTitle: 'Ongeza Rep Progress'
	res: ['rep_info', 'score', 'progress_data']
	collection: Chaplin.mediator.reps

	initialize: =>
		console.log 'initialize progresses-controller'

		if @collection.length is 0
			console.log 'no collection so fetching all data...'
			@fetchData(@res)
		else
			console.log 'fetching expired data...'
			@fetchExpiredData(@res)

	comparator: (model) ->
		- model.get 'score'

	index: =>
		@collection.comparator = @comparator
		@view = new View {@collection}

	refresh: =>
		console.log 'refreshing data...'
		@redirectToRoute 'progresses#index'
		@fetchData(@res)

