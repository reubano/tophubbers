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
		@subscribeEvent 'fetchData', ->
			_.delay @fetchAndPub, config.max_age * 1000 * 60 * 60

	show: (params) =>
		console.log 'show home'
		@view = new View {@model}

	fetchAndPub: =>
		@fetchData()
		@publishEvent 'fetchData', -> null

	fetchData: =>
		console.log 'fetching all form data...'
		@fetchData()
		@forms.syncDirtyAndDestroyed()
		@forms.fetch
			data:
				'results_per_page=' + config.rpp + '&q=' + JSON.stringify
					"order_by": [{"field": "date", "direction": "desc"}]

	refresh: =>
		@redirectToRoute 'home#show'
		@fetchData()

