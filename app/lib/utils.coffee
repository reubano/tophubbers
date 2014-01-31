config = require 'config'
Chaplin = require 'chaplin'
mediator = Chaplin.mediator

# Application-specific utilities
# ------------------------------

utils = Chaplin.utils.beget Chaplin.utils # Delegate to Chaplin’s utils module

Minilog
  .enable()
  .pipe new Minilog.backends.jQuery {url: config.api_logs, interval: 5000}

minilog = Minilog 'tophubbers'

_(utils).extend
  # Persistent data storage
  # -----------------------
  # sessionStorage with session cookie fallback
  # sessionStorage(key) gets the value for 'key'
  # sessionStorage(key, value) set the value for 'key'
  sessionStorage: do ->
    if window.sessionStorage and sessionStorage.getItem and
    sessionStorage.setItem and sessionStorage.removeItem
      (key, value) ->
        if typeof value is 'undefined'
          value = sessionStorage.getItem(key)
          if value? and value.toString then value.toString() else value
        else
          sessionStorage.setItem(key, value)
          value
    else
      (key, value) ->
        if typeof value is 'undefined'
          utils.getCookie(key)
        else
          utils.setCookie(key, value)
          value

  # sessionStorageRemove(key) removes the storage entry for 'key'
  sessionStorageRemove: do ->
    if window.sessionStorage and sessionStorage.getItem and
    sessionStorage.setItem and sessionStorage.removeItem
      (key) -> sessionStorage.removeItem(key)
    else
      (key) -> utils.expireCookie(key)

  # Cookie fallback
  # ---------------
  # Get a cookie by its name
  getCookie: (key) ->
    pairs = document.cookie.split('; ')
    for pair in pairs
      val = pair.split('=')
      if decodeURIComponent(val[0]) is key
        return decodeURIComponent(val[1] or '')
    null

  # Set a session cookie
  setCookie: (key, value, options = {}) ->
    payload = "#{encodeURIComponent(key)}=#{encodeURIComponent(value)}"
    getOption = (name) ->
      if options[name] then "; #{name}=#{options[name]}" else ''

    expires = if options.expires
      "; expires=#{options.expires.toUTCString()}"
    else
      ''

    document.cookie = [
      payload, expires,
      (getOption 'path'), (getOption 'domain'), (getOption 'secure')
    ].join('')

  expireCookie: (key) ->
    document.cookie = "#{key}=nil; expires=#{(new Date).toGMTString()}"

  # Logging helper
  # ---------------------
  log: (message, level='debug') ->
    if level
      text = JSON.stringify message
      message = if text.length > 512 then "size exceeded" else message

      data =
        message: message
        time: (new Date()).getTime()
        user: if mediator.user? then mediator.user.get 'email' else null

      minilog[level] data
    else console.log message
module.exports = utils
