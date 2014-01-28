View = require 'views/base/view'
template = require 'views/templates/visit'

module.exports = class VisitView extends View
  template: template
  tagName: 'tr'

  initialize: ->
    super
    @listenTo @model, 'change', @render
    @model.fetchData @refresh

  render: =>
    super
    # utils.log 'rendering visit view'
