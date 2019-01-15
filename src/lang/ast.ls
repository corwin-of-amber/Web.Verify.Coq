require! assert


class Ast extends Tree

  @of-east = (east) ->
    assert.equal east[0], 'AstNode'
    [_, root, subtrees] = east
    root-id =
      if root[0] == 'Identifier' then root[1]
      else if root[0] == 'Rel' then '~'
      else if root[0] == 'Empty' then void
      else '?'
    if root-id == '~'
      new Ast(root-id, [new Ast(root[1])])
    else
      new Ast(root-id, subtrees.map ~> @of-east it)


export Ast