debug_mobile = false
debug_canvas = false
debug_prod = false
debug_minilog = false
debug_prod_verbose = false
host = window?.location?.hostname ? require('os').hostname()
dev = host in ['localhost', 'tokpro.local', 'tokpro']
prod = not dev
gh_api_token = $PROCESS_ENV_GITHUB_TOKEN_TH ? null
query = "followers:%3E8500&access_token=#{gh_api_token}"
reps_url = "https://api.github.com/search/users?q=#{query}"
rep_url = "https://api.github.com/users/"
cm_api_key = $PROCESS_ENV_CLOUD_MADE_API_KEY ? null

if dev and not debug_prod
  console.log 'development environment set'
  mode = 'development'
  api_progress = "/api/progress"
  api_render = "/api/render"
  api_uploads = "/api/uploads"
  api_logs = "http://localhost:8888/api/logs"
  age = 72 # in hours
else
  console.log 'production environment set'
  mode = 'production'
  api_progress = 'https://tophubbers.herokuapp.com/api/progress'
  api_render = 'https://tophubbers.herokuapp.com/api/render'
  api_uploads = 'https://tophubbers.herokuapp.com/api/uploads'
  api_logs = 'https://flogger.herokuapp.com/api/logs'
  age = 12 # in hours

ua = navigator?.userAgent?.toLowerCase()
list = 'iphone|ipod|ipad|android|blackberry|opera mini|opera mobi'
mobile_device = (/"#{list}"/).test ua?.toLowerCase()
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
  srchProviders:
    google: 'Google'
    openstreetmap: 'OpenStreetMap'
    esri: 'Esri'

  tileProviders:
    1: 'MapBox.reubano.ghdp3e73'
    2: 'OpenStreetMap'
    3: 'Esri.WorldTopoMap'
    4: 'CloudMade'

  options:
    icon: 'user'
    tileProvider: 3
    tpOptions: {maxZoom: 5, apiKey: cm_api_key, styleID: 1}
    srchProviderName: 'openstreetmap'
    zoomLevel: 2
    center: [20, 8]
    setView: true

  author:
    name: 'Reuben Cummings'
    url: 'https://www.reubano.xyz/'

  cm_api_key: cm_api_key
  mode: mode
  prod: prod
  debug_prod: debug_prod
  debug_minilog: debug_minilog
  debug_prod_verbose: debug_prod_verbose
  dev: dev
  api_progress: api_progress
  api_render: api_render
  api_uploads: api_uploads
  api_logs: api_logs
  api_token: gh_api_token
  reps_url: reps_url
  rep_url: rep_url
  mobile: mobile
  svg: svg
  canvas: not svg
  max_age: age
  info_attr: 'info'
  prgrs_attr: 'progress'
  data_attr: 'work_data'
  chart_attr: 'work_string'
  score_attr: 'work_score'
  hash_attr: 'work_hash'
  svg_attr: 'work_svg'
  img_attr: 'work_img'

module.exports = config
