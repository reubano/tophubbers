module.exports = (match) ->
  match '', 'home#show'
  match 'logout', 'auth#logout'
  match 'login', 'auth#login'
  match 'refresh', 'graphs#refresh'
  match 'refresh/rep/:id', 'rep#refresh'

  # Dynamic checklist of reps ordered and categorized by progress
  match 'tocall', 'tocall#index'

  # Cumulative working month graph sorted by employee num
  match 'graphs', 'graphs#index'

  # Data table of reps ordered by progress
  # Mint like progress bars summarizing data table for each rep
  match 'progress', 'progress#index'

  # Cumulative working month graph
  # Customer feedback score
  # Data table of progress
  # Mint like progress bars
  match 'rep/:id', 'rep#show'
