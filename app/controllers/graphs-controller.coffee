config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
GraphsView = require 'views/graphs-view'

module.exports = class Controller extends Controller
	adjustTitle: 'Graph list'
	collection: Chaplin.mediator.graphs
	url: config.info_api

	getReps: ->
		$.ajax url: @url, type: 'get', dataType: 'json'

	publishReps: (response) =>
		# console.log '< 0'
		reps = ({id: i, first_name: rep.first_name, last_name: rep.last_name} for i, rep of response)
		# reps = ({id: i, first_name: rep.first_name} for i, rep of response)

		if @collection.length > 0
			# check if the current rep list differs from the server
			curCol = @collection.pluck 'id'
			newCol = _.pluck reps, 'id'
			diff1 = _.difference curCol, newCol
			diff2 = _.difference newCol, curCol

			if diff1 != [] or diff2 != []
				@publishEvent 'graphs:clear'
				(@collection.create graph for graph in reps)
		else
			(@collection.create graph for graph in reps)

	initialize: =>
		# console.log 'init'
		if @collection.length > 0
			# console.log '> 0'
			# check if the cache needs to be refreshed
			ages = @collection.pluck 'age'
			now = (new Date).getTime() / 3600000

			if (now - Math.min.apply null, ages) > config.max_age
				@getReps().success(@publishReps)
				# test = {'one': {first_name: 1}, 'two': {first_name: 2}}
				# @publishReps test
		else
			# console.log '< 0'
			@getReps().success(@publishReps)

	show: (params) =>
		# console.log 'show'
		# console.log @collection
		@view = new GraphsView {@collection}
