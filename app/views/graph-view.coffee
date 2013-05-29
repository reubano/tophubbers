View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template

	initialize: ->
		super
		@listenTo @model, 'change', @render

	render: =>
		super
