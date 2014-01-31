config = require 'config'
Controller = require 'controllers/base/controller'
View = require 'views/graphs-view'
utils = require 'lib/utils'

module.exports = class GraphsController extends Controller
  initialize: =>
    @adjustTitle 'Activity Graph'
    utils.log 'initialize graphs-controller'

  comparator: (model) -> model.get 'id'

  index: (params) =>
    @collection.comparator = @comparator
    utils.log 'show graphs', 'info'
    @view = new View
      collection: @collection
      refresh: params?.refresh ? false
      ignore_cache: params?.ignore_cache ? false
