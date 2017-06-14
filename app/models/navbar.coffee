Model = require 'models/base/model'
utils = require 'lib/utils'

module.exports = class Navbar extends Model
  defaults:
    items: [
      {
        href: '/tocalls', title: 'Check List', desc: 'View Check List',
        id: 'tocalls'
      }
      {href: '/graphs', title: 'Activity', desc: 'View Activity', id: 'graphs'}
      {href: '/visits', title: 'Stats', desc: 'View Stats', id: 'visits'}
    ]

    main:
      href: '/', title: 'Home'

  initialize: ->
    super
    utils.log 'initialize navbar model'
