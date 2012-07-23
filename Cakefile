[fs,path,{exec},ms] = (require s for s in 'fs path child_process ./lib/macros'.split ' ')

'use macros';
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

w_cwd = (dir, fn, dbg=no) ->
  old_cwd = process.cwd()
  p "OLD: #{process.cwd()}" if dbg
  process.chdir dir
  p "NEW: #{process.cwd()}" if dbg
  fn()
  p "NOW: #{process.cwd()}" if dbg
  process.chdir old_cwd

task 't1','test current working directory fn',->
  p process.cwd()
  w_cwd 'test', ->
    p process.cwd()
  p process.cwd()

runTests = ->
  passed = 0
  failures = []
  dir = 'test'

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

  files = fs.readdirSync dir
  for file in files when file.match /\.coffee$/i
    currentFile = filename = path.join dir, file
    code = fs.readFileSync filename
    try
      w_cwd dir, ->
        ms.eval code.toString(), {filename}
    catch error
      failures.push {filename, error}
  return !failures.length

task 'test', 'running macros.coffee tests', ->
  runTests()

task 'docs', 'generate docco docs (requires docco) ... docco.', ->
  exec 'docco lib/macros.coffee lib/core_macros.coffee'

task 'loc', '(painfully slowly) counting lines of code in macros.coffee', ->
  code = fs.readFileSync './lib/macros.coffee'
  code = code.toString()
  lines = code.split '\n'
  num_lines = lines.length
  lines = (line.trim() for line in lines)
  count = 0
  comments = (line for line in lines when line.length is 0 or line[0] is '#')
  num_comments = comments.length
  # console.log comment for comment in comments       # to double-check logic...
  console.log num_lines - num_comments