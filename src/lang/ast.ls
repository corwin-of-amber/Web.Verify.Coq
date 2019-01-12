require! assert


class Ast extends Tree

  @of-east = (east) ->
    assert.equal east[0], 'AstNode'
    [_, root, subtrees] = east
    root =
      if root[0] == 'Identifier' then root[1]
      else if root[0] == 'Empty' then void
      else '?'
    new Ast(root, subtrees.map ~> @of-east it)


export Ast