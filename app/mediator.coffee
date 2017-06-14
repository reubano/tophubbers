mediator = module.exports = Chaplin.mediator

mediator.setActive = (title) ->
  mediator.active = title
  console.log "set activeNav: #{mediator.active}"
  mediator.publish 'activeNav', title

mediator.setSynced = ->
  console.log "I'm synced!!"
  mediator.synced = true
  mediator.publish 'synced'

mediator.setUrl = (url) ->
  console.log "mediator.url is #{url}"
  mediator.url = url
