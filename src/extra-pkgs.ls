require! fs
JSZip = require('jszip')



class ExtraPackages
  (@coq) ->
    @pkg-names = ['hahn', 'sflib', 'paco']

  load: ->
    for let pkg in @pkg-names
      fs.readFile "coq-pkgs/#{pkg}.coq-pkg" (err, data) ~>
        if err
          console.error err
        else
          JSZip.loadAsync data .then (zip) ~>
            @coq.packages.addBundleZip pkg, zip
          .catch -> console.error it



export ExtraPackages