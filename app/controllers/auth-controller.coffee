Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'

module.exports = class AuthController extends Controller
  mediator = Chaplin.mediator

  collection: Chaplin.mediator.users

  logout: =>
    console.log 'auth-controller logging out'
    @collection.get(1).destroy()
    @redirectToRoute 'home#show', login: false
    @publishEvent '!logout'

  login: =>
    console.log 'logging in'
    @publishEvent '!login', 'google'
    @redirectToRoute 'home#show'
    location.reload()
