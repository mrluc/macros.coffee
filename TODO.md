where we're at.
===============

I've been down in South America ever since I presented the 
original proof-of-concept at Ruby.mn, and I didn't do much
with it. But I found some time to refactor and cut line noise.

But now things don't work that worked before. And I still 
need to make this more like a 'real' project: 
(readme, tests, npm-installable, in that order).

In the process of cleaning the room, I've uncovered some 
architectural flaws, and haven't had time to completely solve
them:

- For instance, do macros only look like function calls? In 
  Lisp that's the case, but now we have syntax, and it'd be
  lame not to let us make use of it. 

  This is addressed by 'recognizers' in macros.coffee, 
  or at least there's a place for it -- but there's no
  precedence determined, for instance, and it hasn't even
  been tested once yet.

- Macro-defining-macros, at any rate emulating Lisp directly,
  are broken, probably because of deepcopy reasons. See
  the test that fails for this.

- DEEP COPY. This is causing a huge number of our sneakiest 
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

- cc, para, and other macros from my writeups. They don't work any more.

- Browser generally, ie, it loads and runs.

- Repl for browser, ie, I can easily embed coffeescript with
  macros.coffee in a web page.