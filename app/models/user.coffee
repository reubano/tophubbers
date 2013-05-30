Model = require 'models/base/model'

module.exports = class User extends Model
  defaults:
    name: ''
    id: ''
    imageUrl: ''

  initialize: ->
    super
