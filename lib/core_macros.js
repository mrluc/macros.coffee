mac(quote(function(n) {
  var fn, key, _ref;
  if ((_ref = Macro.quotes) == null) {
    Macro.quotes = {};
  }
  fn = n.args[0];
  key = gensym();
  Macro.quotes[key] = fn.body;
  return CS.nodes("deepcopy Macro.quotes['" + key + "']");
}));
mac(cc(function(n, par) {
  var a, cont, cut_async, expr, exprs, index, p_ex, tmp, _ref;
  _ref = [par.expressions, n_index(n, par)], p_ex = _ref[0], index = _ref[1];
  expr = p_ex[index];
  exprs = function(n, i) {
    if (n == null) {
      n = false;
    }
    if (i == null) {
      i = index;
    }
    if (n) {
      return p_ex[i] = n;
    } else {
      return p_ex[i];
    }
  };
  (tmp = quote(function() {})).expressions = deepcopy(p_ex.slice(index + 1, (p_ex.length - 1 + 1) || 9e9));
  cont = bq({
    FUTURE: tmp
  }, quote(function() {
    return function(__thang) {
      EXPR;      return FUTURE;
    };
  }));
  cut_async = function(node, set) {
    var arg, async, i, _len, _ref2;
    if (node.args != null) {
      _ref2 = node.args;
      for (i = 0, _len = _ref2.length; i < _len; i++) {
        arg = _ref2[i];
        if (arg === n) {
          node.args[i] = cont;
          async = deepcopy(node);
          set(quote(function() {
            return __thang;
          }));
          return async;
        }
      }
    }
    return false;
  };
  if (a = cut_async(expr, exprs)) {
    exprs(bq({
      EXPR: quote(function() {})
    }, a), index);
  } else {
    nodewalk(expr, function(node, set) {
      if (a = cut_async(node, set)) {
        return exprs(bq({
          EXPR: expr
        }, a), index);
      }
    });
  }
  return p_ex.length = index + 1;
}));