gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)

gulp.task "start-server", ->
  plugins.developServer.listen path: './server/server.coffee'
