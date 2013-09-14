Chaplin = require 'chaplin'
routes = require 'routes'
Reps = require 'models/reps'
Users = require 'models/users'
Forms = require 'models/forms'
Navbar = require 'models/navbar'
Layout = require 'views/layout'

# The application object.
module.exports = class Application extends Chaplin.Application
	# Set your application name here so the document title is set to
	# “Controller title – Site title” (see Chaplin.Layout#adjustTitle)
	title: 'Ongeza Sales Rep App'

	initialize: ->
		super

		# Initialize core components.
		# ---------------------------

		# Dispatcher listens for routing events and initialises controllers.
		@initDispatcher controllerSuffix: '-controller'

		# Layout listens for click events & delegates internal links to router.
		@initLayout()

		# Composer grants the ability for views and stuff to be persisted.
		@initComposer()

		# Mediator is a global message broker which implements pub / sub pattern.
		@initMediator()

		# Register all routes.
		# You might pass Router/History options as the second parameter.
		# Chaplin enables pushState per default and Backbone uses / as
		# the root per default. You might change that in the options
		# if necessary:
		# @initRouter routes, pushState: false, root: '/subdir/'
		@initRouter routes

		# Actually start routing.
		@startRouting()

		# Freeze the application instance to prevent further changes.
		Object.freeze? this

	initLayout: ->
		@layout = new Layout {@title}

	# Create additional mediator properties.
	initMediator: ->
		# Add additional application-specific properties and methods
		Chaplin.mediator.user = null
		Chaplin.mediator.loggingIn = false
		Chaplin.mediator.loginFailed = false
		Chaplin.mediator.synced = false
		Chaplin.mediator.download = {}
		Chaplin.mediator.rep_id = null
		Chaplin.mediator.users = new Users()
		Chaplin.mediator.forms = new Forms()
		Chaplin.mediator.reps = new Reps()
		Chaplin.mediator.navbar = new Navbar()
		Chaplin.mediator.users.fetch()
		Chaplin.mediator.forms.fetch {remote: false}
		Chaplin.mediator.reps.fetch()
		Chaplin.mediator.seal()
