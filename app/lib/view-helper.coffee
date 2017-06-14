config = require 'config'
mediator = require 'mediator'

# Application-specific view helpers
# http://handlebarsjs.com/#helpers
# --------------------------------

register = (name, fn) -> Handlebars.registerHelper name, fn

# Partials
# ----------------------
register 'partial', (name, context) ->
  template = require "views/templates/partials/#{name}"
  new Handlebars.SafeString template context

# Map helpers
# -----------

# Make 'with' behave a little more mustachey.
register 'with', (context, options) ->
  if not context or Handlebars.Utils.isEmpty context
    options.inverse(this)
  else
    options.fn(context)

# Inverse for 'with'.
register 'without', (context, options) ->
  inverse = options.inverse
  options.inverse = options.fn
  options.fn = inverse
  Handlebars.helpers.with.call(this, context, options)

# Get Chaplin-declared named routes. {{#url "like" "105"}}{{/url}}
register 'url', (routeName, params..., options) ->
  Chaplin.helpers.reverse routeName, params

# Evaluate block with context being config
register 'with_config', (options) ->
  context = config
  Handlebars.helpers.with.call(this, context, options)

# Conditional evaluation
# ----------------------
register 'if_active_page', (id, options) ->
  console.log "active id: #{id}"
  console.log "mediator.active: #{mediator.active}"
  if id is mediator.active
    options.fn(this)
  else
    options.inverse(this)

# Other helpers
# -----------

# Loop n times
register 'times', (n, block) ->
  accum = ''
  i = 0
  x = Math.round n

  while i < x
    accum += block.fn(i)
    i++

  accum

# Loop 5 - n times
register 'untimes', (n, block) ->
  accum = ''
  i = 0
  x = 5 - Math.round(n)

  while i < x
    accum += block.fn(i)
    i++

  accum
