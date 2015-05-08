#!/usr/bin/env node
path       = require 'path'
http       = require 'http'
express    = require 'express'
io         = require 'socket.io'

chalk      = require 'chalk'
log        = require './log'

McTerminal = require './mcTerminal'


process.title = 'term.js'

app = express()
server = http.createServer(app)

app.use express.static path.join __dirname + '/../public'

mcTerminal = new McTerminal app

port = 1337

server.listen port


log "Express listening on port: #{chalk.green.bold port}"

io = io.listen server, log: true



io.sockets.on 'connection', (sock) ->
  sock.on 'terminal:create', ->
    mcTerminal.create sock
    sock.emit 'terminal:created'

  sock.on 'disconnect', ->
    mcTerminal.destroy()
