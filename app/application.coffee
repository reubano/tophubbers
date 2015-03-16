mediator = require 'mediator'
routes = require 'routes'
Reps = require 'models/reps'
Navbar = require 'models/navbar'
utils = require 'lib/utils'

# The application object.
module.exports = class Application extends Chaplin.Application
  title: 'Top Githubbers'

  # start: ->
  #   # You can fetch some data here and start app
  #   # (by calling `super`) after that.
  #   super

  # Create additional mediator properties.
  initMediator: ->
    # Add additional application-specific properties and methods
    utils.log 'initializing mediator'
    mediator.download = {}
    mediator.rep_id = null
    mediator.reps = new Reps()
    mediator.navbar = new Navbar()
    mediator.reps.cltnFetch().done (collection) ->
      localStorage.setItem 'tophubbers:synced', true
      collection.display()
    mediator.seal()
    super
