config = require 'config'
SiteView = require 'views/site-view'
FooterView = require 'views/footer-view'
NavbarView = require 'views/navbar-view'
mediator = require 'mediator'
utils = require 'lib/utils'

module.exports = class Controller extends Chaplin.Controller
  collection: mediator.reps

  beforeAction: (params, route) =>
    @reuse 'site', SiteView
    @reuse 'site-footer', FooterView
    @reuse 'navbar', =>
      @view = new NavbarView model: mediator.navbar
