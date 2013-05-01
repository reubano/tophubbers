CollectionView = require 'views/base/collection-view'
template = require 'views/templates/graphs'
GraphView = require 'views/graph-view'

module.exports = class GraphsView extends CollectionView
  el: '#graph-container'
  itemView: GraphView
  listSelector: '#graph-list'
  template: template

  initialize: ->
    super

  render: =>
    super
