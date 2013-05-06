Chaplin = require 'chaplin'
routes = require 'routes'
Graphs = require 'models/graphs'
Layout = require 'views/layout'

# The application object.
module.exports = class Application extends Chaplin.Application
  # Set your application name here so the document title is set to
  # “Controller title – Site title” (see Chaplin.Layout#adjustTitle)
  title: 'Chaplin • TodoMVC'

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

  # Instantiate common controllers
  # ------------------------------
  initControllers: ->
    # These controllers are active during the whole application runtime.
    # You don’t need to instantiate all controllers here, only special
    # controllers which do not to respond to routes. They may govern models
    # and views which are needed the whole time, for example header, footer
    # or navigation views.
    # e.g. new NavigationController()

  # Create additional mediator properties.
  initMediator: ->
    # Add additional application-specific properties and methods
    # e.g. Chaplin.mediator.prop = null
    Chaplin.mediator.graphs = new Graphs()
    Chaplin.mediator.graphs.fetch()

    # Seal the mediator.
    Chaplin.mediator.seal()
