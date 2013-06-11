config =
	# api: 'http://ongeza-api.herokuapp.com/',
	api: 'http://localhost:5000/',
	max_age: 24  # in hours
	to_chart: 'work_data'
	data_attrs: ['cur_work_data', 'prev_work_data']
	chart_suffix: '_c'

module.exports = config