CollectionView = require 'views/base/collection-view'
template = require 'views/templates/graphs'
GraphView = require 'views/graph-view'

module.exports = class GraphsView extends CollectionView
	itemView: GraphView
	autoRender: true
	listSelector: '#graph-list'
	region: 'content'
	className: 'span12'
	template: template

	initialize: ->
		super
		@subscribeEvent 'loginStatus', -> console.log 'caught loginStatus event'
		@subscribeEvent 'dispatcher:dispatch', -> console.log 'caught dispatcher event'
		@listenTo @collection, 'change', -> console.log 'caught collection change'
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'dispatcher:dispatch', @render
		@listenTo @collection, 'change', @render
		@subscribeEvent 'graphs:clear', @clear

	render: =>
		super

	clear: ->
		model.destroy() while model = @collection.first()
