CollectionView = require 'views/base/collection-view'
template = require 'views/templates/progresses'
View = require 'views/progress-view'
utils = require 'lib/utils'

module.exports = class ProgressesView extends CollectionView
	itemView: View
	autoRender: true
	listSelector: '#progress-list'
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
			utils.log 'progresses-view caught dispatcher event'
		# @listenTo @model,'all', @renderCheckbox

	sort: =>
		utils.log 'resorting progresses view'
		@collection.sort()

	render: =>
		super
		utils.log 'rendering progresses view'
		@collection.sort()
