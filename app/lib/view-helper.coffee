Chaplin = require 'chaplin'
config = require 'config'
utils = require 'lib/utils'
mediator = Chaplin.mediator

# Application-specific view helpers
# http://handlebarsjs.com/#helpers
# --------------------------------

# Map helpers
# -----------

# Make 'with' behave a little more mustachey.
Handlebars.registerHelper 'with', (context, options) ->
  if not context or Handlebars.Utils.isEmpty context
    options.inverse(this)
  else
    options.fn(context)

# Inverse for 'with'.
Handlebars.registerHelper 'without', (context, options) ->
  inverse = options.inverse
  options.inverse = options.fn
  options.fn = inverse
  Handlebars.helpers.with.call(this, context, options)

# Get Chaplin-declared named routes. {{#url "like" "105"}}{{/url}}
Handlebars.registerHelper 'url', (routeName, params..., options) ->
  Chaplin.helpers.reverse routeName, params

# Evaluate block with context being config
Handlebars.registerHelper 'with_config', (options) ->
  context = config
  Handlebars.helpers.with.call(this, context, options)

# Evaluate block with context being current user
Handlebars.registerHelper 'with_user', (options) ->
  context = mediator.user or {}
  Handlebars.helpers.with.call(this, context, options)

# Conditional evaluation
# ----------------------

# Choose block by user login status
Handlebars.registerHelper 'if_logged_in', (options) ->
  if mediator.user
    options.fn(this)
  else
    options.inverse(this)

Handlebars.registerHelper 'show_login_url', ->
  {protocol, host} = window.location
  path = Chaplin.helpers.reverse 'auth#callback'
  encodeURIComponent "#{protocol}//#{host}#{path}"

# URL helpers
# -----------

# Facebook image URLs
Handlebars.registerHelper 'fb_img_url', (fbId, type) ->
  new Handlebars.SafeString utils.facebookImageURL(fbId, type)
