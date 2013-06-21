Momentous = require 'lib/momentous'
Chaplin = require 'chaplin'
View = require 'views/graph-view'
template = require 'views/templates/rep'

module.exports = class RepView extends View
	mediator = Chaplin.mediator

	autoRender: true
	region: 'content'
	className: 'span12'
	template: template
	user: mediator.users.get(1)
	forms: mediator.forms

	initialize: (options) ->
		super
		@attrs = options.attrs
		@id = @model.get 'id'
		mediator.rep_id = @id
		console.log 'initialize rep-view for ' + @id
		console.log @forms
		console.log options

		if @user
			@name = @user.get 'name'
		else
			@name = 'N/A'
			@subscribeEvent 'userUpdated', @setUserName

		console.log 'User name is ' + @name
		@delegate 'click', '#network-form-submit', @networkFormSubmit
		@delegate 'click', '#review-form-submit', @reviewFormSubmit
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'rep-view caught dispatcher event'
		# @subscribeEvent 'dispatcher:dispatch', @render

		for prefix in ['change:cur_', 'change:prev_']
			@listenTo @model, prefix + 'work_data_c', @render
			@listenTo @model, prefix + 'feedback_data', @render
			@listenTo @model, prefix + 'progress', @render

		@listenTo @forms, 'add', ->
			console.log 'rep-view caught add event'
		@listenTo @forms, 'request', (model, xhr, options) ->
			console.log 'rep-view caught request event'
			console.log model
			console.log xhr
			console.log options
		@listenTo @forms, 'sync', ->
			console.log 'rep-view caught sync event'
		@listenTo @forms, 'sync', @success
		@listenTo @forms, 'error', @failWhale
		@listenTo @forms, 'invalid', @failWhale

	setUserName: (user) =>
		@name = user.get 'name'
		console.log 'User name is ' + @name

	render: =>
		super
		@svg()
		_.defer @removeActive
		console.log 'rendering rep view for ' + @id
		@renderDatepicker '#review-datepicker'
		@renderDatepicker '#network-datepicker'

	svg: =>
		console.log 'checking svg'
		chart_class = 'chart-' + @attrs[1][0..2]
		parent = '#' + @id + '.view .' + chart_class
		html = @$(parent).html()
		bad = 'opacity: 0.000001;'
		# console.log html
		html and html.indexOf(bad) < 0 and html.length > 40

	removeActive: =>
		# Hack to get the chart to render in the inactive tab
		# http://stackoverflow.com/a/11816438
		chart_class = 'chart-' + @attrs[1][0..2]
		tab = '#' + chart_class + '-cont'
		@$(tab).removeClass 'active'

	renderDatepicker: (selection) =>
		momentous = new Momentous @.$ selection
		momentous.init()
		# console.log momentous

	objectify: (form) ->
		data = @.$(form).serializeArray()
		keys = ((y for x,y of z)[0] for z in data)
		values = ((y for x,y of z)[1] for z in data)
		obj = _.object(keys, values)
		_.extend obj, {rep: @id, manager: @name, form: form}

	networkFormSubmit: =>
		json = @objectify('#network-form')
		console.log 'saving form data...'
		console.log json
		@forms.create json

	reviewFormSubmit: =>
		json = @objectify('#review-form')
		console.log 'saving form data...'
		console.log json
		@forms.create json

	success: (model, resp, options) =>
		if model.get('id')
			console.log 'successfully posted form for ' + model.get('id') + '!'
			@$('#success-modal').modal()
		else
			console.log 'successfully fetched forms'
			@render()

		console.log model
		console.log resp
		console.log options

	failWhale: (model, xhr, options) =>
		if model.get('id')
			console.log 'failed to post form for ' + model.get('id')
			@$('#fail-modal').modal()
		else
			console.log 'failed to fetch forms'

		console.log model
		console.log xhr
		console.log options

