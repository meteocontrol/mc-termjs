angular.module("mcTermJs").run(["$templateCache", function($templateCache) {$templateCache.put("app/terminalContainer.tpl.html","<mc-terminal-container class=\"draggable-container\" mc-draggable>\n  <div class=\"draggable-header draggable-handler\" mc-draggable-handler>\n    <div class=\"terminal-title\">Apollon Debug-Console</div>\n    <mc-terminal-close></mc-terminal-close>\n    <mc-terminal-hide></mc-terminal-hide>\n  </div>\n  <mc-terminal class=\"draggable-content\"></mc-terminal>\n  <div class=\"draggable-footer\"></div>\n</mc-terminal-container>\n");}]);