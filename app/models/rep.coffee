Model = require 'models/base/model'
Common = require 'lib/common'
utils = require 'lib/utils'

module.exports = class Rep extends Model
	defaults:
		called: no

	initialize: ->
		super
		@set created: new Date().toString() if @isNew() or not @has 'created'
		ss = if @has 'score_sort' then @get 'score_sort' else @get 'score'
		@set score_sort: ss

	toggle: ->
		@set called: not @get 'called'
		score_sort = if @get('called') then 0 else @get 'score'
		@set score_sort: JSON.stringify score_sort
		utils.log 'called: ' + @get 'called'
		utils.log 'score: ' + @get 'score'
		utils.log 'score sort: ' + score_sort

	getChartData: (attr) ->
		Common.getChartData attr, @get(attr), @get 'id'
