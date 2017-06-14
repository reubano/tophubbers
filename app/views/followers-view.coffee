CollectionView = require 'views/base/collection-view'
template = require 'views/templates/followers'
View = require 'views/person-view'
mediator = require 'mediator'
utils = require 'lib/utils'
config = require 'config'

module.exports = class FollowersView extends CollectionView
  itemView: View
  autoRender: true
  listSelector: '#follower-list'
  className: 'row'
  region: 'content'
  template: template

  initialize: (options) =>
    super
    utils.log 'initializing followers view'
    # @subscribeEvent 'dispatcher:dispatch', @render
    mediator.setActive 'home'

  addMarkers: (map) ->
    if mediator.markers?.clearLayers?
      mediator.markers.clearLayers()

    mediator.markers = new L.LayerGroup().addTo map

  render: (options) =>
    super
    utils.log 'rendering followers view'

    @on 'addedToDOM', @setMap
    # @listenTo @collection, 'sync', -> mediator.map.addLayer markers

  setMap: =>
    options = config.options
    tileProvider = config.tileProviders[options.tileProvider]
    L.Icon.Default.imagePath = '/images'
    mediator.tiles = L.tileLayer.provider tileProvider, options.tpOptions

    map = mediator.map = L.map 'map'
    map.addLayer mediator.tiles
    map.setView options.center, options.zoomLevel, false
    @addMarkers map
    mediator.publish 'mapSet'

  getTemplateData: =>
    utils.log 'get followers view template data'
    templateData = super
    templateData
