debug_mobile = true
debug_prod = false
host = window?.location?.hostname ? require('os').hostname()
dev = host in ['localhost', 'tokpro.local', 'tokpro']
prod = not dev
port = 3333

if dev and not debug_prod
	console.log 'development envrionment set'
	mode = 'development'
	api_fetch = "http://localhost:#{port}/api/fetch"
	api_upload = "http://localhost:#{port}/api/upload"
	api_get = "http://localhost:5001/"
	api_forms = "http://localhost:5002/api/forms"
	api_logs = "http://localhost:8888/api/logs"
	age = 72  # in hours
else
	console.log 'production envrionment set'
	mode = 'production'
	api_fetch = 'http://ongeza.herokuapp.com/api/fetch'
	api_upload = 'http://ongeza.herokuapp.com/api/upload'
	api_get = 'http://ongeza-api.herokuapp.com/'
	api_forms = 'http://ongeza-forms.herokuapp.com/api/forms'
	api_logs = 'http://flogger.herokuapp.com/api/logs'
	age = 12 # in hours

ua = navigator?.userAgent?.toLowerCase()
mobile = (/iphone|ipod|ipad|android|blackberry|opera mini|opera mobi/).test ua
console.log "host: #{host}"
console.log "mobile device: #{mobile}"
console.log "debug mobile: #{debug_mobile}"
console.log "debug production: #{debug_prod}"

config =
	mode: mode
	prod: prod
	port: port
	debug_mobile: debug_mobile
	debug_prod: debug_prod
	dev: dev
	api_fetch: api_fetch
	api_upload: api_upload
	api_get: api_get
	api_forms: api_forms
	api_logs: api_logs
	mobile: mobile or (dev and debug_mobile)
	rpp: 100  # form results per page
	max_age: age
	to_chart: 'work_data'
	data_attrs: ['cur_work_data', 'prev_work_data']
	hash_attrs: ['cur_work_hash', 'prev_work_hash']
	res: ['rep_info', 'work_data', 'score', 'progress_data', 'feedback_data']
	parsed_suffix: '_c'
	svg_suffix: '_svg'
	img_suffix: '_img'

module.exports = config
