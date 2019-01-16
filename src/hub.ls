

class CoqAssistant

  ->
    @pprint = new PrettyPrint
    @testbed = $('#testbed')

  attach: (coq-manager) ->
    coq-manager.coq.observers.push @
    @

  coqGoalInfo: (sid, pp, east) ->
    ast = Ast.of-east(east)
    if ast.root?
      console.log ast.toString!
      @testbed.empty!append @pprint.format(ast)


if typeof Reload   # dev mode (Kremlin)
  $ ->
    $(document).keydown (ev) ->
      if ev.metaKey && ev.keyCode == 82   # Cmd+R
        Reload.reload!


export CoqAssistant
