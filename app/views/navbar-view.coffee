View = require 'views/base/view'
template = require 'views/templates/navbar'
mediator = require 'mediator'
utils = require 'lib/utils'

module.exports = class NavbarView extends View
  autoRender: true
  className: 'container'
  region: 'navbar'
  template: template

  initialize: (options) ->
    super
    utils.log 'initializing navbar view', 'info'
    @delegate 'click', @collapseNav
    @subscribeEvent 'activePage', (page) =>
      @activatePage page

  collapseNav: (e) ->
    if e.target.href? and e.currentTarget.parentElement.id is 'navbar'
      $('.navbar-collapse').collapse('hide')

  activatePage: (page) =>
    @$('nav li.active').removeClass('active')
    @$("#nav-#{page.id}").addClass('active')
