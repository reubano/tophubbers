View = require 'views/base/view'
template = require './templates/home'

module.exports = class HomePageView extends View
  autoRender: yes
  template: template
  region: 'content'
  className: 'container-fluid'

  initialize: ->
    @subscribeEvent 'loginStatus', @render
    @subscribeEvent 'dispatcher:dispatch', @render
