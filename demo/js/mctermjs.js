angular.module('mcTermJs', ['btford.socket-io', 'mcDraggable']).factory('mcSocket', ['socketFactory', function(socketFactory) {
  return socketFactory({
    prefix: 'mcTerm'
  });
}]).service("terminal", ['$rootScope', '$document', '$window', 'mcSocket', function($rootScope, $document, $window, mcSocket) {
  return {
    resetCss: null,
    resetTerminal: {
      cols: 80,
      rows: 24
    },
    createTerminal: function() {
      return new Terminal({
        cols: 80,
        rows: 24,
        useStyle: true,
        screenKeys: true,
        cursorBlink: true
      });
    },
    open: function(element) {
      if (this.terminal) {
        return;
      }
      this.terminal = this.createTerminal();
      mcSocket.emit('terminal:create');
      mcSocket.on('terminal:created', (function(_this) {
        return function() {
          _this.terminal.open(element);
          return _this.write('\x1b[31mWelcome to term.js!\x1b[m\r\n');
        };
      })(this));
      mcSocket.on('data', (function(_this) {
        return function(data) {
          return _this.write(data);
        };
      })(this));
      mcSocket.on('disconnect', (function(_this) {
        return function() {
          return _this.write('\r\n\x1b[31mSocket disconnected!\x1b[m\r\n');
        };
      })(this));
      mcSocket.on('forced:disconnect', (function(_this) {
        return function() {
          return _this.write('\r\n\x1b[31mForced disconnect from server! Reload Page!\x1b[m\r\n');
        };
      })(this));
      mcSocket.on('reconnecting', (function(_this) {
        return function(number) {
          return _this.write("\x1b[31mTrying to reconnect socket! Attempt:" + number + "\x1b[m\r\n");
        };
      })(this));
      mcSocket.on('reconnect', (function(_this) {
        return function() {
          return _this.write("\x1b[31mSuccessfully reconnected to socket\x1b[m\r\n");
        };
      })(this));
      return this.terminal.on('data', function(data) {
        return mcSocket.emit('data', data);
      });
    },
    close: function() {
      mcSocket.emit('terminal:destroy');
      mcSocket.removeAllListeners('terminal:created');
      mcSocket.removeAllListeners('data');
      mcSocket.removeAllListeners('disconnect');
      mcSocket.removeAllListeners('forced:disconnect');
      mcSocket.removeAllListeners('reconnecting');
      mcSocket.removeAllListeners('reconnect');
      return this.terminal = null;
    },
    scroll: function(rows) {
      return this.terminal.scrollDisp(rows);
    },
    resize: function(x, y) {
      x = (x * this.terminal.cols) | 0;
      y = (y * this.terminal.rows) | 0;
      this.terminal.resize(x, y);
      return mcSocket.emit('resize', x, y);
    },
    maximize: function() {
      var x, y;
      this.resetTerminal.cols = this.terminal.cols;
      this.resetTerminal.rows = this.terminal.rows;
      console.log(this.terminal.element.offsetWidth);
      console.log(this.terminal.element.offsetHeight);
      x = $window.innerWidth / this.terminal.element.offsetWidth;
      y = $window.innerHeight / this.terminal.element.offsetHeight;
      console.log(x, y);
      return this.resize(x, y);
    },
    reset: function() {
      this.terminal.resize(this.resetTerminal.cols, this.resetTerminal.rows);
      return mcSocket.emit('resize', this.resetTerminal.cols, this.resetTerminal.rows);
    },
    setResetCss: function(css) {
      return this.resetCss = {
        top: css.top + "px",
        left: css.left + "px",
        right: null,
        bottom: null
      };
    },
    write: function(text) {
      if (!this.terminal) {
        return;
      }
      if (!text) {
        return;
      }
      return this.terminal.write(text);
    },
    focus: function() {
      return this.terminal.focus();
    },
    hasFocus: function() {
      if (!this.terminal) {
        return false;
      }
      return !this.terminal.focus;
    }
  };
}]).directive('mcTerminalOpener', ['$document', '$templateCache', '$compile', 'terminal', function($document, $templateCache, $compile, terminal) {
  return {
    restrict: "A",
    scope: {
      options: "="
    },
    link: function(scope, el, attrs) {
      scope.terminal = {
        isOpen: false,
        isHidden: false
      };
      return el.on('click', function() {
        var draggableContainer, terminalContainer;
        if (scope.terminal.isOpen) {
          scope.terminal.isHidden = false;
          terminal.focus();
          return scope.$apply();
        }
        draggableContainer = $templateCache.get('app/terminalContainer.tpl.html');
        draggableContainer = $compile(draggableContainer)(scope);
        $document.find('body').append(draggableContainer);
        terminalContainer = draggableContainer.find('mc-terminal');
        terminal.open(terminalContainer[0]);
        terminalContainer.on('DOMMouseScroll mousewheel', function(ev) {
          if (ev.type === 'DOMMouseScroll') {
            return terminal.scroll(ev.detail > 0 ? -5 : 5);
          } else {
            return terminal.scroll(ev.wheelDeltaY > 0 ? -5 : 5);
          }
        });
        return scope.terminal.isOpen = true;
      });
    }
  };
}]).directive('mcTerminalMaximize', ['$document', 'terminal', function($document, terminal) {
  return {
    restrict: "E",
    template: "<div class='terminal-control'>O</div>",
    link: function(scope, el, attrs) {
      return el.on('click', function() {
        var terminalContainer;
        terminalContainer = $document.find('mc-terminal-container');
        terminal.setResetCss(terminalContainer[0].getBoundingClientRect());
        terminal.maximize();
        scope.maximized = true;
        return terminalContainer.css({
          top: 0,
          left: 0,
          bottom: 0,
          right: 0
        });
      });
    }
  };
}]).directive('mcTerminalResize', ['$document', 'terminal', function($document, terminal) {
  return {
    restrict: "E",
    template: "<div class='terminal-resize'></div>",
    link: function(scope, el, attrs) {
      var mousemove, mouseup, newHeight, newWidth, startPos, terminalContainer;
      startPos = null;
      terminalContainer = null;
      newWidth = null;
      newHeight = null;
      el.on('mousedown', function(ev) {
        terminalContainer = $document.find('mc-terminal-container');
        terminalContainer.css({
          opacity: 0.6
        });
        startPos = terminalContainer[0].getBoundingClientRect();
        ev.preventDefault();
        $document.on('mousemove', mousemove);
        return $document.on('mouseup', mouseup);
      });
      mousemove = function(ev) {
        var x, y;
        x = ev.pageX;
        y = ev.pageY;
        newWidth = Math.floor(startPos.width + (x - startPos.left - startPos.width));
        newHeight = Math.floor(startPos.height + (y - startPos.top - startPos.height));
        $document.find('mc-terminal').children().css({
          height: (newHeight - 40) + "px"
        });
        return terminalContainer.css({
          width: newWidth + "px",
          height: newHeight + "px"
        });
      };
      return mouseup = function() {
        var x, y;
        x = newWidth / startPos.width;
        y = newHeight / (startPos.height - 35);
        terminal.resize(x, y);
        $document.find('mc-terminal').children().css({
          height: null
        });
        terminalContainer.css({
          opacity: 1,
          height: null,
          width: null
        });
        $document.unbind('mousemove', mousemove);
        return $document.unbind('mouseup', mouseup);
      };
    }
  };
}]).directive('mcTerminalReset', ['$document', 'terminal', function($document, terminal) {
  return {
    restrict: "E",
    template: "<div class='terminal-control'>O</div>",
    link: function(scope, el, attrs) {
      return el.on('click', function() {
        var terminalContainer;
        terminalContainer = $document.find('mc-terminal-container');
        terminal.reset();
        scope.maximized = false;
        return terminalContainer.css(terminal.resetCss);
      });
    }
  };
}]).directive('mcTerminalClose', ['$document', 'terminal', function($document, terminal) {
  return {
    restrict: "E",
    template: "<div class='terminal-control'>X</div>",
    link: function(scope, el, attrs) {
      return el.on('click', function() {
        terminal.close();
        $document.find('mc-terminal-container').remove();
        return scope.terminal.isOpen = false;
      });
    }
  };
}]).directive('mcTerminalHide', ['$document', 'terminal', function($document, terminal) {
  return {
    restrict: "E",
    template: "<div class='terminal-control'>_</div>",
    link: function(scope, el, attrs) {
      el.on('click', function() {
        return scope.$apply(function() {
          return scope.terminal.isHidden = !scope.terminal.isHidden;
        });
      });
      return scope.$watch("terminal.isHidden", function() {
        var height;
        height = scope.terminal.isHidden ? "30px" : null;
        return $document.find('mc-terminal-container').css({
          height: height
        });
      });
    }
  };
}]);

angular.module('mcDraggable', []).service('drag', ['$document', function($document) {
  var drag;
  return drag = {
    el: null,
    pos: null,
    move: (function(_this) {
      return function(e) {
        var newX, newY;
        newY = e.clientY - drag.pos.top;
        newX = e.clientX - drag.pos.left;
        return drag.el.css({
          top: newY + 'px',
          left: newX + 'px'
        });
      };
    })(this),
    start: function(left, top) {
      drag.pos = {
        left: left,
        top: top
      };
      $document.on('mousemove', drag.move);
      return $document.on('mouseup', drag.end);
    },
    end: function() {
      $document.unbind('mousemove', drag.move);
      return $document.unbind('mouseup', drag.end);
    }
  };
}]).directive('mcDraggable', ['drag', function(drag) {
  return {
    restrict: 'A',
    scope: {},
    link: function(scope, el, attr) {
      return drag.el = el;
    }
  };
}]).directive('mcDraggableHandler', ['drag', function(drag) {
  return {
    restrict: 'A',
    link: function(scope, el) {
      return el.on('mousedown', function(e) {
        e.preventDefault();
        return drag.start(e.clientX - drag.el[0].offsetLeft, e.clientY - drag.el[0].offsetTop);
      });
    }
  };
}]);
