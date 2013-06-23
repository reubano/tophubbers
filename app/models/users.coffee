Collection = require 'models/base/collection'
Model = require 'models/user'

module.exports = class Users extends Collection
	model: Model
	url: 'users'
	local: true

	initialize: =>
		super
		console.log 'initialize users collection'
