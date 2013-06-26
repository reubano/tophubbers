View = require 'views/base/view'
template = require 'views/templates/site'

# Site view is a top-level view which is bound to body.
module.exports = class SiteView extends View
	container: 'body'
	id: 'container'
	className: 'container-fluid'
	regions:
		'#navbar': 'navbar'
		'#content': 'content'
	template: template
