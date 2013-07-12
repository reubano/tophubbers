Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
View = require 'views/login-view'

module.exports = class AuthController extends Controller
	mediator = Chaplin.mediator

	logout: =>
		console.log 'auth-controller logging out'
		@redirectToRoute 'home#show', login: false
		@publishEvent '!logout'

	login: =>
		console.log 'auth-controller logging in'
		@publishEvent '!login', 'google'
		@view = new View()
