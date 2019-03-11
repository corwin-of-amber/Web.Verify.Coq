
jscoq_worker = require 'jscoq/coq-js/jscoq_worker'
jscoq = require 'jscoq/coq-js/jscoq'
format-pprint = require 'jscoq/ui-js/format-pprint'

ast = require './lang/ast'



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
    @coq ?= new HeadlessWorker
    @coq.observers.push @

    @pprint = new format-pprint.FormatPrettyPrint

    @doc = [{text: s} for s in [
      "Require Arith."
    ]]
    @inspect-prefix = ["Coq", "Arith"]
      
    /*
      "From Coq Require Import Init.Prelude Unicode.Utf8."
      "From Coq Require Import ssreflect ssrfun ssrbool."
      "From mathcomp Require Import eqtype ssrnat div prime."
      "Lemma prime_above m : {p | m < p & prime p}."
      "have /pdivP[p pr_p p_dv_m1]: 1 < m`! + 1 by rewrite addn1 ltnS fact_gt0."
      "exists p => //; rewrite ltnNge; apply: contraL p_dv_m1 => p_le_m."
      "by rewrite dvdn_addr ?dvdn_fact ?prime_gt0 // gtnNdvd ?prime_gt1."
      "Qed."
      ]]*/
    
    /*
      "Require Import Coq.Init.Prelude."
      "Require Import Arith."
      "Check nat."
      "From hahn Require Import Hahn."
      "Load \"coq-pkgs/imm/src/hardware/Arm-redacted.v\"."
    ]]*/

  find-sid: (sid) ->
    for stm in @doc
      if stm.sid == sid then return stm

  find-sid-index: (sid) ->
    for stm, i in @doc
      if stm.sid == sid then return i

  coqReady: (sid) ->
    require! fs
    @coq.reassureLoadPath []
    if sid == 1
      @doc[0]
        ..sid = 2
        ..added = true
        @coq.add sid, ..sid, ..text, true

  coqCoqExn: (, , msg) ->
    console.error "[Exception] #{@pprint.pp2Text(msg)}"

  coqLog: ([lvl], msg) ->
    console.log "[#{lvl}] #{@pprint.pp2Text(msg)}"

  feedProcessingIn: (sid) ->
    stm = @find-sid(sid)
    if stm?
      stm.executed = true

  feedProcessed: (sid) ->
    console.log "Processed", sid

    idx = @find-sid-index(sid)

    if idx?
      stm = @doc[idx + 1]
      if stm? && !stm.added
        stm.sid = sid + 1
        stm.added = true
        @coq.add sid, stm.sid, stm.text, true
      if !stm? && @inspect-prefix?
        @coq.sendCommand ["Inspect", ["ModulePrefix", @inspect-prefix]]

  feedMessage: (sid, [lvl], loc, msg) ->
    console.log '-' * 40
    console.log lvl
    console.log @pprint.pp2Text(msg)
    console.log '-' * 40

  feedFileDependency: ->
  feedFileLoaded: ->

  coqAdded: (sid) ->
    stm = @find-sid(sid)
    if stm?
      if !stm.executed
        setImmediate ~> @coq.exec sid
  
  coqGoalInfo: (sid, goals) ->
    console.log "Goals (sid=#{sid})"
    console.log @pprint.pp2Text(goals)

  coqSearchResults: (bunch) ->
    console.log "Search results (#{bunch.length} entries)."
    @search-results = [ast.Identifier.of-kername(kn) for [kn,ty] in bunch]
    if @inspect-prefix?
      out-fn = "#{@inspect-prefix.join('.')}.symb.json"
      fs.writeFileSync out-fn, JSON.stringify({lemmas: @search-results})



class CoqProject
  (@filename) ->
    if fs.statSync(@filename).isDirectory!
      @base-dir = @filename
      @filename = path.join @base-dir, '_CoqProject'
    else
      @base-dir = path.dirname(@filename)
    @_text = fs.readFileSync(@filename, 'utf-8')
    @load-path = []
      for line in @_text.split(/\n+/)
        if (mo = /\s*-R\s+(\S+)\s+(\S+)/.exec(line))
          ..push ...@recursive(mo.2.split("."), path.join(@base-dir, mo.1))

  recursive: (modpath, dir) ->
    mods = find.dirSync(dir) \
               .map(-> path.relative(dir, it).split("/")) \
               .filter(@~is-valid-modpath)
    [[modpath ++ m, [dir, ...m, '.']] for m in [[], ...mods]]

  is-valid-modpath: (modpath) ->
    modpath.every(@~is-valid-identifier)

  is-valid-identifier: (name) ->
    /^[a-zA-Z_][a-zA-Z_0-9]*$/.exec(name)?


#coq = new HeadlessWorker
#coq.observers.push new HeadlessManager(coq)

coq = new HeadlessManager

bare-minimum = ["Coq/ltac/ltac_plugin.cmo", "Coq/ltac/tauto_plugin.cmo", 
                "Coq/syntax/nat_syntax_plugin.cmo", 
                "Coq/cc/cc_plugin.cmo",
                "Coq/firstorder/ground_plugin.cmo"]

require! fs
require! path
require! find

COQPKGS = 'node_modules/jscoq/coq-pkgs'

COQPROJS = [new CoqProject('coq-pkgs/imm')]

find.eachfile /\.cmo$/, "#COQPKGS/Coq", coq.coq~register
.end ->
  COQLIB = find.dirSync("#COQPKGS/Coq") \
               .map(-> path.relative(COQPKGS, it).split("/"))
  MATHCOMPLIB = find.dirSync("#COQPKGS/mathcomp") \
               .map(-> path.relative(COQPKGS, it).split("/"))
  LIB = COQLIB ++ MATHCOMPLIB
  coq.coq.init({implicit_libs: true, stm_debug: false}, [], [[[], ['.']]] ++ \
    [[mod, [COQPKGS]] for mod in LIB].concat(...COQPROJS.map (.load-path)))


export HeadlessWorker, coq, COQPROJS

