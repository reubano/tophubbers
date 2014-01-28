Collection = require 'models/base/collection'
Model = require 'models/rep'
config = require 'config'
utils = require 'lib/utils'

module.exports = class Reps extends Collection
  model: Model
  local: => localStorage.getItem @url
  url: config.reps_url
  sync: (method, collection, options) =>
    utils.log "collection's sync method is #{method}"
    utils.log "sync collection locally: #{@local}"
    Backbone.sync(method, collection, options)

  initialize: (options) =>
    super
    utils.log 'initialize reps collection'

  parseBeforeLocalSave: (response) ->
    utils.log 'parsing reps response for localStorage'
    response.items
