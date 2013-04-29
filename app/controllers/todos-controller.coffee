Controller = require 'controllers/base/controller'
GraphsView = require 'views/graphs-view'
mediator = require 'mediator'

module.exports = class GraphsController extends Controller
  initialize: ->
    super
    @view = new GraphsView collection: mediator.graphs
