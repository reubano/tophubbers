Collection = require 'models/base/collection'
Model = require 'models/rep'
config = require 'config'
utils = require 'lib/utils'

module.exports = class Reps extends Collection
  model: Model
  url: config.reps_url
  storeName: 'Reps'
  local: -> localStorage.getItem 'synced'

  sync: (method, collection, options) =>
    utils.log "collection's sync method is #{method}"
    utils.log "read collection from server: #{not @local()}"
    Backbone.sync(method, collection, options)

  initialize: (options) =>
    super
    utils.log 'initialize reps collection'

  parseBeforeLocalSave: (response) ->
    utils.log 'parsing reps response for localStorage'
    response.items
