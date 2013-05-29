Chaplin = require 'chaplin'
Model = require 'models/base/model'

module.exports = class Collection extends Chaplin.Collection
  _.extend @prototype, Chaplin.SyncMachine

  model: Model

  initialize: (models, options) ->
    console.log 'initialize base collection'
    @url = options.url if options?.url?
    super

