# **macros.coffee** is Lisp-style macros for CoffeeScript in 100 lines.
#
# Jump to:
#
# - [Implementation](#impl)
# - [Using with node: `require()`, compiling](#usage)
# - [AST utilities](#utils)
#
# ### Why CoffeeScript?
#
# 1. CoffeeScript is a tiny language that only compiles down to Javascript,
#    so its AST is pretty easy to work with.
#
# 2. Plus, CoffeeScript has a really flexible syntax, which you need for
#    macros to look like anything.
#
# 3. Too, Javascript's metaprogramming is largely limited to tricks with
#    `this`, so the control over the meaning of language features offered
#    by macros is correspondingly more attractive.
#
# If you `require 'macros.coffee'`, CoffeeScript will work normally, but it will
# understand macro definitions of the form
#
#     mac foo (ast) -> transformed_ast
#
# ... and will automatically *macroexpand* them in coffeescript files that
# contain the declaration `"use macros"`. See the docs for `core_macros.coffee`,
# or the contents of the test directory, for examples of files that
# use this declaration.
#
# This isn't written by a Lisp Expert(tm). I just like the experience of writing and using
# macros; it feels natural, and I miss it outside of Lisp. I wanted to
# see how close I could get with a minimal implementation.
#
# The [github project](https://github.com/mrluc/macros.coffee) contains more information,
# as [my blog](http://mrluc.github.com) might from time to time.

#### Utility Functions <a id='utils'></a>
[G_COUNT, p, root]  = [0, console.log, window ? global]
[ fs, path, CS, _, dc ] = (require(s) for s in 'fs path coffee-script underscore owl-deepcopy'.split(' '))

# `gensym` gives names to variables in generated code.
#
# `nodewalk` walks the nodes of the tree returned by `CoffeeScript.nodes`.
# Our visitor callback is handed a 'setter' function that can be used to
# set the value of the current node; for instance,
# `nodewalk CoffeeScript.nodes(codestring), (n,set)-> set CoffeeScript.nodes "2"`
# uses the setter function to replace the first node encountered with the number 2.

gensym = (s='')-> "#{s}_g#{++G_COUNT}"

nodewalk = (n, visit, dad = undefined) ->
  return unless n.children
  dad = n if n.expressions
  for name in n.children
    return unless kid = n[name]
    if kid instanceof Array then while kid.length > ((++i if i?) ? i=0)
      visit kid[i], ((node) -> kid[i] = node), dad
      nodewalk kid[i], visit, dad
    else
      visit kid, ((node)-> kid = n[name] = node), dad
      nodewalk kid, visit, dad
  n

isNode = (o)-> o.isStatement? or o.compile?
isValue = (o)->
  for k in 'Number String Boolean RegExp Date Function'.split(' ')
    return yes if _["is#{k}"](o)
  no

# `deepcopy` of the AST using OWL's wonderful deep copy implementation
deepcopy = dc.deepCopy

# `backquote` takes a hash of values and a tree of nodes. For instance,
# `backquote (a:2), quote -> 2 + a` would produce `2 + 2`. Its definition
# must be special-cased to recognize names in language features like comprehensions.
# TODO: tests to see what language features are still not replaceable.
backquote = bq = (vs,ns) ->
  get_name = (n)-> node_name(n) ? n.base?.value
  val2node = (val)->if isNode(val) then val else CS.nodes "#{val}"
  nodewalk ns, (n,set)->
    set val2node(vs[s]) if (s=get_name(n)) and vs[s]?
    n.name.value = vs[ss]          if (ss=n.name?.value)  and vs[ss] #no .source allows .vars
    n.index.value = vs[ss]         if n.source? and (ss=n.index?.value) and vs[ss]

uses_macros = (ns)-> r=no; nodewalk(ns,(n)-> r=yes if n.base?.value is "'use macros'"); r
node_name = (n)-> n?.variable?.base?.value

#### Instance Methods <a id='impl'></a>

