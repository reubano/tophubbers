View = require 'views/base/view'
template = require 'views/templates/graph-hdr'

module.exports = class HeaderView extends View
	autoRender: yes
	el: '#graph-header'
	template: template

	initialize: ->
		super
		# @delegate 'keypress', '#new-graph', @refresh

	render: =>
		super
		@refresh

	refresh: =>
		titles = ['E0009', 'E0015', 'E0019']
		(@collection.create {title} for title in titles)

