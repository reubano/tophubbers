Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'

module.exports = class AuthController extends Controller
  logout: =>
    console.log 'auth-controller logging out'
    localStorage.clear()
    @redirectToRoute 'home#show'
    @publishEvent '!logout'

  login: =>
    console.log 'logging in'
    @publishEvent '!login', 'google'
    @redirectToRoute 'home#show'
    location.reload()
