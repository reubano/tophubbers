CollectionView = require 'views/base/collection-view'
template = require 'views/templates/tocalls'
View = require 'views/tocall-view'
utils = require 'lib/utils'

module.exports = class TocallsView extends CollectionView
	itemView: View
	autoRender: true
	listSelector: '#tocall-list'
	region: 'content'
	className: 'span12'
	template: template

	initialize: (options) =>
		super
		@subscribeEvent 'resort', @sort
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'loggingIn', @render
		@subscribeEvent 'userUpdated', @render
		@subscribeEvent 'dispatcher:dispatch', ->
			utils.log 'tocalls-view caught dispatcher event'
		# @listenTo @model,'all', @renderCheckbox

	sort: =>
		utils.log 'resorting tocalls view'
		@collection.sort()

	render: =>
		super
		utils.log 'rendering tocalls view'
		@collection.sort()
