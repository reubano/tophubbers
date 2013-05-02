# nvd3util = require '../nvd3util'
View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template

	initialize: ->
		super
		@modelBind 'change', @render
		@delegate 'click', '.icon-remove-sign', @destroy

	render: =>
		super

	destroy: =>
		@model.destroy()
