Chaplin = require 'chaplin'
View = require 'views/graph-view'
template = require 'views/templates/rep'

module.exports = class RepView extends View
	mediator = Chaplin.mediator
	history = '&pageHistory=0'
	base = 'https://docs.google.com/forms/d/'

	autoRender: true
	region: 'content'
	className: 'span12'
	template: template

	initialize: (options) ->
		super
		@delegate 'click', '#network-form-submit', @networkFormSubmit
		@delegate 'click', '#review-form-submit', @reviewFormSubmit
		@listenTo @model, options.change, @render
		@subscribeEvent 'loginStatus', @render
		@subscribeEvent 'dispatcher:dispatch', ->
			console.log 'rep-view caught dispatcher event'
		# @subscribeEvent 'dispatcher:dispatch', @render

	render: =>
		super
		console.log 'rendering rep view'
		user = mediator.user

	networkFormSubmit: =>
		data = @.$('#network-form').serializeArray()
		date = data[0].value
		month = date[0..1]
		day = date[3...5]
		year = date[6..]
		reason = encodeURIComponent data[1].value
		key = '1NUy1KZTgjFqMXp6HPe1G5nr2AaiFe_FfRltT9sMsAek'

		response = '/formResponse?draftResponse=%5B%5B%5B%2C1240672778%2C%5B%22'
		response += '2013-06-00%22%5D%0D%0A%2C0%5D%0D%0A%5D%0D%0A%5D%0D%0A'
		day = '&entry.1240672778_day=' + day
		month = '&entry.1240672778_month=' + month
		year = '&entry.1240672778_year=' + year
		reason = '&entry.1863214152=' + reason
		url = base + key + response + day + month + year + reason + history
		console.log 'posting form data...'
		console.log data
		console.log url
		$.post(url).always(@processResponse)

	reviewFormSubmit: =>
		data = @.$('#review-form').serializeArray()
		key = '1NUy1KZTgjFqMXp6HPe1G5nr2AaiFe_FfRltT9sMsAek'
		response = '/formResponse?draftResponse=%5B%5B%5B%2C1240672778%2C%5B%22'
		response += '2013-06-00%22%5D%0D%0A%2C0%5D%0D%0A%5D%0D%0A%5D%0D%0A'
		type = encodeURIComponent data[0].value
		observations = encodeURIComponent data[1].value
		notes = encodeURIComponent data[2].value
		url = base + key + response + type + observations + notes + history
		console.log 'posting form data...'
		console.log data
		console.log url
		# $.post(url).always(@processResponse)

	processResponse: (jqXHR, textStatus, errorThrown) =>
		if jqXHR.status == 0
			console.log 'successfully posted form!'
		else
			console.log 'failed to post form'
			console.log 'error: ' + errorThrown if errorThrown
