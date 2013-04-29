Controller = require 'controllers/base/controller'
FooterView = require 'views/tdfooter-view'
mediator = require 'mediator'

module.exports = class FooterController extends Controller
  initialize: ->
    super
    @view = new FooterView collection: mediator.todos
