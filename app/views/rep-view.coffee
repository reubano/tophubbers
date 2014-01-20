config = require 'config'
Momentous = require 'lib/momentous'
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
  forms: mediator.forms

  initialize: (options) =>
    super
    @attr = options.attr
    @id = @model.get 'id'
    mediator.rep_id = @id

    utils.log 'initialize rep-view for ' + @id
    console.log @forms
    console.log options

    @checkOnline().done(@sendForms).done(@fetchForms)
    @delegate 'click', '#network-form-submit', @networkFormSubmit
    @delegate 'click', '#review-form-submit', @reviewFormSubmit
    @subscribeEvent 'dispatcher:dispatch', ->
      utils.log 'rep-view caught dispatcher event'

    for suffix in ['work_data_c', 'feedback_data', 'progress']
      @listenTo @model, "change:cur_#{suffix}", @render

    @listenTo @forms, 'add', -> utils.log 'rep-view caught add event'
    @listenTo @forms, 'request', @viewRequest
    @listenTo @forms, 'change', @render
    @listenTo @forms, 'sync', @success
    @listenTo @forms, 'error', @failWhale
    @listenTo @forms, 'invalid', @failWhale

  render: =>
    super
    utils.log 'rendering rep view for ' + @id
    @renderDatepicker '#review-datepicker'
    @renderDatepicker '#network-datepicker'

  renderDatepicker: (selection) =>
    momentous = new Momentous @.$ selection
    momentous.init()
    # utils.log momentous

  objectify: (form) ->
    data = @.$(form).serializeArray()
    keys = ((y for x,y of z)[0] for z in data)
    values = ((y for x,y of z)[1] for z in data)
    obj = _.object(keys, values)
    _.extend obj, {rep: @id, manager: 'name', form: form[1..]}

  checkOnline: -> $.ajax config.api_forms

  sendForms: =>
    utils.log 'sending form changes to server'
    @forms.syncDirtyAndDestroyed()

  fetchForms: =>
    if not mediator.synced
      utils.log 'fetching form changes from server'
      @forms.fetch
        data:
          'results_per_page=' + config.rpp + '&q=' + JSON.stringify
            "order_by": [{"field": "date", "direction": "desc"}]
            "filters": [
              {"name": 'form', "op": 'eq', "val": "network-form"}]
    else
      utils.log 'forms already synced'

  networkFormSubmit: =>
    json = @objectify('#network-form')
    utils.log 'saving network form data...'
    utils.log json
    @forms.create json

  reviewFormSubmit: =>
    json = @objectify('#review-form')
    utils.log 'saving review form data...', 'info'
    utils.log json
    @forms.create json

  viewRequest: (model, textStatus, res) ->
    utils.log 'rep-view caught request event'
    utils.log model, false
    utils.log res, false

  success: (model, textStatus, res) =>
    utils.log 'rep-view caught sync event'
    if model.get('id')
      utils.log 'successfully posted form #' + model.get('id') + '!'
      @render()
      @$('#success-modal').modal()
    else
      utils.log 'successfully synced forms'
      mediator.synced = true

    utils.log model, false
    utils.log res, false

  failWhale: (model, textStatus, res) =>
    if model.get('id')
      utils.log 'failed to post form for ' + model.get('id')
      @$('#fail-modal').modal()
    else
      utils.log 'failed to fetch forms'

    utils.log model, false
    utils.log res, false
