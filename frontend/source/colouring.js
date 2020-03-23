function setup_colouring(opts) {
    if (!opts)
        opts = {};
    var want_linenumbers = opts['linenumbers'] ? true : false;
    var want_autosize = opts['autosize'] ? true : false;
    var want_scroll = opts['scroll'] ? true : false;

    var extra_style = '';
    if (want_autosize)
        extra_style = ' autosize';
    else if (want_scroll)
        extra_style = ' scrolly';

    var areas = document.getElementsByClassName('source-code');
    for (var i = 0; i < areas.length; i++) {
        var textarea = areas[i];
        var options = {
                lineNumbers: want_linenumbers,
                mode: 'text/x-jfpatch',
                theme: 'liquibyte' + extra_style,
                lineWrapping: true,
                viewportMargin: (want_autosize ? Infinity : 10),
            };
        if (textarea.readOnly)
        {
            // 'nocursor' => no cursor, cannot use keyboard to scroll, cannot edit, can select
            //options.readOnly = 'nocursor';

            // true => cursor visible (but not blinking, with rate change), can use keyboard to
            //         scroll, cannot exit, can select
            options.readOnly = true;
            options.cursorBlinkRate = 0;
        }
        var cm = CodeMirror.fromTextArea(textarea, options);
    }
}
