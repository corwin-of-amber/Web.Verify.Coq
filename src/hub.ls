

class CoqAssistant

  ->
    @pprint = new PrettyPrint
    @testbed = $('#testbed')

  attach: (@coq-manager) ->
    @coq-manager.coq.observers.splice 0, 0, @
    @extra-pkgs = new ExtraPackages(@coq-manager)
    @

  feedProcessed: ->
    if !@ready
      @ready = true
      @extra-pkgs.load!

  coqGoalInfo: (sid, pp, east) ->
    if east?
      ast = Ast.of-east(east)
      if ast.root?
        console.log ast.toString!
        @testbed.empty!append @pprint.format(ast)
  
  coqSearchResults: (results) ->
    @testbed.empty!
    for [mod-path, label, type] in results
      ast = Ast.of-east(type)
      lbl = $ '<span>' .text "#{label} : "
      @testbed.append ($ '<div>' .append lbl .append @pprint.format(ast))



if typeof Reload   # dev mode (Kremlin)
  $ ->
    $(document).keydown (ev) ->
      if ev.metaKey && ev.keyCode == 82   # Cmd+R
        Reload.reload!


export CoqAssistant
