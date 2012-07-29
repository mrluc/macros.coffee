'use macros'

test 'defining cc macro',(ms)->
  # Current Callback -- from first impl
  # Recently resuscitated
  # This code is hard to follow. Really, really hard to follow. For me anyway.
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

test 'whalla whalla cc what?', (ms)->

  s = ms.compile """
    agreet = (name,ret)->
      ret 'Hey, '+name
      return 'And when does this happen?'
    if x = agreet 'Tim', cc()
      p x
    else
      p 'Ohnoz'
  """

  should_be = """
    agreet = function(name, ret) {
      ret('Hey, ' + name);
      return 'And when does this happen?';
    };
    agreet('Tim', function(__thang) {
      var x;
      if (x = __thang) {
        p(x);
      } else {
        p('Ohnoz');
      }

    });
    """

  ok s is should_be