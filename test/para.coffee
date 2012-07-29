
'use macros'


test 'para list comprehension rewrite', (ms)->

  mac para (n)->
    argschain = (n,acc=[]) ->
      acc.push n if acc.length == 0
      if n.args?.length
        acc.push( if n.args.length == 1 then n.args[0] else n.args )
        argschain( n.args[n.args.length-1], acc )
      else
        acc

    strip_expression = (n)-> if n.expressions?[0]? then n.expressions[0] else n

    # WHOA! WHOA. WHOA NELLY. Builtins not showing up?
    # What about var declarations? I'm not seeing those.
    # If it's not one thing, ... this is why you test more, dammit ...
    eval '__slice=[].slice;'

    [parasym, ss, spacer, a, rest..., space, fn] = argschain strip_expression(n)

    cond = if rest.length >= 2 then rest[1].variable else (quote -> true)

    backquote {n:gensym('n'), arr:a.variable, body: fn.body, cond:cond}, quote ->
      (body if cond) for n in arr

  ok ms.compile("para x en [1,2,3] haz -> x") is """_ref = [1, 2, 3];
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  n_g9 = _ref[_i];
  if (true) {
    x;

  }
}"""
