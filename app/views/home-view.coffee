View = require 'views/base/view'
template = require 'views/templates/home'

module.exports = class HomePageView extends View
  autoRender: true
  template: template
  region: 'content'
  className: 'span12'

  initialize: ->
    @subscribeEvent 'loginStatus', @render
    @subscribeEvent 'dispatcher:dispatch', @render
