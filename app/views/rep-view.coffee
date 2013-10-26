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
  user: mediator.users.get(1)
  forms: mediator.forms

  initialize: (options) =>
    super
    @attrs = options.attrs
    @id = @model.get 'id'
    @name = if @user then @user.get 'name' else 'N/A'
    mediator.rep_id = @id

    utils.log 'initialize rep-view for ' + @id
    console.log @forms
    console.log options

    @checkOnline().done(@sendForms).done(@fetchForms)
    @delegate 'click', '#network-form-submit', @networkFormSubmit
    @delegate 'click', '#review-form-submit', @reviewFormSubmit
    @subscribeEvent 'userUpdated', @setUserName
    @subscribeEvent 'rendered:' + @attrs[1], @removeActive
    @subscribeEvent 'loginStatus', @render
    @subscribeEvent 'loggingIn', @render
    @subscribeEvent 'dispatcher:dispatch', ->
      utils.log 'rep-view caught dispatcher event'

    for prefix in ['change:cur_', 'change:prev_']
      @listenTo @model, prefix + 'work_data_c', @render
      @listenTo @model, prefix + 'feedback_data', @render
      @listenTo @model, prefix + 'progress', @render

    @listenTo @forms, 'add', -> utils.log 'rep-view caught add event'
    @listenTo @forms, 'request', @viewRequest
    @listenTo @forms, 'change', @render
    @listenTo @forms, 'sync', @success
    @listenTo @forms, 'error', @failWhale
    @listenTo @forms, 'invalid', @failWhale

  setUserName: (user) =>
    @name = user.get 'name'
    utils.log 'User name is ' + @name

  render: =>
    super
    utils.log 'rendering rep view for ' + @id
    @renderDatepicker '#review-datepicker'
    @renderDatepicker '#network-datepicker'

  removeActive: =>
    # Hack to get the chart to render in the inactive tab
    # http://stackoverflow.com/a/11816438
    chart_class = 'chart-' + @attrs[1][0..2]
    tab = '#' + chart_class + '-cont'
    @$(tab).removeClass 'active'

  renderDatepicker: (selection) =>
    momentous = new Momentous @.$ selection
    momentous.init()
    # utils.log momentous

  objectify: (form) ->
    data = @.$(form).serializeArray()
    keys = ((y for x,y of z)[0] for z in data)
    values = ((y for x,y of z)[1] for z in data)
    obj = _.object(keys, values)
    _.extend obj, {rep: @id, manager: @name, form: form[1..]}

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
