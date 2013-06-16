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

	show: (params) =>
		@id = params.id
		@ignore_svg = if params?.ignore_svg? then params.ignore_svg else false
		console.log 'show route id is ' + @id

		if @collection.length is 0
			console.log 'no collection so fetching all data...'
			@fetchData(@res, @id)
		else
			console.log 'fetching expired data...'
			@fetchExpiredData(@res, @id)

		@view = new View
			model: @collection.get @id
			attrs: config.data_attrs
			ignore_svg: @ignore_svg

	refresh: (params) =>
		console.log 'refreshing data...'
		@fetchData(@res, params.id)
		@redirectToRoute 'rep#show', id: params.id

