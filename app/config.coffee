switch window?.location?.hostname ? require('os').hostname()
	when 'localhost', 'tokpro.local'
		console.log 'development envrionment set'
		api_url = 'http://localhost:5000/'
		forms_url = 'http://localhost:5001/api/forms'
		logs_url = 'http://localhost:8888/api/logs'
		age = 72	 # in hours
	else
		console.log 'production envrionment set'
		api_url = 'http://ongeza-api.herokuapp.com/'
		forms_url = 'http://ongeza-forms.herokuapp.com/api/forms'
		logs_url = 'http://flogger.herokuapp.com/api/logs'
		age = 12	 # in hours

config =
	api: api_url
	rpp: 100   # form results per page
	forms: forms_url
	logs: logs_url
	max_age: age
	to_chart: 'work_data'
	data_attrs: ['cur_work_data', 'prev_work_data']
	res: ['rep_info', 'work_data', 'score', 'progress_data', 'feedback_data']
	chart_suffix: '_c'
	svg_suffix: '_svg'

module.exports = config
