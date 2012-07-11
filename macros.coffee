
[G_COUNT, p, root]  = [0, console.log, window ? global]
[ fs, path, CS, _ ] = (require(s) for s in ['fs','path', 'coffee-script', './examples/underscore'])

# Implementation
exports.MacroScript = class MacroScript
  # First, some supporting functions:
  #
  # `gensym` is used to generate unique names for variables in generated code.
  gensym = (s='')-> "#{s}_g#{++G_COUNT}"
  # `nodewalk` walks the nodes of the tree returned by `CoffeeScript.nodes`.
  # Our visitor callback is handed a 'setter' function that can be used to
  # set the value of the current node; for instance,
  # `nodewalk CoffeeScript.nodes(codestring), (n,set)-> set CoffeeScript.nodes "2"`
  # uses the setter function to replace the first node encountered with the number 2.
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

  deepcopy = (o)->
    for k,v of o2 = _.clone o
      if _.isArray(v) or (typeof(v)=='object' && !isValue(o) && _.keys(o).length > 0)
        o2[k] = deepcopy v
    o2

  # `backquote` takes a hash of values and a tree of nodes. For instance,
  # `backquote (a:2), quote -> 2 + a` would produce `2 + 2`. Its definition
  # must be special-cased to recognize names in language features like comprehensions.
  backquote = (vs,ns) ->
    get_name = (n)-> node_name(n) ? n.base?.value
    val2node = (val)->if isNode(val) then val else CS.nodes "#{val}"
    nodewalk ns, (n,set)->
      set val2node(vs[s]) if (s=get_name(n)) and vs[s]?
      n.name.value = vs[ss]          if n.source? and (ss=n.name?.value)  and vs[ss]
      n.index.value = vs[ss]         if n.source? and (ss=n.index?.value) and vs[ss]

  node_name = (n)-> n?.variable?.base?.value

  # By default, macro definitions look like a 'mac' function call.
  constructor: (@macros={}, @types=[name:'mac', recognize: node_name])->
  # `eval`, `compile`, and `nodes` work about the same as the CoffeeScript
  # versions.
  eval: (s) => eval @compile s

  compile: (s,opts=bare:on)=>
    @nodes s if s
    @compile_lint @ast, opts

  compile_lint: (n,opts=bare:on)-> n.compile(opts).replace(/undefined/g,"")
  # `nodes` is a high-level description of the implementation:
  # We get the AST from CoffeeScript, find and compile any macro definitions
  # it may contain, and then expand any calls to those macros that may exist.
  nodes: (str)=>
    @ast = CS.nodes str
    @find_and_compile_macros()
    @macroexpand() until @all_expanded()
    @ast

  # Macro definitions are expected to have the form
  # `macroSignifier(nameOfMacro(definitionOfMacro))`.
  # Upon recognizing a macro as defined in `@types`,
  # add a new definition to `@macros` under the name recognized
  # from its first argument, containing the uncompiled nodes from
  # the macro definition, and a function to recognize occurrences
  # of calls to that macro. Replace the macro definition with a comment.
  find_and_compile_macros: =>
    nodewalk @ast, (n,set) =>
      for {name, recognize} in @types when name is recognize n
        name = recognize n.args[0]
        @macros[name] =
          nodes: n.args[0].args[0]
          recognize: (n)->  name if name is recognize n
          compiled: undefined
        set CS.nodes "`//#{name} defined`"
    # Macros have to be compiled in the right order, because they
    # may themselves call other macros.
    # todo: see about binding these in a better context than global :P
    until @all_compiled()
      for name, {nodes, compiled} of @macros when not compiled
        if @calls_only_compiled nodes
          js = @compile_lint @macroexpand nodes
          console.log js
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

## Usage
# As with CoffeeScript, you can either require CoffeeScript files (that use macros) directly,
# or you can expand+compile files to Javascript and run that.

# Simply `require 'module_using_macros'` should work,
exports.instance = instance = new MacroScript
require.extensions['.coffee'] = (module, fname) ->
  module._compile instance.compile(fs.readFileSync(fname, 'utf-8')), fname

# but be aware that command-line compiling is limited; the order
# that files containing macros are compiled in will matter. And, since
# CoffeeScript doesn't ship with an easy way to hook its command-line
# compilation, this implementation takes the easy way out and doesn't
# support specifying an output directory; the compiled javascript is
# always written into the same location as the coffeescript.
if process? && (args = process?.argv).length > 2 and ns = args[2..args.length]
  console.log "called from command line"
  MS = new exports.MacroScript
  for src in ns
    p src
    fs.readFile src, "utf-8", (err, code) ->
      Throw err if err
      name = path.basename src, path.extname(src)
      dir  = path.join(path.dirname(src), "#{name}.js")
      out  = MS.compile code
      fs.writeFile dir, out, (err)-> if err then throw err else p "Success!"