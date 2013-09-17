config = require 'config'
Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
View = require 'views/home-view'
utils = require 'lib/utils'

module.exports = class HomeController extends Controller
	mediator = Chaplin.mediator

	adjustTitle: 'Ongeza Home'
	collection: mediator.reps
	model: mediator.navbar
	forms: mediator.forms

	initialize: =>
		utils.log 'initialize home-controller'
		@subscribeEvent 'fetchData', ->
			_.delay @fetchAndPub, config.max_age * 1000 * 60 * 60

	show: (params) =>
		utils.log 'show home'
		@view = new View {@model}

	fetchAndPub: =>
		@fetchData()
		@fetchFormData()
		@publishEvent 'fetchData', -> null

	fetchFormData: =>
		utils.log 'fetching all form data...'
		@forms.syncDirtyAndDestroyed()
		@forms.fetch
			data:
				'results_per_page=' + config.rpp + '&q=' + JSON.stringify
					"order_by": [{"field": "date", "direction": "desc"}]

	refresh: =>
		@redirectToRoute 'home#show'
		@fetchAndPub()

