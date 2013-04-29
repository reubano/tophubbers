View = require 'views/base/view'
template = require 'views/templates/tdheader'

module.exports = class HeaderView extends View
  autoRender: yes
  el: '#tdheader'
  template: template

  initialize: ->
    super
    @delegate 'keypress', '#new-graph', @createOnEnter

   createOnEnter: (event) =>
     ENTER_KEY = 13
     title = $(event.currentTarget).val().trim()
     return if event.keyCode isnt ENTER_KEY or not title
     @collection.create {title}
     @$('#new-graph').val ''
