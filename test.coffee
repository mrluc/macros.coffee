[CS, _] = [require('coffee-script'), require('./examples/underscore')]

class MacroScript

  [G_COUNT, p, root] = [0, console.log, window ? process]
  gensym = (s)-> "#{s ? s or ''}_g#{++G_COUNT}"

  nodewalk = (n, visit, dad=undefined) ->
    return unless n.children
    dad = n if n.expressions
    for name in n.children
      return unless kid = n[name]
      if kid instanceof Array then while kid.length > ((++i if i?) ? i=0)
        visit kid[i], ((newval) -> kid[i] = newval), dad
        nodewalk kid[i], visit, dad
      else
        visit kid, ((newval)-> kid = n[name] = newval), dad
        nodewalk kid, visit, dad
    n

  isValue = (o)->
    for fn in [_.isNumber, _.isString, _.isBoolean, _.isRegExp, _.isDate, _.isFunction]
      return yes if fn o
    no

  deepcopy = (o)->
    for k,v of o2 = _.clone o
      if ( _.isArray(v) or typeof(v)=='object') && !isValue(o) &&_.keys(o).length > 0
        o2[k] = deepcopy v
    o2

  node_name = (n)-> n?.variable?.base?.value

  constructor: (str=' ', @macros={}, @types=[name:'mac', recognize: node_name])->
    @nodes str

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

  compile: (s)=>
    @nodes s if s
    @compile_lint @ast

  eval: (s) => eval @compile s

  compile_lint: (n=@ast)-> n.compile(bare:on).replace(/undefined/g,"")

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

module.exports = new MacroScript
