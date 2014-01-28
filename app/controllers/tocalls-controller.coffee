Controller = require 'controllers/base/controller'
View = require 'views/tocalls-view'
utils = require 'lib/utils'

module.exports = class TocallsController extends Controller
  adjustTitle: 'Github Call List'

  initialize: => utils.log 'initialize tocalls-controller'
  comparator: (model) -> - model.get 'score_sort'

  index: (params) =>
    @collection.comparator = @comparator
    @view = new View
      collection: @collection
      refresh: params?.refresh ? false
