config = require 'config'
Chaplin = require 'chaplin'

module.exports = class Model extends Chaplin.Model
  _.extend @prototype, Chaplin.SyncMachine

  apiRoot: config.api

  urlPath: ->
    ''

  url: ->
    urlPath = @urlPath()
    if urlPath
      @apiRoot + urlPath
    else if @collection
      @collection.url()
    else
      throw new Error('Model must redefine urlPath')

  fetch: (options = {}) ->
    @beginSync()
    previous = options.success
    options.success = (args...) =>
      previous? args...
      @finishSync()
    super
