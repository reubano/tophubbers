config = require 'config'
# nvd3util = require 'lib/nvd3util'
View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template
# 	listen:
# 		addedToParent: 'getChartScript'
# 		addedToParent: 'addedToParentAlert'
# 		visibilityChange: 'visibilityChangeAlert'

	initialize: (options) =>
		super
		console.log 'initialize graph-view'
		@options = options
		@id = @model.get 'id'
		@listenTo @model, 'change', @render
		# @listenTo @model, 'change', ->
		# 	console.log 'caught collection change'
		# @subscribeEvent 'dispatcher:dispatch', ->
		# 	console.log 'graph-view caught dispatcher event'

	render: =>
		super
		console.log 'rendering graph view for ' + @id
		@attach()
		_.defer @getChartScript

	visibilityChangeAlert: ->
		console.log 'graph-view heard visibilityChange'

	addedToParentAlert: ->
		console.log 'graph-view heard addedToParent'

	getChartScript: (force=true) =>
		# console.log 'chart html'
		# console.log @model.get 'chart'
		attrs = @options.attrs

		for attr in attrs
			chart_class = 'chart-' + attr[0..2]
			selection = '#' + @id + '.view .' + chart_class + ' svg';
			# rendered = @$(selection).html()
			rendered = false

			if (rendered and not @model.hasChanged(attr) and not force)
				console.log @id + ' ' + attr + " hasn't changed"
				return

			chart_attr = attr + config.chart_suffix
			chart_data = @model.get chart_attr
			name = @model.get 'first_name'
			console.log 'getting chart script for ' + @id

			if chart_data and name
				console.log @id + ' has ' + chart_attr
				selection_string = JSON.stringify selection
				options = [chart_data, selection_string]
				draw = '#draw-' + chart_class
				tab = '#' + chart_class + '-tab'
				script = "<script>_.defer(makeChart, #{options});</script>"
				# @$(tab).click()
				@$(draw).html script
			else
				console.log @id + ' has no ' + chart_attr + ' or no name'

	setHTML: =>
		html = @$('#svg').html()
		console.log 'getting chart html for ' + @id

		if html
			console.log html
			@model.set chart: html
			@model.save()
		else
			console.log 'no html found'
