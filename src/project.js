
const {CoqBuild} = coqBuild;

var coq_build, pm, cm;

function setupPackageManager(coq_manager) {
    var pm = new PackageManager($('#packages-panel')[0]);
    pm.coq = coq_manager.coq;

    // Load standard libs from coq-pkgs
    var pkgs= ['init', 'coq-base', 'coq-collections', 'coq-arith', 'coq-reals'],
        deps = ['init'];
    pkgs.reduce((p, d) => p.then(() => pm.addBundleResource(d)), Promise.resolve())
    .then(() => pm.loadDeps(deps))
    .then(() => coq_manager.project.path.push(...pm.getLoadPath()));

    return pm;
}

function loadFromSelectedFiles(ev) {
    var files = ev.dataTransfer ? ev.dataTransfer.files
        : (ev.target.files || []);
    
    for (let file of files) {
        if (file.type === 'application/zip') {
            coq_build.startNew().ofZip(file)
            .then(() => coq_build.prepare());

            return; /* TODO multiple zips? */
        }
    }
    /*
     * TODO support folders in webkit
    for (let item of drop_ev.dataTransfer.items) {
        if (item.kind === 'folder') {
            console.log(item, item.webkitGetAsEntry());
        }
    }
    */
}

function setupDropZone(jdom) {
    jdom.on('dragover', ev => {
        if (ev.originalEvent.dataTransfer.types.includes("Files")) {
            jdom.addClass('draghov');
            ev.preventDefault();
            ev.originalEvent.dataTransfer.dropEffect = 'link';
        }
    });
    jdom.on('dragenter', ev => { jdom.addClass('draghov'); });
    jdom.on('dragleave', ev => { jdom.removeClass('draghov'); });
    jdom.on('drop', ev => {
        ev.preventDefault(); ev.stopPropagation();
        jdom.removeClass('draghov');
        loadFromSelectedFiles(ev.originalEvent);
    });
}



loadJsCoq().then(async () => {

    coq_build = await new CoqBuild().ofDirectory('coq-pkgs/toy');

    $(() => {
        coq_build.withUI('#project-panel file-list', '#log-panel');
    });
    
    Object.assign(coq_build.options, {
        prelude: true, log_debug: true, debug: true
    });

    coq_build.prepare();

    pm = setupPackageManager(coq_build.coq);

    cm = new CmCoqProvider('code-pane');

    // UI events
    setupDropZone($('#outline-pane'));
    $('#open').click(() => $('#open-files').click());
    $('#open-files').change(ev => loadFromSelectedFiles(ev.originalEvent));
    $('#build').click(() => coq_build.start());
});
