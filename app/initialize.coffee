Application = require 'application'
routes = require 'routes'
mediator = require 'mediator'
utils = require 'lib/utils'

window.onLoadGoogleApiCallback = ->
  L.GeoSearch.Provider.Google.Geocoder = new google.maps.Geocoder()
  document.body.removeChild(document.getElementById('load_google_api'))
  mediator.publish 'googleLoaded'
  mediator.googleLoaded = true
  utils.log 'published googleLoaded'

# Initialize the application on DOM ready event.
$ ->
  utils.log 'initializing app'
  new Application {
    controllerSuffix: '-controller'
    routes
  }
