Model = require 'models/base/model'
utils = require 'lib/utils'

module.exports = class Form extends Model
  defaults:
    created: new Date().toString()
    updated_at: new Date().toString()

  initialize: ->
    super
    # utils.log 'initialize form model'