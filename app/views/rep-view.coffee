Chaplin = require 'chaplin'
GraphView = require 'views/graph-view'
template = require 'views/templates/rep'

module.exports = class RepView extends GraphView
	mediator = Chaplin.mediator

	autoRender: true
	region: 'content'
	className: 'span12'
	template: template

	initialize: (options) ->
		@listenTo @model, options.change, @render
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'rep-view caught dispatcher event'
		# @subscribeEvent 'dispatcher:dispatch', @render
		super

	render: =>
		console.log 'rendering rep view'
		user = mediator.user
		super
