switch window.location.hostname
	when 'localhost'
		console.log 'development envrionment set'
		url = 'http://localhost:5000/'
		age = 72	 # in hours
	else
		console.log 'production envrionment set'
		url = 'http://ongeza-api.herokuapp.com/'
		age = 24	 # in hours

config =
	api: url
	max_age: age
	to_chart: 'work_data'
	data_attrs: ['cur_work_data', 'prev_work_data']
	chart_suffix: '_c'
	svg_suffix: '_svg'
#	attrs: ['cur_work', 'prev_work']
#	data_suffix: '_data'
#	chart_suffix: '_chart_data'

module.exports = config
