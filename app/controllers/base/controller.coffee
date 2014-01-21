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

  getData: (attrs) =>
    # add logic to fetch png if on mobile and 'work_data' is in url
    # post url to 'api/fetch' to fetch rep data serverside
#     if config.mobile and (/work_data/).test url
#       utils.log "fetching #{url} server side"
#       $.ajax
#         url: config.api_fetch
#         data: {url: url}
#         type: 'post'
#         dataType: 'json'
#         beforeSend: (res, settings) -> res.url = settings.url
#     else
