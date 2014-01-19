Chaplin = require 'chaplin'
config = require 'config'
utils = require 'lib/utils'
mediator = Chaplin.mediator

today = moment()
month = today.month()
year = today.year()
currStart = moment([year, month, 1])
currEnd = moment(currStart).endOf('month')
prevStart = moment(currStart).subtract('months', 1)
prevEnd = moment(prevStart).endOf('month')

isBetween = (date, start, ended) ->
  (date.isBefore(ended) && date.isAfter(start)) or
  date.isSame(start) or
  date.isSame(ended)

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

# Evaluate block with context being forms
Handlebars.registerHelper 'with_forms', (options) ->
  context = mediator.forms or {}
  Handlebars.helpers.with.call(this, context, options)

# Evaluate block with context being download
Handlebars.registerHelper 'with_download', (options) ->
  context = mediator.download or {}
  Handlebars.helpers.with.call(this, context, options)

# Conditional evaluation
# ----------------------
Handlebars.registerHelper 'if_cur_month', (date, options) ->
  fmt = if date and date[2..2] is '-' then 'MM-DD-YYYY' else 'YYYY-MM-DD'
  momented = moment date, fmt
  between = isBetween(momented, currStart, currEnd)
  if between then options.fn(this) else options.inverse(this)

Handlebars.registerHelper 'if_prev_month', (date, options) ->
  fmt = if date and date[2..2] is '-' then 'MM-DD-YYYY' else 'YYYY-MM-DD'
  momented = moment date, fmt
  between = isBetween(momented, prevStart, prevEnd)
  if between then options.fn(this) else options.inverse(this)

Handlebars.registerHelper 'if_cur_rep', (id, options) ->
  if id == mediator.rep_id then options.fn(this) else options.inverse(this)

# Other helpers
# -----------

# Convert date to day
Handlebars.registerHelper 'get_day', (date) ->
  day = if date[-2..-2] is '0' then date[-1..] else date[-2..]
  new Handlebars.SafeString day

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
