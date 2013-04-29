Controller = require 'controllers/base/controller'
GraphHdrView = require 'views/graph-hdr-view'
mediator = require 'mediator'

module.exports = class GraphHdrController extends Controller
  initialize: ->
    super
    @view = new GraphHdrView collection: mediator.graphs
