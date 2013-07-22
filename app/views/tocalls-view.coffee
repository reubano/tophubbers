CollectionView = require 'views/base/collection-view'
template = require 'views/templates/tocalls'
View = require 'views/tocall-view'

module.exports = class TocallsView extends CollectionView
	itemView: View
	listSelector: '#tocall-list'
	region: 'content'
	className: 'span12'
	template: template

	initialize: (options) =>
		super
		@subscribeEvent 'resort', @sort
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'userUpdated', @render
		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'tocalls-view caught dispatcher event'
		# @subscribeEvent 'dispatcher:dispatch', @render
		# @listenTo @model,'all', @renderCheckbox

	sort: =>
		console.log 'resorting tocalls view'
		@collection.sort()

	render: =>
		super
		console.log 'rendering tocalls view'
		@collection.sort()