# Our MacroScript instance provides the same API as the CoffeeScript require.
# `eval`, `compile`, and `nodes` work about the same.
exports.MacroScript = class MacroScript

  constructor:(s='',@macros={},@types=[name:'mac',recognize:node_name],@strict=no,@opts=bare:on)->
    @nodes s

  eval: (s,strict=@strict) => eval @compile s,@opts,strict

  compile: (s,opts=@opts, strict=@strict)=>
    @nodes (s ? ''), strict
    @compile_lint @ast, opts

  compile_lint: (n,opts=@opts)-> n.compile(opts).replace(/undefined/g,"")
  # `nodes` is a high-level description of the implementation:
  # We get the AST from CoffeeScript, find and compile any macro definitions
  # it may contain, and then expand any calls to those macros that may exist.
  nodes: (str, strict=@strict)=>
    @ast = CS.nodes str
    if !strict or uses_macros(@ast)
      @find_and_compile_macros()
      @macroexpand() until @all_expanded()
    @ast

  # `find_and_compile_macros` expands and compiles macro definitions, and
  # calls from within those definitions. (It doesn't touch anything outside
  # of macro _definitions_, however).
  # By default, it can recognize names of function calls that looks like this:
  # `mac foo (n)-> n`; that is to say,
  # `macroSignifier( nameOfMacro( definitionOfMacroAsFunction) )`.
  # We store the nodes of that macro, and a function to recognize it,
  # under the name recognized from its first argument.
  # Replace the macro definition with a comment.
  find_and_compile_macros: =>

    nodewalk @ast, (n,set) =>
      for {name, recognize} in @types when name is recognize n
        name = recognize n.args[0]
        @macros[name] =
          nodes: n.args[0].args[0]
          recognize: (n)->  name if name is recognize n
          compiled: undefined
        set CS.nodes "`//#{name} defined`"

    # The macro definitions are **compiled**, taking care to do it in the right
    # order, since they might rely on other macros.
    until @all_compiled()
      for name, {nodes, compiled} of @macros when not compiled
        if @calls_only_compiled nodes
          js = @compile_lint @macroexpand nodes
          @macros[name].compiled = eval "(#{js})"

  # Once the macros are all compiled, the logic
  # for macroexpansion is simple: if a node is recognized as a macro call,
  # then transform it with that macro's compiled definition.
  macroexpand: (ns=@ast)=>
    expander = (n, set, parent)=>
      for k, {recognize, compiled} of @macros when recognize n
        set compiled(n, parent, @)
        @find_and_compile_macros() # this buys us macro-defining macros.
    nodewalk ns, expander, ns

  all_compiled: =>
    return no for name, {compiled} of @macros when not compiled
    yes

  all_expanded: (ast=@ast, iz = yes) =>
    return no for k, {recognize} of @macros when recognize @ast
    nodewalk ast, (n) =>
      iz = no for name, {recognize} of @macros when recognize n
    iz

  calls_only_compiled: (ast=@ast, does = yes) =>
    nodewalk ast, (n) =>
      does = no for name, {compiled, recognize} of @macros when !compiled and recognize n
    does

## Usage <a id='usage'></a>
# As with CoffeeScript, you can either require CoffeeScript files (that use macros) directly,
# or you can expand+compile files to Javascript and run that.

# Simply `require 'module_using_macros'` should work,
exports[k]=v for k,v of new MacroScript fs.readFileSync("#{__dirname}/core_macros.coffee",'utf-8')

require.extensions['.coffee'] = (module, fname) ->
  module._compile exports.compile(fs.readFileSync(fname, 'utf-8'),exports.opts, yes), fname

# but be aware that command-line compiling is limited; the order
# that files containing macros are compiled in will matter. And, since
# CoffeeScript doesn't ship with an easy way to hook its command-line
# compilation, this implementation takes the easy way out and doesn't
# support specifying an output directory; the compiled javascript is
# always written into the same location as the coffeescript.
if module.filename is process.mainModule.filename and names = process?.argv.slice(2)
  for src in names
    p src fs.readFile src, "utf-8", (err, code) ->
      throw err if err
      name = path.basename(src, path.extname(src))
      dir  = path.join(path.dirname(src), "#{name}.js")
      out  = exports.compile code
      fs.writeFile dir, out, (err)-> if err then throw err else p "Success!"