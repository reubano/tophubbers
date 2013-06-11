CollectionView = require 'views/base/collection-view'
template = require 'views/templates/graphs'
View = require 'views/graph-view'

module.exports = class GraphsView extends CollectionView
	itemView: View
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
		console.log 'initialize graphs-view'
		@options = options
		@subscribeEvent 'loginStatus', ->
			console.log 'graphs-view caught loginStatus event'

		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'graphs-view caught dispatcher event'

		@listenTo @collection, 'reset', ->
			console.log 'graphs-view heard collection reset'

		@subscribeEvent 'loginStatus', @render
		# @subscribeEvent 'dispatcher:dispatch', @render
		@listenTo @collection, 'reset', @render
		@subscribeEvent 'graphs:clear', @clear

	initItemView: (model) ->
		new @itemView
			model: model
			autoRender: false
			autoAttach: false
			attrs: @options.attrs

	render: =>
		super
		console.log 'rendering graphs view'
		@collection.sort()

	clear: ->
		model.destroy() while model = @collection.first()
