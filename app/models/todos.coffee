Collection = require 'models/base/collection'
Graph = require 'models/graph'

module.exports = class Graphs extends Collection
  localStorage: new Store 'todos-chaplin'
  model: Graph

  allAreCompleted: ->
    @getCompleted().length is @length

  getCompleted: ->
    @where completed: yes

  getActive: ->
    @where completed: no

  comparator: (todo) ->
    todo.get('created')
