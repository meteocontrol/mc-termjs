angular.module 'mcTermJs', [
  'mcDraggable'
]

.service "terminal", ($rootScope, $document, $window, mcSocket) ->
  resetCss: null
  resetTerminal:
    cols: 80
    rows: 24

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

  scroll: (rows) ->
    @terminal.scrollDisp rows


  resize: (x ,y) ->
    x = (x * @terminal.cols) | 0;
    y = (y * @terminal.rows) | 0;

    @terminal.resize x, y
    mcSocket.emit 'resize',  x, y


  maximize: ->
    @resetTerminal.cols = @terminal.cols
    @resetTerminal.rows = @terminal.rows

    console.log @terminal.element.offsetWidth
    console.log @terminal.element.offsetHeight

    x = $window.innerWidth / @terminal.element.offsetWidth
    y = $window.innerHeight / @terminal.element.offsetHeight

    console.log x, y

    @resize x, y

  reset: ->
    @terminal.resize @resetTerminal.cols, @resetTerminal.rows
    mcSocket.emit 'resize',  @resetTerminal.cols, @resetTerminal.rows


  setResetCss: (css) ->
    @resetCss =
      top:    "#{css.top}px"
      left:   "#{css.left}px"
      right:  null
      bottom: null


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


      terminalContainer.on 'DOMMouseScroll mousewheel', (ev) ->
        if ev.type == 'DOMMouseScroll'
          terminal.scroll if ev.detail > 0 then -5 else 5
        else
          terminal.scroll if ev.wheelDeltaY > 0 then -5 else 5

      scope.terminal.isOpen = true


.directive 'mcTerminalMaximize', ($document, terminal) ->
  restrict: "E"
  template: "<div class='terminal-control'>O</div>"
  link: (scope, el, attrs) ->
    el.on 'click', ->
      terminalContainer = $document.find('mc-terminal-container')

      terminal.setResetCss terminalContainer[0].getBoundingClientRect()

      terminal.maximize()
      scope.maximized = true

      terminalContainer.css
        top: 0
        left: 0
        bottom: 0
        right:  0


.directive 'mcTerminalResize', ($document, terminal) ->
  restrict: "E"
  template: "<div class='terminal-resize'></div>"
  link: (scope, el, attrs) ->

    startPos          = null
    terminalContainer = null
    newWidth          = null
    newHeight         = null

    el.on 'mousedown', (ev) ->
      terminalContainer = $document.find('mc-terminal-container')
      terminalContainer.css
        opacity: 0.6

      startPos = terminalContainer[0].getBoundingClientRect()

      ev.preventDefault()
      $document.on 'mousemove', mousemove
      $document.on 'mouseup', mouseup


    mousemove = (ev) ->
      x = ev.pageX
      y = ev.pageY

      newWidth = Math.floor startPos.width + (x - startPos.left - startPos.width)
      newHeight = Math.floor startPos.height + (y - startPos.top - startPos.height)

      $document.find('mc-terminal').children().css
        height: "#{newHeight-40}px"


      terminalContainer.css
        width: "#{newWidth}px"
        height: "#{newHeight}px"

    mouseup = ->

      x = newWidth / startPos.width
      y = newHeight / (startPos.height - 35)

      terminal.resize x, y

      $document.find('mc-terminal').children().css
        height: null

      terminalContainer.css
        opacity: 1
        height: null
        width: null

      $document.unbind 'mousemove', mousemove
      $document.unbind 'mouseup', mouseup


.directive 'mcTerminalReset', ($document, terminal) ->
  restrict: "E"
  template: "<div class='terminal-control'>O</div>"
  link: (scope, el, attrs) ->
    el.on 'click', ->
      terminalContainer = $document.find('mc-terminal-container')

      terminal.reset()
      scope.maximized = false
      terminalContainer.css terminal.resetCss



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
      height = if scope.terminal.isHidden then "30px" else null
      $document.find('mc-terminal-container').css height: height
