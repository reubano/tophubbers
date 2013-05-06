View = require 'views/base/view'
template = require 'views/templates/header'

module.exports = class HeaderView extends View
  autoRender: yes
  className: 'navbar-inner'
  region: 'header'
  id: 'header'
  template: template
