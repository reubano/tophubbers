config = require 'config'
Chaplin = require 'chaplin'

module.exports = class Model extends Chaplin.Model
  _.extend @prototype, Chaplin.SyncMachine

  apiRoot: config.api

  urlPath: ->
    ''

  url: ->
    if @urlPath()
      console.log 'model url'
      console.log @urlPath()
      @apiRoot + @urlPath()
    else if @collection
      console.log 'collection url'
      console.log @collection.url()
      @collection.url()
    else
      throw new Error('Model must redefine urlPath')

  fetch: (options = {}) ->
    console.log 'syncing...'
    @beginSync()
    previous = options.success
    options.success = (args...) =>
      previous? args...
      @finishSync()
    super
