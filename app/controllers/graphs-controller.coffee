config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/graphs-view'
utils = require 'lib/utils'

module.exports = class GraphsController extends Controller
  adjustTitle: 'Github Commit Graph'
  attr: if config.mobile then config.hash_attr else config.data_attr
  collection: Chaplin.mediator.reps

  initialize: => utils.log 'initialize graphs-controller'
  comparator: (model) -> model.get 'id'

  index: (params) =>
    @ignore_cache = params?.ignore_cache ? false
    refresh = params?.refresh ? false

    @collection.comparator = @comparator
    @view = new View
      collection: @collection
      attr: @attr
      refresh: refresh
      ignore_cache: @ignore_cache
