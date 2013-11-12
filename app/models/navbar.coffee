Model = require 'models/base/model'
utils = require 'lib/utils'

module.exports = class Navbar extends Model
  defaults:
    items: [
      {href: '/tocalls', title: 'Calls', desc: 'View Call List'},
      {href: '/graphs', title: 'Graphs', desc: 'View Graphs'},
      {href: '/progresses', title: 'Progress', desc: 'View Progress'},
      {href: '/visits', title: 'Visits', desc: 'View Visits'},
    ]

    main:
      href: '/', title: 'Home'

  initialize: ->
    super
