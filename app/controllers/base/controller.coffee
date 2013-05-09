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
		reps = ({id: i, first_name: rep.first_name, last_name: rep.last_name} for i, rep of response)
		# reps = ({id: i, first_name: rep.first_name} for i, rep of response)
		curCol = @collection.pluck 'id'
		newCol = _.pluck reps, 'id'
		diff1 = _.difference curCol, newCol
		diff2 = _.difference newCol, curCol

		if diff1 != [] or diff2 != []
			@publishEvent 'graphs:clear'
			(@collection.create graph for graph in reps)

	initialize: =>
		ages = @collection.pluck 'age'
		now = (new Date).getTime() / 3600000

		if (now - Math.min.apply null, ages) > 24
			@getReps().success(@publishReps)
			# test = {'one': {first_name: 1}, 'two': {first_name: 2}}
			# @publishReps test

	beforeAction: (params, route) =>
		@compose 'site', SiteView
		@compose 'navbar', NavbarView
		@compose 'graphs', =>
			@view = new GraphsView {@collection}

