View = require 'views/base/view'
template = require 'views/templates/graph-hdr'

module.exports = class HeaderView extends View
	autoRender: yes
	el: '#graph-header'
	template: template

	getTemplateData: =>
		graphs: [{title: 'E0009'}, {title: 'E0015'}, {title: 'E0019'}]
		collection: @collection

	initialize: ->
		super
		graphs = [{title: 'E0009'}, {title: 'E0015'}, {title: 'E0019'}]
		@delegate 'keypress', '#new-graph', @createOnEnter
		@delegate 'click', '#refresh', @refresh

	refresh: =>
		graphs = [{title: 'E0009'}, {title: 'E0015'}, {title: 'E0019'}]
		@publishEvent 'graphs:clear'
		(@collection.create graph for graph in graphs)

	createOnEnter: (event) =>
		ENTER_KEY = 13
		value = $(event.currentTarget).val().trim()
		return if event.keyCode isnt ENTER_KEY or not value
		@collection.create {title: value}
		@$('#new-graph').val ''