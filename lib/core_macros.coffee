# Quote -- use like: ast = quote -> code you want the AST of.
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

# TODO: BUG WITH HASH LITERALS. Currently they can't be used in quotes.
#   REASON:
#     Comes down to the implementation rf deepcopoy in CoffeeScript. CS uses instanceof
#     a lot in conditionals about nodes, which creates problems mentioned in detail below.
#     only 'real' solution is a 'real' deep copy, one that instantiates the correct types
#     and probably needs to know how to call constructors and such for dif node types.
#
#     Sigh.
#
#   TO REPRODUCE:
#   # eval(ms.instance.compile 'quote -> {a:2}').compile(bare:on)
#
  # Going Inside:
      # m = {instance} = require './macros'
      # require './lib/core_macros.coffee'
      # m.compile 'quote -> a:1'
      #
      # > '\ndeepcopy(global.quotes[\'_g3\']);\n'
      #
      # o = global.quotes._g3
      # d = deepcopy o
      # d.compile()
      #
      # > '(function() {\n\n  ({\n    a: 1: a: 1\n  });\n\n}).call(this);\n'
      #
      # dv = d.unwrap() # gets first expression, I believe, or from within parens.
      # db = dv.base    # Obj constructor, db.compileNode is problem...
      # db.compileNode.toString()
      #
      # it creates Assign objects, whose .compile produces the "k:v" strings.
      #
      # Assign is passed prop, prop, 'object' in each case, so read the code to see...
      # aha.
      # Yeah, it's instanceof. There are two paths that ought to be exclusive but aren't
      # if a node isn't instanceof.
mac BQ (n) ->
  # note to self ... okay, we were going to write a 'prettier' backquote as
  # a macro (remember, it's a function now), but were hampered by the use of
  # object literals in the calls. Well ... TODO, but some thoughts ...
  # The syntax we want, if we're providing a shorter syntax here, is to allow
  #[vars,rest] = n.args
  # weird. a:2 becomes a: 2: a: 2 in the ensuing js ... how?!?
  quote ->
    args = {}
    args.a = 2; args.b = 3
    backquote args, quote ->
      x=a

# 'Current Callback'
#  TODO: UPDATE FOR CURRENT VERSION OF m.c
# If you can decode this, you are a stallion. It's code golf.
#mac cc (n,par)->
#  n_index = (node,parent) ->
#
#  [p_ex, index] = [par.expressions, n_index(n,par)]  #alias; index in parent's expressions
#  expr  = p_ex[index]                                #expression/'line' containing cc()
#  exprs = (n=no,i=index)-> if n then p_ex[i]=n else p_ex[i]   # get/set parent's exprs.
#  (tmp=quote ->).expressions = deepcopy p_ex[(index+1)..(p_ex.length-1)]  #'future' exprs
#  cont = bq {FUTURE: tmp}, quote -> (__thang) -> EXPR; FUTURE       #template, includes ^
#  cut_async = (node,set)->  # fn to snip/replace/return async call containing cc() if any
#    if node.args? then for arg,i in node.args #imagine: 'x = grab txt, cc(); p x;'
#      if arg is n                #call contains this cc() node
#        node.args[i] = cont     # replace cc() w/continuation
#        async = deepcopy node   # deepcopy the async call. that done,
#        set (quote -> __thang)  # 'x = __thang'
#        return async            # async call w/'cont' (ex: 'grab txt, (__thang)->...')
#    no
#  # EXPR is nothing for 'async(...,cc())'; else: 'x=async(..)', EXPR is 'x=__thang'
#  if a = cut_async(expr, exprs) then exprs bq((EXPR: quote ->), a), index
#  else nodewalk expr, (node,set)->
#    if a=cut_async(node,set)    then exprs bq((EXPR: expr),     a), index
#  p_ex.length = index+1         # clean up
