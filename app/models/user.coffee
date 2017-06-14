Model = require 'models/base/model'
config = require 'config'
utils = require 'lib/utils'

# User model. Main application model. Stores user data.
# Inherits from Chaplin model which inherits from Backbone model.
module.exports = class User extends Model
  # Corresponds to stuff like https://api.github.com/users/paulmillr.
  # Used when model fetch and save are done.

  initialize: (options) =>
    super
    login = @get('login') ? options
    # utils.log "initializing #{login} user model"
    @url = "#{config.api_base}/#{@get 'login'}?access_token=#{config.api_token}"
