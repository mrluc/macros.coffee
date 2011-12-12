
# **macros.coffee** is a 100-line prototype of Lisp-style macros in CoffeeScript.
#
#### Why CoffeeScript?
#
# 1. CoffeeScript is a small language that only compiles down to Javascript,
# not a VM, so its AST is pretty easy to work with.
#
# 2. Plus, CoffeeScript has a really flexible syntax, which you need for macros to
# look like anything.
#
# 3. Too, JavaScript's metaprogramming is largely limited to tricks with `this`,
# so the abilities macros offer are correspondingly more attractive.
#
#### How This Code Is Organized
#
# It's one class, plus a bunch of supporting functions.
#
# The class `Macros` acts like the CoffeeScript
# object; it relies on a number of supporting functions for AST
# trickery. It doesn't do anything to CoffeeScript's lexer/parser,
# or use CoffeeScript internals.
#
# Also, it's written kind of densely ... a little code-golfed, to be honest.
# I'm sorry -- 100 lines sounds like a nice, round number.

# We use Underscore.js for type recognition and shallow copy, in browser or node.js
[CS, _, G_COUNT] = if window?
                     [CoffeeScript, window._, 0]
                   else
                     [require('coffee-script'), require('underscore'), 0]

## Utility Functions
#
# We need a whole library of functions to make transforming the AST easier. This
# isn't that library; it'd be easier to write them once we have macros, anyhow.
#
# These are just some functions that
# mangle the AST *just* enough to get us macros.
#
Utils =
  # **nodewalk**  walks the nodes of the AST. `nodewalk node, (n,set)-> set CS.nodes 2`
  # replaces every node encountered with a 2. Which means that the whole node tree
  # would get replaced with a 2, as once the root node turns into a 2, there are no
  # children to walk.
  #
  # `nodewalk` started life as the David Padbury's `replacingWalk`,
  # and is the workhorse behind macroexpansion and backquotes.
  nodewalk: (node, visitor, parent=undefined) => # from d.padbury's replacingWalk.
    return unless node.children
    parent = node if node.expressions   # TODO: parent if: 1. toplevel, or 2. is a fn.body
    for name in node.children
      return if !(child = node[name])
      if child instanceof Array then while ((++i if i?) ? i=0) < child.length
        visitor child[i], ((newval) -> child[i] = newval), parent
        nodewalk child[i], visitor, parent
      else
        visitor child, ((newval) -> child = node[name] = newval), parent
        nodewalk child, visitor, parent

  # **deepcopy** is important for macros. To `quote` a tree of source code for use as a template,
  # you need to deep copy it, or you'll get hilarious shared-structure bugs.
  # This is a naive implementation that recursively shallow-copies with `_.clone`.
  # It's doesn't handle circular objects, just the kind of 'tree of values' that makes up an AST.
  deepcopy: (o)->
    throw "No underscore?!?" unless _ and _.clone
    for k,v of (o2=_.clone o)
      if ( _.isArray(v) or typeof(v) == 'object') and !(is_value(v) or _.isFunction(v))
        try (o2[k] = deepcopy v if keys(v).length > 0) catch e then console.log [e, v]
    o2

  # **is_value** is used by deepcopy, and delegates to Underscore.js to detect types.
  is_value:  (o)-> _.isNumber(o) or _.isString(o) or _.isBoolean(o) or _.isRegExp(o) or _.isDate(o)

  # **backquote** is the workhorse behind the return value of most macros.
  # Given a hash of `v`alue`s` and a(n AST)ree of `n`ode`s`, like so:
  #
  #     backquote { my_var: 3, my_other_var: quote -> 2+2 }, quote ->
  #       x = my_var
  #       y = my_other_var
  #
  # backquote will walk the nodes of that AST, making the substitutions
  # found in the values hash, and returns the transformed tree. The
  # logic has to be special-cased to recognize and set various language features,
  # like variable assignment, or the name/index fields in a list comprehension,
  # and it doesn't support them all yet.
  backquote: (vs,ns) ->
    nodewalk ns, (n,set)->
      set val2node(vs[s]) if (s=get_name(n)) and vs[s]?
      (n.variable.base.value = vs[ss]; set n) if (ss=n.variable?.base?.value)      and vs[ss]
      (n.name.value = vs[ss]; set n)          if n.source? and (ss=n.name?.value)  and vs[ss]
      (n.index.value = vs[ss]; set n)         if n.source? and (ss=n.index?.value) and vs[ss]
    ns
  bq: (args, nodes) -> backquote args, nodes   # Alias for backquote.

  # **val2node** is called by `backquote` on values to be spliced in.
  # If something's not a node yet (like a string or number) this turns it into one.
  val2node: (v)->if is_node(v) then v else CS.nodes "#{v}"

  # **gensym**s are generated symbols with unique names, used to avoid name clashes
  # in generated code. There are no symbols in Java/CoffeeScript, but we still need
  # generated variable names.
  #
  # These aren't guaranteed unique, but if you don't normally
  # add `_g207` to your variable names it'll work for our macros.
  gensym: (s)-> "#{s ? s or ''}_g#{++G_COUNT}"

  # **argschain** is a helper for down-and-dirty DSL macros that may
  # want to abuse function-call syntax.
  #
  # In CoffeeScript, like Ruby and other languages,
  # `a b c d` means `a(b(c(d)))`. That nesting can be a pain; in Lisp,
  # sequences have the same syntax as function calls, so it's a non-issue.
  # `argschain quote -> a b c d, e b g (100) 123` returns nodes in an
  # array, like `[a,b,c,[d,e],b,g,(100),123]`
  #
  argschain: (n,acc=[]) ->
    acc.push n if acc.length == 0
    if n.args?.length
      acc.push( if n.args.length == 1 then n.args[0] else n.args )
      argschain( n.args[n.args.length-1], acc )
    else acc

  # Some shortcuts for checking properties of nodes,
  # mostly copy-pasted from the Repl.
  n_index: (node, p) -> # index of node in expressions array of parent/undefined.
    (return i if n.contains? && n.contains((nu)->nu is node)) for n,i in p.expressions
    undefined
  n_last:                  (n)-> n.expressions?[n.expressions?.length-1] if n
  n_is_in:                 (n,parent) -> parent.contains (k) -> k is n
  n_is_last:               (n,parent)->  n_last(parent) is n
  # We use this to wrap up a chained check into some of the common places
  # that a node might store its 'name' -- a name, a value, or a value wrapped in a block.
  get_name:                (n)-> node_name(n) ? values(n) ? simple_expression_value(n)
  simple_expression_value: (n)-> n?.variable?.base?.body?.expressions[0]?.base?.value
  strip_expression:        (n)-> if n.expressions?[0]? then n.expressions[0] else n
  # This is the one we use to identify macro names.
  node_name:               (n)-> n?.variable?.base?.value
  values:                  (n)-> n?.base?.value
  variable:                (n)-> n?.variable
  is_node:                 (n)-> n?.isStatement? or n?.compile?
  arguments: undefined # Monkeypatch weirdness in some browsers,
  keys:      (o)-> k for own k of o
  propmost: (n,k='first')-> if n[k]? and n[k][k]? then propmost(n[k], k) else n


