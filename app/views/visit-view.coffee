View = require 'views/base/view'
template = require 'views/templates/visit'
utils = require 'lib/utils'

module.exports = class VisitView extends View
  template: template
  tagName: 'tr'

  initialize: (options) =>
    super
    @listenTo @model, 'change', @render
    @model.fetchData options.refresh

  render: =>
    super
    utils.log 'rendering visit view'
