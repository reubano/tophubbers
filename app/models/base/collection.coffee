Model = require 'models/base/model'
utils = require 'lib/utils'

module.exports = class Collection extends Chaplin.Collection
  model: Model

  # _.extend @prototype, Chaplin.SyncMachine

  display: =>
    utils.log @, false
#     utils.log @at(1).getAttributes(), false

  # DualStorage Fetch promise helper
  # --------------------------------
  cltnFetch: =>
    $.Deferred((deferred) => @fetch
      success: deferred.resolve
      error: deferred.reject).promise()

