Chaplin = require 'chaplin'
View = require 'views/base/view'
template = require 'views/templates/rep'

module.exports = class RepView extends View
	mediator = Chaplin.mediator

	autoRender: true
	region: 'content'
	className: 'span12'
	template: template

	initialize: ->
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'dispatcher:dispatch', @render
		@listenTo @model, 'change', @render
		super

	render: =>
		user = mediator.user
		super
