switch window?.location?.hostname ? require('os').hostname()
	when 'localhost', 'tokpro.local'
		console.log 'development envrionment set'
		api_get = 'http://localhost:5000/'
		api_forms = 'http://localhost:5001/api/forms'
		api_logs = 'http://localhost:8888/api/logs'
		age = 72  # in hours
	else
		console.log 'production envrionment set'
		api_get = 'http://ongeza-api.herokuapp.com/'
		api_forms = 'http://ongeza-forms.herokuapp.com/api/forms'
		api_logs = 'http://flogger.herokuapp.com/api/logs'
		age = 12  # in hours

config =
	api_get: api_get
	api_forms: api_forms
	api_logs: api_logs
	rpp: 100  # form results per page
	max_age: age
	to_chart: 'work_data'
	data_attrs: ['cur_work_data', 'prev_work_data']
	res: ['rep_info', 'work_data', 'score', 'progress_data', 'feedback_data']
	chart_suffix: '_c'
	svg_suffix: '_svg'

module.exports = config
