config =
	# api: 'http://ongeza-api.herokuapp.com/',
	api: 'http://localhost:5000/',
	max_age: 24  # in hours
	to_chart: 'work_data'
	data_attrs: ['cur_work_data', 'prev_work_data']
	chart_suffix: '_c'
	svg_suffix: '_svg'
# 	attrs: ['cur_work', 'prev_work']
# 	data_suffix: '_data'
# 	chart_suffix: '_chart_data'

module.exports = config
