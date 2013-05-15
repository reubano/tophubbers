Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
User = require 'models/user'
LoginView = require 'views/login-view'
Facebook = require 'lib/services/facebook'

module.exports = class SessionController extends Controller
  mediator = Chaplin.mediator

  # Service provider instances as static properties
  # This just hardcoded here to avoid async loading of service providers.
  # In the end you might want to do this.
  @serviceProviders = facebook: new Facebook()

  # Was the login status already determined?
  loginStatusDetermined: false
  loginView: null
  serviceProviderName: null

  initialize: ->
    @subscribeEvent 'serviceProviderSession', @serviceProviderSession
    @subscribeEvent 'logout', @logout
    @subscribeEvent 'userData', @userData
    @subscribeEvent '!showLogin', @showLoginView
    @subscribeEvent '!login', @triggerLogin
    @subscribeEvent '!logout', @triggerLogout

    # Determine the logged-in state
    @getSession()

  # Load the libraries of all service providers
  loadServiceProviders: ->
    for name, serviceProvider of SessionController.serviceProviders
      serviceProvider.load()

  # Instantiate the user with the given data
  createUser: (userData) ->
    mediator.user = new User userData

  # Try to get an existing session from one of the login providers
  getSession: ->
    @loadServiceProviders()
    for name, serviceProvider of SessionController.serviceProviders
      serviceProvider.done serviceProvider.getLoginStatus

  # Handler for the global !showLogin event
  showLoginView: ->
    return if @loginView
    @loadServiceProviders()
    @loginView = new LoginView
      serviceProviders: SessionController.serviceProviders

  # Handler for the global !login event
  # Delegate the login to the selected service provider
  triggerLogin: (serviceProviderName) =>
    serviceProvider = SessionController.serviceProviders[serviceProviderName]

    # Publish an event in case the provider library could not be loaded
    unless serviceProvider.isLoaded()
      @publishEvent 'serviceProviderMissing', serviceProviderName
      return

    @publishEvent 'loginAttempt', serviceProviderName

    # Delegate to service provider
    serviceProvider.triggerLogin()

  # Handler for the global serviceProviderSession event
  serviceProviderSession: (session) =>
    @serviceProviderName = session.provider.name
    @disposeLoginView()

    # Transform session into user attributes and create a user
    session.id = session.userId
    delete session.userId
    @createUser session
    @publishLogin()

  # Publish an event to notify all application components of the login
  publishLogin: ->
    @loginStatusDetermined = true
    @publishEvent 'login', mediator.user
    @publishEvent 'loginStatus', true

  # Logout
  # ------

  # Handler for the global !logout event
  triggerLogout: ->
    @publishEvent 'logout'

  # Handler for the global logout event
  logout: =>
    @loginStatusDetermined = true
    @disposeUser()
    @serviceProviderName = null
    @showLoginView()
    @publishEvent 'loginStatus', false

  # Handler for the global userData event
  # -------------------------------------
  userData: (data) ->
    mediator.user.set data

  # Disposal
  # --------
  disposeLoginView: ->
    return unless @loginView
    @loginView.dispose()
    @loginView = null

  disposeUser: ->
    return unless mediator.user
    mediator.user.dispose()
    mediator.user = null
