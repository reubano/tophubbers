Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/progresses-view'
utils = require 'lib/utils'

module.exports = class ProgressesController extends Controller
  adjustTitle: 'Ongeza Rep Progress'
  res: ['rep_info', 'score', 'progress_data']
  collection: Chaplin.mediator.reps

  initialize: =>
    utils.log 'initialize progresses-controller'

    if @collection.length is 0
      utils.log 'no collection so fetching all data...'
      @fetchData(@res)
    else
      utils.log 'fetching expired data...'
      @fetchExpiredData(@res)

  comparator: (model) ->
    - model.get 'score'

  index: =>
    @collection.comparator = @comparator
    @view = new View {@collection}

  refresh: =>
    utils.log 'refreshing data...'
    @redirectToRoute 'progresses#index'
    @fetchData(@res)

