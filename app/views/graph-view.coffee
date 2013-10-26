View = require 'views/base/view'
Common = require 'lib/common'
makeChart = require 'lib/makechart'
config = require 'config'
template = require 'views/templates/graph'
utils = require 'lib/utils'

module.exports = class GraphView extends View
	template: template
#	 listen:
#		 addedToParent: 'getChartScript'
#		 addedToParent: 'addedToParentAlert'
#		 visibilityChange: 'visibilityChangeAlert'

	initialize: (options) =>
		super
		@attrs = options.attrs
		@listen_suffix = if @mobile then '' else config.parsed_suffix
		@ignore_cache = options.ignore_cache
		@id = @model.get 'id'
		@changed = false
		@mobile = config.mobile
		utils.log 'initialize graph-view for ' + @id
		utils.log options, false

		@listen_attrs = if @mobile then config.hash_attrs else config.data_attrs
		changes = ('change:' + attr + @listen_suffix for attr in @listen_attrs)

		@listenTo @model, changes[0], =>
			utils.log 'graph-view heard ' + changes[0]
			@changed = @listen_attrs[0]
			@unsetCache @changed
			@render() if @changed in @attrs

		@listenTo @model, changes[1], =>
			utils.log 'graph-view heard ' + changes[1]
			@changed = @listen_attrs[1]
			@unsetCache @changed
			@render() if @changed in @attrs

	render: =>
		super
		utils.log 'rendering graph-view for ' + @id
		@attach()
		_.defer @getChartScript, @ignore_cache

	visibilityChangeAlert: ->
		utils.log 'graph-view heard visibilityChange'

	addedToParentAlert: ->
		utils.log 'graph-view heard addedToParent'

	getChartScript: (ignore_cache) =>
		utils.log 'getting chart for ' + @id
		(@unsetCache attr for attr in @listen_attrs) if ignore_cache

		for @attr in @attrs
			utils.log 'setting variables for ' + @attr
			@options = {attr: @attr, id: @id}
			@parent = Common.getParent @options
			@svg_attr = @attr + config.svg_suffix
			@img_attr = @attr + config.img_suffix
			@text = if @mobile then "#{@id} #{@img_attr}" else "#{@id} #{@svg_attr}"
			chart_attr = @attr + @listen_suffix
			chart_json = @model.has chart_attr
			name = @model.get 'first_name'
			svg = if @model.has @svg_attr then @model.get @svg_attr else null
			img = if @model.has @img_attr then @model.get @img_attr else null

			if @mobile and img and not @changed and not ignore_cache
				utils.log "fetching #{@text} from cache"
				utils.log img
				@$(@parent).html img
				@pubRender @attr
			else if @mobile and name
				utils.log "fetching #{@text} from server"
				data = {hash: @model.get @attr}
				_.extend data, @options
				$.post(config.api_render, data).done(@gvSuccess).fail(@gvFailWhale)
			else if svg and not @changed and not ignore_cache
				utils.log "drawing #{@text} from cache"
				@$(@parent).html svg
				@pubRender @attr
			else if chart_json and name
				selection = Common.getSelection @options
				utils.log "#{@id} #{@attr} has svg: #{svg?}"
				utils.log "#{@id} #{@attr} ignore svg: #{ignore_cache}"
				utils.log "fetching script for #{selection}"
				chart_data = JSON.parse @model.get chart_attr
				do (@options, @attr) =>
					nv.addGraph makeChart(chart_data, selection, @changed), =>
						@setSVG @options
						@pubRender @attr
			else
				utils.log "#{@id} has no #{chart_attr} or no name"

	pubRender: (attr) =>
		@publishEvent 'rendered:' + attr
		utils.log 'published rendered:' + attr

	unsetCache: (prefix) =>
		suffix = if @mobile then 'img_suffix' else 'svg_suffix'
		attr = prefix + config[suffix]
		utils.log "unsetting #{@id} #{attr}"
		@model.unset attr
		@model.save()

	setImg: (options) =>
		parent = Common.getParent options
		html = $(parent).html()

		if html and html.length is 57
			img = html.replace(/\"/g, '\'')
			attr = options.attr + config.img_suffix
			utils.log "setting #{options.id} #{attr}"
			@model.set attr, img
			@model.save()
		else
			utils.log 'html blank or malformed for ' + parent

	setSVG: (options) =>
		parent = Common.getParent options
		html = @$(parent).html()
		bad = 'opacity: 0.000001;'

		if html and html.indexOf(bad) < 0 and html.length > 40
			svg = html.replace(/\"/g, '\'')
			attr = options.attr + config.svg_suffix
			utils.log "setting #{options.id} #{attr}"
			@model.set attr, svg
			@model.save()
		else
			utils.log 'html blank or malformed for ' + parent

	gvSuccess: (data, textStatus, res) =>
		if data?.id?
			parent = Common.getParent data
			utils.log "successfully fetched png for #{data.id}!"

			if $(parent)
				url = "#{config.api_uploads}/#{data.hash}"
				utils.log "setting html for #{parent} to #{url}"
				$(parent).html "<img src=#{url}>"
				@setImg data
				@pubRender data.attr
			else utils.log "selection #{parent} doesn't exist", 'error'
		else
			progress = res.getResponseHeader 'Location'
			console.log "trying to get progress: #{progress}"
			$.get(progress).done(@gvSuccess).fail(@gvFailWhale)

	gvFailWhale: (res, textStatus, err) =>
		if res.status is 503
			wait = parseInt res.getResponseHeader 'Retry-After'
			console.log "retrying #{res.getResponseHeader 'Location'} in #{wait/1000}s"
			do (res) => _.delay @gvSuccess, wait, {}, 'OK', res
		else
			try
				error = JSON.parse(res.responseText).error
			catch error
				error = res.responseText
			utils.log "failed to fetch png: #{error}.", 'error'
