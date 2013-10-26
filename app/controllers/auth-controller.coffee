Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
View = require 'views/home-view'
utils = require 'lib/utils'

module.exports = class AuthController extends Controller
  model: Chaplin.mediator.navbar

  initialize: =>
    utils.log 'initialize auth-controller'
    @subscribeEvent 'login', -> @redirectToRoute 'home#show'

  logout: =>
    utils.log 'auth-controller logging out'
    utils.log 'show home from auth-controller'
    @view = new View {@model}
    @publishEvent '!logout'

  login: =>
    utils.log 'auth-controller logging in'
    @publishEvent '!login', 'google'
    @publishEvent '!showLogin'
