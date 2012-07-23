# Quote -- use like: ast = quote -> code you want the AST of.
#
# Weep, lisp implementers. Where's your Cons now?!?
'use macros';

mac quote ({args: [{body}]}, p, m) ->
  key = gensym()
  (root.quotes ?= {})[key] = body
  CS.nodes "deepcopy global.quotes['" + key + "']"

# Aliasing ... and programmatic access to other macros generally, right now
# it looks like this. Stinky!
mac Q (n, parent, Macros) ->
  quote -> ref # forces quote to be compiled first
  Macros.macros.quote.compiled n

# Current Callback -- from first impl; currently broken
# like everything else that relies on quote -> (fn_with_any_params)->
mac cc (n,par,ms)->

  n_index = (node, p) -> # index of node in expressions array of parent/undefined.
    for nn,i in p.expressions when nn.contains? && nn.contains((nu)->nu is node)
      return i
    undefined

  #index in parent's expressions
  [pexprs, index] = [par.expressions, n_index(n,par)]
  expr = pexprs[index]

  set_pexpr = (n=no,i=index)-> if n then pexprs[i]=n
  (future = quote ->).expressions = deepcopy pexprs[(index+1)..(pexprs.length-1)]

  # template of code to generate
  cont = bq {FUTURE: future}, quote -> (__thang) -> EXPR; FUTURE

  # fn to copy+return async call containing cc() if any
  cut_async = (node,set)->
    if node.args? then for arg,i in node.args when arg is n
      #imagine: 'x = grab txt, cc(); p x;'
      node.args[i] = cont     # replace cc() w/continuation
      async = deepcopy node   # deepcopy the async call. that done,
      set (quote -> __thang)  # 'x = __thang
      return async
      # async call w/'cont' (ex: 'grab txt, (__thang)->...')
    no
  # EXPR is nothing for 'async(...,cc())';
  if a = cut_async(expr, set_pexpr) then set_pexpr bq((EXPR: quote ->), a)

  #but for 'x=async(..)', EXPR is 'x=__thang'
  else nodewalk expr, (node,set)->
    if a=cut_async(node,set)    then set_pexpr bq((EXPR: expr),     a)

  # Now we delete everything that comes after the call to cc,
  # since we've copied it and stuffed it into the async callback.
  pexprs.length = index+1
  n
