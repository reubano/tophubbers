Collection = require 'models/base/collection'
Rep = require 'models/rep'
config = require 'config'

module.exports = class Graphs extends Collection
	model: Rep
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
