#!/usr/bin/env coffee
path       = require 'path'
http       = require 'http'
express    = require 'express'
io         = require 'socket.io'

chalk      = require 'chalk'
log        = require './log'

enableDestroy = require('server-destroy')

McTerminal = require './McTerminal'

messenger = require 'messenger'


class McTerminalHttpServer

  port: if process.env.NODE_ENV == 'production' then 80 else 8000
  retryTimeout: 5000

  constructor: ->
    @messageOverTCPListener = messenger.createListener 2342

    @app = express()
    @server = http.Server @app
    enableDestroy @server

    @socketIo = io @server

    @mcTerminal = new McTerminal @app

    @register("NodeProcessErrorHandler")
    @register("StaticFolder")
    @register("HttpErrorHandler")
    @register("ShutdownOnMessage")
    @register("SocketListeners")
    @register("ServerListeners")


  register: (module) ->
    try
      @["register#{module}"]()
    catch err
      log chalk.cyan.bold module + chalk.red " failed!"
      console.trace chalk.red.bold "Error while registering module #{chalk.cyan.bold module}\n", chalk.red err
      process.exit 0
    log chalk.cyan module + chalk.green " registered!"


  registerStaticFolder: ->
    @app.use express.static path.join __dirname + '/../public'


  registerHttpErrorHandler: ->
    @server.on 'error', (err) =>
      if err.code == 'EADDRINUSE'
        log  "Port #{chalk.cyan.bold @port} in use! Retry in #{chalk.cyan.bold @retryTimeout / 1000}s"
        @retryToListen()
      else
        log  "#{chalk.bold.red 'Server Error'}: #{err.code}"


  registerNodeProcessErrorHandler: =>
    process.on "uncaughtException", (err) =>
      console.trace 'Exception ', err


  registerShutdownOnMessage: ->
    @messageOverTCPListener.on 'McTerminal:Shutdown', (message, data) =>
      log chalk.cyan "Got Shutdown Signal. Init Server shutdown!"
      @destroy.call @, =>
        log chalk.cyan "Going into check mode!"
        @retryToListen()
        message.reply mcTerminal: 'shutdown'


  registerSocketListeners: ->
    @socketIo.sockets.on 'connection', (sock) =>
      log chalk.green "Socket-Client connected. #{ chalk.bold.cyan sock.id}"

      sock.on 'terminal:create', =>
        @mcTerminal.create sock
        sock.emit 'terminal:created'


      sock.on 'disconnect', =>
        log chalk.green "Socket-Client disconnected. #{ chalk.bold.cyan sock.id}"
        @mcTerminal.destroy()


  registerServerListeners: ->
    @server.on 'listening', =>
      log "Http-Server #{chalk.green.bold 'Listening'} on port: #{chalk.cyan.bold @port}"


  retryToListen: ->
    setTimeout =>
      @listen()
    , @retryTimeout


  listen: ->
    @server.listen @port


  destroy: (callback) ->
    @socketIo.sockets.sockets.map (sock) ->
      sock.emit "forced:disconnect"
      sock.disconnect()

    @server.destroy ->
      log  "#{chalk.green 'Http-Server Closed!'}"
      callback()


server = new McTerminalHttpServer()
server.listen()
