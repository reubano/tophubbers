Controller = require 'controllers/base/controller'
View = require 'views/visits-view'
utils = require 'lib/utils'

module.exports = class VisitsController extends Controller
  initialize: =>
    @adjustTitle 'Stats Summary'
    utils.log 'initialize visits-controller'

  comparator: (model) -> model.get 'id'

  index: (params) =>
    @collection.comparator = @comparator
    @view = new View
      collection: @collection
      refresh: params?.refresh ? false
