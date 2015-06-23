path = require 'path'
require('fs').readdirSync(__dirname).forEach (file) ->
  return if file == 'index.coffee'
  module.exports[path.basename(file, '.coffee')] = require(path.join(__dirname, file))
