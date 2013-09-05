CollectionView = require 'views/base/collection-view'
template = require 'views/templates/graphs'
View = require 'views/graph-view'
utils = require 'lib/utils'

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
		utils.log 'graphs-view heard addedToParent'

	addedToDOMAlert: ->
		utils.log 'graphs-view heard addedToDOM'

	visibilityChangeAlert: ->
		utils.log 'graphs-view heard visibilityChange'

	initialize: (options) ->
		super
		utils.log 'initialize graphs-view'
		@options = options
		@subscribeEvent 'loginStatus', ->
			utils.log 'graphs-view caught loginStatus event'
			@render()

		@subscribeEvent 'loggingIn', @render
		@subscribeEvent 'userUpdated', @render
		@subscribeEvent 'dispatcher:dispatch', ->
			utils.log 'graphs-view caught dispatcher event'
			@render()

		@listenTo @collection, 'reset', ->
			utils.log 'graphs-view heard collection reset'
			@render()

	initItemView: (model) ->
		new @itemView
			model: model
			autoRender: false
			# autoAttach: false
			attrs: @options.attrs
			ignore_svg: @options.ignore_svg

	render: =>
		super
		utils.log 'rendering graphs view'
		@collection.sort()

	clear: ->
		model.destroy() while model = @collection.first()
