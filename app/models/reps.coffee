Collection = require 'models/base/collection'
Rep = require 'models/rep'
config = require 'config'

module.exports = class Graphs extends Collection
	model: Rep
	localStorage: new Store 'reps-chaplin'

	comparator: (model) ->
		model.get('id')

	initialize: ->
		super
		console.log 'initialize reps collection'
