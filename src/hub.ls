

class CoqAssistant

  attach: (coq-manager) ->
    coq-manager.coq.observers.push @

  coqGoalInfo: (sid, pp, east) ->
    console.log Ast.of-east(east).toString!



export CoqAssistant
