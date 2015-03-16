utils = require 'lib/utils'

module.exports = class Model extends Chaplin.Model
  # _.extend @prototype, Chaplin.SyncMachine

  display: =>
    utils.log @, false
    utils.log @getAttributes(), false

  saveTstamp: (attr) =>
    tstamp = "#{attr}_tstamp"
    utils.log "saving #{@get 'login'}'s #{tstamp}"
    @set tstamp, new Date().toString()
    @save patch: true

  # DualStorage Fetch promise helper
  # --------------------------------
  modelFetch: =>
    $.Deferred((deferred) => @fetch
      success: deferred.resolve
      error: deferred.reject).promise()

