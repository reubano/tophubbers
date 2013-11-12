Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
View = require 'views/login-view'
Provider = require 'lib/services/google'
utils = require 'lib/utils'

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
    @subscribeEvent '!showLogin', @showLoginView
    @subscribeEvent '!login', @triggerLogin
    @subscribeEvent '!logout', @triggerLogout

    utils.log 'initialize SessionController'

    if @user and @user.get 'accessToken'
      utils.log 'user found in SessionController'
      name = @user.get 'name'
      utils.log 'welcome back ' + name + '!'
      utils.log @user, false
      @user.setAccess()
      @publishLogin()
    else
      utils.log 'no user in SessionController'

      # login unless params.login is false
      @getSession() if not params?.login? or not params.login

  # Load the libraries of all service providers
  loadServiceProviders: ->
    utils.log 'session-controller loadServiceProviders'
    for name, serviceProvider of SessionController.serviceProviders
      serviceProvider.load()

  # Try to get an existing session from one of the login providers
  getSession: ->
    utils.log 'session-controller getSession'
    @loadServiceProviders()
    for name, serviceProvider of SessionController.serviceProviders
      utils.log 'getting session'
      serviceProvider.done serviceProvider.getLoginStatus
      utils.log 'done getting session'

  # Handler for the global !showLogin event
  showLoginView: =>
    utils.log 'session-controller showLoginView'
    return if @loginView
    @publishEvent 'loggingIn', true
    @loadServiceProviders()
    @loginView = new View()
    timeout = setTimeout(
      => @publishEvent('loginFail')
      60000)
    @subscribeEvent 'loginStatus', =>
      clearTimeout timeout
      @unsubscribeEvent 'loginStatus', -> null

  # Handler for the global !login event
  # Delegate the login to the selected service provider
  triggerLogin: (serviceProviderName) =>
    utils.log 'session-controller heard !login event'
    utils.log 'session-controller triggerLogin'
    serviceProvider = SessionController.serviceProviders[serviceProviderName]

    # Publish an event in case the provider library could not be loaded
    unless serviceProvider.isLoaded()
      utils.log 'serviceProviderMissing'
      return

    @publishEvent 'loginAttempt', serviceProviderName

    # Delegate to service provider
    serviceProvider.triggerLogin()

  # Handler for the global serviceProviderSession event
  serviceProviderSession: (session) =>
    utils.log 'session-controller serviceProviderSession'
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
    utils.log 'session-controller publishLogin', 'info'
    @loginStatusDetermined = true
    @publishEvent 'login', @user
    @publishEvent 'loginStatus', true
    @publishEvent 'loggingIn', false

  setLoggingIn: (value) =>
    mediator.loggingIn = value

  processFail: (params) =>
    name = params?.provider?.name or 'provider'
    utils.log name + ' login failed'
    mediator.loginFailed = true
    @publishEvent 'loginStatus', false

  # Logout
  # ------

  # Handler for the global !logout event
  triggerLogout: =>
    utils.log 'session-controller heard !logout event'
    @publishEvent 'logout'

  # Handler for the global logout event
  logout: =>
    utils.log 'session-controller heard logout event'
    utils.log 'session-controller logging out'
    @loginStatusDetermined = true
    @disposeUser()
    @serviceProviderName = null
    @publishEvent 'loginStatus', false

  saveUser: =>
    utils.log 'saving collection'
    @collection.get(1).save {patch: true}
    @user = @collection.get(1)

  # Update the user with the given data and handles the global userData event
  updateUser: (userData) =>
    utils.log 'session-controller updateUser'
    @collection.set userData
    @saveUser()
    mediator.user = @user
    @user.setAccess()
    @publishEvent 'userUpdated', @user
    utils.log @collection
    utils.log @user.getAttributes()

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
