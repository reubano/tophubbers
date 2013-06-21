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
	to_chart: 'work_data'
	data_attrs: ['cur_work_data', 'prev_work_data']
	chart_suffix: '_c'
	svg_suffix: '_svg'
#	attrs: ['cur_work', 'prev_work']
#	data_suffix: '_data'
#	chart_suffix: '_chart_data'

module.exports = config
