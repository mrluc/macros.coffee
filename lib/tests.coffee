p = if window? then window.p ? alert else console.log
tests =
  "2+2 is 4": -> 2+2 is 4
  "Macros exists":-> Macros?
  "@macs exists": -> Macros.macs?
  "Quote macro returns a node":->
    (quote -> x)?.expressions?

exports = window if window?
exports.runtests = (verbose = no) ->
  [failed,total] = [0,0]
  for n, t of tests
    try
      total++
      throw "function not defined#{t}" unless t?
      if t() then p "TEST #{total} passed(#{total-failed}): '#{n}'"
      else p        "TEST #{total} FAILED(#{++failed    }): '#{n}'"
    catch e then  p "TEST #{total} ERR   (#{++failed    }): '#{n}' with '#{e}'"
  p "Passed #{total - failed} of #{total}"