gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)

bowerFiles  = require "main-bower-files"


gulp.task "build-scripts", ->
  sources =[
    "!./src/**/*.spec.coffee"
    "!./src/app/demo.coffee"
    "./src/**/*.coffee"
  ]
  gulp.src(sources)
  .pipe(
    plugins.compileJs
      coffee:
        bare: true
  )
  .pipe(plugins.ngAnnotate( single_quotes: true ))
  .pipe(plugins.concat("mctermjs.js"))
  .pipe gulp.dest("./demo/js")


gulp.task "build-styles", ->
  sources =[
    "./src/**/*.css"
  ]
  gulp.src(sources)
  .pipe(plugins.concat("mctermjs.css"))
  .pipe gulp.dest("./demo/css")


gulp.task "copy-index", ->
  sources =[
    "./src/index.html"
  ]
  gulp.src(sources)
  .pipe gulp.dest("./demo/")


gulp.task "compile-templates", ->
  sources =[
    "./src/**/*.tpl.html"
  ]
  gulp.src(sources)
  .pipe(
    plugins.angularTemplatecache
      module: 'mcTermJs'
  )
  .pipe gulp.dest("./demo/js")


gulp.task "build-demo-scripts", ->
  sources =[
    "./src/app/demo.coffee"
  ]
  gulp.src(sources)
  .pipe(
    plugins.compileJs
      coffee:
        bare: true
  )
  .pipe gulp.dest("./demo/js")


gulp.task "build-vendorjs", ->
  gulp.src(bowerFiles())
  .pipe(plugins.concat("vendor.js"))
  .pipe gulp.dest("./demo/js")
