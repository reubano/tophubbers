Chaplin = require 'chaplin'
SiteView = require 'views/site-view'
NavbarView = require 'views/navbar-view'
Navbar = require 'models/navbar'

module.exports = class Controller extends Chaplin.Controller
	model: Chaplin.mediator.navbar

	beforeAction: (params, route) =>
		@compose 'site', SiteView
		@compose 'auth', ->
			SessionController = require 'controllers/session-controller'
			@controller = new SessionController

		@compose 'navbar', =>
			@view = new NavbarView {@model}

