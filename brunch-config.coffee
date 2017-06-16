exports.config =
  # See http://brunch.io/#documentation for docs.
  watcher: usePolling: true
  notifications: false

  plugins:
    coffeelint:
      pattern: /^app\/.*\.coffee$/
      options:
        indentation:
          value: 2
          level: "error"

  files:
    javascripts:
      joinTo:
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': /^(vendor|bower_components)/
        'test/javascripts/test.js': /^test(\/|\\)(?!vendor)/
        'test/javascripts/test-vendor.js': /^test(\/|\\)(?=vendor)/

    stylesheets:
      joinTo:
        'stylesheets/app.css': /^(?!test)/
        'test/stylesheets/test.css': /^test/
      order:
        after: ['vendor/styles/normalize.css']

    templates:
      joinTo: 'javascripts/app.js'
