var McTerminal, app, chalk, express, http, io, log, mcTerminal, path, port, server;

path = require('path');

http = require('http');

express = require('express');

io = require('socket.io');

chalk = require('chalk');

log = require('./log');

McTerminal = require('./mcTerminal');

process.title = 'term.js';

app = express();

server = http.createServer(app);

app.use(express["static"](path.join(__dirname + '/../public')));

mcTerminal = new McTerminal(app);

port = 1337;

server.listen(port);

log("Express listening on port: " + (chalk.green.bold(port)));

io = io.listen(server, {
  log: true
});

io.sockets.on('connection', function(sock) {
  sock.on('terminal:create', function() {
    mcTerminal.create(sock);
    return sock.emit('terminal:created');
  });
  return sock.on('disconnect', function() {
    return mcTerminal.destroy();
  });
});
