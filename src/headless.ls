
jscoq_worker = require 'jscoq/coq-js/jscoq_worker'
jscoq = require 'jscoq/coq-js/jscoq'
format-pprint = require 'jscoq/ui-js/format-pprint'



class HeadlessWorker extends jscoq.CoqWorker
  ->
    /* does NOT call super */
    @options = {debug: false}
    @observers = [@]
    @routes = [@observers]
    @sids = []
  
    @worker = jscoq_worker.jsCoq
    @worker.onmessage = (evt) ~> process.nextTick ~> @~coq_handler {data: evt}


class HeadlessManager
  (@coq) ->
    @pprint = new format-pprint.FormatPrettyPrint

  coqReady: (sid) ->
    require! fs
    fs.readFile "proofs/Simple.vo" (err, data) ~>
      if err
        console.error err
      else
        @coq.put "/lib/Simple.vo", data
    if sid == 1
      @coq.add 1, 2, 'Check Prop.'

  coqCoqExn: (, , msg) ->
    console.error @pprint.pp2Text(msg)

  coqLog: ([lvl], msg) ->
    console.log @pprint.pp2Text(msg)

  feedProcessingIn: (sid) ->

  feedProcessed: (sid) ->
    console.log "Processed", sid

  feedMessage: (sid, [lvl], loc, msg) ->
    console.log '-' * 40
    console.log lvl
    console.log @pprint.pp2Text(msg)
    console.log '-' * 40

  feedFileDependency: ->
  feedFileLoaded: ->

  coqAdded: (sid) ->
    if sid == 2
      @coq.exec 2
      @coq.reassureLoadPath []
      @coq.add 2, 3, "Require Simple.", true


coq = new HeadlessWorker
coq.observers.push new HeadlessManager(coq)

bare-minimum = ["Coq/ltac/ltac_plugin.cmo", "Coq/ltac/tauto_plugin.cmo", 
                "Coq/syntax/nat_syntax_plugin.cmo", 
                "Coq/cc/cc_plugin.cmo",
                "Coq/firstorder/ground_plugin.cmo"]

require! fs
require! find

COQPKGS = 'node_modules/jscoq/coq-pkgs'

find.eachfile /\.cmo$/, "#COQPKGS/Coq", coq~register
.end ->
  coq.init(true, [], [
           [[], ["proofs"]], 
           [["Coq", "ltac"],           [COQPKGS]]
           [["Coq", "syntax"],         [COQPKGS]]
           [["Coq", "cc"],             [COQPKGS]]
           [["Coq", "firstorder"],     [COQPKGS]]
           [["Coq", "Init"],           [COQPKGS]]
           ])


export HeadlessWorker, coq

