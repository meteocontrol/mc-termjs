gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)

compile     = require "gulp-compile-js"
bowerFiles  = require('main-bower-files')

chalk       = require "chalk"
path        = require "path"
term        = require('term.js')

io          = require('socket.io')


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
  .pipe gulp.dest("./public/js")


gulp.task "compile-templates", ->
  sources =[
    "./src/**/*.tpl.html"
  ]
  gulp.src(sources)
  .pipe(
    plugins.angularTemplatecache
      module: 'mcTermJs'
  )
  .pipe gulp.dest("./public/js")


gulp.task "demoScripts", ->
  sources =[
    "./src/demo.coffee"
  ]
  gulp.src(sources)
  .pipe(
    compile
      coffee:
        bare: true
    )
  .pipe gulp.dest("./public/js")


gulp.task "vendorJS", ->
  gulp.src(bowerFiles())
  .pipe(plugins.concat("vendor.js"))
  .pipe gulp.dest("./public/js")



gulp.task "deploy-server", ->
  sources =[
    "./server/**/*.coffee"
  ]
  gulp.src(sources)
  .pipe(
    compile
      coffee:
        bare: true
  )
  .pipe gulp.dest("./build/server")

gulp.task "deploy-client", ->
  sources =[
    "./public/**/*"
  ]
  gulp.src(sources)
  .pipe gulp.dest("./build/public")



gulp.task "watchSourceFiles", ->
  sources = [
    "./src/**/*.coffee"
  ]
  gulp.watch sources, ["scripts", "demoScripts", "karma-unit"]


gulp.task "watchTemplates", ->
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



gulp.task "default", [
  "build"
  "watchSourceFiles"
  "watchTemplates"
]

gulp.task "build", [
  "scripts"
  "compile-templates"
  "demoScripts"
  "karma-unit"
  "vendorJS"
]


gulp.task "deploy", [
  "build"
  "deploy-server"
  "deploy-client"
]
