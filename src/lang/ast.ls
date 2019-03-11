require! assert

tree =
  # Hack to run in Node.js as well
  if typeof exports == 'object' && typeof module != 'undefined'
    require './tree'
  else {Tree}



class Ast extends tree.Tree

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
    else if root-id == '?'
      new Ast(root-id, [])
        ..east = east
    else
      new Ast(root-id, subtrees.map ~> @of-east it)

  @identifier-from-element = (el) ->
    assert.equal el[0], 'Identifier'
    Identifier.of-kername(el[1])
      ..tags = el[2]


class Identifier
  (@prefix, @label) ->

  toString: -> [...@prefix, @label].join(".")

  equals: (other) ->
    other instanceof Identifier && \
      @prefix === other.prefix && @label === other.label

  @of-kername = ([kername, modpath, dirpath, label]) ->
    assert.equal kername, 'KerName'
    modsuff =
      while (modpath[0] == 'MPdot')
        modpath[2]
          ..; modpath = modpath[1]
    assert.equal modpath[0], 'MPfile'
    new Identifier([...modpath[1]].reverse! ++ modsuff, label)



export Ast, Identifier