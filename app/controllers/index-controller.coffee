Controller = require 'controllers/base/controller'

module.exports = class IndexController extends Controller
  adjustTitle: 'Todo list'

  list: (options) ->
    @publishEvent 'todos:filter', options.filterer?.trim() ? 'all'
