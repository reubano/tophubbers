Controller = require 'controllers/base/controller'
View = require 'views/tocalls-view'
utils = require 'lib/utils'

module.exports = class TocallsController extends Controller
  adjustTitle: 'Github Call List'
  res: ['rep_info', 'score']

  initialize: => utils.log 'initialize tocalls-controller'
  comparator: (model) -> - model.get 'score_sort'

  index: (params) =>
    refresh = params?.refresh ? false
    expired = params?.expired ? true

    if refresh or @collection.length is 0
      if refresh then utils.log 'refreshing data...'
      else utils.log 'no collection so fetching all data...'
      @fetchData @res
    else if expired
      utils.log 'fetching expired data...'
      @fetchExpiredData @res

    @collection.comparator = @comparator
    @view = new View {@collection}
