Collection = require 'models/base/collection'
Model = require 'models/form'
config = require 'config'
utils = require 'lib/utils'

module.exports = class Forms extends Collection
  model: Model
  url: config.api_forms

  initialize: =>
    super
    utils.log 'initialize forms collection'
    utils.log 'forms collection url is ' + @url

  parseBeforeLocalSave: (response) ->
    utils.log 'parsing forms response for localStorage'
    response.objects

  comparator: (model) -> model.get 'date'
