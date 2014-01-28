Model = require 'models/base/model'
utils = require 'lib/utils'

module.exports = class Navbar extends Model
  defaults:
    items: [
      {href: '/tocalls', title: 'List', desc: 'View Check List'},
      {href: '/graphs', title: 'Activity', desc: 'View Activity'},
      {href: '/progresses', title: 'Progress', desc: 'View Progress'},
      {href: '/visits', title: 'Stats', desc: 'View Stats'},
    ]

    main:
      href: '/', title: 'Home'

  initialize: ->
    super
    utils.log 'initialize navbar model'
