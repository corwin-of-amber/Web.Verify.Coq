require! assert


class Notation
  (@prec) ->
  format: (ast, recurse, at) ->
    @_format ...&
      ..prec ?= @prec
  _format: (ast, recurse, at) -> /* jdom */

ctxt = -> $(document.createTextNode(it))
cat = -> it.reduce (x,y) -> x.add(y)

class AppNotation extends Notation
  ->
    super ...
    @arg-prec = {left: @prec.left - 1, right: @prec.right - 1}
  _format: (ast, recurse, at) ->
    assert ast.subtrees.length > 0
    v = [recurse(s) for s in ast.subtrees]
    cat [at(v.0, @prec)] ++ v[1 to].map ~> ctxt(" ").add(at(it, @arg-prec))

class NatNumeralNotation extends Notation
  _format: (ast, recurse, at) ->
    v = ast
    val = 0
    while v.root == '@' && v.subtrees[0].is-leaf! && v.subtrees[0].root == 'S'
      v = v.subtrees[1] ; val += 1
    if v.root == 'O'
      @mkval(val)
        ..prec = {left: 0, right: 0}
    else
      cat [@mkplus(val), at(recurse(v), @prec)]
  mkval: (val) ->
    $ '<span>' .add-class <[notation nat numeral]> .text ""+val
  mkplus: (val) ->
    $ '<span>' .add-class <[notation nat prefix-val-plus]> .append @mkval(val)
    .append ($ '<span>' .add-class 'infix-op' .text '+')

class InfixNotation extends Notation
  (@operator, prec, assoc='none') ->
    super prec
    @lprec = {left: 99, right: (if assoc === 'left' then prec.right else prec.right - 1)}
    @rprec = {right: 99, left: (if assoc === 'right' then prec.left else prec.left - 1)}
  _format: (ast, recurse, at) ->
    [l, r] = [recurse(ast.subtrees[*-2]), recurse(ast.subtrees[*-1])]
    cat [at(l, @lprec), @mkop!, at(r, @rprec)]
      ..prec = {left: Math.max(@prec.left, l.prec.left), right: Math.max(@prec.right, r.prec.right)}
  mkop: ->
    $ '<span>' .add-class <[notation infix-op]> .append @operator.clone!

class QuantifierNotation extends Notation
  (@quantifier, outer-prec, @inner-prec) ->
    @body-prec = {left: @inner-prec.left, right: outer-prec.right}
    super outer-prec
  _format: (ast, recurse, at) ->
    va = recurse(ast.subtrees[0])
    body = recurse(ast.subtrees[1])
    cat [@mkop!, at(va, @inner-prec), @mksep!, at(body, @body-prec)]
  mkop: ->
    $ '<span>' .add-class <[notation prefix-quantifier]> .append @quantifier.clone!
  mksep: ->
    $ '<span>' .add-class <[notation sep-quantifier-comma]> .text ", "

class LiteralNotation extends Notation
  (@literal, prec) -> super prec
  _format: (ast, recurse) ->
    $ '<span>' .add-class <[notation literal]> .append @literal.clone!


class PrettyPrint
  ->
    @notations = 
      '@': new AppNotation({left: 1, right: 1})
      'forall': new QuantifierNotation(ctxt("∀ "), {left: 0, right: 99}, {left: 90, right: 90})
      ':': new InfixNotation(ctxt(" : "), {left: 89, right: 89})
      'Coq.Init.Datatypes.nat': new LiteralNotation(ctxt("ℕ"), {left: 0, right: 0})
      'S': new NatNumeralNotation({left: 45, right: 45})
      'O': new NatNumeralNotation({left: 0, right: 0})
      'Coq.Init.Nat.add': new InfixNotation(ctxt(" + "), {left: 45, right: 45})
      'Coq.Init.Logic.eq': new InfixNotation(ctxt(" = "), {left: 70, right: 70})
  
  format: (ast, ctx=[]) ->
    if ast.root == 'forall'
      ctx = ctx ++ @get-var(ast.subtrees[0])

    if (nota = @get-notation(ast))?
      nota.format(ast, (~> @format(it, ctx)), @~parenthesize)
    else if ast.root == '~'
      @format(@get-rel(ast, ctx), ctx)
    else if ast.is-leaf!
      $ '<span>' .add-class 'identifier' .append ctxt(ast.root)
        ..prec = {left: 0, right: 0}
    else
      $ '<span>' .add-class 'stub' .append ctxt("{"), ctxt(ast.toString!), ctxt("}")

  parenthesize: (jdom, prec) ->
    eprec = jdom.prec ? {left: 99, right: 99}
    if prec.left < eprec.left || prec.right < eprec.right
      cat [ctxt("("), jdom, ctxt(")")]
        ..prec = {left: 0, right: 0}
    else
      jdom

  get-notation: (ast) ->
    head-symb = 
      if ast.root == '@' && ast.subtrees[0].is-leaf! 
        ast.subtrees[0].root 
      else ast.root

    @notations[head-symb] ? @notations[ast.root]

  /**
   * Extracts a relative (de-Bruijn) reference from the current context.
   * The ast should have the form ~{i}, where i is a positive integer
   */
  get-rel: (ast, ctx) ->
    /**/ assert.equal 1 ast.subtrees.length ; assert.equal 0 ast.subtrees[0].subtrees.length /**/
    relidx = ast.subtrees[0].root
    /**/ assert 1 <= relidx <= ctx.length /**/
    ctx[ctx.length - relidx]

  get-var: (ast) ->
    if ast.root == ':' then ast.subtrees[0] else ast



export PrettyPrint