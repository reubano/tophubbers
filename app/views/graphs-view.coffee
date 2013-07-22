CollectionView = require 'views/base/collection-view'
template = require 'views/templates/graphs'
View = require 'views/graph-view'

module.exports = class GraphsView extends CollectionView
	itemView: View
	autoRender: true
	listSelector: '#graph-list'
	fallbackSelector: '.fallback'
	loadingSelector: '.loading'
	region: 'content'
	className: 'span12'
	template: template

	listen:
		addedToParent: 'addedToParentAlert'
		addedToDOM: 'addedToDOMAlert'
		# visibilityChange: 'visibilityChangeAlert'

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
			@render()

		@subscribeEvent 'loggingIn', @render
		@subscribeEvent 'userUpdated', @render
		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'graphs-view caught dispatcher event'
			@render()

		@listenTo @collection, 'reset', ->
			console.log 'graphs-view heard collection reset'
			@render()

	initItemView: (model) ->
		new @itemView
			model: model
			autoRender: false
			autoAttach: false
			attrs: @options.attrs
			ignore_svg: @options.ignore_svg

	render: =>
		super
		console.log 'rendering graphs view'
		@collection.sort()

	clear: ->
		model.destroy() while model = @collection.first()
