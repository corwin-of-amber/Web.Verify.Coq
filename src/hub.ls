

class CoqAssistant

  ->
    @pprint = new PrettyPrint
    @testbed = $('#testbed')

  attach: (@coq-manager) ->
    @coq-manager.coq.observers.splice 0, 0, @
    @extra-pkgs = new ExtraPackages(@coq-manager)
      ..load!
    @

  coqGoalInfo: (sid, pp, east) ->
    if east?
      ast = Ast.of-east(east)
      if ast.root?
        console.log ast.toString!
        @testbed.empty!append @pprint.format(ast)
  
  show-search-results: (results) ->
    @testbed.empty!
    for [kername, type] in results
      ident = Identifier.of-kername(kername)
      ast = Ast.of-east(type)
      lbl = $ '<span>' .text "#{ident.label} : "
      @testbed.append ($ '<div>' .append lbl .append @pprint.format(ast))



export CoqAssistant
