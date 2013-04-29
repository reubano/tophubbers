Controller = require 'controllers/base/controller'

module.exports = class IndexController extends Controller
  title: 'Graph list'

  list: (options) ->
    @publishEvent 'graphs:filter', options.filterer?.trim() ? 'all'
