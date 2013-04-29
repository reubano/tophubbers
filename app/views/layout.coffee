Chaplin = require 'chaplin'

# Layout is the top-level application ‘view’.
module.exports = class Layout extends Chaplin.Layout
  initialize: ->
    super
    @subscribeEvent 'todos:filter', @changeFilterer

  changeFilterer: (filterer = 'all') ->
    $('#graphapp').attr 'class', "filter-#{filterer}"
