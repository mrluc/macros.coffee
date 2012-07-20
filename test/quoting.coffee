# Some basic tests of the quote macro, the backquote function,
# and macro-defining macros, which ideally would be just another
# application of quote.

cs = require 'coffee-script'
p = console.log
compile = (o)-> o.compile bare:on if o.compile?

test 'ordinary coffeescript still works', ->
  ok 2+2

test 'the macroscript object is present and works', (ms, fn)->
  # so, that's weird. It's passing me the fn instead of the instance
  ok ms
  ok ms.compile
  ok ms.compile "mac info (n, p, m) -> console.log m; CS.nodes '2'"

test 'requiring quote macro works', (ms)->
  p process.cwd()
  require './core_macros.coffee' # hmmm, no. That's too late for
  ok q = ms.eval 'quote -> 2+2'
  ok compile(q) is cs.compile('2+2', bare:on)

test 'short quote works', ->
  mac shortq (n)-> Q -> 2
  ok shortq(3) is 2

test 'backquote works', ->
  y = [0,12]
  mac tbq (n)-> backquote {a:1}, quote -> x = y[a]
  # TODO: support 'x = y.a' ... similar to issue of .macros, probably distinct
  tbq()
  ok x is 12
  mac loopbq (n)-> backquote {a:'OOO', i:'ZZZ'}, Q -> a for a, i in [1,2,3,4]
  z = loopbq()
  sum = (a)-> n=0; n+=val for val in a; n
  ok sum(z) is sum [1,2,3,4]

test 'dot-backquotes: backquote works for the `y` in `x.y`', (ms)->
  x = {}
  x.z = ["bodiddly"]
  mac bqworks (n)->
    backquote {y: 'z'}, quote -> (x.y)
  ok bqworks() is x.z

test 'russian dolls: deeply nested macros expand in the right order', ->
    # if macroexpansion happens out of order this will be expanded < 4x, or not at all
    aaa = 0
    mac zzz (n,p,m)->
      @n ?= 0
      @n++
      global.aaa = @n
      backquote {n: @n}, Q -> aaa = n

    mac zzy (n)-> Q -> zzz(); zzz()
    mac zzx (n)-> Q -> zzy(); zzy()
    zzx()     # TODO: aha, lines ending with ;; instead of ;. What's ast look like?
    ok aaa is 4

test 'macro_defining_macros', (ms) ->
    # TODO: mac-generating-macros error out because of .length of undefined
    # in Code.paramNames, referencing Param.names loop of name.objects.
    # ... I don't have time to track that down, so ...
    ms.eval """
      mac make_fub (n) ->
        quote ->
          mac fub (n) ->
            quote -> 'hamburger'
      make_fub()
    """
    ms.eval "ok 'hamburger' is fub()"

test 'macro_defining_macros workaround 1', (ms)->
  # Not good form; just demonstrating that, since we have access
  # to the macros object at macexp-time, there shouldn't
  # be any *real* obstacle to macro-defining macros.
  mac make_foo (n,p,m) ->
    name = 'foo'
    m.macros[name] =
      recognize: (n)-> name if name is node_name(n)
      compiled: (n)->
        quote -> "hamburger"
    Q -> 2+2
  make_foo()
  ok 'hamburger' is foo()
