View = require 'views/base/view'
template = require 'views/templates/home'
Chaplin = require 'chaplin'
utils = require 'lib/utils'

module.exports = class HomePageView extends View
  mediator = Chaplin.mediator

  autoRender: true
  template: template
  region: 'content'
  className: 'span12'
  reps: mediator.reps

  initialize: (options) =>
    @subscribeEvent 'dispatcher:dispatch', @render
    @setRepData()

  json2CSV: (json) ->
    str = ''
    line = ''

    for index of json[0]
      value = index + ""
      line += '"' + value.replace(/"/g, '""') + '",'

    line = line[...-1]
    str += line + '\r\n'
    num = json.length - 1

    for i in [0..num]
      line = ''

      for index of json[i]
        value = json[i][index] + ""
        line += '"' + value.replace(/"/g, '""') + '",'

      line = line.slice(0, -1)
      str += line + '\r\n'

    str

  setRepData: =>
    keys = [
      'id', 'name', 'login', 'followers', 'public_repos', 'public_gists',
      'email', 'location']

    collection = []
    for model in @reps.toJSON()
      obj = {}
      res = _.pick model, keys
      collection.push _.extend res, obj
      collection

    csv = @json2CSV collection
    mediator.download.rep_href = "data:text/csv;charset=utf-8," + escape csv
