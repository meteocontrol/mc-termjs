require "./gulpTasks"

gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)


gulp.task "default", plugins.sequence "build", "watch", "start-server"


gulp.task "build", plugins.sequence [
    "build-scripts"
    "build-styles"
    "copy-index"
    "compile-templates"
    "build-demo-scripts"
  ],
  "build-vendorjs",
  "karma-unit"



gulp.task "deploy", [
  "deploy-app"
]
