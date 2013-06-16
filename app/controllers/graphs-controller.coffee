config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/graphs-view'

module.exports = class Controller extends Controller
	adjustTitle: 'Ongeza Work Graph'
	res: ['rep_info', 'work_data']
	data_attrs: [config.data_attrs[0]]
	collection: Chaplin.mediator.reps

	initialize: =>
		console.log 'initialize graphs-controller'

		if @collection.length is 0
			console.log 'no collection so fetching all data...'
			@fetchData(@res, false, @data_attrs)
		else
			console.log 'fetching expired data...'
			@fetchExpiredData(@res, false, @data_attrs)

	comparator: (model) ->
		model.get('id')

	index: (params) =>
		@ignore_svg = if params?.ignore_svg? then params.ignore_svg else false

		@collection.comparator = @comparator
		@view = new View
			collection: @collection
			attrs: @data_attrs
			ignore_svg: @ignore_svg

	refresh: =>
		console.log 'refreshing data...'
		@fetchData(@res, false, @data_attrs)
		@redirectToRoute 'graphs#index'

