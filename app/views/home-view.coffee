View = require 'views/base/view'
template = require 'views/templates/home'
Chaplin = require 'chaplin'
utils = require 'lib/utils'

module.exports = class HomePageView extends View
  mediator = Chaplin.mediator

  autoRender: true
  template: template
  region: 'content'
  className: 'span12'
  reps: mediator.reps

  initialize: (options) =>
    super
    # @subscribeEvent 'dispatcher:dispatch', @render

