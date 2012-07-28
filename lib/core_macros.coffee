# macro declaration.
# In the future, we will obviously want macro namespacing.
# Any problems with old-timey namespacing? Like
#
# `"in macros.namespace"` and `"use macros.namespace"` as a nod to CL?
'use macros'

# Quote -- use like:
#
#     ast = quote -> code you want the AST of.
#
# Weep, lisp implementers. Where's your Cons now?!?
mac quote ({args: [{body}]}, p, m) ->
  key = gensym()
  (root.quotes ?= {})[key] = body
  CS.nodes "deepcopy global.quotes['" + key + "']"

# Aliasing ... and programmatic access to other macros generally, right now
# it looks like this. Stinky!
mac Q (n, parent, Macros) ->
  quote -> ref # forces quote to be compiled first
  Macros.macros.quote.compiled n
