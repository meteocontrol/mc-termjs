gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)

compile     = require "gulp-compile-js"
bowerFiles  = require('main-bower-files')


gulp.task "scripts", ->
  sources =[
    "!./src/**/*.spec.coffee"
    "!./src/demo.coffee"
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
  .pipe gulp.dest("./build/js")
  .pipe gulp.dest("./demo/js")


gulp.task "compile-templates", ->
  sources =[
    "./src/**/*.tpl.html"
  ]
  gulp.src(sources)
  .pipe(
    plugins.angularTemplatecache
      module: 'mcTermJs'
  )
  .pipe gulp.dest("./build/js")
  .pipe gulp.dest("./demo/js")


gulp.task "build-demo-scripts", ->
  sources =[
    "./src/demo.coffee"
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



gulp.task "deploy-client", ->
  sources =[
    "./public/**/*"
  ]
  gulp.src(sources)
  .pipe gulp.dest("./build/")



gulp.task "watch-source-files", ->
  sources = [
    "./src/**/*.coffee"
  ]
  gulp.watch sources, ["scripts", "build-demo-scripts", "karma-unit"]


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
  "watch-templates"
  "start-server"
]

gulp.task "build", [
  "scripts"
  "compile-templates"
  "build-demo-scripts"
  "karma-unit"
  "build-vendorjs"
]


gulp.task "deploy", [
  "build"
  "deploy-client"
]
