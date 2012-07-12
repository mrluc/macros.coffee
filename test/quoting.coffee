cs = require 'coffee-script'
p = console.log
compile = (o)-> o.compile bare:on if o.compile?

console.log "doing something, hopefully without errors."

test 'ordinary coffeescript still works', ->
  ok 2+2

test 'the macroscript object is present and works', (ms, fn)->
  # so, that's weird. It's passing me the fn instead of the instance
  ok ms
  ok ms.compile
  ok ms.compile "mac info (n, p, m) -> console.log m; CS.nodes '2'"

test 'requiring quote macro works', (ms)->
  require './lib/core_macros.coffee' # hmmm, no. That's too late for
  ok q = ms.eval 'quote -> 2+2'
  ok compile(q) is cs.compile('2+2', bare:on)

test 'short quote works', ->
  mac shortq (n)-> Q -> 2
  ok shortq(3) is 2

test 'backquote works', ->
  y = [0,12]
  mac tbq (n)->
    backquote {a:1}, quote -> x = y[a]
  # TODO: support 'x = y.a' ... similar to issue of .macros, probably distinct
  tbq()
  ok x is 12
  mac loopbq (n)-> backquote {a:'OOO', i:'ZZZ'}, Q -> a for a, i in [1,2,3,4]
  z = loopbq()
  sum = (a)-> n=0; n+=val for val in a; n
  ok sum(z) is sum [1,2,3,4]

test 'deeply nested macros expand in the right order', ->
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

test 'short BQ macro', (m)->

  # what does it take to recognize and replace a thing.THISPLACE?
  ns = quote -> thing.x
  nodewalk ns, (n)->
    p n.name?.value

  mac bq (nodes, parent, Macros) ->
    nodes = nodes.args?[0]?.body
    return (quote -> throw 'bq macro called without expressions') unless nodes?.isEmpty

    # TODO: WHOA gensyms are kicking our butt. Think about bq'd gensyms and come back.
    # okay so they gave us a block of code, we prefix it with args defs...
    args_gs = gensym 'args'

    # TODO: no gensyms atm because currently bq doesn't support REPLACE.REPLACE;
    # the first replacement is made, destroying the child 'access' object.
    result = Q -> args = {}

    # build up args defs -- note -- as below, we want args to be gensym'd :P
    nodewalk nodes, (n)->
      get_name = (n)-> node_name(n) ? n.base?.value
      name = get_name n
      if name?[0] is '$'
        vname = name[1..name.length-1]
        result.push backquote {name: name, vname: vname}, Q ->
          args.name = vname

    # note -- we're double-quoting because we want a quote in the output
    result.push backquote (nodes: nodes), Q ->
      backquote(args, quote -> nodes)
    p result.compile()
    result
  mac shortbq (n)->
    a = 2
    b = 3
    result = bq -> $a + $b # we actually want this to use gensyms
    # ie
    #   g_args = {}
    #   g_args.g_12 = a
    #   backquote g_args, Q -> g_012_a + ...
    # But we're truly limited by backquote, since we need both THING.OTHERTHING to
    # be replaced
    p "so close"
    p result.compile(bare:on) # aha, this is still 'return 2+3' -- why RETURN?
    # ah -- it was previously turned into a return being the last statement.
    # that's a pita, I suppose; with a closure wrapper there'd be no problem ...
    # if a node is a Return, you could just set it with its .expression, right?
    result
  # actually, this might just be a consequence of our hacking the 'body' section
  # out of the input ... although I think that's what we do for the quote macro too (yes),
  # so ... stumped again.

  p m.compile "x = 1; shortbq(); x=2"
