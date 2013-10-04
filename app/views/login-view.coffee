View = require 'views/base/view'
template = require 'views/templates/login'

module.exports = class LoginView extends View
  autoRender: true
  region: 'content'
  className: 'span12'
  template: template

  initialize: (options) ->
    super
    @subscribeEvent 'dispatcher:dispatch', @render
    @subscribeEvent 'loginFail', @render
