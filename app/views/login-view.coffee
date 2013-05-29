utils = require 'lib/utils'
View = require 'views/base/view'
template = require 'views/templates/login'

module.exports = class NavbarView extends View
  autoRender: true
  region: 'content'
  className: 'login'
  template: template

  initialize: (options) ->
    super
    @subscribeEvent 'loginStatus', @render
    @subscribeEvent 'dispatcher:dispatch', @render
