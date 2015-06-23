gulp        = require "gulp"
gutil       = require "gulp-util"
plugins     = require("gulp-load-plugins")(lazy: false)


gulp.task "deploy-app",["build"], ->
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


inc = (importance) ->
  gulp.src([
    './package.json'
    './bower.json'
  ])
  .pipe(plugins.bump(type: importance))
  .pipe(gulp.dest('./'))
  .pipe(plugins.git.commit('bumps package version'))
  .pipe(plugins.filter('package.json'))
  .pipe plugins.tagVersion()


gulp.task 'deploy-patch', ["deploy-app"], ->
  inc 'patch'

gulp.task 'deploy-feature', ["deploy-app"], ->
  inc 'minor'

gulp.task 'deploy-release', ["deploy-app"],  ->
  inc 'major'
