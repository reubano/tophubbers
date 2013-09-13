config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/graphs-view'
utils = require 'lib/utils'

module.exports = class GraphsController extends Controller
	adjustTitle: 'Ongeza Work Graph'
	res: ['rep_info', 'work_data']
	attrs: if config.mobile then [config.hash_attrs[0]] else [config.data_attrs[0]]
	collection: Chaplin.mediator.reps

	initialize: =>
		utils.log 'initialize graphs-controller'

		if @collection.length is 0
			utils.log 'no collection so fetching all data...'
			@fetchData(@res, false, @attrs)
		else
			utils.log 'fetching expired data...'
			@fetchExpiredData(@res, false, @attrs)

	comparator: (model) ->
		model.get('id')

	index: (params) =>
		@ignore_cache = params?.ignore_cache ? false

		@collection.comparator = @comparator
		@view = new View
			collection: @collection
			attrs: @attrs
			ignore_cache: @ignore_cache

	refresh: =>
		utils.log 'refreshing data...'
		@fetchData(@res, false, @attrs)
		@redirectToRoute 'graphs#index'
