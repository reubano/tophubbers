Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'

module.exports = class AuthController extends Controller
  mediator = Chaplin.mediator

  logout: =>
    console.log 'auth-controller logging out'
    @redirectToRoute 'home#show', login: false
    @publishEvent '!logout'

  login: =>
    console.log 'logging in'
    @publishEvent '!login', 'google'
    @redirectToRoute 'home#show'
    location.reload()
