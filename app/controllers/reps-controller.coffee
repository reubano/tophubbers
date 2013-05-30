config = require 'config'
Controller = require 'controllers/base/controller'
Chaplin = require 'chaplin'
RepView = require 'views/rep-view'
GraphsView = require 'views/graphs-view'

module.exports = class Controller extends Controller
	collection: Chaplin.mediator.reps
	rep_url: config.api + 'info'
	cur_work_url: config.api + 'cur_work'
	cur_feedback_url: config.api + 'cur_feedback'
	cur_progress_url: config.api + 'cur_progress'

	getData: (url, callback) ->
		$.ajax url: url, type: 'get', dataType: 'json', success: callback

	resetReps: (response) =>
		console.log 'resetting collection'
		Chaplin.mediator.reps.reset response.data
		console.log Chaplin.mediator.reps
		@collection.reset response.data

	setReps: (response) =>
		console.log 'setting collection'
		Chaplin.mediator.reps.set response.data
		console.log Chaplin.mediator.reps
		@collection.set response.data, {remove: false}

	cacheExpired: =>
		# check if the cache has expired
		ages = @collection.pluck 'age'
		now = (new Date).getTime() / 3600000
		(now - Math.min.apply null, ages) > config.max_age

	repListDiffers: (reps) =>
		# check if the current rep list differs from the server
		curCol = @collection.pluck 'id'
		newCol = _.pluck reps, 'id'
		diff1 = _.difference curCol, newCol
		diff2 = _.difference newCol, curCol
		diff1 != [] or diff2 != []

	initialize: =>
		if (@collection.length == 0 or @cacheExpired())
			console.log 'collection length: ' + Chaplin.mediator.reps.length
			console.log 'cacheExpired: ' + @cacheExpired()
			console.log 'fetching graphs'
			@publishEvent 'graphs:clear'
			@getData @rep_url, @resetReps
			@getData @cur_work_url, @setReps
			# @getData @cur_feedback_url, @setReps
			# @getData @cur_progress_url, @setReps
		else
			console.log 'collection length: ' + Chaplin.mediator.reps.length
			console.log 'using cached graphs'

	show: (params) =>
		console.log 'rendering rep view'
		@model = @collection.get(params.id)
		@view = new RepView {@model}

	index: (params) =>
		console.log 'rendering graphs view'
		@view = new GraphsView {@collection}
