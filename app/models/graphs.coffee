Collection = require 'models/base/collection'
Graph = require 'models/graph'
config = require 'config'

module.exports = class Graphs extends Collection
	model: Graph
	localStorage: new Store 'graphs-chaplin'
	url: config.api + 'info'

	comparator: (model) ->
		model.get('id')

	parse: (response) =>
		console.log 'parse response'
		response.data

	initialize: ->
		super
