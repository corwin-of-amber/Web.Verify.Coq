require! assert


class Ast extends Tree

  @of-east = (east) ->
    assert.equal east[0], 'AstNode'
    [_, root, subtrees] = east
    root-id =
      switch root[0]
      | 'Operator' => root[1]
      | 'Identifier' => @identifier-from-element(root)
      | 'Rel' => '~'
      | 'Empty' => void
      | _ => '?'
    if root-id == '~'
      new Ast(root-id, [new Ast(root[1])])
    else
      new Ast(root-id, subtrees.map ~> @of-east it)

  @identifier-from-element = (el) ->
    assert.equal el[0], 'Identifier'
    @identifier-from-kername(el[1])
      ..tags = el[2]

  @identifier-from-kername = ([kername, modpath, dirpath, label]) ->
    assert.equal kername, 'KerName'
    assert.equal modpath[0], 'MPfile'
    new Identifier([...modpath[1]].reverse!, label)


class Identifier
  (@prefix, @label) ->

  toString: -> [...@prefix, @label].join(".")

  equals: (other) ->
    other instanceof Identifier && \
      @prefix === other.prefix && @label === other.label


export Ast, Identifier