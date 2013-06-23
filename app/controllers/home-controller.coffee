config = require 'config'
Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
View = require 'views/home-view'

module.exports = class HomeController extends Controller
	adjustTitle: 'Ongeza Home'
	collection: Chaplin.mediator.reps
	model: Chaplin.mediator.navbar
	forms: Chaplin.mediator.forms

	initialize: =>
		console.log 'initialize home-controller'

	show: (params) =>
		console.log 'show home'
		@view = new View {@model}

	fetchData: =>
		if @collection.length is 0
			console.log 'no collection so fetching all data...'
			@fetchData()
		else
			console.log 'fetching expired data...'
			@fetchExpiredData()

		@forms.syncDirtyAndDestroyed()
		@forms.fetch
			data:
				"results_per_page=100&q=" + JSON.stringify
					"order_by": [{"field": "date", "direction": "desc"}]

		_.delay @fetchData, config.poll_intrv * 1000 * 60 * 60
		# _.delay @fetchData, 5000

	refresh: =>
		@redirectToRoute 'home#show'
		@fetchData()