## Macro Object

# An instance of Macro will behave like the CoffeeScript object,
#  with `.nodes`, `.compile`, `.run`.
#
#### API
#
# `compile` and `run` result in complete macroexpansion and compilation
# of the code string passed in.
#
# `nodes`, `macex`, and `ex1` results in differing levels of macroexpansion,
# if you want to gander at the AST more closely -- use `nodes` to see
# it after macro *definitions* have been expanded, and `macex` to see
# it after more complete macroexpansion. Or perform a single, targetted
# expansion with `ex1`.
#
class Macro

  #### Setup &amp; Constructor

  # Monkey-include Utils functions directly into lexical scope.
  eval("#{k} = Utils['#{k}'];") for own k of Utils

  # Cleanup; `undefined` shows up in indented code;
  # we're apparently nuking indent info somewhere. TODO.
  compile_lint = (n)-> n.compile(bare:on).replace(/undefined/g,"")

  # Pass a string of code to the constructor, and it gets sent
  # right to `.nodes`. `nodes` is probably the most important
  # function in the implementation.
  constructor: (str=' ',@macs={}, @macnodes={})-> @nodes str

  #### Implementation

  # **nodes** calls
  # `CoffeeScript.nodes`, but then does two other things: it *finds and saves*
  # macro definitions, and then *macroexpands and compiles*
  # them for later use.

  nodes: (str)=>
    # It does this by walking the AST and copying out anything that looks like a
    # macro definition, saving it into `macnodes` under its name.
    # For `mac foo (n)-> ...`, the expansion of
    # `(n)->...` would be saved into `@macnodes['foo']`,
    # and replaced with a comment in the output.
    nodewalk (@input = CS.nodes str), (n,set) =>
      if node_name(n) is 'mac'
        @macnodes[ name = node_name(n.args[0]) ] = n.args[0].args[0]
        set CS.nodes("/* mac '#{name}' defined  */")

    # Next, it loops through uncompiled macro definitions, expanding and compiling.
    # This must be done in the right order; macros often use *other* macros!
    # So for each of the macro definitions that's not compiled yet,
    until keys(@macnodes).length <= keys(@macs).length
      for k, v of @macnodes when is_node(v) and !@macs[k] and doit=on
        # if the definition *doesn't* call an *uncompiled* macro,
        nodewalk v,(n)=>doit=no if (s=node_name(n)) && @macnodes[s]? && !@macs[s]?
        # then macroexpansion will work! Expand,
        # compile and evaluate the definition, and save
        # the result in `@macs` under the macro name.
        @macex(v) and @macs[k] = eval "(#{compile_lint v})" if doit
    @input


  # **macex** expands *all* macro calls, not just those in macro definitions.
  # Given nodes, it looks for a call against a function with
  # a macro's name. It sends those nodes to be processed by the associated
  # macro, performing a single macroexpansion via `ex1`.
  macex: (ns=@input) =>
    nodewalk ns,((n,set,p)=>set @ex1 s,n,p if (s=node_name n) && @macs[s]?), ns

  # **ex1** perform a single macroexpansion. Given a macro name, a node, and its parent,
  # call the macro stored with that name, passing the node and the node whose
  # `expressions` array contains it.
  ex1: (macro, node, p) => @macs[macro](node, p)

  # The order of expansion means `macex` need only be run once. Probably.
  # But just in case, **macex_done** can be used to test whether or not a code tree
  # contains un-expanded macro calls.
  macex_done: (nodes=@input, done=yes)=>
    nodewalk nodes, (n)=> done=no if (s=node_name n) && s of @macs
    done

  # **compile**, like CoffeeScript's compile, outputs javascript.
  # It calls `nodes`, which takes care of any macro *definitions* it
  # may contain, performs macroexpansion on the AST via `macex`,
  # and spits out compiled javascript.
  compile: (s)=>
    @nodes(s) if s
    @macex() until @macex_done()
    compile_lint @input

  # Like the CoffeeScript object, `run` uses `eval` to
  # execute `compile`d code immediately.
  run: (s)=> eval( if s? then @compile(s) else @compile() )



