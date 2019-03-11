require! fs
require! path
JSZip = require('jszip')



class ExtraPackages
  (@coq) ->
    @pkg-names = ['hahn', 'sflib', 'paco', 'promising-coq', 'imm-base']
    @search-path = ["coq-pkgs", "node_modules/jscoq/coq-pkgs"]

  resolve: (pkg) ->
    for pe in @search-path
      pkg-path = path.join(pe, "#{pkg}.coq-pkg")
      if fs.existsSync(pkg-path)
        return pkg-path
    throw new Error("package not found: '#{pkg}'")

  load: ->
    for let pkg in @pkg-names
      fs.readFile @resolve(pkg), (err, data) ~>
        if err
          console.error err
        else
          JSZip.loadAsync data .then (zip) ~>
            @coq.packages.addBundleZip pkg, zip
          .catch -> console.error it



export ExtraPackages