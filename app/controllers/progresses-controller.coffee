Controller = require 'controllers/base/controller'
View = require 'views/progresses-view'
utils = require 'lib/utils'

module.exports = class ProgressesController extends Controller
  adjustTitle: 'Github User Progress'

  initialize: => utils.log 'initialize progresses-controller'
  comparator: (model) -> - model.get 'score'

  index: (params) =>
    @collection.comparator = @comparator
    @view = new View
      collection: @collection
      refresh: params?.refresh ? false
