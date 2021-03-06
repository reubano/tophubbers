module.exports = (match) ->
  match '', 'home#show'
  match 'home', 'home#show'

  # Dynamic checklist of reps ordered and categorized by progress
  match 'tocalls', 'tocalls#index'
  match 'tocalls/:refresh', 'tocalls#index'

  # Cumulative working month graph sorted by employee num
  match 'graphs', 'graphs#index'
  match 'graphs/:ignore_cache', 'graphs#index'
  match 'graphs/:ignore_cache/:refresh', 'graphs#index'

  # Data table of reps ordered by employee num summarizing house visits
  match 'visits', 'visits#index'
  match 'visits/:refresh', 'visits#index'

  # Cumulative working month graph
  # Customer feedback score
  # Data table of progress
  # Mint like progress bars
  match 'rep/:login', 'rep#show'
  match 'rep/:login/:ignore_cache', 'rep#show'
  match 'rep/:login/:ignore_cache/:refresh', 'rep#show'
