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
		@subscribeEvent 'loginStatus', @render
		@listenTo @model, options.change, @render
		@subscribeEvent 'dispatcher:dispatch', -> console.log 'rep-view caught dispatcher event'
		# @subscribeEvent 'dispatcher:dispatch', @render
		super

	render: =>
		user = mediator.user
		super
