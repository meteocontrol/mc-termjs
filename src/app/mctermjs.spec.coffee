describe 'mcTermJs', ->

  someMock = {}
  beforeEach angular.mock.module ($provide) ->
    $provide.value 'someMock', someMock
    return

  beforeEach angular.mock.module 'mcTermJs'

  beforeEach inject (_$rootScope_, _$compile_, _$httpBackend_) ->
    $rootScope    = _$rootScope_
    $compile      = _$compile_
    $httpBackend  = _$httpBackend_

  it 'should do something',  ->
    expect(true).to.be.true
