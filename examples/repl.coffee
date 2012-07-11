root = window if window
require = (o)->	root[name] = thing for name, thing of o
sp =    (i=1)-> (' ' for n in [0..(i*4)]).join ''
isValue = (o)-> _.isNumber(o) or _.isString(o) or _.isBoolean(o) or _.isRegExp(o) or _.isDate(o)
compile = (s)-> CoffeeScript.compile(s,bare:on)

class Repl
	constructor: (@compile=compile,@$=$,@buttonId="#eval_button",@replId="#repl",@histId="#history",@show_fn=false)->
		[@hist, @histdepth,@s] = [[], 0, 0]
		@style = js:'js', err:'err', out:'out', eval:'eval'
		@rebind_events(@$)
	rebind_events: ($=@$)->
		$(@buttonId).click => @do_eval()
		$(@replId).keydown (e) =>
			if e.shiftKey then switch e.which  #ctrlEnter-->eval, ctrlUp-->load history
				when 13 then @do_eval()
				when 38 then $(@replId).val @hist[@hist.length - @histdepth++ - 1]
	to_s: (o)=>
		if isValue(o) then o.toString()
		else if _.isArray(o) then @s++;"[\n"+sp(@s)+("#{@to_s k}" for k in o).join(",\n"+sp(@s--))+"]"
		else if _.isFunction(o) then (if !@show_fn then 'fn' else this.toString())
		else @s++;"{\n"+sp(@s)+("#{k}: #{@to_s v}" for own k,v of o).join(",\n"+sp(@s--))+"}"
	p: (s,style=@style.out)=> @show_eval (@to_s s), style
	show_eval: (val, t=@style.js) ->
		(el=$(@histId)[0]).innerHTML=("<p class='repl #{t}'>#{val}</p>"+el.innerHTML)
		no
	do_eval: (entered = $(@replId).val()) ->
		try
			@hist.push entered
			js = @compile entered
			@show_eval( js, @style.js )
			@show_eval( root.eval(js), @style.eval)
		catch e
			@show_eval e, @style.err
			throw e
		@show_eval "<br/>"
		$(@replId).val('').focus()
		@histdepth=0

require Repl: Repl, require: require