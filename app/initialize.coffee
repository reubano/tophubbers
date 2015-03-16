Application = require 'application'
routes = require 'routes'
utils = require 'lib/utils'

# Initialize the application on DOM ready event.
$ ->
  utils.log 'initializing app'
  new Application {
    controllerSuffix: '-controller'
    routes
  }
