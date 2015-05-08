angular.module 'mcTermJs', [
  'btford.socket-io'
  'mcDraggable'
]


.factory 'mcSocket', (socketFactory) ->
  socketFactory prefix: 'mcTerm'

.service "terminal", ($document, mcSocket) ->

  terminal: new Terminal
    cols: 80,
    rows: 24,
    useStyle: true,
    screenKeys: true,
    cursorBlink: true


  open: (element) ->
    mcSocket.emit 'terminal:create'

    mcSocket.on 'terminal:created', =>
      @terminal.open element

      @terminal.write '\x1b[31mWelcome to term.js!\x1b[m\r\n'

    mcSocket.on 'data', (data) =>
      @terminal.write data

    mcSocket.on 'disconnect', =>
      @terminal.destroy()

    @terminal.on 'data', (data) ->
      mcSocket.emit 'data', data

  close: ->
    mcSocket.emit 'close'

    mcSocket.removeAllListeners 'data'
    mcSocket.removeAllListeners 'terminal:created'
    mcSocket.removeAllListeners 'disconnect'

    @terminal.destroy()


  write: (text) ->
    return unless text
    @terminal.write text


.directive 'mcTerminalOpener', ($document, $templateCache, $compile, terminal) ->
  restrict: "A"
  scope:
    options: "="
  link: (scope, el, attrs) ->
    el.on 'click', ->
      draggableContainer = $templateCache.get 'terminalContainer.tpl.html'
      draggableContainer = $compile(draggableContainer)(scope)
      $document.find('body').append draggableContainer

      terminalContainer =  draggableContainer.find('mc-terminal')
      terminal.open terminalContainer[0]


.directive 'mcTerminalClose', ($document, terminal) ->
  restrict: "E"
  template: "<div class='terminal-close'>X</div>"
  link: (scope, el, attrs) ->
    el.on 'click', ->
      terminal.close()
      $document.find('mc-terminal-container').remove()
