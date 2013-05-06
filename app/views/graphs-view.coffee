CollectionView = require 'views/base/collection-view'
template = require 'views/templates/graphs'
GraphView = require 'views/graph-view'

module.exports = class GraphsView extends CollectionView
	itemView: GraphView
	listSelector: '#graph-list'
	className: 'graphs'
	region: 'graphs'
	id: 'graphs'
	template: template

	initialize: ->
		super
		@subscribeEvent 'graphs:clear', @clear

	render: =>
		super

	clear: ->
		model.destroy() while model = @collection.first()
