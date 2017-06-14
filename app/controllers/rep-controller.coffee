config = require 'config'
Controller = require 'controllers/base/controller'
View = require 'views/rep-view'
utils = require 'lib/utils'

module.exports = class RepController extends Controller
  initialize: =>
    @adjustTitle 'User View'
    utils.log 'initialize rep-controller'

  show: (params) =>
    @login = params.login
    @ignore_cache = params?.ignore_cache ? false
    refresh = params?.refresh ? false
    utils.log "show #{@login}", 'info'

    @view = new View
      model: @collection.findWhere login: @login
      refresh: params?.refresh ? false
      resize: true
      ignore_cache: @ignore_cache
