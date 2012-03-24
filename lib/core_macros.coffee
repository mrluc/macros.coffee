#
# Quote -- use like: ast = quote -> code you want the AST of.
#
# Weep, lisp implementers. Where's your Cons now?!?
mac quote ( {args: [{body}, soak...]} ) ->
  key = gensym()
  (root.quotes ?= {})[ key ] = body
  CS.nodes "deepcopy root.quotes['#{ key }']"

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
#      if arg is n               #call contains this cc() node
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
