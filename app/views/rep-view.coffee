Momentous = require 'lib/momentous'
Chaplin = require 'chaplin'
View = require 'views/graph-view'
template = require 'views/templates/rep'

module.exports = class RepView extends View
	response = '/formResponse?draftResponse=%5B%5D%0D%0A'
	history = '&pageHistory=0'
	base = 'https://docs.google.com/forms/d/'
	mediator = Chaplin.mediator

	autoRender: true
	region: 'content'
	className: 'span12'
	template: template
	user: mediator.users.get(1)

	initialize: (options) ->
		super
		console.log 'initialize rep-view for ' + @id
		@attrs = options.attrs
		@id = @model.get 'id'
		@name = @user.get 'name'

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

	render: =>
		super
		_.defer @removeActive
		console.log 'rendering rep view for ' + @id
		@renderDatepicker '#review-datepicker'
		@renderDatepicker '#network-datepicker'

	removeActive: =>
		# Hack to get the chart to render in the inactive tab
		# http://stackoverflow.com/a/11816438
		chart_class = 'chart-' + @attrs[1][0..2]
		tab = '#' + chart_class + '-cont'
		@$(tab).removeClass 'active'

	renderDatepicker: (selection) =>
		momentous = new Momentous @.$ selection
		momentous.init()
		console.log momentous

	networkFormSubmit: =>
		data = @.$('#network-form').serializeArray()
		date = data[0].value
		month = date[0..1]
		day = date[3...5]
		year = date[6..]
		key = '1dq25yvpMKDxpXB8EKf0R-Ss9awgJQ3s4ZTrxUhVSRk4'
		reason = encodeURIComponent data[1].value
		day = '&entry.550366252_day=' + day
		month = '&entry.550366252_month=' + month
		year = '&entry.550366252_year=' + year
		reason = '&entry.1863214152=' + reason
		user = '&entry.1079468731=' + encodeURIComponent @name
		rep = '&entry.1854922402=' + @id
		fields = day + month + year + reason + user + rep
		url = base + key + response + fields + history
		console.log 'posting form data...'
		console.log data
		console.log url
		$.post({url: url, dataType: "html"}).done(@success).fail(@failWhale)

	reviewFormSubmit: =>
		data = @.$('#review-form').serializeArray()
		date = data[0].value
		month = date[0..1]
		day = date[3...5]
		year = date[6..]
		key = '1NUy1KZTgjFqMXp6HPe1G5nr2AaiFe_FfRltT9sMsAek'
		day = '&entry.1240672778_day=' + day
		month = '&entry.1240672778_month=' + month
		year = '&entry.1240672778_year=' + year
		type = '&entry.1863214152=' + encodeURIComponent data[1].value
		observations = '&entry.2056428099=' + encodeURIComponent data[2].value
		notes = '&entry.1079468731=' + encodeURIComponent data[3].value
		user = '&entry.804551073=' + encodeURIComponent @name
		rep = '&entry.1854922402=' + @id
		fields = day + month + year + type + observations + notes + user + rep
		url = base + key + response + fields + history
		console.log 'posting form data...'
		console.log data
		console.log url
		$.post({url: url, dataType: "html"}).done(@success).fail(@failWhale)


	success: (data, textStatus, jqXHR) =>
		console.log 'successfully posted form!'
		@$('#success-modal').modal()

	failWhale: (jqXHR, textStatus, errorThrown) =>
		console.log 'failed to post form'
		console.log textStatus + ': ' + jqXHR.status
		console.log 'error: ' + errorThrown if errorThrown
		@$('#fail-modal').modal()
