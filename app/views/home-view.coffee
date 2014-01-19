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
  forms: mediator.forms
  reps: mediator.reps

  initialize: ->
    @subscribeEvent 'dispatcher:dispatch', @render
    @setFormData()
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

  setFormData: =>
    csv = @json2CSV @forms.toJSON()
    mediator.download.form_href = "data:text/csv;charset=utf-8," + escape csv

  setRepData: =>
    keys1 = [
      'first_name', 'last_name', 'id', 'score', 'airtel', 'called',
      'created', 'ward']
    keys2 = [
      'cur_feedback_data', 'cur_progress', 'prev_feedback_data',
      'prev_progress',]

    collection = []
    for model in @reps.toJSON()
      obj = {}
      res = _.pick model, keys1

      for key, value of _.pick model, keys2
        for k, v of value
          obj[key + '_' + k] = v

      collection.push _.extend res, obj
      collection

    csv = @json2CSV collection
    mediator.download.rep_href = "data:text/csv;charset=utf-8," + escape csv
