Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
View = require 'views/home-view'

module.exports = class AuthController extends Controller
	model: Chaplin.mediator.navbar

	initialize: =>
		console.log 'initialize auth-controller'
		@subscribeEvent 'login', -> @redirectToRoute 'home#show'

	logout: =>
		console.log 'auth-controller logging out'
		console.log 'show home from auth-controller'
		@view = new View {@model}
		@publishEvent '!logout'

	login: =>
		console.log 'auth-controller logging in'
		@publishEvent '!login', 'google'
		@publishEvent '!showLogin'
