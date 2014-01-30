debug_mobile = false
debug_canvas = false
debug_prod = false
host = window?.location?.hostname ? require('os').hostname()
dev = host in ['localhost', 'tokpro.local', 'tokpro']
prod = not dev
gh_api_token = 'cdac348c97dbdf5252d530103e0bfb2b9275d126'
query = "followers:%3E5000&access_token=#{gh_api_token}"
reps_url = "https://api.github.com/search/users?q=#{query}"
rep_url = "https://api.github.com/users/"

if dev and not debug_prod
  console.log 'development envrionment set'
  mode = 'development'
  api_progress = "/api/progress"
  api_render = "/api/render"
  api_uploads = "/api/uploads"
  api_forms = "http://localhost:5002/api/forms"
  api_logs = "http://localhost:8888/api/logs"
  age = 72 # in hours
else
  console.log 'production envrionment set'
  mode = 'production'
  api_progress = 'http://ongeza.herokuapp.com/api/progress'
  api_render = 'http://ongeza.herokuapp.com/api/render'
  api_uploads = 'http://ongeza.herokuapp.com/api/uploads'
  api_forms = 'http://ongeza-forms.herokuapp.com/api/forms'
  api_logs = 'http://flogger.herokuapp.com/api/logs'
  age = 12 # in hours

ua = navigator?.userAgent?.toLowerCase()
mobile_device = (/iphone|ipod|ipad|android|blackberry|opera mini|opera mobi/).test ua
force_mobile = (dev and debug_mobile)
mobile = mobile_device or force_mobile
svg_support = Modernizr?.svg ? not mobile_device
force_canvas = (dev and debug_canvas)
svg = svg_support and not force_canvas

console.log "host: #{host}"
console.log "mobile device: #{mobile}"
console.log "svg: #{svg}"
console.log "debug production: #{debug_prod}"

config =
  mode: mode
  prod: prod
  debug_prod: debug_prod
  dev: dev
  api_progress: api_progress
  api_render: api_render
  api_uploads: api_uploads
  api_forms: api_forms
  api_logs: api_logs
  api_token: gh_api_token
  reps_url: reps_url
  rep_url: rep_url
  mobile: mobile
  svg: svg
  canvas: not svg
  rpp: 100 # form results per page
  max_age: age
  info_attr: 'info'
  prgrs_attr: 'progress'
  data_attr: 'work_data'
  chart_attr: 'work_string'
  hash_attr: 'work_hash'
  svg_attr: 'work_svg'
  img_attr: 'work_img'

module.exports = config
