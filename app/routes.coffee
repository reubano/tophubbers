module.exports = (match) ->
  match '', 'home#show'
  match 'logout', 'auth#logout'
  match 'login', 'auth#login'

  # Dynamic checklist of reps ordered and categorized by progress
  match 'tocall', 'tocall#index'

  # Cumulative working month graph sorted by employee num
  match 'graphs', 'reps#index'

  # Data table of reps ordered by progress
  # Mint like progress bars summarizing data table for each rep
  match 'progress', 'progress#index'

  # Cumulative working month graph
  # Customer feedback score
  # Data table of progress
  # Mint like progress bars
  match 'reps/:id', 'reps#show'
