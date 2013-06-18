Collection = require 'models/base/collection'
Model = require 'models/rep'

module.exports = class Reps extends Collection
	model: Model
	localStorage: new Store 'reps-collection'

	allAreCalled: ->
		@getCalled().length is @length

	getCalled: ->
		@where called: yes

	getActive: ->
		@where called: no

	initialize: (options) ->
		super
		console.log 'initialize reps collection'
