config = require 'config'
Chaplin = require 'chaplin'

module.exports = class Model extends Chaplin.Model
  _.extend @prototype, Chaplin.SyncMachine
