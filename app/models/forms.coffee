Collection = require 'models/base/collection'
Model = require 'models/form'

module.exports = class Forms extends Collection
	model: Model
	localStorage: new Store 'forms-collection'

	initialize: ->
		super
		console.log 'initialize forms collection'

	comparator: (model) ->
		model.get('date')
