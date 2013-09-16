switch window?.location?.hostname ? require('os').hostname()
	when 'localhost', 'tokpro.local'
		console.log 'development envrionment set'
		mode = 'development'
		api_get = 'http://localhost:5000/'
		api_fetch = 'http://localhost:3333/api/fetch'
		api_upload = 'http://localhost:3333/api/upload'
		api_forms = 'http://localhost:5001/api/forms'
		api_logs = 'http://localhost:8888/api/logs'
		age = 72  # in hours
	else
		console.log 'production envrionment set'
		mode = 'production'
		api_get = 'http://ongeza-api.herokuapp.com/'
		api_fetch = 'http://ongeza.herokuapp.com/api/fetch'
		api_upload = 'http://ongeza.herokuapp.com/api/upload'
		api_forms = 'http://ongeza-forms.herokuapp.com/api/forms'
		api_logs = 'http://flogger.herokuapp.com/api/logs'
		age = 12  # in hours

ua = navigator?.userAgent?.toLowerCase()
mobile = (/iphone|ipod|ipad|android|blackberry|opera mini|opera mobi/).test ua
console.log "mobile device: #{mobile}"

config =
	mode: mode
	prod: mode is 'production'
	dev: mode is 'development'
	api_get: api_get
	api_fetch: api_fetch
	api_upload: api_upload
	api_forms: api_forms
	api_logs: api_logs
	mobile: mobile
	rpp: 100  # form results per page
	max_age: age
	to_chart: 'work_data'
	data_attrs: ['cur_work_data', 'prev_work_data']
	hash_attrs: ['cur_work_hash', 'prev_work_hash']
	res: ['rep_info', 'work_data', 'score', 'progress_data', 'feedback_data']
	chart_suffix: '_c'
	svg_suffix: '_svg'
	img_suffix: '_img'

module.exports = config
