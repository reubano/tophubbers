Chaplin = require 'chaplin'
utils = require 'lib/utils'

module.exports = class Model extends Chaplin.Model
  # _.extend @prototype, Chaplin.SyncMachine

  saveTstamp: (attr) =>
    tstamp = "#{attr}_tstamp"
    utils.log "saving #{@get 'login'}'s #{tstamp}"
    @set tstamp, new Date().toString()
    @save patch: true

  # Promise helper
  # ---------------------
  promize: =>
#     file bug with dualstorage to return promise after local fetch
    if @fetch.promise
      utils.log "fetch has promise"
      @fetch()
    else
      utils.log "fetch doesn't have promise"
      $.Deferred((deferred) => @fetch
        success: deferred.resolve
        error: deferred.reject).promise()

