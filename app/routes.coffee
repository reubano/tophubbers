module.exports = (match) ->
  match '', 'home#show'
  match ':login', 'home#show'
  match 'logout', 'auth#logout'
  match 'login', 'auth#login'
  match 'refresh/graphs', 'graphs#refresh'
  match 'refresh/tocalls', 'tocalls#refresh'
  match 'refresh/progresses', 'progresses#refresh'
  match 'refresh/rep/:id', 'rep#refresh'

  # Dynamic checklist of reps ordered and categorized by progress
  match 'tocalls', 'tocalls#index'

  # Cumulative working month graph sorted by employee num
  match 'graphs', 'graphs#index'
  match 'graphs/:ignore_svg', 'graphs#index'

  # Data table of reps ordered by watch score
  # Mint like progress bars summarizing points for each rep
  match 'progresses', 'progresses#index'

  # Cumulative working month graph
  # Customer feedback score
  # Data table of progress
  # Mint like progress bars
  match 'rep/:id', 'rep#show'
  match 'rep/:id/:ignore_svg', 'rep#show'
