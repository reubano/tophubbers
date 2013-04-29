Model = require 'models/base/model'

module.exports = class Graph extends Model
  defaults:
    title: ''

  initialize: ->
    super
