[CS, _] = [require('coffee-script'), require('./examples/underscore')] #TODO npm _

[G_COUNT, p, root] = [0, console.log, window ? process]

exports.utils =

  gensym: (s)-> "#{s ? s or ''}_g#{++G_COUNT}"

  nodewalk:(n, visit, dad = undefined) ->
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

  isNode: (o)-> o.isStatement? or o.compile?
  isValue: (o)->
    for k in 'Number String Boolean RegExp Date Function'.split(' ')
      return yes if _["is#{k}"](o)
    no

  deepcopy: (o)->
    for k,v of o2 = _.clone o
      if ( _.isArray(v) or typeof(v)=='object') && !isValue(o) &&_.keys(o).length > 0
        o2[k] = deepcopy v
    o2

  # TODO: refactor this junk. special-casing not cool.
  backquote: (vs,ns) ->
    get_name = (n)-> node_name(n) ? n.base?.value
    val2node = (val)->if isNode(val) then val else CS.nodes "#{val}"
    nodewalk ns, (n,set)->
      set val2node(vs[s]) if (s=get_name(n)) and vs[s]?
      # for the rest, we need to special-case recognition and setting. Makes me sad.
      (n.name.value = vs[ss]; set n)          if n.source? and (ss=n.name?.value)  and vs[ss]
      (n.index.value = vs[ss]; set n)         if n.source? and (ss=n.index?.value) and vs[ss]
    ns
  BQ: (vs,ns)-> backquote vs,ns

  node_name: (n)-> n?.variable?.base?.value

class MacroScript

  eval "#{k} = exports.utils['#{k}']" for own k of exports.utils

  constructor: (@macros={}, @types=[name:'mac', recognize: node_name])->

  eval: (s) => eval @compile s

  compile: (s)=>
    @nodes s if s
    @compile_lint()

  compile_lint: (n=@ast)-> n.compile(bare:on).replace(/undefined/g,"")

  nodes: (str)=>
    @ast = CS.nodes str
    nodewalk @ast, (n,set) =>
      for {name, recognize} in @types when name is node_name n
        name = node_name n.args[0]
        @macros[name] =
          nodes: n.args[0].args[0]
          recognize: (n)->  name if name is recognize n
          compiled: undefined
        set CS.nodes "`//#{name} defined`"

    until @all_compiled()
      for name, {nodes, compiled} of @macros when not compiled
        if @calls_only_compiled nodes
          js = @compile_lint @macroexpand nodes
          @macros[name].compiled = eval "(#{js})"

    @macroexpand() until @all_expanded()

  macroexpand: (ns=@ast)=>
    #TODO: eventually need to respect the ordering established in @types
    expander = (n, set, parent)=>
      set compiled(n, parent, @) for k, {recognize, compiled} of @macros when recognize n
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

if process? && (args = process?.argv).length > 2 and ns = args[2..args.length]
  [fs, path] = (require(s) for s in ['fs','path'])
  [p, MS]    = [console.log, new MacroScript]
  for src in ns
    p src
    fs.readFile src, "utf-8", (err, code) ->
      throw err if err
      name = path.basename src, path.extname(src)
      dir  = path.join(path.dirname(src), "#{name}.js")
      out  = MS.compile code
      fs.writeFile dir, out, (err)-> if err then throw err else p "Success!"

exports.MacroScript = MacroScript
exports.instance = new MacroScript
