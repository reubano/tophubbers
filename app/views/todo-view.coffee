View = require 'views/base/view'
template = require 'views/templates/todo'

module.exports = class GraphView extends View
  template: template
  tagName: 'li'

  initialize: ->
    super
    @modelBind 'change', @render
    @delegate 'click', '.icon-remove-sign', @destroy
    @delegate 'dblclick', 'label', @edit
    @delegate 'keypress', '.edit', @save
    @delegate 'blur', '.edit', @save

  render: =>
    super

  destroy: =>
    @model.destroy()

  edit: =>
    @$el.addClass 'editing'
    @$('.edit').focus()

  save: (event) =>
    ENTER_KEY = 13
    title = $(event.currentTarget).val().trim()
    return @model.destroy() unless title
    return if event.type is 'keypress' and event.keyCode isnt ENTER_KEY
    @model.save {title}
    @$el.removeClass 'editing'
