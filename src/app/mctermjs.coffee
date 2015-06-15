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

      @write '\x1b[31mWelcome to term.js!\x1b[m\r\n'

    mcSocket.on 'data', (data) =>
      @write data

    mcSocket.on 'disconnect', =>
      @write '\r\n\x1b[31mSocket disconnected!\x1b[m\r\n'

    mcSocket.on 'forced:disconnect', =>
      @write '\r\n\x1b[31mForced disconnect from server! Reload Page!\x1b[m\r\n'

    mcSocket.on 'reconnecting', (number) =>
      @write "\x1b[31mTrying to reconnect socket! Attempt:#{number}\x1b[m\r\n"

    mcSocket.on 'reconnect', =>
      @write "\x1b[31mSuccessfully reconnected to socket\x1b[m\r\n"

    @terminal.on 'data', (data) ->
      mcSocket.emit 'data', data

  close: ->
    mcSocket.emit 'terminal:destroy'

    mcSocket.removeAllListeners 'terminal:created'
    mcSocket.removeAllListeners 'data'
    mcSocket.removeAllListeners 'disconnect'
    mcSocket.removeAllListeners 'forced:disconnect'
    mcSocket.removeAllListeners 'reconnecting'
    mcSocket.removeAllListeners 'reconnect'

    @terminal = null


  write: (text) ->
    return unless @terminal
    return unless text
    @terminal.write text

  focus: ->
    @terminal.focus()

  hasFocus: ->
    return false unless @terminal
    !@terminal.focus

.directive 'mcTerminalOpener', ($document, $templateCache, $compile, terminal) ->
  restrict: "A"
  scope:
    options: "="
  link: (scope, el, attrs) ->
    scope.terminal =
      isOpen: false
      isHidden: false

    el.on 'click', ->
      if scope.terminal.isOpen
        scope.terminal.isHidden = false
        terminal.focus()
        return scope.$apply()

      draggableContainer = $templateCache.get 'app/terminalContainer.tpl.html'
      draggableContainer = $compile(draggableContainer)(scope)
      $document.find('body').append draggableContainer

      terminalContainer =  draggableContainer.find('mc-terminal')
      terminal.open terminalContainer[0]

      scope.terminal.isOpen = true



.directive 'mcTerminalClose', ($document, terminal) ->
  restrict: "E"
  template: "<div class='terminal-control'>X</div>"
  link: (scope, el, attrs) ->
    el.on 'click', ->
      terminal.close()
      $document.find('mc-terminal-container').remove()
      scope.terminal.isOpen = false


.directive 'mcTerminalHide', ($document, terminal) ->
  restrict: "E"
  template: "<div class='terminal-control'>_</div>"
  link: (scope, el, attrs) ->

    el.on 'click', ->
      scope.$apply ->
        scope.terminal.isHidden = !scope.terminal.isHidden

    scope.$watch "terminal.isHidden", ->
      console.log scope.terminal.isHidden
      height = if scope.terminal.isHidden then "30px" else null
      $document.find('mc-terminal-container').css height: height
