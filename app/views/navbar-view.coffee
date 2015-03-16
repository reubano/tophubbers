View = require 'views/base/view'
template = require 'views/templates/navbar'
mediator = require 'mediator'

module.exports = class NavbarView extends View
  autoRender: true
  className: 'navbar-inner'
  region: 'navbar'
  template: template

  initialize: (options) =>
    super
    # utils.log 'navbar-view init'
    # @subscribeEvent 'dispatcher:dispatch', @render
