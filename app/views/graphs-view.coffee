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

	initialize: (options) ->
		super
		@options = options
		@subscribeEvent 'loginStatus', -> console.log 'caught loginStatus event'
		@subscribeEvent 'dispatcher:dispatch', -> console.log 'caught dispatcher event'
		@listenTo @collection, 'reset', -> console.log 'caught collection reset'
		# @listenTo @collection, 'change', -> console.log 'caught collection change'
		@subscribeEvent 'loginStatus', @render
		# @subscribeEvent 'dispatcher:dispatch', @render
		@listenTo @collection, 'change', @render
		@listenTo @collection, 'reset', @render
		@subscribeEvent 'graphs:clear', @clear

	initItemView: (model) ->
		new @itemView
			model: model
			autoRender: false
			chart: @options.chart
			change: @options.change

	render: =>
		console.log 'rendering graphs view'
		super

	clear: ->
		model.destroy() while model = @collection.first()
