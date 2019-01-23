require! assert


class Notation
  (@prec) ->
  format: (ast, recurse, at) ->
    @_format ...&
      ..prec ?= @prec
  _format: (ast, recurse, at) -> /* jdom */

ctxt = -> $(document.createTextNode(it))
cat = -> it.reduce (x,y) -> x.add(y)
cat-sep = (jdoms, sep) -> jdoms.reduce (x,y) -> x.add(sep.clone!).add(y)


class AppNotation extends Notation
  ->
    super ...
    @arg-prec = {left: @prec.left - 1, right: @prec.right - 1}
  _format: (ast, recurse, at) ->
    assert ast.subtrees.length > 0
    v = [recurse(s) for s in ast.subtrees]
    cat [at(v.0, @prec)] ++ v[1 to].map ~> ctxt(" ").add(at(it, @arg-prec))

class NatNumeralNotation extends Notation
  @O = new Identifier([], 'O')
  @S = new Identifier([], 'S')
  _format: (ast, recurse, at) ->
    v = ast
    val = 0
    while v.root == '@' && v.subtrees[0].is-leaf! && @@S.equals(v.subtrees[0].root)
      v = v.subtrees[1] ; val += 1
    if @@O.equals(v.root)
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


class PrefixNotation extends Notation
  (@operator, prec) -> super prec
  _format: (ast, recurse, at) ->
    r = recurse(ast.subtrees[*-1])
    cat [@mkop!, at(r, @prec)]
  mkop: ->
    $ '<span>' .add-class <[notation prefix-op]> .append @operator.clone!


class QuantifierNotation extends Notation
  (@quantifier, outer-prec, @inner-prec, @multivar-prec, @arrow-notation) ->
    @body-prec = {left: @inner-prec.left, right: outer-prec.right}
    super outer-prec

  _format: (ast, recurse, at) ->
    [va, body] = ast.subtrees
    if @is-arrow(ast)
      @arrow-notation.format(new Tree('->', [va.subtrees[1], body]), recurse, at)
    else
      [more-vars, body] = @collect(body)
      vars = [va, ...more-vars].map recurse ; body = recurse(body)
      vars-prec = if vars.length > 1 then @multivar-prec else @inner-prec
      cat [@mkop!, (@var-list [at(x, vars-prec) for x in vars]), @mksep!, at(body, @body-prec)]

  is-arrow: (ast) ->
    [va, body] = ast.subtrees
    @arrow-notation? && va.root == ':' && !@has-rel(body, 1)
  has-rel: (ast, rel-index) ->
    if ast.root == '~'
      ast.subtrees[0].root == rel-index
    else 
      if ast.root == 'forall' then rel-index += 1
      ast.subtrees.some ~> @has-rel it, rel-index
  collect: (ast) ->
    if ast.root == 'forall' && !@is-arrow(ast)
      [va, body] = ast.subtrees
      [more-vars, body] = @collect(body)
      [[va, ...more-vars], body]
    else
      [[], ast]

  var-list: (jdoms) ->
    $ '<span>' .add-class <[quantifier-vars]> .append cat-sep(jdoms, @mkvarsep!)

  mkop: ->
    $ '<span>' .add-class <[notation prefix-quantifier]> .append @quantifier.clone!
  mksep: ->
    $ '<span>' .add-class <[notation sep-quantifier-comma]> .text ", "
  mkvarsep: ->
    $ '<span>' .add-class <[notation sep-quantifier-space]> .text " "


class LiteralNotation extends Notation
  (@literal, prec) -> super prec
  _format: (ast, recurse) ->
    $ '<span>' .add-class <[notation literal]> .append @literal.clone!


/**
 * Main pretty-printing entry point.
 */
class PrettyPrint
  ->
    @notations = 
      '@': new AppNotation({left: 1, right: 1})
      'forall': new QuantifierNotation(ctxt("∀ "), {left: 0, right: 99}, {left: 90, right: 90}, {left: 1, right: 1},
                                       new InfixNotation(ctxt(" → "), {left: 75, right: 75}))
      ':': new InfixNotation(ctxt(" : "), {left: 89, right: 89})
      'Coq.Init.Datatypes.nat': new LiteralNotation(ctxt("ℕ"), {left: 0, right: 0})
      'S': new NatNumeralNotation({left: 45, right: 45})
      'O': new NatNumeralNotation({left: 0, right: 0})
      'Coq.Init.Nat.add': new InfixNotation(ctxt(" + "), {left: 45, right: 45})
      'Coq.Init.Logic.eq': new InfixNotation(ctxt(" = "), {left: 70, right: 70})
      'Coq.Init.Logic.not': new PrefixNotation(ctxt("¬"), {left: 2, right: 50})

    @open-namespaces = new OpenNamespaces([['JsCoq'], ['Coq', 'Init']])
  
  format: (ast, ctx=[]) ->
    @resolve-rels ast, ctx
    @_format(ast)

  _format: (ast) ->
    if (nota = @get-notation(ast))?
      nota.format(ast, @~_format, @~parenthesize)
    else if ast.root == '~'
      /**/ assert ast.bound-to? /**/
      @_format(ast.bound-to)
    else if ast.is-leaf! && ast.root
      caption = if ast.root instanceof Identifier then @open-namespaces.dequalify(ast.root) else ast.root
      tags = if ast.root instanceof Identifier then ast.root.tags else void
      $ '<span>' .add-class 'identifier' .append ctxt(caption.toString!)
        if tags then ..attr 'data-tags' tags
        ..prec = {left: 0, right: 0}
    else
      $ '<span>' .add-class 'stub' .append ctxt("{"), ctxt(ast.toString!), ctxt("}")

  resolve-rels: (ast, ctx=[]) ->
    if ast.root == '~'
      ast.bound-to = @get-rel(ast, ctx)
    else if ast.root == 'forall'
      /**/ assert.equal 2 ast.subtrees.length /**/
      @resolve-rels ast.subtrees[0], ctx
      @resolve-rels ast.subtrees[1], ctx ++ [@get-var(ast.subtrees[0])]
    else
      for s in ast.subtrees
        @resolve-rels s, ctx

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


class OpenNamespaces
  (@ns-list) ->

  dequalify: (ident) ->
    prefix = ident.prefix
    for ns in @ns-list
      if prefix[til ns.length] === ns
        return new Identifier(prefix[ns.length til], ident.label)
    ident



export PrettyPrint