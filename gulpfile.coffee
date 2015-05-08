gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)

compile     = require "gulp-compile-js"
bowerFiles  = require('main-bower-files')

chalk       = require "chalk"
path        = require "path"
term        = require('term.js')

io          = require('socket.io')

server =
  port: 2342
  livereloadPort: 35729
  basePath: path.join(__dirname)
  _lr: null
  started: null
  start: ->
    console.log chalk.white("Start Express")
    express = require("express")
    app = express()
    app.use require("connect-livereload")()
    app.use term.middleware()
    app.use express.static(server.basePath)

    expressInstance = app.listen server.port

    socketio = io.listen expressInstance

    socketio.on 'connection', (socket) ->

    app.get '/', (req, res) ->
      res.redirect 'demo/'

    console.log chalk.cyan("Express started: #{server.port}")
    server.started = true
    return

  livereload: ->
    server._lr = require("tiny-lr")()
    server._lr.listen server.livereloadPort
    console.log chalk.cyan("Live-Reload on: #{server.livereloadPort}")
    return

  livestart: ->
    server.start()
    server.livereload()
    return

  notify: (event) ->
    fileName = path.relative(server.basePath, event.path)
    server._lr.changed body:
      files: [fileName]
    return


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


gulp.task "livereload", ->
  server.livestart()


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


gulp.task "watchBuildFiles", ->
  sources = [
    "./public/**/*.js"
  ]
  gulp.watch sources, (event) ->
    console.log event
    server.notify event


gulp.task "watchDemoFiles", ->
  sources = [
    "./public/**/*.html"
    "./public/**/*.css"
  ]
  gulp.watch sources, (event) ->
    console.log event
    server.notify event


gulp.task "karma-unit", ->
  gulp.src('./idontexist')
  .pipe(plugins.karma
    configFile: './karma-unit.coffee'
    action: 'run'
  )
  .on 'error', (err) ->

gulp.task "default", [
  "scripts"
  "compile-templates"
  "demoScripts"
  "karma-unit"
  "vendorJS"
  "livereload"
  "watchSourceFiles"
  "watchTemplates"
  "watchBuildFiles"
  "watchDemoFiles"

]
