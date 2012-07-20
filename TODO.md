Todo
===============

### where we're at

I've been down in South America ever since I presented the 
original proof-of-concept at Ruby.mn, and I didn't do much
with it. I did find an afternoon to refactor and cut line noise.

But now many of the old macros are broken. And no progress at all was made
on making this a 'real' project, like tests and organization.

### priorities

Aside from fixes, priorities are probably:

1. organize (meh, mostly done)
2. readme (begun)
3. tests (begun)
4. npm-installable (begun)
5. browser module installable (not started - requirejs?)

### really also need

**cc, para, and other macros from the original articles**. They don't work any more.

**Repl for browser**, ie, I can easily embed a repl with macros.coffee in a web browser. The old one is broke and needed to be served up in most browsers the way we had it … there's got to be a good little project out there for this sort of thing. Edit: there are, and they're massively overengineered. I'll just build my own again, just for the project page and simple embedding.


### architecturally puzzling todos:

In the process of cleaning the code, I've uncovered some 
architectural flaws, and haven't had time to completely solve
them:

- **Do macros always look like function calls?** In 
  Lisp that's the case, but now we have syntax, and it'd be
  lame not to let us make use of it.

  The architectural solution is sketched via 'recognizers' 
  in macros.coffee, but precedence is undefined, for instance, 
  and it hasn't even been tested once yet.

- **Macro-defining-macros**, at any rate straightforward ones that
  emulate Lisp directly,
  are broken, probably because of deepcopy reasons. In theory,
  we've written code for this already

- **Backquote hell**. It's doing replacements at the NODE level,
  and walks at the node level. However, that will wipe out some
  other features that would otherwise be walked and replaced,
  like a `.chained` method or property,
  so ... that's actually a pretty finicky problem.

  -  And solving it may involve making a painful archi choice,
     (unlike the current val2node approach) CHANGING a NAME if
     the value is a string, but REPLACING the NODE (as now) if the
     value to splice is a node.

     This would require, then, a function that can take ANY node,
     and knows how to find and change its name if it has one (ie,
     you can't rename a node that represents just `[]`, but you
     can rename the x in `x.y` to `z.y`).

     Until then, if you want to change the `x` in `x.y`, doing so
     with backquote will wipe away that whole chain; do it yourself
     (after all, you've got the AST).

- **DEEP COPY**. This is causing a huge number of our sneakiest 
  problems. Maybe macro-defining-macros, definitely hash literals,
  are affected.

  Quote, as we've implemented it, needs to deep-copy
  the DEEP tree of the CoffeeScript language. However, right now
  we're doing 'naive' deep copy, and frankly I can't find 
  a 'real' deep copy out there.

  CoffeeScript uses 'instanceof' a lot, and even if you, say, 
  copy over the .constructor property, you won't match instanceof
  unless you ARE. So that means calling constructors and probably
  custom instantiators for AST nodes, bloating deep copy considerably.

  It's crazy that CoffeeScript is so well-designed that it's
  been compiling all this time even with me stripping that info out
  with my naive deep copy.

