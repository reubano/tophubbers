config = require 'config'
Collection = require 'models/base/collection'
Model = require 'models/form'

module.exports = class Forms extends Collection
	model: Model
	url: config.forms

	initialize: =>
		super
		console.log 'initialize forms collection'
		console.log 'forms collection url is ' + @url

	parseBeforeLocalSave: (response) ->
		console.log 'parsing response for localStorage'
		response.objects

	comparator: (model) ->
		model.get('date')
