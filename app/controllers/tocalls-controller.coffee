Controller = require 'controllers/base/controller'
View = require 'views/tocalls-view'
utils = require 'lib/utils'

module.exports = class TocallsController extends Controller
  initialize: =>
    @adjustTitle 'Check List'
    utils.log 'initialize tocalls-controller'

  comparator: (model) -> - model.get 'score_sort'

  index: (params) =>
    @collection.comparator = @comparator
    @view = new View
      collection: @collection
      refresh: params?.refresh ? false
