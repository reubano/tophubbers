Chaplin = require 'chaplin'
View = require 'views/base/view'

module.exports = class CollectionView extends Chaplin.CollectionView
  # This class doesn’t inherit from the application-specific View class,
  # so we need to borrow the method from the View prototype:
  getTemplateFunction: View::getTemplateFunction

  initItemView: (model) ->
    new @itemView
      model: model
      refresh: @options.refresh
      resize: @options.resize
      ignore_cache: @options.ignore_cache
