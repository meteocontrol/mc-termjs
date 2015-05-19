angular.module 'mcTermJs', [
  'btford.socket-io'
  'mcDraggable'
]


.factory 'mcSocket', (socketFactory) ->
  socketFactory prefix: 'mcTerm'

.service "terminal", ($rootScope, $document, mcSocket) ->

  createTerminal: ->
    new Terminal
      cols:         80
      rows:         24
      useStyle:     true
      screenKeys:   true
      cursorBlink:  true


  open: (element) ->
    return if @terminal

    @terminal = @createTerminal()

    mcSocket.emit 'terminal:create'

    mcSocket.on 'terminal:created', =>
      @terminal.open element

      @terminal.write '\x1b[31mWelcome to term.js!\x1b[m\r\n'

    mcSocket.on 'data', (data) =>
      @terminal.write data

    mcSocket.on 'disconnect', =>
      @terminal.write '\r\n\x1b[31mSocket disconnected!\x1b[m\r\n'

    mcSocket.on 'forced:disconnect', =>
      @terminal.write '\r\n\x1b[31mForced disconnect from server! Reload Page!\x1b[m\r\n'

    mcSocket.on 'reconnecting', (number) =>
      @terminal.write "\x1b[31mTrying to reconnect socket! Attempt:#{number}\x1b[m\r\n"

    mcSocket.on 'reconnect', =>
      @terminal.write "\x1b[31mSuccessfully reconnected to socket\x1b[m\r\n"

    @terminal.on 'data', (data) ->
      mcSocket.emit 'data', data

  close: ->
    mcSocket.emit 'terminal:destroy'

    mcSocket.removeAllListeners 'data'
    mcSocket.removeAllListeners 'terminal:created'
    mcSocket.removeAllListeners 'disconnect'


    @terminal = null


  write: (text) ->
    return unless text
    @terminal.write text


.directive 'mcTerminalOpener', ($document, $templateCache, $compile, terminal) ->
  restrict: "A"
  scope:
    options: "="
  link: (scope, el, attrs) ->
    el.on 'click', ->
      draggableContainer = $templateCache.get 'app/terminalContainer.tpl.html'
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
