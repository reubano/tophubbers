_ = _ ? require 'underscore'

Common =
  getParent: (login='login') -> "##{login}.view .chart"
  getSelection: (login='login') -> @getParent(login) + ' svg'
  convertData: (raw, login) ->
    console.log "generating #{login}'s chart data..."
    endRows = []
    durRows = []
    dur_val = 5

    _.each raw, (model) ->
      created = model['created_at']
      date = moment(created).format('MM-DD-YYYY')
      time = moment(created).format('HH:mm:ss').split(':')
      start = (time[0] * 60) + (time[1] * 1) + (time[2] / 60)
      end_val = parseFloat start.toFixed(3)
      endRows.push {label: date, value: end_val}
      durRows.push {label: date, value: dur_val}

    data = [{key: 'End', values: endRows}, {key: 'Duration', values: durRows}]


module.exports = Common
