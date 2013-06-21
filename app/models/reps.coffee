Collection = require 'models/base/collection'
Model = require 'models/rep'

module.exports = class Reps extends Collection
	model: Model
	localStorage: new Store 'reps'

	initialize: (options) =>
		super
		console.log 'initialize reps collection'

	getCalled: ->
		@where called: yes

	getActive: ->
		@where called: no
