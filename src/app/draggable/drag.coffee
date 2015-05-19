angular.module 'mcDraggable', []

.service 'drag', ($document)->
  drag =
    el: null
    pos: null
    move: (e) =>
      newY = e.clientY - drag.pos.top
      newX = e.clientX - drag.pos.left
      drag.el.css
        top:  newY + 'px'
        left: newX + 'px'
    start: (left, top) ->
      drag.pos =
        left: left
        top: top

      $document.on 'mousemove', drag.move
      $document.on 'mouseup', drag.end

    end: ->
      $document.unbind 'mousemove', drag.move
      $document.unbind 'mouseup', drag.end


.directive 'mcDraggable', (drag) ->
    restrict: 'A'
    scope: {}
    link: (scope, el, attr) ->
      drag.el = el


.directive 'mcDraggableHandler', (drag) ->
  restrict: 'A'
  link: (scope, el) ->
    el.on 'mousedown', (e) ->
      e.preventDefault()
      drag.start e.clientX - drag.el[0].offsetLeft, e.clientY - drag.el[0].offsetTop

