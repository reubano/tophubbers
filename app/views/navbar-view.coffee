Chaplin = require 'chaplin'
View = require 'views/base/view'
template = require 'views/templates/navbar'

module.exports = class NavbarView extends View
	mediator = Chaplin.mediator

	autoRender: true
	className: 'navbar-inner'
	region: 'navbar'
	template: template

	initialize: (options) ->
		super
		# utils.log 'navbar-view init'
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'dispatcher:dispatch', @render
