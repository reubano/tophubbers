View = require 'views/base/view'
template = require 'views/templates/progress'

module.exports = class ProgresView extends View
	template: template
	tagName: 'li'

	initialize: ->
		super
		@listenTo @model, 'change', @render
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'progress-view caught dispatcher event'
		# @subscribeEvent 'dispatcher:dispatch', @render

	render: =>
		super
		console.log 'rendering progress view'
