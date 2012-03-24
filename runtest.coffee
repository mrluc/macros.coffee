CS = require 'coffee-script'
MS = MacroScript = require('./test')

p = console.log

quote_macro = """
mac quote ({args: [{body}, soak...]}, parent, macros) ->
  key = gensym()
  (root.quotes ?= {})[key] = body
  CS.nodes "deepcopy root.quotes['" + key + "']"
"""

quote_usage = "quote -> hey"

#fex = (n)-> n.expressions[0]

tests =
  defs: ->

    p 'creating new MacroScript...'
    p MS.compile '2+2'

    p MS.compile quote_macro

  info: ->
    MS.compile "mac info (n, p, m) -> console.log m; CS.nodes '2'"
    p MS.compile "info 2"

  usage: ->

    p MS.compile "mac two (n)-> CS.nodes '2'"
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
    p MS.compile usage_text

  quote: ->
    p MS.compile 'quote -> hey there, homie'
    p fn.toString() for k, fn of process.quotes
    # aha, to use quote, we need to be within another macro. good idea.
    p MS.compile "mac log2 (n)-> quote -> 222"
    p MS.compile "log2 1"

p "going to perform tests..."

for name, test of tests
  p "------ #{ name }"
  test()