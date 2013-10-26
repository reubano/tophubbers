config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/rep-view'
utils = require 'lib/utils'

module.exports = class RepController extends Controller
  adjustTitle: 'Ongeza Rep View'
  res: ['rep_info', 'work_data', 'feedback_data', 'progress_data']
  collection: Chaplin.mediator.reps

  initialize: =>
    utils.log 'initialize rep-controller'
    utils.log @collection

  show: (params) =>
    @id = params.id
    @ignore_cache = params?.ignore_cache ? false
    utils.log 'show route id is ' + @id
    utils.log 'ignore_cache is ' + @ignore_cache

    if @collection.length is 0 and @collection.get(@id)
      utils.log 'no collection so fetching all data...'
      @fetchData(@res, @id)
      @subscribeEvent 'repsSet', ->
        @showView @collection.get @id
        @unsubscribeEvent 'repsSet', -> null
    else if @collection.get(@id)
      utils.log 'fetching expired data...'
      @fetchExpiredData(@res, @id)
      @showView @collection.get @id
    else
      @redirectToRoute 'home#show'

  refresh: (params) =>
    utils.log 'refreshing data...'
    @fetchData(@res, params.id)
    @redirectToRoute 'rep#show', id: params.id

  showView: (model) =>
    utils.log 'rendering showView'
    utils.log 'ignore_cache is ' + @ignore_cache
    @view = new View
      model: model
      attrs: if config.mobile then config.hash_attrs else config.data_attrs
      ignore_cache: @ignore_cache
