

'use macros'

test 'para list comprehension macro from RUM', (ms)->

  mac para (n)->

    # **argschain** is a helper for down-and-dirty DSL macros that may
    # want to abuse function-call syntax.
    #
    # In CoffeeScript, like Ruby and other languages,
    # `a b c d` means `a(b(c(d)))`. That nesting can be a pain; in Lisp,
    # sequences have the same syntax as function calls, so it's a non-issue.
    # `argschain quote -> a b c d, e b g (100) 123` returns nodes in an
    # array, like `[a,b,c,[d,e],b,g,(100),123]`
    #
    argschain = (n,acc=[]) ->
      acc.push n if acc.length == 0
      if n.args?.length
        acc.push( if n.args.length == 1 then n.args[0] else n.args )
        argschain( n.args[n.args.length-1], acc )
      else
        acc

    n.args[0]