gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)


gulp.task "karma-unit", ->
  gulp.src('./idontexist')
  .pipe(plugins.karma
      configFile: './karma-unit.coffee'
      action: 'run'
  )
  .on 'error', (err) ->
