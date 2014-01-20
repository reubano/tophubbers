config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/graphs-view'
utils = require 'lib/utils'

module.exports = class GraphsController extends Controller
  adjustTitle: 'Github Commit Graph'
  res: ['rep_info', 'work_data']
  attr: if config.mobile then config.hash_attr else config.data_attr
  collection: Chaplin.mediator.reps

  initialize: => utils.log 'initialize graphs-controller'
  comparator: (model) -> model.get 'id'

  index: (params) =>
    @ignore_cache = params?.ignore_cache ? false
    refresh = params?.refresh ? false

    if refresh or @collection.length is 0
      if refresh then utils.log 'refreshing data...'
      else utils.log 'no collection so fetching all data...'
      @fetchData @res, false, @attr
    else
      utils.log 'fetching expired data...'
      @fetchExpiredData @res, false, @attr

    @collection.comparator = @comparator
    @view = new View
      collection: @collection
      attr: @attr
      ignore_cache: @ignore_cache
