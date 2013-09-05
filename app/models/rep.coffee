Model = require 'models/base/model'
utils = require 'lib/utils'

module.exports = class Rep extends Model
	defaults:
		called: no

	initialize: ->
		super
		utils.log 'init score sort: ' + @get 'score_sort'
		utils.log 'has score sort: ' + @has 'score_sort'
		@set created: new Date().toString() if @isNew() or not @has 'created'
		ss = if @has 'score_sort' then @get 'score_sort' else @get 'score'
		@set score_sort: ss
		utils.log 'next score sort: ' + @get 'score_sort'

	toggle: ->
		@set called: not @get 'called'
		score_sort = if @get('called') then 0 else @get 'score'
		@set score_sort: JSON.stringify score_sort
		utils.log 'called: ' + @get 'called'
		utils.log 'score: ' + @get 'score'
		utils.log 'score sort: ' + score_sort

	getChartData: (attr) =>
		d = @get attr

		if not d
			utils.log 'no ' + attr + ' found for ' + @get('id')
			return

		utils.log @get('id') + ': generating ' + attr + ' chart data...'

		if d.rows
			endRows = (label: obj.date, value: obj.start for obj in d.rows)
			durRows = (label: obj.date, value: obj.duration for obj in d.rows)
		else
			endRows = []
			durRows = []

		if d.missing
			endMiss = (label: obj, value: 0 for obj in d.missing)
			durMiss = (label: obj, value: 0 for obj in d.missing)
		else
			endMiss = []
			durMiss = []

		endValues = endRows.concat endMiss
		durValues = durRows.concat durMiss

		endValues = _.sortBy endValues, 'label'
		durValues = _.sortBy durValues, 'label'

		data = [
			{key: 'End', values: endValues},
			{key: 'Duration', values: durValues}]

		JSON.stringify data
