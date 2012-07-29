Todo
===============

Bug: run some tests; I think that macroexpansions are
losing CoffeeScript variable scope information, because
`var` and builtins like `__slice` aren't being generated in
the body of the `para` macro. We should really be testing
that quoted code is 1:1 with unquoted, a little more stringently.

### where we're at

I've been down in South America ever since I presented the 
original proof-of-concept at Ruby.mn, and I didn't do much
with it. I did find a day to refactor and cut line noise.

The refactoring broke a number of old macros, but since returning
to the states I've been able to address some major technical 
issues relating to the AST strategy (yay deepcopy); conversion
to another canonical format should hopefully not become necessary).

### priorities

Aside from fixes, priorities are probably:

1. organize (meh, mostly done)
2. readme quality (not so hot)
3. tests (not so hot)
4. npm-installable (seems ok)
5. browser module installable (not started - requirejs?)

### really also need

**cc, para, and other macros from the original articles**. I've managed to get cc working.
Should probably update `para` as well.

**Repl for browser**; that's how we *developed* the proof-of-concept, but I haven't 
given it a second glance since the rewrites. It's a pain, but there's also no reason
not to do it. there's got to be a good little project out there for this sort of thing. Edit: there are, and they're massively overengineered for what we need. 

This would rely on requireJS or similar.


### architecturally puzzling todos:

#### Deepcopy

In the process of refactoring the old proof-of-concept, I uncovered some 
architectural flaws. The most puzzling was the deepcopy 
conundrum, now fixed; the bugs that that caused were devilish, 
and can be seen in the deepcopy branch, and explained in 
earlier versions of this file. Macro-defining-macros, inability 
to `quote` object literals, inability to `quote` calls to 
`backquote`, and a host of others.

It's always possible that the CS AST could become complex in
ways (closure-related) that could foil deepcopy. In which case
we'd have to provide our own canonical format CF such that
we can easily convert AST->CF->AST for quoting, which would be
no mean task and probably necessitate a complete reimagining of
the project.

#### Other pretty open questions for the implementation

- **Do macros always look like function calls?** In 
  Lisp that's the case, but now we have syntax, and it'd be
  lame not to let us make use of it.

  The architectural solution is sketched via 'recognizers' 
  in macros.coffee, but haven't made use of it yet.

  Precedence is undefined, for instance, 
  and it hasn't even been tested once yet.

- **Macro-defining-macros** seem to be fixed. Keep an eye on this
  as some of the coolest uses of macros in On Lisp and Let Over Lambda
  make use of them.

- **Backquote hell**. It's doing replacements at the NODE level,
  and walks at the node level. However, that will wipe out some
  other features that would otherwise be walked and replaced,
  like a `.chained` method or property.

  Example: `x.y` where we want to backquote and change x to `b` and
  y to `c`. Doing the first one obliterates the subtree containing the
  second one.
  
  so ... that could actually be a pretty finicky problem.

  -  It's easier in a language with cons cells and the concept
     of atoms built in. :P

  -  And solving it may involve making a painful archi choice,
     (unlike the current val2node approach) CHANGING a NAME if
     the value is a string, but REPLACING the NODE (as now) if the
     value to splice is a node.

  -  Or, maybe, study how Arc treats quoted code that makes use
     of syntax, since it does have some.
