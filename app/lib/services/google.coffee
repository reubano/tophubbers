utils = require 'lib/utils'
ServiceProvider = require 'lib/services/service-provider'

module.exports = class Google extends ServiceProvider
  # Client-Side OAuth 2.0 login with Google
  # https://code.google.com/p/google-api-javascript-client/
  # https://code.google.com/p/google-api-javascript-client/wiki/Authentication

  # Note: This is the ID for an example Google API project.
  # You might change this to your own project ID.
  # See https://code.google.com/apis/console/
  clientId = '486945395268'
  apiKey = 'AIzaSyC-8OmYrW23uSmi7ok8_e5hkW_TEKNto5s'

  # The permissions we’re asking for. This is a space-separated list of URLs.
  # See https://developers.google.com/accounts/docs/OAuth2Login#scopeparameter
  # or https://developers.google.com/+/api/oauth
  # and the individual Google API documentations
  scopes = 'https://www.googleapis.com/auth/plus.me'

  name: 'google'

  load: ->
    console.log 'load'
    return if @state() is 'resolved' or @loading
    @loading = true

    # Register load handler
    window.googleClientLoaded = @loadHandler

    # No success callback, there's googleClientLoaded
    utils.loadLib 'https://apis.google.com/js/client.js?onload=googleClientLoaded', null, @reject

  loadHandler: =>
    console.log 'loadHandler'
    gapi.client.setApiKey @apiKey
    # Remove the global load handler
    try
      # IE 8 throws an exception
      delete window.googleClientLoaded
    catch error
      window.googleClientLoaded = undefined

    # Initialize
    gapi.auth.init @resolve

  isLoaded: ->
    console.log 'isLoaded'
    Boolean window.gapi and gapi.auth and gapi.auth.authorize

  triggerLogin: =>
    console.log 'triggerLogin'
    gapi.auth.authorize
      client_id: clientId, scope: scopes, immediate: false
      @loginHandler

  loginHandler: (authResponse) =>
    console.log 'loginHandler'
    console.log authResponse
    if authResponse
      console.log 'loginSuccessful'
      # Publish successful login
      @publishEvent 'loginSuccessful', {provider: this, authResponse}

      # Publish the session
      @publishEvent 'serviceProviderSession',
        provider: this
        accessToken: authResponse.access_token

      @getUserData @processUserData

    else
      console.log 'loginFail'
      @publishEvent 'loginFail', {provider: this, authResponse}

  getLoginStatus: =>
    console.log 'getLoginStatus'
    gapi.auth.authorize
      client_id: clientId, scope: scopes, immediate: true
      @loginHandler

  getUserData: (callback) ->
    console.log 'getUserInfo'
    gapi.client.load 'plus', 'v1', ->
      request = gapi.client.plus.people.get {'userId': 'me'}
      request.execute callback

  processUserData: (response) =>
    console.log 'processUserData'
    @publishEvent 'userData',
      imageUrl: response.image.url
      name: response.displayName
      id: response.id
