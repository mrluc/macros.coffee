macros.coffee
=============

Down-and-dirty, 100-line implementation of Lisp-style macros for CoffeeScript.

You can install it like so:

    npm install macros.coffee

And then require() it before requiring any file(s) that use macros:

    require "macros.coffee"
    app = require "my_application_that_uses_macros" 

    app.start()

Or, to compile to javascript files from the command line:

    prompt> macros.coffee app/*.coffee

## Writing Macros

Macros are functions that operate on nodes of a program's Abstract Syntax Tree (AST). 
As an example, here's a pretty useless macro that just gets replaced by an assignment.

    mac foo (nodes)->
      CoffeeScript.nodes "x = 2"

`foo()` becomes `x = 2;`.

More complex or messy macros may want access to two other arguments that are passed in 
every macro: the parent node, and the global Macros object containing all of the
macro definitions.

## Basic Macro Tools: Quote, Backquote and Gensyms

A macro that replaces occurrences of `x` with a 2:

    mac two_for_x (n)->
      backquote (x:2), n

    two_for_x( y = x ) # entire line becomes 'y = 2'

Backquote is a function that performs the implied replacement on an AST. Quote,
on the other hand, is itself a macro, as there is no way to implement it as a 
function in CoffeeScript.

    node1 = quote -> 2 + 2
    node2 = CoffeeScript.nodes "2+2"
    node1.compile() is node2.compile()

Here's a useless example that assigns x to a value before a body of expressions:

    mac assign_xyz ({args:[val,rest...]})->
      backquote {val:val}, quote ->
        x = y = z = val

    assign_xyz 12

TODO EL RESTO

   - macros.coffee
     contains the implementation

   - lib/core_macros.coffee
     contains the quote macro, which you'll want (probably) and the Current Callback 
     macro, which is all line noise and is proof-of-concept for sync-> async.

   - There's an html REPL that loads the .coffee with xhr, and a dumb webrick file to serve it with.
     I use it to fiddle around in and make sure that the node stuff I added doesn't break browser
     compatability.

   - At the end of macros.coffee there's a few lines to let it be used from node. If you call it
     with a list of coffee files it'll compile them with macro support.

   - The code is full of line noise ATM. ;) 