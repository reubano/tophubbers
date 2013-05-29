Model = require 'models/base/model'

module.exports = class Graph extends Model
  defaults:
    id: ''
    first_name: ''
    last_name: ''
    age: (new Date).getTime() / 3600000
