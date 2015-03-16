config = require 'config'
mediator = require 'mediator'

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

# Other helpers
# -----------

# Loop n times
Handlebars.registerHelper 'times', (n, block) ->
  accum = ''
  i = 0
  x = Math.round n

  while i < x
    accum += block.fn(i)
    i++

  accum

# Loop 5 - n times
Handlebars.registerHelper 'untimes', (n, block) ->
  accum = ''
  i = 0
  x = 5 - Math.round(n)

  while i < x
    accum += block.fn(i)
    i++

  accum
