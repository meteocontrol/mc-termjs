#!/usr/bin/env coffee
path       = require 'path'
http       = require 'http'
express    = require 'express'
io         = require 'socket.io'

chalk      = require 'chalk'
log        = require './log'

enableDestroy = require('server-destroy')

McTerminal = require './mcTerminal'

messenger = require 'messenger'

listener = messenger.createListener 2342

app = express()
server = http.Server(app)
enableDestroy(server)

socketIo = io(server)


app.use express.static path.join __dirname + '/../public'

mcTerminal = new McTerminal app

port = 8000

retryTimeout = 5000

server.on 'error', (err) ->
  if err.code == 'EADDRINUSE'
    server.close()
    log  "Port #{chalk.cyan.bold port} in use! Retry in #{chalk.cyan.bold retryTimeout / 1000}s"
    setTimeout ->
      startServer()
    ,retryTimeout
  else
    log  "#{chalk.bold.red 'Server Error'}: #{err.code}"

server.on 'listening', ->
  log "Http-Server #{chalk.green.bold 'Listening'}: on port: #{chalk.cyan.bold port}"


listener.on 'ShutdownMcTerminal', (message, data) ->
  log chalk.cyan "Got Shutdown Signal. Init Server shutdown!"
  closeServer ->
    log chalk.cyan "Going into check mode"
    setTimeout ->
      startServer()
    ,retryTimeout

    message.reply mcTerminal: 'shutdown'


do
startServer = ->
  server.listen port


closeServer = (callback) ->
  log chalk.cyan

  socketIo.sockets.sockets.map (sock) ->
    sock.emit "forced:disconnect"
    sock.disconnect()

  server.destroy ->
    log  "#{chalk.green 'Http-Server Closed'}: #{chalk.cyan.bold port}"
    callback()

socketIo.sockets.on 'connection', (sock) ->

  log chalk.green "Socket-Client connected. #{ chalk.bold.cyan sock.id}"

  sock.on 'terminal:create', ->
    mcTerminal.create sock
    sock.emit 'terminal:created'

  sock.on 'disconnect', ->
    log chalk.green "Socket-Client disconnected. #{ chalk.bold.cyan sock.id}"
    mcTerminal.destroy()
