View = require 'views/base/view'
template = require 'views/templates/home'
utils = require 'lib/utils'
mediator = require 'mediator'

module.exports = class HomePageView extends View
  autoRender: true
  template: template
  region: 'content'
  className: 'span12'
  reps: mediator.reps

  initialize: (options) =>
    super
    # @subscribeEvent 'dispatcher:dispatch', @render

