Model = require 'models/base/model'

module.exports = class Navbar extends Model
  defaults:
    items: [
      {href: '/tocall', title: 'Calls', desc: 'View Call List'},
      {href: '/graphs', title: 'Graphs', desc: 'View Graphs'},
      {href: '/progress', title: 'Progress', desc: 'View Progress'},
    ]

    main:
      href: '/', title: 'Home'

  initialize: ->
    super
