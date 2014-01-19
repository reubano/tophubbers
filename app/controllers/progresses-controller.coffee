Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/progresses-view'
utils = require 'lib/utils'

module.exports = class ProgressesController extends Controller
  adjustTitle: 'Github User Progress'
  res: ['rep_info', 'score', 'progress_data']
  collection: Chaplin.mediator.reps

  initialize: => utils.log 'initialize progresses-controller'
  comparator: (model) -> - model.get 'score'

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
