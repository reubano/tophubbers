Model = require 'models/base/model'

module.exports = class Graph extends Model
 	defaults: ->
 		data: ''

	initialize: ->
		super
		@set 'created', new Date().toString() if @isNew() or not @get 'created'
		# @set 'first_name', 'Name not found in database' if not @get 'first_name'
		# @set 'airtel', 'N/A' if not @get 'airtel'
		# @set 'ward', 'N/A' if not @get 'ward'

	getChartData: (attr) =>
		d = @get attr + '_data'

		if not d
			console.log 'no ' + attr + '_data found for ' + @get('id')
			return

		console.log @get('id') + ': setting ' + attr + ' chart data'
		if d.rows
			endValues = (label: obj.date, value: obj.start for obj in d.rows)
			durValues = (label: obj.date, value: obj.duration for obj in d.rows)
			endValues.push(label: obj, value: 0 for obj in d.missing)
			durValues.push(label: obj, value: 0 for obj in d.missing)
		else
			endValues = (label: obj, value: 0 for obj in d.missing)
			durValues = (label: obj, value: 0 for obj in d.missing)

		endValues = _.sortBy endValues, 'label'
		durValues = _.sortBy durValues, 'label'

		data = [
			{key: 'End', values: endValues},
			{key: 'Duration', values: durValues}]

		JSON.stringify(data)

