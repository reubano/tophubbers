RepsController = require 'controllers/reps-controller'
GraphsView = require 'views/graphs-view'

module.exports = class Controller extends RepsController
	adjustTitle: 'Graph list'

	initialize: =>
		super

	index: (params) =>
		console.log 'rendering graphs view'
		@view = new GraphsView {@collection}
