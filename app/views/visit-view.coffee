View = require 'views/base/view'
template = require 'views/templates/visit'

module.exports = class VisitView extends View
  template: template
  tagName: 'li'

  initialize: ->
    super
    @listenTo @model, 'change', @render

  render: =>
    super
    # utils.log 'rendering visit view'
