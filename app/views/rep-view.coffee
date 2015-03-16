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
    @listenTo @model, "change", @render
    @model.fetchData @refresh, 'all'

  render: =>
    super
    utils.log 'rendering rep-view for ' + @login
