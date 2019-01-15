

class CoqAssistant

  ->
    @pprint = new PrettyPrint
    @testbed = $('#testbed')

  attach: (coq-manager) ->
    coq-manager.coq.observers.push @
    @

  coqGoalInfo: (sid, pp, east) ->
    ast = Ast.of-east(east)
    console.log ast.toString!
    @testbed.empty!append @pprint.format(ast)



export CoqAssistant
