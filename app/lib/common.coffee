Common =
  getParent: (login) -> "##{login}.view .chart"
  getSelection: (login) -> @getParent(login) + ' svg'

module.exports = Common
