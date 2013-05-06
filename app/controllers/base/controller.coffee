Chaplin = require 'chaplin'
SiteView = require 'views/site-view'
HeaderView = require 'views/header-view'
TopView = require 'views/top-view'
GraphsView = require 'views/graphs-view'
Graphs = require 'models/graphs'

module.exports = class Controller extends Chaplin.Controller
	beforeAction: (params, route) ->
		@collection = new Graphs [{title: 'E0009'}, {title: 'E0015'}, {title: 'E0019'}]

		@compose 'site', SiteView
		@compose 'header', HeaderView
		@compose 'top', =>
			@view = new TopView {@collection}

		@compose 'graphs', =>
			@view = new GraphsView {@collection}
