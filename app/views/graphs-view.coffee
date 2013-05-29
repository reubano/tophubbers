CollectionView = require 'views/base/collection-view'
template = require 'views/templates/graphs'
GraphView = require 'views/graph-view'

module.exports = class GraphsView extends CollectionView
	itemView: GraphView
	autoRender: no
	listSelector: '#graph-list'
	region: 'content'
	className: 'span12'
	template: template

	initialize: ->
		super
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'dispatcher:dispatch', @render
		@listenTo @collection, 'change', @render
		@subscribeEvent 'graphs:clear', @clear

	render: =>
		super

	clear: ->
		model.destroy() while model = @collection.first()
