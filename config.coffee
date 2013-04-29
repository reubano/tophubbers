exports.config =
  # See http://brunch.readthedocs.org/en/latest/config.html for documentation.
  files:
    javascripts:
      joinTo:
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': /^vendor/
        'test/javascripts/test.js': /^test[\\/](?!vendor)/
        'test/javascripts/test-vendor.js': /^test[\\/](?=vendor)/
      order:
        # Files in `vendor` directories are compiled before other files
        # even if they aren't specified in order.before.
        before: [
          'vendor/scripts/console-polyfill.js',
          'vendor/scripts/jquery-1.9.1.js',
          'vendor/scripts/lodash.min.js',
          'vendor/scripts/moment.min.js',
          'vendor/scripts/handlebars.min.js',
          'vendor/scripts/console-helper.js',
          'vendor/scripts/backbone-0.9.2.js',
          'vendor/scripts/backbone-localStorage.js',
          'vendor/scripts/bootstrap.js',
          'vendor/scripts/base.js',
          'vendor/scripts/nvd3/lib/d3.v2.js',
          'vendor/scripts/nvd3/nv.d3.js',
          'vendor/scripts/nvd3/src/utils.js',
          'vendor/scripts/nvd3/src/tooltip.js',
          'vendor/scripts/nvd3/src/models/legend.js',
          'vendor/scripts/nvd3/src/models/axis.js',
          'vendor/scripts/nvd3/src/models/multiBarHorizontal.js',
          'vendor/scripts/nvd3/src/models/multiBarHorizontalChart.js',
          'vendor/scripts/stream_layers.js',
        ]
        after: [
          'app/scripts/gen-chart.js',
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
        ]
        after: ['vendor/styles/helpers.css']

    templates:
      joinTo: 'javascripts/app.js'
