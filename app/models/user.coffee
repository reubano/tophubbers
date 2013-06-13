Model = require 'models/base/model'

module.exports = class User extends Model
	initialize: ->
		super
		console.log 'initialize user model'
