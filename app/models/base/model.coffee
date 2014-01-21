Chaplin = require 'chaplin'
utils = require 'lib/utils'

module.exports = class Model extends Chaplin.Model
  # _.extend @prototype, Chaplin.SyncMachine

  saveTstamp: (attr) =>
    tstamp = "#{attr}_tstamp"
    utils.log "saving #{@get 'login'}'s #{tstamp}"
    date = new Date().toString()
    @set tstamp, date

