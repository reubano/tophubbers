Model = require 'models/base/model'

module.exports = class Form extends Model
	defaults:
		created: new Date().toString()

	initialize: ->
		super
		console.log 'initialize form model'
