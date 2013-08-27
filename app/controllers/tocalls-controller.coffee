Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/tocalls-view'
utils = require 'lib/utils'

module.exports = class TocallsController extends Controller
	adjustTitle: 'Ongeza Call List'
	res: ['rep_info', 'score']
	collection: Chaplin.mediator.reps

	initialize: =>
		utils.log 'initialize tocalls-controller'

		if @collection.length is 0
			utils.log 'no collection so fetching all data...'
			@fetchData(@res)
		else
			utils.log 'fetching expired data...'
			@fetchExpiredData(@res)

	comparator: (model) ->
		- model.get 'score_sort'

	index: =>
		@collection.comparator = @comparator
		@view = new View {@collection}

	refresh: =>
		utils.log 'refreshing data...'
		@redirectToRoute 'tocalls#index'
		@fetchData(@res)

