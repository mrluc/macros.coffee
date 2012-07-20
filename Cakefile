fs = require 'fs'
path = require 'path'
#cs = require 'coffee-script'
ms = require './lib/macros'
require "./lib/core_macros"

# ANSI Terminal Colors.
enableColors = no
unless process.platform is 'win32'
  enableColors = not process.env.NODE_DISABLE_COLORS

bold = red = green = reset = ''
if enableColors
  bold  = '\x1B[0;1m'
  red   = '\x1B[0;31m'
  green = '\x1B[0;32m'
  reset = '\x1B[0m'

# Log a message with a color.
log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')
p = console.log

runTests = ->
  passed = 0
  failures = []

  global[name] = func for name, func of require 'assert'

  global.test = (description, fn)->
    try
      fn.test = {description, currentFile}
      fn ms
      ++passed
    catch e
      e.description = description if description?
      e.source      = fn.toString() if fn.toString?
      failures.push filename: currentFile, error: e

  # When all the tests have run, collect and print errors.
  # If a stacktrace is available, output the compiled function source.
  process.on 'exit', ->
    message = "passed #{passed} tests"
    return log(message, green) unless failures.length
    log "failed #{failures.length} and #{message}", red
    for fail in failures
      {error, filename}  = fail
      jsFilename         = filename.replace(/\.coffee$/,'.js')
      match              = error.stack?.match(new RegExp(fail.file+":(\\d+):(\\d+)"))
      match              = error.stack?.match(/on line (\d+):/) unless match
      [match, line, col] = match if match
      console.log ''
      log "  #{error.description}", red if error.description
      log "  #{error.stack}", red
      log "  #{jsFilename}: line #{line ? 'unknown'}, column #{col ? 'unknown'}", red
      console.log "  #{error.source}" if error.source
    return

  files = fs.readdirSync 'test'
  for file in files when file.match /\.coffee$/i
    currentFile = filename = path.join 'test', file
    code = fs.readFileSync filename
    try
      ms.eval code.toString(), {filename}
    catch error
      failures.push {filename, error}
  return !failures.length

task 'test', 'running macros.coffee tests', ->
  runTests()