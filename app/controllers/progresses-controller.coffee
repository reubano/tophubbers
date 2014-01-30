Controller = require 'controllers/base/controller'
View = require 'views/progresses-view'
utils = require 'lib/utils'

module.exports = class ProgressesController extends Controller
  initialize: =>
    @adjustTitle 'Follower Progress'
    utils.log 'initialize progresses-controller'

  comparator: (model) -> - model.get 'followers'

  index: (params) =>
    @collection.comparator = @comparator
    utils.log 'show progresses', 'info'
    @view = new View
      collection: @collection
      refresh: params?.refresh ? false
