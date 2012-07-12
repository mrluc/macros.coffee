

console.log "doing something, hopefully without errors."

test 'ordinary coffeescript still works', ->
  ok 2+2

test 'the macroscript object is present and works', (ms, fn)->
  # so, that's weird. It's passing me the fn instead of the instance
  console.log [ms,fn]
  ok ms
  ok ms.compile
  ok ms.compile "mac info (n, p, m) -> console.log m; CS.nodes '2'"

test 'requiring quote macro works', (ms)->
  require './lib/core_macros.coffee' # hmmm, no. That's too late for
  ok ms.eval 'quote -> 2+2'
