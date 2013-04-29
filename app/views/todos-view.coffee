CollectionView = require 'views/base/collection-view'
template = require 'views/templates/todos'
GraphView = require 'views/todo-view'

module.exports = class GraphsView extends CollectionView
  el: '#graph-container'
  itemView: GraphView
  listSelector: '#graph-list'
  template: template

  initialize: ->
    super
    @subscribeEvent 'graphs:clear', @clear
    @modelBind 'all', @renderCheckbox

  render: =>
    super
    @renderCheckbox()

  renderCheckbox: =>
    @$('#toggle-all').prop 'checked', @collection.allAreCompleted()
    @$el.toggle(@collection.length isnt 0)

  clear: ->
    @collection.getCompleted().forEach (model) ->
      model.destroy()
