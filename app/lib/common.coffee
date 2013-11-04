_ = _ ? require 'underscore'

Common =
  getParent: (options) ->
    attr = options?.attr ? 'attr'
    id = options?.id ? 'id'
    chart_class = 'chart-' + attr[..2]
    "##{id}.view .#{chart_class}"

  getSelection: (options) -> @getParent(options) + ' svg'
  getChartData: (attr, d, id) ->
    if not d then return console.log "no #{attr} found for #{id}"
    console.log "#{id}: generating #{attr} chart data..."

    endRows = []
    durRows = []

    for obj in d.rows
      end_val = parseFloat obj.start.toFixed(3)
      dur_val = parseFloat obj.duration.toFixed(3)
      endRows.push {label: obj.date, value: end_val}
      durRows.push {label: obj.date, value: dur_val}

    if d.missing
      endMiss = (label: obj, value: 0 for obj in d.missing)
      durMiss = (label: obj, value: 0 for obj in d.missing)
    else
      endMiss = []
      durMiss = []

    endValues = endRows.concat endMiss
    durValues = durRows.concat durMiss

    endValues = _.sortBy endValues, 'label'
    durValues = _.sortBy durValues, 'label'

    data = [
      {key: 'End', values: endValues},
      {key: 'Duration', values: durValues}]

    JSON.stringify data

module.exports = Common
