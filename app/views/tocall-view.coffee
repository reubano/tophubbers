View = require 'views/base/view'
template = require 'views/templates/tocall'
utils = require 'lib/utils'

module.exports = class TocallView extends View
	template: template
	tagName: 'li'

	initialize: ->
		super
		@listenTo @model, 'change', @render
		@delegate 'click', '.toggle', @toggle

	render: =>
		super
		# utils.log 'rendering tocall view'
		@$el.removeClass 'text-error text-success muted'

		if @model.get 'called'
			className = 'muted'
		else if  @model.get('score') >= 100
			className = 'text-error'
		else
			className = 'text-success'

		@$el.addClass className

	toggle: =>
		@model.toggle()
		@model.save()
		@publishEvent 'resort'
