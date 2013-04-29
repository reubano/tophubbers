Controller = require 'controllers/base/controller'
TdHeaderView = require 'views/tdheader-view'
mediator = require 'mediator'

module.exports = class TdHeaderController extends Controller
  initialize: ->
    super
    @view = new TdHeaderView collection: mediator.todos
