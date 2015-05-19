gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)

compile     = require "gulp-compile-js"
bowerFiles  = require('main-bower-files')


gulp.task "build-scripts", ->
  sources =[
    "!./src/**/*.spec.coffee"
    "!./src/app/demo.coffee"
    "./src/**/*.coffee"
  ]
  gulp.src(sources)
  .pipe(
    compile
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
    compile
      coffee:
        bare: true
    )
  .pipe gulp.dest("./demo/js")


gulp.task "build-vendorjs", ->
  gulp.src(bowerFiles())
  .pipe(plugins.concat("vendor.js"))
  .pipe gulp.dest("./demo/js")



gulp.task "deploy-app", ->
  sources =[
    "./demo/js/mctermjs.js"
    "./demo/js/templates.js"
  ]
  gulp.src(sources)
  .pipe(plugins.concat("mctermjs.js"))
  .pipe gulp.dest("./build/")

  sources =[
    "./demo/css/**/*.css"
  ]
  gulp.src(sources)
  .pipe gulp.dest("./build/")


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


gulp.task "karma-unit", ->
  gulp.src('./idontexist')
  .pipe(plugins.karma
    configFile: './karma-unit.coffee'
    action: 'run'
  )
  .on 'error', (err) ->

gulp.task "start-server", ->
  plugins.developServer.listen path: './server/server.coffee'



gulp.task "default", [
  "build"
  "watch-source-files"
  "watch-styles"
  "watch-templates"
  "start-server"
]

gulp.task "build", [
  "build-scripts"
  "build-styles"
  "copy-index"
  "compile-templates"
  "build-demo-scripts"
  "karma-unit"
  "build-vendorjs"
]


gulp.task "deploy", [
  "build"
  "deploy-app"
]
