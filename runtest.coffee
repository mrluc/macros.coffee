CS = require 'coffee-script'
MS = MacroScript = require('./test').instance

p = console.log

quote_macro = """
mac quote ({args: [{body}, soak...]}, parent, macros) ->
  key = gensym()
  (root.quotes ?= {})[key] = body
  CS.nodes "deepcopy root.quotes['" + key + "']"
mac Q (n,parent,MacroScriptInstance)->
  quote -> gotta reference quote, just to be sure it gets compiled
  MacroScriptInstance.macros.quote.compiled n
"""

quote_usage = "quote -> hey"

#fex = (n)-> n.expressions[0]

t = (o)-> p MS.compile o
tests =
  defs: ->

    p 'creating new MacroScript...'
    t '2+2'

    t quote_macro

  info: ->
    MS.compile "mac info (n, p, m) -> console.log m; CS.nodes '2'"
    t "info 2"

  usage: ->

    t "mac two (n)-> CS.nodes '2'"
    p 'compileabobs?'
    usage_text = 'two 3'
    usage_nodes = CS.nodes usage_text
    usage = usage_nodes.expressions[0]
    p MS.macros.two.compiled usage
    p 'so, it works -- but I bet he no recognize u bro'
    p MS.macros.two.recognize usage
    p 'or -- i bet the thinks you are expanded if we use CS.nodes directly'
    p MS.all_expanded usage_nodes #aha!
    p 'but not when we cherry-pick the expression. well, what IS getting passed in is_exp? '
    p MS.all_expanded usage
    p "yayno?"
    t usage_text

  quote: ->
    t 'quote -> hey there, homie'
    p fn.toString() for k, fn of process.quotes
    # aha, to use quote, we need to be within another macro. good idea.
    t "mac log2 (n)-> quote -> 222"
    t "log2 1"

  backquote: ->
    t "mac tbq (n)-> backquote {a:1}, quote -> x = y[a]"
    # TODO: support 'quote -> x = y.a'
    t "tbq()"
    t "mac short_bq (n)-> BQ {a:1}, Q -> x = a"
    t "short_bq()"
    t "mac loop_bq (n)-> BQ {a:'OOO', i:'ZZZ'}, Q -> a for a, i in [1,2,3,4]"
    t "loop_bq()"

  utils: ->


p "going to perform tests..."

for name, test of tests
  p "------ #{ name }"
  test()
