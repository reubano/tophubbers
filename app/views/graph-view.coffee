config = require 'config'
View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template

	initialize: (options) =>
		super
		@options = options
		@listenTo @model, options.change, @render
		# @subscribeEvent 'dispatcher:dispatch', @setHTML

	render: =>
		super
		@drawChart()

	drawChart: =>
		# console.log 'chart html'
		# console.log @model.get 'chart'
		attr = @options.chart

		if not attr
			console.log 'options not set'
			return

		chart_attr = attr + config.chart_suffix
		chart_data = @model.get chart_attr
		name = @model.get 'first_name'
		id = @model.get 'id'

		if chart_data and name
			console.log id + ' has ' + chart_attr
			# func = nvd3util.makeChart chart_data, id
			# script = "<script>#{func};</script>"
			options = [chart_data, id]
			script = "<script>_.defer(makeChart, #{options});</script>"
			# script = "<script>makeChart(#{chart_data}, #{id});</script>"
			@$('#draw').html script
		else
			console.log id + ' has no ' + chart_attr + ' or no name'

	getHTML: =>
		id = @model.get 'id'
		console.log 'getting chart html for ' + id
		console.log @$('#svg').html()

	setHTML: =>
		setTimeout @getHTML, 100000
		# @model.set chart: JSON.stringify $(selection).html()
		# @model.save()
