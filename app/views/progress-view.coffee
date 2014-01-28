View = require 'views/base/view'
template = require 'views/templates/progress'
config = require 'config'
utils = require 'lib/utils'

module.exports = class ProgressView extends View
  template: template
  tagName: 'li'

  initialize: (options) =>
    super
    @listenTo @model, 'change', @render
    @model.fetchData @refresh, 'progress'

  render: =>
    super
    utils.log 'rendering progress view'
