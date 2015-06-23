gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)


gulp.task "watch-source-files", ->
  sources = [
    "./src/**/*.coffee"
  ]
  gulp.watch sources, ["build-scripts", "build-demo-scripts", "karma-unit"]


gulp.task "watch-styles", ->
  sources = [
    "./src/**/*.css"
  ]
  gulp.watch sources, ["build-styles"]

gulp.task "watch-templates", ->
  sources = [
    "./src/**/*.tpl.html"
  ]
  gulp.watch sources, ["compile-templates"]


gulp.task "watch", ["watch-source-files", "watch-styles", "watch-templates"]

