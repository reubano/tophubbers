View = require 'views/base/view'
template = require 'views/templates/progress'
config = require 'config'
utils = require 'lib/utils'

module.exports = class ProgressView extends View
  template: template
  tagName: 'li'

  initialize: (options) =>
    super
    utils.log 'initialize progress-view'
    @listenTo @model, 'change', @render
    @model.fetchData options.refresh, 'progress'

  render: =>
    super
    utils.log 'rendering progress view'
