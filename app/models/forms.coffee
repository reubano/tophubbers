config = require 'config'
Collection = require 'models/base/collection'
Model = require 'models/form'

module.exports = class Forms extends Collection
	model: Model
	# localStorage: new Store 'forms'
	url: config.forms

	initialize: =>
		super
		console.log 'initialize forms collection'
		console.log 'forms collection url is ' + @url

	parse: (response) ->
		console.log 'parsing response'
		response.objects

	comparator: (model) ->
		model.get('date')