## Using From Node.js

# In a Node.js environment, this file functions as a
# basic preprocessor. Call it like this:
#
#     coffee macros.coffee file1.coffee file2.coffee ...
#
# Or like this:
#
#     coffee macros.coffee dir/*.coffee
#
# And it will kick out a macro-expanded, compiled-to-javascript
# version of those coffee files.
#
# There's no support for specifying an output directory yet.
# But what do you want? Egg in your suds?
if process? && (ns = process?.argv).length > 2 and ns = ns[2..ns.length] #1st 2 are
  console.log "Processing from the command line: #{ns}"
  [fs, path, _]    = (require(s) for s in ['fs','path','underscore'])
  [p, MacroScript] = [console.log, (new Macro '')]
  for src in ns
    p src
    fs.readFile src, "utf-8", (err, code) ->
      throw err if err
      p "#{code}"
      name = path.basename src, path.extname(src)
      dir  = path.join(path.dirname(src), "#{name}.js")
      out  = MacroScript.compile code, {bare:on}
      p "#{out}"
      fs.writeFile dir, out, (err)-> if err then throw err else p "Success!"

_.extend window, {Macro: Macro} if window?
exports.Macro = Macro if exports?
exports[k] = v for k, v in Utils if exports?



## Macros in Other Languages
#
# CoffeeScript has a very clean [AST](http://en.wikipedia.org/wiki/Abstract_Syntax_Tree).
#
# You can get at the AST in [Ruby](http://parsetree.rubyforge.org/) and
# [Python](http://norvig.com/python-lisp.html) pretty easily, though. If you
# like macros and don't want to do without them in one of those languages,
# I can't think offhand why something like this wouldn't work.
#
# We use preprocessors on our SCSS to compile to CSS, and use
# ad-hoc macros there.
#
# We use generators in Rails.
#
# We use a thousand templating languages to generate code all day long.
#
# It is really so weird to add an abstraction that supports
# *real* code generation? Even if it's implemented as a preprocessing step?
#
# Seems worth exploring further.
#

##### This One's for my homies ...
# Big shoutout to David Padbury for getting HackerNews thinking about this
# stuff with his
# [original blog post](http://blog.davidpadbury.com/2010/12/09/making-macros-in-coffeescript/)
#
# Those were were C-style, substitution-based macros, not functions that allowed
# arbitrary transformations on the AST -- but he used
# AST to do them, and it was probably a repost on Hacker News
# that got me wondering if real Lisp-style macros were a possibility.
#
#