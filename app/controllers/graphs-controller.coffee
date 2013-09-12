config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/graphs-view'
utils = require 'lib/utils'

module.exports = class GraphsController extends Controller
	adjustTitle: 'Ongeza Work Graph'
	res: ['rep_info', 'work_data']
	data_attrs: [config.data_attrs[0]]
	collection: Chaplin.mediator.reps

	initialize: =>
		utils.log 'initialize graphs-controller'

		if @collection.length is 0
			utils.log 'no collection so fetching all data...'
			@fetchData(@res, false, @data_attrs)
		else
			utils.log 'fetching expired data...'
			@fetchExpiredData(@res, false, @data_attrs)

	comparator: (model) ->
		model.get('id')

	index: (params) =>
		@ignore_svg = params?.ignore_svg ? false

		@collection.comparator = @comparator
		@view = new View
			collection: @collection
			attrs: @data_attrs
			ignore_svg: @ignore_svg

	refresh: =>
		utils.log 'refreshing data...'
		@fetchData(@res, false, @data_attrs)
		@redirectToRoute 'graphs#index'
