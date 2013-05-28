[macros.coffee](http://mrluc.github.com/macros.coffee/)
=============

Down-and-dirty, 100-line (`cake loc` shows 87, actually) implementation of Lisp-style macros for CoffeeScript. [Annotated Source](http://mrluc.github.io/macros.coffee/docs/macros.html)

You can install it like so:

    npm install macros.coffee

And then require() it before requiring any file(s) that use macros:

    require "macros.coffee"
    app = require "my_application_that_uses_macros" 

    app.start()

Or, to compile to javascript files from the command line (currently very flaky):

    $ macros.coffee app/*.coffee

## Examples

Some examples can be seen in the `/test` directory. Use of `quote`, `backquote`,
macro-defining-macros, call-with-current-callback (`cc()`) ...

## Writing Macros

Macros are functions that operate on nodes of a program's Abstract Syntax Tree (AST). Here's a basic macro.

    mac foo (nodes)->
      CoffeeScript.nodes "x = 2"

`foo()` becomes `x = 2;`.

More complex or messy macros may want access to two other arguments that are passed in 
every macro: the parent node, and the global Macros object containing all of the
macro definitions.

### Basic Macro Tools: Quote, Backquote and Gensyms

A macro that replaces occurrences of `x` with a 2:

    mac two_for_x (n)->
      backquote (x:2), n

    two_for_x( y = x ) # produces y = 2

Backquote is a function that performs the implied replacement on an AST. Quote,
on the other hand, is a macro, not a function because it needs to do this:

    node1 = quote -> 2 + 2
    node2 = CoffeeScript.nodes "2+2"
    node1.compile() is node2.compile()

Here's a useless example that assigns x, y, and z to a value:

    mac assign_xyz ({args:[val,rest...]})->
      backquote {val:val}, quote ->
        x = y = z = val

    assign_xyz 12

## ... why???

I wrote this because I really, REALLY wanted to write macros in CoffeeScript. In Ruby, the buy-in to message-passing goes deep, and you can override most of the language, but in JS/CS metaprogramming is limited to tricks on `this`.

If you want to fork this and make it better, or build a substantially more 'heavy-duty' implementation, I'll probably end up using yours.
