CollectionView = require 'views/base/collection-view'
template = require 'views/templates/graphs'
View = require 'views/graph-view'
mediator = require 'mediator'
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

  initialize: (options) =>
    super
    utils.log 'initialize graphs-view'
    mediator.setActive 'graphs'
    @options = options
    # @subscribeEvent 'dispatcher:dispatch', @render
    @listenTo @collection, 'reset', @render

  render: =>
    super
    utils.log 'rendering graphs view'
    @collection.sort()
