Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/visits-view'
utils = require 'lib/utils'

module.exports = class VisitsController extends Controller
  adjustTitle: 'Github User Progress'
  res: ['rep_info', 'visits']
  collection: Chaplin.mediator.reps

  initialize: => utils.log 'initialize visits-controller'
  comparator: (model) -> model.get 'id'

  index: (params) =>
    refresh = params?.refresh ? false

    if refresh or @collection.length is 0
      if refresh then utils.log 'refreshing data...'
      else utils.log 'no collection so fetching all data...'
      @fetchData @res
    else
      utils.log 'fetching expired data...'
      @fetchExpiredData @res

    @collection.comparator = @comparator
    @view = new View {@collection}
