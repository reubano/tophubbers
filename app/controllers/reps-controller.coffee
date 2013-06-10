Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
RepView = require 'views/rep-view'

module.exports = class Controller extends Controller
	adjustTitle: 'Ongeza Rep View'
	res: ['rep_info', 'work_data', 'feedback_data', 'progress_data']
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

	show: (params) =>
		@model = @collection.get params.id
		@view = new RepView
			model: @model
			chart: 'prev_work_data'
			classes: ['chart-cur', 'chart-prev']
			change: 'change:prev_work_data_c'

	refresh: (params) =>
		console.log 'refreshing data...'
		@fetchData(@res)
		@redirectToRoute 'reps#show'

