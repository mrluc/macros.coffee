# Quote -- use like: ast = quote -> code you want the AST of.
#
# Weep, lisp implementers. Where's your Cons now?!?

mac quote ({args: [{body}]}, p, m) ->
  key = gensym()
  (root.quotes ?= {})[key] = body
  CS.nodes "deepcopy global.quotes['" + key + "']"

mac Q (n, parent, Macros) ->
  quote -> ref # forces quote to be compiled first
  Macros.macros.quote.compiled n

# m = require('./macros').instance
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
# Assign is passed prop, prop, 'object' in each case, so read the code (1.2.0 in this case) to see...
mac BQ (n) ->
  #[vars,rest] = n.args
  if no then console.log s for s in [
    n
    n.constructor.toString()
    n.args[0]
    n.args[0].constructor.toString()
  ]
  # weird. a:2 becomes a: 2: a: 2 in the ensuing js ... how?!?
  # eval(ms.instance.compile 'quote -> {a:2}').compile(bare:on)
    # that demos the bug. It must be a problem with deep-copied code; hashes must
    # be rep'd in a way that a single deep copy op is too stupid for.
    # Moreover, this must have changed in the recent upgrades to coffeescript,
    #
  console.log "but there's no problem with hashes other places. Like here: #{ b: 10 }"
  console.log "The deepcopied (quoted) code can no longer be recompiled correctly if it
    contains a:n."
  # possible solutions:
  # 1 - special-case deepcopy, maybe via .constructor checks
    # Hopefully, though, it would be something simpler. We might be able to see what the problem is
    # just by comparing the previous versions of coffeescript.
  # 2 - coffee2coffee (meh), might be better than deepcopy. Big problems though, bc the
  #     translation isn't likely to be 1:1, which would kill macros.
  # 3 - monkeypatch coffeescript ... practically a fork. Meh. Instead, (1) will probably
      # be the way. Once we figure out what the problem is ...
  # 4 - assume we're wrong, and see if deepcopy is really necessary? Wishful thinking?
    # definitely, if we want to do it in a loop. BQ will replace a value in that tree,
    # so that on the second iteration, the name we're looking for will not be there.
  # So to recreate, need 2 things,
  quote ->
    args = {}
    args.a = 2; args.b = 3
    backquote args, quote ->
      x=a

#mac quote ( n )->
#  Macro.quotes ?= {}
#  fn = n.args[0]
#  key = gensym()
#  Macro.quotes[key] = fn.body
#  CS.nodes "deepcopy Macro.quotes['#{key}']"

# 'Current Callback'
#
# If you can decode this, you are a stallion. It's code golf.
#mac cc (n,par)->
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
