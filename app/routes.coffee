module.exports = (match) ->
  match '', 'home#show'
  match 'logout', 'auth#logout'
  match 'auth-callback/', 'auth#callback'

  # Dynamic checklist of reps ordered and categorized by progress
  match 'tocall', 'tocall#show'

  # Cumulative working month graph sorted by employee num
  match 'graphs', 'graphs#show'

  # Data table of reps ordered by progress
  # Mint like progress bars summarizing data table for each rep
  match 'progress', 'progress#index'

  # Cumulative working month graph
  # Customer feedback score
  # Data table of progress
  # Mint like progress bars
  match 'progress/:id', 'progress#show'
