config = require 'config'
Chaplin = require 'chaplin'
View = require 'views/graph-view'
template = require 'views/templates/rep'
utils = require 'lib/utils'

module.exports = class RepView extends View
  mediator = Chaplin.mediator

  autoRender: true
  region: 'content'
  className: 'span12'
  template: template

  initialize: (options) =>
    super
    @attr = options.attr
    @id = @model.get 'id'
    @login = @model.get 'login'
    mediator.rep_id = @id

    utils.log 'initialize rep-view for ' + @login
    console.log options

    @subscribeEvent 'dispatcher:dispatch', ->
      utils.log 'rep-view caught dispatcher event'

    for suffix in ['work_data_c', 'feedback_data', 'progress']
      @listenTo @model, "change:cur_#{suffix}", @render

  render: =>
    super
    utils.log 'rendering rep-view for ' + @login
