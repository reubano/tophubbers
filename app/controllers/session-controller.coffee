Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
View = require 'views/login-view'
Provider = require 'lib/services/google'

module.exports = class SessionController extends Controller
	mediator = Chaplin.mediator
	mediator.user = mediator.users.get(1)

	collection: mediator.users
	user: mediator.user


	# Service provider instances as static properties
	# This just hardcoded here to avoid async loading of service providers.
	# In the end you might want to do this.
	@serviceProviders = google: new Provider()

	# Was the login status already determined?
	loginStatusDetermined: false
	View: null
	serviceProviderName: null

	initialize: (params) ->
		@subscribeEvent 'serviceProviderSession', @serviceProviderSession
		@subscribeEvent 'logout', @logout
		@subscribeEvent 'clearView', @disposeLoginView
		@subscribeEvent 'userData', @updateUser
		@subscribeEvent 'loggingIn', @setLoggingIn
		@subscribeEvent 'loginFail', @processFail
		@subscribeEvent 'serviceProviderMissing', @processFail
		@subscribeEvent '!showLogin', @showLoginView
		@subscribeEvent '!login', @triggerLogin
		@subscribeEvent '!logout', @triggerLogout

		console.log 'initialize SessionController'

		if @user and @user.get 'accessToken'
			console.log 'user found in SessionController'
			name = @user.get 'name'
			console.log 'welcome back ' + name + '!'
			console.log @user
			@user.setAccess()
			@publishLogin()
		else
			console.log 'no user in SessionController'

			# login unless params.login is false
			if not params?.login? or not params.login
				@getSession()

	# Load the libraries of all service providers
	loadServiceProviders: ->
		console.log 'session-controller loadServiceProviders'
		for name, serviceProvider of SessionController.serviceProviders
			serviceProvider.load()

	# Try to get an existing session from one of the login providers
	getSession: ->
		console.log 'session-controller getSession'
		@loadServiceProviders()
		for name, serviceProvider of SessionController.serviceProviders
			console.log 'getting session'
			serviceProvider.done serviceProvider.getLoginStatus
			console.log 'done getting session'

	# Handler for the global !showLogin event
	showLoginView: ->
		console.log 'session-controller showLoginView'
		return if @loginView
		@publishEvent 'loggingIn', true
		@loadServiceProviders()
		@loginView = new View()

	# Handler for the global !login event
	# Delegate the login to the selected service provider
	triggerLogin: (serviceProviderName) =>
		console.log 'session-controller triggerLogin'
		serviceProvider = SessionController.serviceProviders[serviceProviderName]

		# Publish an event in case the provider library could not be loaded
		unless serviceProvider.isLoaded()
			console.log 'serviceProviderMissing'
			@publishEvent 'serviceProviderMissing', serviceProviderName
			return

		@publishEvent 'loginAttempt', serviceProviderName

		# Delegate to service provider
		serviceProvider.triggerLogin()

	# Handler for the global serviceProviderSession event
	serviceProviderSession: (session) =>
		console.log 'session-controller serviceProviderSession'
		@serviceProviderName = session.provider.name
		@disposeLoginView()

		# Transform session into user attributes and updates a user
		session.id = session.userId
		delete session.userId
		@updateUser
			id: 1
			provider: session.provider.name
			accessToken: session.accessToken

		@publishLogin()

	# Publish an event to notify all application components of the login
	publishLogin: ->
		console.log 'session-controller publishLogin'
		@loginStatusDetermined = true
		@publishEvent 'login', @user
		@publishEvent 'loginStatus', true
		@publishEvent 'loggingIn', false

	setLoggingIn: (value) =>
		mediator.loggingIn = value

	processFail: (params) =>
		name = if params.provider then params.provider.name else 'provider'
		console.log name + ' login failed'
		mediator.loginFailed = true
		@publishEvent 'loggingIn', false

	# Logout
	# ------

	# Handler for the global !logout event
	triggerLogout: ->
		@publishEvent 'logout'

	# Handler for the global logout event
	logout: =>
		console.log 'session-controller logging out'
		@loginStatusDetermined = true
		@disposeUser()
		@serviceProviderName = null
		@publishEvent 'loginStatus', false

	saveUser: =>
		console.log 'saving collection'
		@collection.get(1).save {patch: true}
		@user = @collection.get(1)

	# Update the user with the given data and handles the global userData event
	updateUser: (userData) =>
		console.log 'session-controller updateUser'
		@collection.set userData
		@saveUser()
		mediator.user = @user
		@user.setAccess()
		@publishEvent 'userUpdated', @user
		console.log @collection
		console.log @user.getAttributes()

	# Disposal
	# --------
	disposeLoginView: ->
		return unless @loginView
		@loginView.dispose()
		@loginView = null

	disposeUser: ->
		return unless @user
		@user.destroy()
		mediator.user = null
