Model = require 'models/base/model'
utils = require 'lib/utils'

module.exports = class User extends Model
	admins = ['reubano@gmail.com', 'patrick.fischer@ongeza.com',
		'mustafa.pirbhai@ongeza.com', 'reuben.cummings@ongeza.com']

	managers = ['deogratius.haule@ongeza.com', 'wesley.muyenze@ongeza.com',
		'jackson.urio@ongeza.com']

	support = ['hilda.okoth@ongeza.com']
	sales = ['sales@ongeza.com']

	initialize: ->
		super
		utils.log 'initialize user model'

	setAccess: =>
		email = @get 'email'
		return unless email?
		utils.log 'setting user access'

		if email in admins
			@set role: 'admin'  # No restrictions
		else if email in managers
			@set role: 'manager'  # Access to all views (no data download)
		else if email in sales
			@set role: 'sales'  # Access to rep-view only (no forms)
		else if email in support
			@set role: 'support'  # Access to rep-view only (no forms)
		else @set role: 'guest'  # Access to home-view only

		utils.log 'user role: ' + @get 'role'
