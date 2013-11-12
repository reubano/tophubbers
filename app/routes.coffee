module.exports = (match) ->
  match '', 'home#show'
  match 'home', 'home#show'
  match 'home/:refresh', 'home#show'
  match 'logout', 'auth#logout'
  match 'login', 'auth#login'

  # Dynamic checklist of reps ordered and categorized by progress
  match 'tocalls', 'tocalls#index'
  match 'tocalls/:refresh', 'tocalls#index'

  # Cumulative working month graph sorted by employee num
  match 'graphs', 'graphs#index'
  match 'graphs/:ignore_cache', 'graphs#index'
  match 'graphs/:ignore_cache/:refresh', 'graphs#index'

  # Data table of reps ordered by watch score
  # Mint like progress bars summarizing points for each rep
  match 'progresses', 'progresses#index'
  match 'progresses/:refresh', 'progresses#index'

  # Data table of reps ordered by employee num summarizing house visits
  match 'visits', 'visits#index'
  match 'visits/:refresh', 'visits#index'

  # Cumulative working month graph
  # Customer feedback score
  # Data table of progress
  # Mint like progress bars
  match 'rep/:id', 'rep#show'
  match 'rep/:id/:ignore_cache', 'rep#show'
  match 'rep/:id/:ignore_cache/:refresh', 'rep#show'
