
# **macros.coffee** is a 100-line prototype of Lisp-style macros in CoffeeScript.
#
#

if window? then [root,_] = [window, window._] #probably error w/o underscore.js toplev.
else [(root = this).CoffeeScript,_] = [require('coffee-script'),require('underscore')]
G_COUNT = 0 # Gensym Counter
utils =
  arguments: undefined # monkeypatches browser weirdness.
  CS: root.CoffeeScript
  require2: (o,eso=root)->eso[name] = thing for name, thing of o
  keys:   (o)-> k for own k of o
  isValue:(o)-> _.isNumber(o) or _.isString(o) or _.isBoolean(o) or _.isRegExp(o) or _.isDate(o)
  gensym: (s)-> "#{s ? s or ''}_g#{++G_COUNT}"
  deepcopy: (o)-> # naive deepcopy by recursively shallow-cp w/_.clone. Dies on circles.
    throw "No underscore?!?" unless _ and _.clone
    for k,v of (o2=_.clone o)
      if ( _.isArray(v) or typeof(v) == 'object') and !(isValue(v) or _.isFunction(v))
        try (o2[k] = deepcopy v if keys(v).length > 0) catch e then p [e, v], 'err'
    o2
  propmost: (n,k='first')-> if n[k]? and n[k][k]? then propmost(n[k], k) else n
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
  bq: (args, nodes) -> backquote args, nodes
  val2node: (v)->if is_node(v) then v else CS.nodes "#{v}"
  backquote: (vs,ns) ->
    nodewalk ns, (n,set)->
      set val2node(vs[s]) if (s=get_name(n)) and vs[s]?
      # variable in an assignment ... var, idx in list comprehension ... grr, need setf...
      (n.variable.base.value = vs[ss]; set n) if (ss=n.variable?.base?.value)      and vs[ss]
      (n.name.value = vs[ss]; set n)          if n.source? and (ss=n.name?.value)  and vs[ss]
      (n.index.value = vs[ss]; set n)         if n.source? and (ss=n.index?.value) and vs[ss]
    ns
  argschain: (n,acc=[]) -> # AST: "a b c d, e b g (100) 123" --> [a,b,c,[d,e],b,g,(100),123]
    acc.push n if acc.length == 0
    if n.args?.length
      acc.push( if n.args.length == 1 then n.args[0] else n.args )
      argschain( n.args[n.args.length-1], acc )
    else acc
  # utilities -- mostly copy-pasted from repl. lots of room for improvement.
  n_index: (node, p) -> # index of node in expressions array of parent/undefined.
    (return i if n.contains? && n.contains((nu)->nu is node)) for n,i in p.expressions
    undefined
  n_last:                  (n)-> n.expressions?[n.expressions?.length-1] if n
  n_is_in:                 (n,parent) -> parent.contains (k) -> k is n
  n_is_last:               (n,parent)->  n_last(parent) is n
  get_name:                (n)-> node_name(n) ? values(n) ? simple_expression_value(n)
  simple_expression_value: (n)-> n?.variable?.base?.body?.expressions[0]?.base?.value
  strip_expression:        (n)-> if n.expressions?[0]? then n.expressions[0] else n
  node_name:               (n)-> n?.variable?.base?.value
  values:                  (n)-> n?.base?.value
  variable:                (n)-> n?.variable
  is_node:                 (n)-> n?.isStatement? or n?.compile?

# An instance of Macro will behave like the CoffeeScript object,
#  with .nodes, .compile, .run, but supporting macros.
class Macro
  eval("#{k} = utils['#{k}']") for own k of utils
  compile_lint = (n)-> n.compile(bare:on).replace(/undefined/g,"")
  constructor: (str=' ',@macs={}, @macnodes={})-> @nodes str

  #find/save 'mac foo fn'; expand macs in right order
  nodes: (str)=>
    nodewalk (@input = CS.nodes str), (n,set) =>
      if (s=node_name(n)) == 'mac'
        @macnodes[ name = node_name(n.args[0]) ] = n.args[0].args[0]
        set CS.nodes("/* mac '#{name}' defined  */")
    until keys(@macnodes).length <= keys(@macs).length
      for k, v of @macnodes when is_node(v) and !@macs[k] and doit=on
        nodewalk v,(n)=>doit=no if (s=node_name(n)) && @macnodes[s]? && !@macs[s]?
        @macex(v) and @macs[k] = eval "(#{compile_lint v})" if doit
    @input
  compile: (s)=>
    @nodes(s) if s
    @macex() until @macex_done()
    compile_lint @input
  run: (s)=> eval( if s? then @compile(s) else @compile() )
  ex1:   (macro, node, p) => @macs[macro](node, p)
  macex: (ns=@input) =>
    nodewalk ns,((n,set,p)=>set @ex1 s,n,p if (s=node_name n) && @macs[s]?), ns
  macex_done: (nodes=@input, done=yes)=>
    nodewalk nodes, (n)=> done=no if (s=node_name n) && s of @macs
    done

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

utils.require2({Macro: Macro}) if window?
exports.Macro = Macro if exports?
exports[k] = v for k, v in utils if exports?
