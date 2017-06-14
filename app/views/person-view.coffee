View = require 'views/base/view'
template = require 'views/templates/person'
mediator = require 'mediator'
config = require 'config'
utils = require 'lib/utils'

module.exports = class PersonView extends View
  autoRender: false
  tagName: 'li'
  className: 'col-sm-12 col-md-6 gallery'
  template: template

  initialize: (options) =>
    super
    @listenTo @model, 'change:location', =>
      location = @model.get 'location'
      # console.log "change location: #{location}"

      if location and not @model.get 'coordinates'
        # console.log "no coordinates: #{@model.get 'login'}"
        @model.fetchData @refresh, 'coordinates'

    @listenTo @model, 'change:coordinates', @render
    id = @model.get 'id'
    location = @model.get 'location'
    coordinates = @model.get 'coordinates'
    login = @model.get 'login'
    return if not (id or login)

    if coordinates
      [x, y] = [coordinates.X, coordinates.Y]
      utils.log "initialize person-view: #{login} at #{x}, #{y}"
    else if location
      utils.log "initialize person-view: #{login} in #{location}"
      @model.fetchData @refresh, 'coordinates'
    else
      utils.log "initialize person-view: #{login}"
      @model.fetch()

  addCoords: (coordinates) =>
    location = @model.get 'location'
    login = @model.get 'login'
    # console.log "addCoords #{login}: #{location}"

    [x, y] = [coordinates.X, coordinates.Y]
    [AwesomeMarker, markers] = [mediator.AwesomeMarker, mediator.markers]
    marker = L.marker([y, x], {icon: AwesomeMarker}).addTo markers
    marker.bindPopup "#{login}: #{location}"
    marker.on 'mouseover', (e) -> e.target.openPopup()
    marker.on 'mouseout', (e) -> e.target.closePopup()
    mediator.map.fireEvent 'geosearch_showlocation', {Location: coordinates}

  render: =>
    super
    @$("[data-toggle='tooltip']").tooltip()
    location = @model.get 'location'
    login = @model.get 'login'
    coordinates = @model.get 'coordinates'

    if mediator.map and coordinates
      @addCoords coordinates
    else if coordinates

      @subscribeEvent 'mapSet', =>
        @addCoords coordinates
        mediator.unsubscribe 'mapSet'
