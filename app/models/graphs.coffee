Collection = require 'models/base/collection'
Graph = require 'models/graph'

module.exports = class Graphs extends Collection
	model: Graph
	localStorage: new Store 'graphs-chaplin'

	comparator: (model) ->
		model.get('last_name')