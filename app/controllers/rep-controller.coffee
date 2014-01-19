config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
View = require 'views/rep-view'
utils = require 'lib/utils'

module.exports = class RepController extends Controller
  adjustTitle: 'Github User View'
  res: ['rep_info', 'work_data', 'feedback_data', 'progress_data']
  collection: Chaplin.mediator.reps

  initialize: =>
    utils.log 'initialize rep-controller'
    console.log @collection

  show: (params) =>
    @id = params.id
    @ignore_cache = params?.ignore_cache ? false
    refresh = params?.refresh ? false
    utils.log 'show route id is ' + @id
    utils.log 'ignore_cache is ' + @ignore_cache

    if (refresh or @collection.length is 0) and @collection.get(@id)
      if refresh then utils.log 'refreshing data...'
      else utils.log 'no collection so fetching all data...'
      @fetchData @res, @id
      @showView @collection.get @id
    else if @collection.get(@id)
      utils.log 'fetching expired data...'
      @fetchExpiredData @res, @id
      @showView @collection.get @id
    else @redirectToRoute 'home#show'

  showView: (model) =>
    utils.log 'rendering showView'
    utils.log 'ignore_cache is ' + @ignore_cache
    @view = new View
      model: model
      attrs: if config.mobile then config.hash_attrs else config.data_attrs
      ignore_cache: @ignore_cache
