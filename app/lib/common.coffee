Common =
  getParent: (login='login') -> "##{login}.view .chart"
  getSelection: (login='login') -> @getParent(login) + ' svg'

module.exports = Common
