Collection = require 'models/base/collection'
Model = require 'models/user'

module.exports = class Users extends Collection
	model: Model
	localStorage: new Store 'user'

	initialize: ->
		super
		console.log 'initialize users collection'
