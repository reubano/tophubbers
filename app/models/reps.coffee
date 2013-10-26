Collection = require 'models/base/collection'
Model = require 'models/rep'
utils = require 'lib/utils'

module.exports = class Reps extends Collection
  model: Model
  url: 'reps'
  local: true

  initialize: (options) =>
    super
    utils.log 'initialize reps collection'

  getCalled: ->
    @where called: yes

  getActive: ->
    @where called: no
