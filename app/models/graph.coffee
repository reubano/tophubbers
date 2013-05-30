Model = require 'models/base/model'

module.exports = class Graph extends Model
  defaults:
    id: ''
    first_name: ''
    last_name: ''
    ward: ''
    airtel: ''
    google_id: ''
    age: (new Date).getTime() / 3600000

  initialize: ->
    super
