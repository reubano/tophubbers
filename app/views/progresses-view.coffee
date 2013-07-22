CollectionView = require 'views/base/collection-view'
template = require 'views/templates/progresses'
View = require 'views/progress-view'

module.exports = class ProgressesView extends CollectionView
	itemView: View
	listSelector: '#progress-list'
	region: 'content'
	className: 'span12'
	template: template

	initialize: (options) =>
		super
		@subscribeEvent 'resort', @sort
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'userUpdated', @render
		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'progresses-view caught dispatcher event'
			@render()
		# @listenTo @model,'all', @renderCheckbox

	sort: =>
		console.log 'resorting progresses view'
		@collection.sort()

	render: =>
		super
		console.log 'rendering progresses view'
		@collection.sort()
