View = require 'views/base/view'
template = require 'views/templates/progress'

module.exports = class ProgresView extends View
	template: template
	tagName: 'li'

	initialize: ->
		super
		@listenTo @model, 'change', @render

	render: =>
		super
		# console.log 'rendering progress view'
