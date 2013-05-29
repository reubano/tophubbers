Controller = require 'controllers/base/controller'

module.exports = class AuthController extends Controller
  logout: ->
    @redirectToRoute 'home#show'
    localStorage.clear()
    @publishEvent '!logout'

  login: ->
    @publishEvent '!login', 'google'
    @redirectToRoute 'home#index'
    location.reload()
