angular.module "mcTermJsDemo", [
  'btford.socket-io'
  'mcTermJs'
]

.factory 'mcSocket', (socketFactory) ->
  socketFactory prefix: 'mcTerm'

.controller "mcTermJsDemoCtrl", ($scope, terminal) ->

