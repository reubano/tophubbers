Collection = require 'models/base/collection'
Graph = require 'models/graph'
config = require 'config'

module.exports = class Graphs extends Collection
  model: Graph
  localStorage: new Store 'graphs-chaplin'
  url: 'info/'

  comparator: (model) ->
    model.get('id')
