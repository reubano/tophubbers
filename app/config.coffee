switch window.location.hostname
	when 'localhost'
		console.log 'development envrionment set'
		api_url = 'http://localhost:5000/'
		forms_url = 'http://localhost:5001/forms'
		age = 72	 # in hours
	else
		console.log 'production envrionment set'
		api_url = 'http://ongeza-api.herokuapp.com/'
		forms_url = 'http://ongeza-forms.herokuapp.com/forms'
		age = 24	 # in hours

config =
	api: api_url
	forms: forms_url
	max_age: age
	poll_intrv: 24	 # in hours
	to_chart: 'work_data'
	data_attrs: ['cur_work_data', 'prev_work_data']
	res: ['rep_info', 'work_data', 'score', 'progress_data', 'feedback_data']
	chart_suffix: '_c'
	svg_suffix: '_svg'

module.exports = config
