angular.module('mcTermJs', ['btford.socket-io', 'mcDraggable']).factory('mcSocket', ['socketFactory', function(socketFactory) {
  return socketFactory({
    prefix: 'mcTerm'
  });
}]).service("terminal", ['$rootScope', '$document', 'mcSocket', function($rootScope, $document, mcSocket) {
  return {
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
          return _this.terminal.write('\x1b[31mWelcome to term.js!\x1b[m\r\n');
        };
      })(this));
      mcSocket.on('data', (function(_this) {
        return function(data) {
          return _this.terminal.write(data);
        };
      })(this));
      mcSocket.on('disconnect', (function(_this) {
        return function() {
          return _this.terminal.write('\r\n\x1b[31mSocket disconnected!\x1b[m\r\n');
        };
      })(this));
      mcSocket.on('forced:disconnect', (function(_this) {
        return function() {
          return _this.terminal.write('\r\n\x1b[31mForced disconnect from server! Reload Page!\x1b[m\r\n');
        };
      })(this));
      mcSocket.on('reconnecting', (function(_this) {
        return function(number) {
          return _this.terminal.write("\x1b[31mTrying to reconnect socket! Attempt:" + number + "\x1b[m\r\n");
        };
      })(this));
      mcSocket.on('reconnect', (function(_this) {
        return function() {
          return _this.terminal.write("\x1b[31mSuccessfully reconnected to socket\x1b[m\r\n");
        };
      })(this));
      return this.terminal.on('data', function(data) {
        return mcSocket.emit('data', data);
      });
    },
    close: function() {
      mcSocket.emit('terminal:destroy');
      mcSocket.removeAllListeners('data');
      mcSocket.removeAllListeners('terminal:created');
      mcSocket.removeAllListeners('disconnect');
      return this.terminal = null;
    },
    write: function(text) {
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
        return scope.terminal.isOpen = true;
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
        console.log(scope.terminal.isHidden);
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

angular.module("mcTermJs").run(["$templateCache", function($templateCache) {$templateCache.put("app/terminalContainer.tpl.html","<mc-terminal-container class=\"draggable-container\" mc-draggable>\n  <div class=\"draggable-header draggable-handler\" mc-draggable-handler>\n    <div class=\"terminal-title\">Apollon Debug-Console</div>\n    <mc-terminal-close></mc-terminal-close>\n    <mc-terminal-hide></mc-terminal-hide>\n  </div>\n  <mc-terminal class=\"draggable-content\"></mc-terminal>\n  <div class=\"draggable-footer\"></div>\n</mc-terminal-container>\n");}]);