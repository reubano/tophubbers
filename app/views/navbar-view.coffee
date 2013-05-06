View = require 'views/base/view'
template = require 'views/templates/navbar'

module.exports = class NavbarView extends View
  autoRender: yes
  className: 'navbar-inner'
  region: 'navbar'
  template: template

