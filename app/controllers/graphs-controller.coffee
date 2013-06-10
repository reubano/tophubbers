Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
GraphsView = require 'views/graphs-view'

module.exports = class Controller extends Controller
	adjustTitle: 'Ongeza Work Graph'
	res: ['work_data']
	collection: Chaplin.mediator.reps

	initialize: =>
		console.log 'initialize reps-controller'

		if @collection.length is 0
			console.log 'no collection so fetching all data...'
			# @publishEvent 'graphs:clear'
			@fetchData(@res)
		else
			console.log 'fetching expired data...'
			@fetchExpiredData()

	index: (params) =>
		@view = new GraphsView
			collection: @collection
			chart: 'prev_work_data'
			classes: ['chart-cur']
			change: 'change:prev_work_data_c'

	refresh: (params) =>
		console.log 'refreshing data...'
		@fetchData(@res)
		@redirectToRoute 'graphs#index'

