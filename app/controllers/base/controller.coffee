config = require 'config'
Chaplin = require 'chaplin'
SiteView = require 'views/site-view'
NavbarView = require 'views/navbar-view'
GraphsView = require 'views/graphs-view'
Graphs = require 'models/graphs'

module.exports = class Controller extends Chaplin.Controller
	collection: Chaplin.mediator.graphs
	url: config.api

	getReps: ->
		$.ajax url: @url, type: 'get', dataType: 'json'

	publishReps: (response) =>
		reps = ({title: rep} for rep in response.data)
		@publishEvent 'graphs:clear'
		(@collection.create graph for graph in reps)

	initialize: ->
		@getReps().success(@publishReps)

	beforeAction: (params, route) =>
		@compose 'site', SiteView
		@compose 'navbar', NavbarView
		@compose 'graphs', =>
			@view = new GraphsView {@collection}

