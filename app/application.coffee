mediator = require 'mediator'
routes = require 'routes'
Reps = require 'models/reps'
Navbar = require 'models/navbar'
config = require 'config'
utils = require 'lib/utils'

# The application object.
module.exports = class Application extends Chaplin.Application
  title: 'Top Githubbers'

  start: ->
    mediator.reps.cltnFetch().done (collection) ->
      collection.display()
      mediator.setSynced()

    super

  # Create additional mediator properties.
  initMediator: ->
    # Add additional application-specific properties and methods
    utils.log 'initializing mediator'
    mediator.rep_id = null
    mediator.reps = new Reps()
    mediator.navbar = new Navbar()
    mediator.map = null
    mediator.AwesomeMarker = L.AwesomeMarkers.icon config.options
    mediator.synced = false
    mediator.active = null
    mediator.url = null
    mediator.googleLoaded = null
    mediator.tiles = null
    mediator.markers = []
    mediator.doneSearching = null
    mediator.title = null
    mediator.seal()
    super
