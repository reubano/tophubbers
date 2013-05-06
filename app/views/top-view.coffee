View = require 'views/base/view'
template = require 'views/templates/top'

module.exports = class FooterView extends View
  autoRender: yes
  className: 'top'
  region: 'top'
  id: 'top'
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
