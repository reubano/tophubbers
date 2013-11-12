CollectionView = require 'views/base/collection-view'
template = require 'views/templates/visits'
View = require 'views/visit-view'
utils = require 'lib/utils'

module.exports = class ProgressesView extends CollectionView
  itemView: View
  autoRender: true
  listSelector: '#visit-list'
  region: 'content'
  className: 'span12'
  template: template

  initialize: (options) =>
    super
    @subscribeEvent 'loginStatus', @render
    @subscribeEvent 'loggingIn', @render
    @subscribeEvent 'userUpdated', @render
    @subscribeEvent 'dispatcher:dispatch', ->
      utils.log 'visits-view caught dispatcher event'
    # @listenTo @model,'all', @renderCheckbox

  render: =>
    super
    utils.log 'rendering visits view'
    @collection.sort()
