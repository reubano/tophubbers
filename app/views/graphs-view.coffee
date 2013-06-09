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

	listen:
		addedToParent: 'addedToParentAlert'
		addedToDOM: 'addedToDOMAlert'
		visibilityChange: 'visibilityChangeAlert'

	addedToParentAlert: ->
		console.log 'graphs-view heard addedToParent'

	addedToDOMAlert: ->
		console.log 'graphs-view heard addedToDOM'

	visibilityChangeAlert: ->
		console.log 'graphs-view heard visibilityChange'

	initialize: (options) ->
		super
		@options = options
		@subscribeEvent 'loginStatus', ->
			console.log 'graphs-view caught loginStatus event'

		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'graphs-view caught dispatcher event'

		@listenTo @collection, 'reset', ->
			console.log 'graphs-view heard collection reset'

		# @listenTo @collection, @options.change, ->
		# 	console.log 'caught collection change'

		@subscribeEvent 'loginStatus', @render
		# @subscribeEvent 'dispatcher:dispatch', @render
		@listenTo @collection, 'change', @render
		@listenTo @collection, 'reset', @render
		@subscribeEvent 'graphs:clear', @clear

	initItemView: (model) ->
		new @itemView
			model: model
			autoRender: false
			autoAttach: false
			chart: @options.chart
			change: @options.change

	render: =>
		console.log 'rendering graphs view'
		super

	clear: ->
		model.destroy() while model = @collection.first()
