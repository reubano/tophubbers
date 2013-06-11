Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
View = require 'views/home-view'

module.exports = class HomeController extends Controller
  adjustTitle: 'Ongeza Home'
  model: Chaplin.mediator.navbar

  show: (params) =>
    @view = new View {@model}
