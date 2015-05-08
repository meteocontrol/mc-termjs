var McTerminal, chalk, fs, log, pty, terminal;

pty = require('pty.js');

fs = require('fs');

terminal = require('term.js');

chalk = require('chalk');

log = require('./log');

McTerminal = (function() {
  McTerminal.prototype.shell = process.env.SHELL || 'sh';

  function McTerminal(app) {
    this.app = app;
    this._registerMiddleware();
  }

  McTerminal.prototype._registerMiddleware = function() {
    this.app.use(terminal.middleware());
    return this.app.use(function(req, res, next) {
      var setHeader;
      setHeader = res.setHeader;
      res.setHeader = function(name) {
        switch (name) {
          case 'Cache-Control':
          case 'Last-Modified':
          case 'ETag':
            return;
        }
        return setHeader.apply(res, arguments);
      };
      return next();
    });
  };

  McTerminal.prototype._addTerminalListener = function() {
    return this.terminal.on('data', (function(_this) {
      return function(data) {
        return _this.socketIo.emit('data', data);
      };
    })(this));
  };

  McTerminal.prototype._addSocketListener = function() {
    this.socketIo.on('data', (function(_this) {
      return function(data) {
        return _this.terminal.write(data);
      };
    })(this));
    return this.socketIo.on('terminal:destroy', (function(_this) {
      return function() {
        return _this.destroy();
      };
    })(this));
  };

  McTerminal.prototype._removeSocketListener = function() {
    this.socketIo.removeAllListeners('data');
    return this.socketIo.removeAllListeners('terminal:destroy');
  };

  McTerminal.prototype.create = function(socketIo) {
    this.socketIo = socketIo;
    this.terminal = pty.fork(this.shell, [], {
      cols: 80,
      rows: 24,
      cwd: process.env.HOME
    });
    this._addTerminalListener();
    this._addSocketListener();
    return log((chalk.bold.green('Created')) + " " + (chalk.bold.cyan(this.shell)) + " shell with pty pid: " + (chalk.bold.cyan(this.terminal.pid)));
  };

  McTerminal.prototype.destroy = function() {
    if (!this.terminal) {
      return;
    }
    log((chalk.bold.red('Destroyed')) + " " + (chalk.bold.cyan(this.shell)) + " shell with pty pid: " + (chalk.bold.cyan(this.terminal.pid)));
    this.terminal.kill(9);
    this.terminal.destroy();
    this.terminal = null;
    return this._removeSocketListener();
  };

  return McTerminal;

})();

module.exports = McTerminal;
