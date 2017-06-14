config = require 'config'
Controller = require 'controllers/base/controller'
FollowersView = require 'views/followers-view'
utils = require 'lib/utils'
mediator = require 'mediator'

module.exports = class HomeController extends Controller
  initialize: =>
    @adjustTitle 'Home'
    utils.log 'initialize home-controller', 'info'

  show: (params) =>
    utils.log 'show home'
    mediator.map = null

    if mediator.synced
      @viewPage FollowersView
    else
      @subscribeEvent 'synced', => @viewPage FollowersView

  viewPage: (theView) =>
    @view = new FollowersView {@collection}
