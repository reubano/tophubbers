Collection = require 'models/base/collection'
Model = require 'models/rep'
config = require 'config'
utils = require 'lib/utils'

module.exports = class Reps extends Collection
  query = "followers:%3E5000&access_token=#{config.api_token}"

  model: Model
  url: "https://api.github.com/search/users?q=#{query}"
  local: @isSynced
  sync: (method, model, options) ->
    utils.log "sync method is #{method}"
    if method isnt 'read'
      return utils.log "not syncing collection on #{method}"
    else
      utils.log "syncing collection"
      Backbone.sync 'read', model, options

  initialize: (options) =>
    super
    utils.log 'initialize reps collection'

  parseBeforeLocalSave: (response) ->
    utils.log 'parsing reps response for localStorage'
    response.items
