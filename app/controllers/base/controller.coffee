config = require 'config'
Chaplin = require 'chaplin'
SiteView = require 'views/site-view'
NavbarView = require 'views/navbar-view'
utils = require 'lib/utils'

module.exports = class Controller extends Chaplin.Controller
  model: Chaplin.mediator.navbar
  collection: Chaplin.mediator.reps

  beforeAction: (params, route) =>
    @compose 'site', SiteView
    utils.log 'beforeAction'
    @compose 'navbar', => @view = new NavbarView {@model}
