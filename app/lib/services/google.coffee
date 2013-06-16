Chaplin = require 'chaplin'
utils = require 'lib/utils'
ServiceProvider = require 'lib/services/service-provider'

module.exports = class Google extends ServiceProvider
  # Client-Side OAuth 2.0 login with Google
  # https://code.google.com/p/google-api-javascript-client/
  # https://code.google.com/p/google-api-javascript-client/source/browse/samples/authSample.html
  # https://developers.google.com/api-client-library/javascript/features/authentication

  # Note: This is the ID for an example Google API project.
  # You might change this to your own project ID.
  # See https://code.google.com/apis/console/
  clientId = '486945395268.apps.googleusercontent.com'
  apiKey = 'AIzaSyC-8OmYrW23uSmi7ok8_e5hkW_TEKNto5s'

  # The permissions we’re asking for. This is a space-separated list of URLs.
  # https://developers.google.com/accounts/docs/OAuth2Login#scopeparameter
  # https://developers.google.com/+/api/oauth
  # scopes = 'https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/userinfo.email'
  # scopes = 'https://www.googleapis.com/auth/plus.me'
  scopes = 'https://www.googleapis.com/auth/userinfo.email'

  name: 'google'
  failed: false

  constructor: ->
    super
    console.log 'google constructor'

  load: =>
    console.log 'google load'
    console.log 'state: ' + @state()
    console.log 'loading: ' + @loading
    return if @state() is 'resolved' or @loading
    @loading = true

    # Register load handler
    window.googleClientLoaded = @loadHandler

    # No success callback, there's googleClientLoaded
    utils.loadLib(
      'https://apis.google.com/js/client.js?onload=googleClientLoaded',
      null,
      @reject)

  loadHandler: =>
    console.log 'google loadHandler'
    gapi.client.setApiKey @apiKey
    # Remove the global load handler
    try
      # IE 8 throws an exception
      delete window.googleClientLoaded
    catch error
      window.googleClientLoaded = undefined

    # Initialize
    @authorize @loginHandler, true

  isLoaded: ->
    console.log 'google isLoaded'
    Boolean window.gapi and gapi.auth and gapi.auth.authorize

  triggerLogin: =>
    console.log 'google triggerLogin'
    @authorize @loginHandler, false

  loginHandler: (authResponse) =>
    console.log 'google loginHandler'
    console.log 'authResponse below'
    console.log authResponse

    if authResponse and not authResponse.error
      console.log 'google login successful!'
      @publishEvent 'loginSuccessful', {provider: this, authResponse}
      @publishSession authResponse, authResponse.access_token
      @getUserData @processUserData
    else if not @failed
      @failed = true
      console.log "couldn't auto login... triggering popup"
      @triggerLogin()
    else
      console.log 'google login failed'
      @publishEvent 'loginFail', {provider: this, authResponse}

  getUserData: (callback) ->
    console.log 'fetching google user data'
    # returns name and id (among other things)
    gapi.client.load 'plus', 'v1', ->
      request = gapi.client.plus.people.get {'userId': 'me'}
      request.execute callback

    # returns email and id
    gapi.client.load 'oauth2', 'v2', ->
      request = gapi.client.oauth2.userinfo.get()
      request.execute callback

  processUserData: (data) =>
    console.log 'google processUserData'
    console.log data
    userData = {}

    hash =
      name: 'displayName'
      email: 'email'
      gid: 'id'

    # used to merge the results of the api calls returned by getUserData
    (userData[key] = data[value] for key, value of hash when data[value])
    userData.id = 1
    @publishEvent 'userData', userData

  authorize: (callback, immediate) ->
    console.log 'google authorize'
    gapi.auth.authorize
      client_id: clientId, scope: scopes, immediate: immediate
      callback

  publishSession: (response, accessToken) =>
    if not response or status is 'error'
      @publishEvent 'logout'
    else
      @publishEvent 'serviceProviderSession',
        provider: this
        userId: response.id
        accessToken: accessToken
