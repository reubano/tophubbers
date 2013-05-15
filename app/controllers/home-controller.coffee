Chaplin = require 'chaplin'
Controller = require 'controllers/base/controller'
Navbar = require 'models/navbar'
HomeView = require 'views/home-view'

module.exports = class HomeController extends Controller
  adjustTitle: 'Home'
  model: Chaplin.mediator.navbar

  show: (params) =>
    @view = new HomeView {@model}
