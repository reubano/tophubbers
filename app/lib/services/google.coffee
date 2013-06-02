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
  scopes = 'https://www.googleapis.com/auth/plus.me'

  name: 'google'

  constructor: ->
    super
    console.log 'google constructor'
    @accessToken = localStorage.getItem 'accessToken'

  load: ->
    console.log 'google load'
    return if @state() is 'resolved' or @loading
    @loading = true

    # Register load handler
    window.googleClientLoaded = @loadHandler

    # No success callback, there's googleClientLoaded
    utils.loadLib 'https://apis.google.com/js/client.js?onload=googleClientLoaded', null, @reject

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
    gapi.auth.init @resolve

  isLoaded: ->
    console.log 'google isLoaded'
    Boolean window.gapi and gapi.auth and gapi.auth.authorize

  triggerLogin: =>
    console.log 'google triggerLogin'
    @authorize @loginHandler false

  loginHandler: (authResponse) =>
    console.log 'google loginHandler'

    if authResponse and not authResponse.error
      console.log 'google loginSuccessful'
      @publishEvent 'loginSuccessful', {provider: this, authResponse}
      @publishEvent 'serviceProviderSession',
        provider: this
        accessToken: authResponse.access_token

      @getUserData @processUserData

    else
      console.log 'google loginFail'
      @publishEvent 'loginFail', {provider: this, authResponse}

  getUserData: (callback) ->
    console.log 'google getUserInfo'
    gapi.client.load 'plus', 'v1', ->
      request = gapi.client.plus.people.get {'userId': 'me'}
      request.execute callback

  processUserData: (response) =>
    console.log 'google processUserData'
    @publishEvent 'userData', response
      # name: response.displayName
      # id: response.id
      # imageUrl: response.image.url

  getLoginStatus: =>
    console.log 'google getLoginStatus'
    @authorize @loginHandler true

  authorize: (callback, immediate) ->
    gapi.auth.authorize
      client_id: clientId, scope: scopes, immediate: immediate
      callback

#     setTimeout ->
#       window.gapi.auth.authorize
#         client_id: clientId, scope: scopes, immediate: immediate
#         callback
