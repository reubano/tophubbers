config = require 'config'
Controller = require 'controllers/base/controller'
View = require 'views/rep-view'
utils = require 'lib/utils'

module.exports = class RepController extends Controller
  initialize: =>
    @adjustTitle 'User View'
    utils.log 'initialize rep-controller'
    console.log @collection

  show: (params) =>
    @login = params.login
    @ignore_cache = params?.ignore_cache ? false
    refresh = params?.refresh ? false
    utils.log 'show route login is ' + @login

    @view = new View
      model: @collection.findWhere login: @login
      attr: if config.mobile then config.hash_attr else config.data_attr
      refresh: params?.refresh ? false
      ignore_cache: @ignore_cache

