Collection = require 'models/base/collection'
Model = require 'models/rep'
config = require 'config'
utils = require 'lib/utils'

module.exports = class Reps extends Collection
  query = "followers:%3E5000&access_token=#{config.api_token}"

  model: Model
  url: "https://api.github.com/search/users?q=#{query}"
  local: => localStorage.getItem @url
  sync: (method, model, options) =>
    utils.log "collection's sync method is #{method}"
    utils.log "sync collection locally: #{@local}"
    Backbone.sync(method, model, options)

  initialize: (options) =>
    super
    utils.log 'initialize reps collection'
    utils.log "local: #{@local}"

  parseBeforeLocalSave: (response) ->
    utils.log 'parsing reps response for localStorage'
    response.items
