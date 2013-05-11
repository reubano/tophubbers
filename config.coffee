exports.config =
  # See http://brunch.readthedocs.org/en/latest/config.html for documentation.
  # modules:
  #   wrapper: false

  # conventions:
  #   vendor: /^vendor.nvd3/

  files:
    javascripts:
      joinTo:
        'javascripts/app.js': /^app/
        # 'javascripts/vendor.js': /^vendor.(?!nvd3)/
        'javascripts/vendor.js': /^vendor/
        # 'javascripts/nvd3.js' : /^vendor.nvd3/
        'test/javascripts/test.js': /^test[\\/](?!vendor)/
        'test/javascripts/test-vendor.js': /^test[\\/](?=vendor)/
      order:
        # Files in `vendor` directories are compiled before other files
        # even if they aren't specified in order.before.
        before: [
          'vendor/scripts/console-polyfill.js',
          'vendor/scripts/jquery.js',
          'vendor/scripts/underscore.js',
          'vendor/scripts/backbone-1.0.0.js',
          'vendor/scripts/moment.min.js',
          'vendor/scripts/backbone-localStorage.js',
          'vendor/scripts/bootstrap.js',
          'vendor/scripts/fabric.js',
          'vendor/scripts/modernizr.js',
        ]

    stylesheets:
      joinTo:
        'stylesheets/app.css': /^(app|vendor)/
        'test/stylesheets/test.css': /^test/
      order:
        before: [
          'vendor/styles/bootstrap.css',
          'vendor/styles/bootstrap-body.css',
          'vendor/styles/bootstrap-responsive.css'
          'vendor/styles/nv.d3.css',
        ]
        after: ['vendor/styles/helpers.css']

    templates:
      joinTo: 'javascripts/app.js'
