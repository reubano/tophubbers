# Tophubbers

This is an HTML5 single page application, built with
[Brunch](https://brunch.io) and [Chaplin](https://chaplinjs.org).

## Installation

Clone this repo 

    git clone https://github.com/reubano/tophubbers.git

## Getting started

### Setup (if you don't have them):

[Node.js](https://nodejs.org) (on OS X)

    sudo port install node
    
or 

    brew install node
    
[Brunch](https://brunch.io)

    npm install -g brunch
    
[Bower](https://bower.io/)
    
    npm install -g bower
    
[CoffeeScript](http://coffeescript.org/)

    npm install -g coffee-script

### Development versions

```bash
$ node --version
v4.4.5
$ npm --version
5.0.3
$ brunch --version
2.10.9
$ bower --version
1.8.0
$ coffee --version
CoffeeScript version 1.12.6
```

### Running

Install both node and bower dependencies

    npm install
  

Watch the project with continuous rebuild. This will also launch HTTP server with [pushState](https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history).

    brunch watch --server
    
## Other commands

Watch the project with continuous rebuild, but don't serve it

    brunch watch
    
Build minified assets

    brunch build --production
    
Launch a production express server

    coffee server.cofee


## License

Tophubbers is distributed under the [MIT License](http://opensource.org/licenses/MIT).
