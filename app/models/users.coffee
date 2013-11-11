Collection = require 'models/base/collection'
Model = require 'models/user'
utils = require 'lib/utils'

module.exports = class Users extends Collection
  model: Model
  url: 'users'
  local: true

  initialize: =>
    super
    utils.log 'initialize users collection'
