config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/rep-view'

module.exports = class Controller extends Controller
	adjustTitle: 'Ongeza Rep View'
	res: ['rep_info', 'work_data', 'feedback_data', 'progress_data']
	collection: Chaplin.mediator.reps

	initialize: =>
		console.log 'initialize rep-controller'
		console.log @collection

	show: (params) =>
		@id = params.id
		@ignore_svg = if params?.ignore_svg? then params.ignore_svg else false
		console.log 'show route id is ' + @id
		console.log 'ignore_svg is ' + @ignore_svg

		if @collection.length is 0
			console.log 'no collection so fetching all data...'
			@fetchData(@res, @id)
			@subscribeEvent 'repsSet', ->
				@showView @collection.get @id
				@unsubscribeEvent 'repsSet', -> null
		else
			console.log 'fetching expired data...'
			@fetchExpiredData(@res, @id)
			@showView @collection.get @id

	showView: (model) =>
		console.log 'rendering showView'
		console.log 'ignore_svg is ' + @ignore_svg
		@view = new View
			model: model
			attrs: config.data_attrs
			ignore_svg: @ignore_svg

	refresh: (params) =>
		console.log 'refreshing data...'
		@fetchData(@res, params.id)
		@redirectToRoute 'rep#show', id: params.id

