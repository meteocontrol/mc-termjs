pty       = require 'pty.js'
fs        = require 'fs'
terminal  = require 'term.js'
chalk     = require 'chalk'

log       = require './log'


class McTerminal
  shell: process.env.SHELL or 'sh'

  constructor: (@app) ->
    @_registerMiddleware()

  _registerMiddleware: ->
    @app.use terminal.middleware()
    @app.use (req, res, next) ->
      setHeader = res.setHeader
      res.setHeader = (name) ->
        switch name
          when 'Cache-Control', 'Last-Modified', 'ETag'
            return
        setHeader.apply res, arguments

      next()


  _addTerminalListener: ->
    @terminal.on 'data', (data) =>
      @socketIo.emit 'data', data


  _addSocketListener: ->
    @socketIo.on 'data', (data) =>
      @terminal.write data

    @socketIo.on 'terminal:destroy', =>
      @destroy()

  _removeSocketListener: ->
    @socketIo.removeAllListeners 'data'
    @socketIo.removeAllListeners 'terminal:destroy'

  create: (@socketIo) ->
    @terminal = pty.fork @shell, [],
      #name: if fs.existsSync('/usr/share/terminfo/x/xterm-256color') then 'xterm-256color' else 'xterm'
      cols: 80
      rows: 24
      cwd: process.env.HOME

    @_addTerminalListener()
    @_addSocketListener()

    log "#{chalk.bold.green 'Created Terminal'}: #{chalk.bold.cyan @shell} shell with pty pid: #{chalk.bold.cyan @terminal.pid}"

  destroy: ->
    return unless @terminal
    log "#{chalk.bold.red 'Destroyed Terminal'}: #{chalk.bold.cyan @shell} shell with pty pid: #{chalk.bold.cyan @terminal.pid}"
    @terminal.kill 9
    @terminal.destroy()
    @terminal = null
    @_removeSocketListener()


module.exports = McTerminal
