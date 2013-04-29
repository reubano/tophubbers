Collection = require 'models/base/collection'
Graph = require 'models/graph'

module.exports = class Graphs extends Collection
  model: Graph
  localStorage: new Store 'todos-chaplin'

  allAreCompleted: ->
    @getCompleted().length is @length

  getCompleted: ->
    @where completed: yes

  getActive: ->
    @where completed: no

  comparator: (todo) ->
    todo.get('created')
