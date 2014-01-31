config = require 'config'
Chaplin = require 'chaplin'
View = require 'views/graph-view'
template = require 'views/templates/rep'
utils = require 'lib/utils'

module.exports = class RepView extends View
  autoRender: true
  region: 'content'
  className: 'span12'
  template: template

  initialize: (options) =>
    super
    @login = @model.get 'login'
    utils.log 'initialize rep-view for ' + @login
    @subscribeEvent 'dispatcher:dispatch', ->
      utils.log 'rep-view caught dispatcher event'

    for suffix in ['work_data_c', 'feedback_data', 'progress']
      @listenTo @model, "change:cur_#{suffix}", @render

  render: =>
    super
    utils.log 'rendering rep-view for ' + @login
