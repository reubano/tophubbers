Controller = require 'controllers/base/controller'
View = require 'views/visits-view'
utils = require 'lib/utils'

module.exports = class VisitsController extends Controller
  initialize: =>
    @adjustTitle 'Stats Summary'
    utils.log 'initialize visits-controller'

  comparator: (model) -> - model.get 'public_repos'

  index: (params) =>
    @collection.comparator = @comparator
    utils.log 'show visits', 'info'
    @view = new View
      collection: @collection
      refresh: params?.refresh ? false
