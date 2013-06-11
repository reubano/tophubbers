Model = require 'models/base/model'

module.exports = class Graph extends Model
	defaults:
		called: no

	initialize: ->
		super
		@set created: new Date().toString() if @isNew() or not @get 'created'
		@set score_sort: @get 'score' if not @get 'score_sort'
		# @set 'first_name', 'Name not found in database' if not @get 'first_name'
		# @set 'airtel', 'N/A' if not @get 'airtel'
		# @set 'ward', 'N/A' if not @get 'ward'

	toggle: ->
		@set called: not @get 'called'
		console.log 'called: ' + @get 'called'
		console.log 'score: ' + if @get('called') then 0 else @get 'score'
		score_sort = if @get('called') then 0 else @get 'score'
		@set score_sort: JSON.stringify score_sort

	getChartData: (attr) =>
		d = @get attr

		if not d
			console.log 'no ' + attr + ' found for ' + @get('id')
			return

		console.log @get('id') + ': generating ' + attr + ' chart data...'

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

		JSON.stringify(data)
