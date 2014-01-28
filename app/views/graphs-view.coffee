CollectionView = require 'views/base/collection-view'
template = require 'views/templates/graphs'
View = require 'views/graph-view'
utils = require 'lib/utils'

module.exports = class GraphsView extends CollectionView
  itemView: View
  autoRender: true
  listSelector: '#graph-list'
  region: 'content'
  className: 'span12'
  template: template

  listen:
    addedToParent: -> utils.log 'graphs-view heard addedToParent'
    addedToDOM: -> utils.log 'graphs-view heard addedToDOM'
    # visibilityChange: -> utils.log 'graphs-view heard visibilityChange'

  initialize: (options) ->
    super
    utils.log 'initialize graphs-view'
    @options = options

    @subscribeEvent 'dispatcher:dispatch', ->
      utils.log 'graphs-view caught dispatcher event'
      @render()

    @listenTo @collection, 'reset', ->
      utils.log 'graphs-view heard collection reset'
      @render()

  render: =>
    super
    utils.log 'rendering graphs view'
    @collection.sort()

  clear: ->
    model.destroy() while model = @collection.first()
