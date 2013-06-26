Chaplin = require 'chaplin'
Model = require 'models/base/model'

module.exports = class Collection extends Chaplin.Collection
	model: Model

	# _.extend @prototype, Chaplin.SyncMachine
