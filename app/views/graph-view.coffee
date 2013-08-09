config = require 'config'
nvd3util = require 'lib/nvd3util'
View = require 'views/base/view'
template = require 'views/templates/graph'

module.exports = class GraphView extends View
	template: template
#	listen:
#		addedToParent: 'getChartScript'
#		addedToParent: 'addedToParentAlert'
#		visibilityChange: 'visibilityChangeAlert'

	initialize: (options) =>
		super
		@attrs = options.attrs
		@chart_suffix = config.chart_suffix
		@ignore_svg = options.ignore_svg
		@id = @model.get 'id'
		@changed = false
		console.log 'initialize graph-view for ' + @id
		console.log options

		data_attrs = config.data_attrs
		changes = ('change:' + attr + @chart_suffix for attr in data_attrs)

		@listenTo @model, changes[0], ->
			console.log 'graph-view heard ' + changes[0]
			@changed = true
			@unsetSVG data_attrs[0]
			@render() if data_attrs[0] in @attrs

		@listenTo @model, changes[1], ->
			console.log 'graph-view heard ' + changes[1]
			@changed = true
			@unsetSVG data_attrs[1]
			@render() if data_attrs[1] in @attrs

	render: =>
		super
		console.log 'rendering graph view for ' + @id
		@attach()
		_.defer @getChartScript, @ignore_svg

	visibilityChangeAlert: ->
		console.log 'graph-view heard visibilityChange'

	addedToParentAlert: ->
		console.log 'graph-view heard addedToParent'

	getChartScript: (ignore_svg) =>
		# console.log 'chart html'
		# console.log @model.get 'chart'

		for attr in @attrs
			chart_class = 'chart-' + attr[0..2]
			selection = '#' + @id + '.view .' + chart_class + ' svg'
			parent = '#' + @id + '.view .' + chart_class
			svg_attr = attr + config.svg_suffix
			chart_attr = attr + @chart_suffix
			chart_json = @model.get chart_attr
			name = @model.get 'first_name'
			svg = if @model.get svg_attr then @model.get svg_attr else null
			text = @id + ' ' + attr + ' '

			if (svg and not @changed and not ignore_svg)
				console.log 'drawing ' + text + 'chart from cache'
				# console.log svg.length
				# console.log svg.indexOf('opacity: 0.000001;') < 0
				@$(parent).html svg
				@pubRender attr
			else if chart_json and name
				# console.log text + 'is rendered: ' + rendered
				console.log text + 'has svg: ' + svg?
				console.log text + 'ignore svg: ' + ignore_svg
				console.log text + 'has changed: ' + @changed
				console.log 'getting ' + text + 'script'
				chart_data = JSON.parse chart_json
				nvd3 = new nvd3util chart_data, selection, @changed
				_.defer nvd3.init
				_.defer @setSVG, attr
				_.defer @pubRender, attr
			else
				console.log @id + ' has no ' + chart_attr + ' or no name'

	pubRender: (attr) =>
		@publishEvent 'rendered:' + attr
		console.log 'published rendered:' + attr

	unsetSVG: (attr) =>
		svg_attr = attr + config.svg_suffix
		console.log 'unsetting ' + svg_attr
		@model.unset svg_attr
		@model.save()

	setSVG: (attr) =>
		chart_class = 'chart-' + attr[0..2]
		parent = '#' + @id + '.view .' + chart_class
		text = ' ' + @id + ' ' + attr + ' '
		html = @$(parent).html()
		bad = 'opacity: 0.000001;'

		if html and html.indexOf(bad) < 0 and html.length > 40
			svg_attr = attr + config.svg_suffix
			console.log 'setting' + text + 'svg'
			svg = html.replace(/\"/g, '\'')
			@model.set svg_attr, svg
			@model.save()
		else
			console.log 'html blank or malformed for ' + parent
