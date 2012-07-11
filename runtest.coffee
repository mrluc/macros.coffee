CS = require 'coffee-script'
MS = require './macros.coffee'

p = console.log
p MS
t = (o)-> p MS.compile o

# So we've traced that one bug down.
# But now I think that the different 'eval'
# contexts between node 0.7-pre and the
# more modern versions is a problem.
# eval, by default, happens in the global
# context in the more recent nodes, but
# not back in 0.7-pre ... so all of those 'global'
# functions ... may now have to be instance
# functions for good. :(
# Hell. Just do that? Then they're available
# uniformly, on ms.deepcopy for instance, and
# passed into each macro ...

require './lib/core_macros.coffee'

p 'yo'
t 'quote -> 33333333333'
process.exit()
#quote_macro = """
#mac quote ({args: [{body}, soak...]}, parent, macros) ->
#  key = gensym()
#  (root.quotes ?= {})[key] = body
#  CS.nodes "deepcopy root.quotes['" + key + "']"
#mac Q (n,parent,MacroScriptInstance)->
#  quote -> gotta reference quote, just to be sure it gets compiled
#  MacroScriptInstance.macros.quote.compiled n
#"""

quote_usage = "quote -> hey"

#fex = (n)-> n.expressions[0]
# TODO: dummy, in-order.
tests =
  defs: -> t '2+2'
  info: ->
    MS.compile "mac info (n, p, m) -> console.log m; CS.nodes '2'"
    t "info 2"

  quote: ->
    t 'quote -> hey there, homie'
    p fn.toString() for k, fn of process.quotes
    # aha, to use quote, we need to be within another macro
    t "mac log2 (n)-> quote -> 222"
    t "log2 1"
    p 'trying short Q quote'
    t "mac shortq (n)-> Q -> 2"
    t "shortq 3"

  backquote: ->
    t "mac tbq (n)-> backquote {a:1}, quote -> x = y[a]"
    # TODO: support 'x = y.a' ... backquote analog to issue of .macros
    t "tbq()"
    t "mac loop_bq (n)-> backquote {a:'OOO', i:'ZZZ'}, Q -> a for a, i in [1,2,3,4]"
    t "loop_bq()"

  macex_russian_dolls: ->
    # macroexpansion flows 'DOWN' an ast,
    #  and quote is implemented as a macro, so the contents of the quote
    #  are saved away and macroexpanded with each macro call.
    t """
      mac zzz (n,p,m)->
        @n ?= 0
        @n++
        console.log @ is m
        backquote {n: @n}, Q -> n
      """
    t "mac zzy (n)-> Q -> zzz(); zzz();"
    t "mac zzx (n)-> Q -> zzy(); zzy();"
    t "zzx()"
    # TODO: aha, lines ending with ;; instead of ;. What's ast look like?

  macro_defining_macros: ->
    t """
      mac make_fub (n)->
        quote ->
          mac fub (n)->
            quote -> 'IT IS WORKING!'"""
    t "make_fub()"
    t "fub()"

  BQmacro: ->
    t "mac short_bq (n)-> x=999; BQ -> $x = a"
    t "short_bq()"


p "going to perform tests..."

for name, test of tests
  p "------ #{ name }"
  test()
p "yay done"
#