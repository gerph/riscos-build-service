<!DOCTYPE html>
<html>
<html-header title='Builder' codecolouring>
  <script src="ansi_up.js" type="text/javascript"></script>
  <script type="text/javascript">
<!--

    var ws;
    var ws_timeout;
    var ansi_up = new AnsiUp;
    var cm;
    var source_code;
    var source_type;
    var unsent_changes = false;

    // Clipboard information
    var clipboard_data = null;
    var clipboard_filetype = null;

    // Throwback state
    var throwback_file = null;
    var throwback_reason = null;

    var filetype_names = {
            0xFFD: 'Data',
            0xFFC: 'Utility',
            0xFFA: 'Module',
            0xFF8: 'Absolute',
        };
    var filetype_icons = {
            0xFFC: 'icons/file_ffc.png',
            0xFFA: 'icons/file_ffa.png',
            0xFF8: 'icons/file_ff8.png',
        };
    var filetype_unknown = 'icons/file_xxx.png';

    function init() {
      ws_connect();

      // Ensure that the state is consistent when we load.
      show_clear();
    }

    function ws_connect() {
      ws = undefined;
      ws_timeout = undefined;

      // Connect to Web Socket
      debug("connect websocket");
      server = "ws://jfpatch.riscos.online/ws";
      if (window.location.protocol == "https:")
        server = server.replace('ws:', 'wss:')

      ws_show_status('Connecting');
      try {
        ws = new WebSocket(server);
      }
      catch (err)
      {
        debug("websocket error: " + err);
        ws_show_status('Error');
        alert("WebSockets aren't working: " + err);
        return;
      }

      // Set event handlers.
      ws.onopen = function() {
        debug("onopen");
        if (source_code)
        {
            if (!unsent_changes)
            {
                show_message("Reconnected to server; source will need to be resent");
                mark_unsent(true);
            }
        }
      };

      ws.onmessage = function(e) {
        // e.data contains received string.
        debug("onmessage: " + e.data);
        var message = JSON.parse(e.data);
        var action = message[0];
        var data = message[1];
        if (action == 'welcome') {
            ws_show_status('OK');
        }
        else if (action == 'output') {
            show_output(data);
        }
        else if (action == 'message') {
            show_message(data);
        }
        else if (action == 'rc') {
            show_rc(data);
        }
        else if (action == 'clipboard') {
            show_clipboard(data);
        }
        else if (action == 'throwback') {
            show_throwback(data);
        }
        else if (action == 'error') {
            show_error(data);
        }
        else if (action == 'complete') {
            mark_running(false);
        }
      };

      ws.onclose = function() {
        debug("onclose");
        ws_show_status('Disconnected');
        console.log('Connection closed')

        // Retry connection
        ws = null;
        ws_retry();
      };

      ws.onerror = function(e) {
        debug("onerror: " + e);
        ws_show_status('Error');
        console.log(e)

        // Retry connection
        ws = null;
        ws_retry();
      };
    }

    function ws_retry() {
        if (ws_timeout)
        {
            clearTimeout(ws_timeout);
        }
        // Retry after 15 seconds
        ws_timeout = setTimeout(ws_connect, 1000 * 15);
    }

    function ws_show_status(str) {
        var sdiv = document.getElementById("status-value");
        sdiv.innerHTML = str;
        sdiv.className = 'status-value status-' + str.toLowerCase();
        hidden = (str == 'OK');

        var sdiv = document.getElementById("status");
        sdiv.style.display = (hidden ? 'none' : 'inline');
        // FIXME: When I'm clever, use transitions to make this slide on and off the screen instead
        //        of just vanishing.
    }


    function onSubmit() {
        var input = document.getElementById("input");
        var action = input.value;
        var data = null;
        var message = [action, data];
        if (!ws)
        {
            show_error("Cannot send message to server; not connected");
            return;
        }
        ws.send(JSON.stringify(message));
        debug("send: " + input.value);
        input.value = "";
        input.focus();
    }

    function onBuild() {
        var action = 'build'
        var data = null;
        var message = [action, data];
        if (!ws)
        {
            show_error("Cannot build on server; not connected");
            return;
        }

        ws.send(JSON.stringify(message));
        debug("send: " + input.value);
        show_clear();
        mark_running(true);
    }

    function onDownload() {
        save('built,' + clipboard_filetype.toString(16),
             clipboard_data,
             'application/riscos')
    }

    function onSourceChange() {
        var ele = document.getElementById('source');
        var file = ele.files[0];
        if (file) {
            var reader = new FileReader();
            reader.readAsBinaryString(file);
            reader.onload = function (evt) { onSourceLoad(evt.target.result) };
            reader.onerror = function (evt) { onSourceError(evt.target.result) };
            ele.value = '';
        }
    }

    function onCreate() {
        // User clicked the 'Create Document' button.
        if (unsent_changes || source_code)
        {
            ok = confirm("Creating a new source file will clear your current document. Are you sure you want to create a new source file?")
            if (!ok)
                return;
        }
        // Hide the help now that they clicked a button
        show_help(false);

        source_code = '';
        show_source();
        focus_source();
        mark_unsent(true);
    }

    function onHelp() {
        toggle_help();
    }

    function onSourceLoad(data) {
        // Hide the help now that they clicked a button
        show_help(false);

        source_code = data;
        if (!send_source())
            // Failed to send the source
            mark_unsent(true);
        else
            mark_unsent(false);
        show_source();
    }

    function onSourceError(data) {
        debug("error loading source");
        alert("Could not load source");
        // FIXME: Report this to the user better?
    }

    function onCloseClick() {
        ws.close();
    }

    function onSave() {
        source_code = cm.getValue();

        // Check if the media type has changed
        var mediatype = detect_mode(source_code);
        if (mediatype != source_type)
        {
            show_source();
        }

        if (send_source())
            // Failed to send the source
            mark_unsent(false);
        else
            mark_unsent(true);
    }

    // Send the source we've got to the server.
    function send_source() {
        var action = 'source';
        var message =[action, btoa(source_code)];
        if (!ws)
        {
            show_error("Cannot send source to server; not connected");
            return false;
        }
        ws.send(JSON.stringify(message));
        debug("send: " + message);

        show_clear();
        show_message('Source sent to server, size is ' + source_code.length + ' bytes');

        var bbutton = document.getElementById("build-button");
        bbutton.removeAttribute('disabled');
        return true;
    }

    // Show the source in our editor box.
    function show_source() {
        var source_box = document.getElementById('source-box');
        if (cm)
        {
            // Convert it back to a text area, so that we end up with the same state
            // each time.
            cm.off('changes', onEditorChange);  // disable the change trigger.
            cm.setValue('');
            cm.toTextArea();
            cm = undefined;
        }
        if (source_code.startsWith('PK'))
        {
            // It's a Zip archive; don't even try to process it.
            source_box.style.display = 'none';
            return;
        }

        // Unhide the source box.
        source_box.style.display = 'block';

        var textarea = document.getElementById('source-content');

        // FIXME: Harmonise this with colouring.js?
        var want_linenumbers = true;
        var want_autosize = false;
        var want_scroll = true;

        var mediatype = detect_mode(source_code);
        source_type = mediatype;

        var extra_style = '';
        if (want_autosize)
            extra_style = ' autosize';
        else if (want_scroll)
            extra_style = ' scrolly';

        var options = {
                lineNumbers: want_linenumbers,
                mode: mediatype,
                theme: 'liquibyte' + (want_autosize ? ' autosize' : ''),
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


        cm = CodeMirror.fromTextArea(textarea, options);
        cm.setValue(source_code);

        mark_unsent(false);

        cm.on('changes', onEditorChange);

        // Make tabs insert spaces
        cm.setOption("extraKeys", {
          Tab: function(cm) {
            var spaces = Array(cm.getOption("indentUnit") + 1).join(" ");
            cm.replaceSelection(spaces);
          }
        });
    }

    // Give our source code focus
    function focus_source() {
        if (cm)
            cm.focus();
    }

    function onEditorChange(cm, changes) {
        if (! unsent_changes)
        {
            // This is the first time we've received changes to the code that was uploaded,
            // so take away the 'build' button, and put a '*' on the title
            debug('changes in ' + cm);
            mark_unsent(true);
            show_message('Source changed; use the Send button to send to the server');
        }
    }

    function toggle_help() {
        show_help(-1);
    }
    function show_help(state) {
        // state should be -1 to toggle, truthy to enable, falsey to disable
        var hdiv = document.getElementById("help");
        if (state == -1)
            state = (hdiv.style.display == 'none');
        if (state)
        {
            hdiv.style.display = 'block';
        }
        else
        {
            hdiv.style.display = 'none'
        }
    }

    // Make the message box visible
    // FIXME: Move all this handling into an object rather than arbitrary functions
    function show_message_box(state) {
        var sdiv = document.getElementById("output-box");
        sdiv.style.display = state ? 'block' : 'none';
    }

    // Clears all the state when we start a fresh build
    function show_clear(str) {
        var cdiv = document.getElementById("output");
        cdiv.innerHTML = '';
        show_message_box(false);

        var dbutton = document.getElementById("download-button");
        var dlabel = document.getElementById("download-label");
        dbutton.setAttribute('disabled', 'disabled');
        dlabel.innerHTML = ''

        var tboxdiv = document.getElementById("throwback-box");
        var tdiv = document.getElementById("throwback");
        tboxdiv.style = 'display: none';
        tdiv.innerHTML = '';

        throwback_file = null;
        throwback_reason = null;
    }

    function show_error(str) {
        mark_running(false);

        var cdiv = document.getElementById("output");
        html = "<span class='protoerror'>Protocol error: " + escapeHTML(str) + "</span>";
        cdiv.innerHTML += html;

        show_message_box(true);
        console.log('WS error: ' + str);
    }

    function show_output(str) {
        html = ansi_up.ansi_to_html(str);
        var cdiv = document.getElementById("output");
        cdiv.innerHTML += html;

        show_message_box(true);
    }

    function show_throwback(data) {
        var reason = data['reason_name']
        if (reason == 'Processing') {
            // I'm imitating Zap here, so I'll just ignore the 'processing' message.
            // We could output a note that we're processing if we wanted, but it's probably
            // not going to be useful as that information is commonly in the main build
            // output.
            // Note: Processing only has a filename; no other data present.
            return
        }
        var file = data['filename']
        var lineno = data['lineno']
        var severity = data['severity_name']
        var message = data['message']
        // Zap doesn't show the severity for information (maybe it doesn't have a meaning there)

        var html = '';
        if (file != throwback_file || reason != throwback_reason) {
            // Need to introduce a new section
            var section_css = ''
            if (reason == 'Error') {
                section = "Errors in file: "
                section_css = 'error'
            }
            else if (reason == 'Info') {
                section = "Information for file: "
                section_css = 'info'
            }
            else {
                section = "Throwback for reason " + reason + ": "
            }
            html += "<div class='section " + section_css + "'>"
            html += "<span class='reason'>" + section + "</span>"
            html += "<span class='filename'>" + file + "</span>"
            html += "</div>"

            // And a new set of headings
            html += "<div class='heading'>"
            html += "<span class='line'>Line</span>"
            if (reason != 'Info') {
                // Info doesn't have a severity
                html += "<span class='type'>Type</span>"
            }
            html += "<span class='message'>Message</span>"
            html += "</div>"

            // Update our throwback state
            throwback_file = file
            throwback_reason = reason
        }

        // Write out the event
        html += "<div class='event'>"
        html += "<span class='line'>" + lineno + "</span>"
        if (reason != 'Info') {
            // Info doesn't have a severity
            var severity_css = ''
            if (severity == 'Error') {
                severity_css = 'error'
            }
            if (severity == 'Serious Error') {
                severity_css = 'serious'
            }
            if (severity == 'Warning') {
                severity_css = 'warning'
            }

            html += "<span class='type " + severity_css + "'>" + severity + "</span>"
        }
        html += "<span class='message'>" + escapeHTML(message) + "</span>"
        html += "</div>"

        var tboxdiv = document.getElementById("throwback-box");
        var tdiv = document.getElementById("throwback");
        tboxdiv.style = '';
        tdiv.innerHTML += html;
    }

    function show_message(str) {
        var cdiv = document.getElementById("output");
        html = escapeHTML(str);
        cdiv.innerHTML += "<span class='message'>" + html + "</span>";

        show_message_box(true);
    }
    function show_rc(rc) {
        var status;
        if (rc == 0)
        {
            message = 'Success';
            status = 'success';
        }
        else
        {
            message = 'Failed (rc=' + rc + ')'
            status = 'failure';
        }
        var cdiv = document.getElementById("output");
        cdiv.innerHTML += "<span class='rc " + status + "'>" + message + "</span>";

        show_message_box(true);
    }

    function show_clipboard(data) {
        clipboard_filetype = data['filetype'];
        clipboard_data = atob(data['data'])

        filetype_name = filetype_names.hasOwnProperty(clipboard_filetype) ? filetype_names[clipboard_filetype] : '&amp;' + clipboard_filetype.toString(16);

        message = 'Download available, filetype is ' + filetype_name;

        var cdiv = document.getElementById("output");
        cdiv.innerHTML += "<span class='clipboard'>" + message + "</span>";

        var dbutton = document.getElementById("download-button");
        var dlabel = document.getElementById("download-label");
        dbutton.removeAttribute('disabled');

        // Set up the label on the download button
        if (0)
        {
            dlabel.innerHTML = 'Download (' + filetype_name + ')'
        }
        else
        {
            icon = filetype_names.hasOwnProperty(clipboard_filetype) ? filetype_icons[clipboard_filetype] : filetype_unknown;
            html = "<img src='" + icon + "'>";
            dlabel.innerHTML = html;
        }
    }

    function mark_running(running) {
        var bdiv = document.getElementById("build-button");
        var sdiv = document.getElementById("source-button");
        if (running) {
            bdiv.setAttribute('disabled', 'disabled');
            sdiv.setAttribute('disabled', 'disabled');
        }
        else
        {
            bdiv.removeAttribute('disabled');
            sdiv.removeAttribute('disabled');
        }
    }

    function mark_unsent(unsent) {
        var bdiv = document.getElementById("build-button");
        unsent_changes = unsent;
        if (unsent) {
            bdiv.setAttribute('disabled', 'disabled');
        }
        else
        {
            bdiv.removeAttribute('disabled');
        }

        var sbutton = document.getElementById('source-save-button');
        sbutton.style.display = unsent ? 'inline' : 'none';

        var heading = document.getElementById('source-heading');
        html = heading.innerHTML.replace(' *', '')
        if (unsent)
        {
            html += ' *';
        }
        heading.innerHTML = html;
    }

    function escapeHTML(unsafe) {
        return unsafe
             .replace(/&/g, "&amp;")
             .replace(/</g, "&lt;")
             .replace(/>/g, "&gt;")
             .replace(/"/g, "&quot;")
             .replace(/'/g, "&#039;");
     }

    function debug(str) {
        var log = document.getElementById("log");
        var escaped = escapeHTML(str);
        log.innerHTML += "<br>" + escaped;
    }

    // https://stackoverflow.com/questions/3665115/how-to-create-a-file-in-memory-for-user-to-download-but-not-through-server
    function save(filename, data, mediatype) {
        var blob = new Blob([data], {'type': mediatype});
        if (window.navigator.msSaveOrOpenBlob) {
            window.navigator.msSaveBlob(blob, filename);
        }
        else {
            var elem = window.document.createElement('a');
            elem.href = window.URL.createObjectURL(blob);
            elem.download = filename;
            document.body.appendChild(elem);
            elem.click();
            document.body.removeChild(elem);
        }
    }

-->
  </script>
</html-header>

<body onload="init();">
    <page section='Build'>
      <!-- General command submission -->
      <form id='general' onsubmit="onSubmit(); return false;">
        <input type="text" id="input"/>
        <input type="text" id="data"/>
        <input type="submit" value="Send"/>
        <button onclick="onCloseClick(); return false;">close</button>
      </form>

      <div class='status' id='status'>
        Service status: <span class='status-value status-unknown' id='status-value'>Unknown</span>
      </div>

      <div class='workflow'>
          <!-- New document -->
          <label class='workflow-button' id='create-button' title="Create a new file">
              <button id='create' onclick="onCreate(); return false;"></button>
              <img src="icons/create.png" alt="[Create]"/>
          </label>

          <!-- File selection -->
          <form onsubmit="onSubmit(); return false;">
            <label class='workflow-button' id="source-button" title="Upload source file or zip archive">
                <input type="file" id="source" onchange="onSourceChange(this.files)"/>
                <img src="icons/upload.png" alt="[Upload]"/>
            </label>
          </form>
          <span class='divider'></span>

          <label class='workflow-button' id='build-button' disabled='disabled' title="Build the sources in the cloud">
              <button id='build' onclick="onBuild(); return false;"></button>
              <img src="icons/build.png" alt="[Build]"/>
          </label>

          <span class='divider'></span>

          <label class='workflow-button' id='download-button' disabled='disabled' title="Download the built RISC OS binary">
              <button id='download' onclick="onDownload(); return false;"></button>
              <img src="icons/download.png" alt="[Download]"/>
              <span id='download-label'>
              </span>
          </label>

          <span class='other-icons'>
              <label class='other-button' id='info-button' title="Information on what these things do">
                  <button id='info' onclick="onHelp(); return false;"></button>
                  <img src="icons/information.png" alt="[Information]"/>
              </label>
          </span>
      </div>

      <div id='help' style='display: block;'>

        <h2>1. Load some source code</h2>
        <p>Either:
        </p>
        <ul>
            <li><img src='icons/create.png' alt='[Create]'/> Starts a new source file.<br/>
                Once you've finished editing, press the Send button to send the source to the server.</li>
            <li><img src='icons/upload.png' alt='[Upload]'/> Uploads a source file or zip archive
                from your computer.<br/>
                Zip archives may contain source files and any resources needed (for example, a JFPatch source
                and the binary that it is patching).<br/>
                Example JFPatch files can be found in a <a href="https://github.com/gerph/jfpatch-as-a-service-examples">supporting repository</a>.
            </li>
        </ul>

        <h2>2. Build the source</h2>
        <p><img src='icons/build.png' alt='[Build]'/> Starts the build on the server.<br/>
           A 'Build output' window will appear to show what the build is doing. If there is throwback output,
           this will appear in a separate window.<br/>
           If the build fails, the source editor can be used to edit the code and fix bugs.<br>
           If the build was successful, the download icon will appear.
        </p>

        <h2>3. Download the binary</h2>
        <p><img src='icons/download.png' alt='[Download]'/> Downloads the built binary.<br/>
           Binaries are only returned when the build tool copies them to the clipboard on a successful build.
        </p>
      </div>

      <div class='box source-box' id='source-box' style='display:none'>
        <div class='box-heading' id='source-heading'>
            <label id='source-save-button' style='display: none'>
                <button id='source-save' onclick="onSave(); return false;">[Send]</button>
            </label>
            Source code</div>
        <textarea class='box-content' id='source-content'></textarea>
      </div>
      <div class='box output-box' id='output-box' style='display: none'>
        <div class='box-heading'>Build output</div>
        <div class='box-content' id='output'></div>
      </div>
      <div class='box throwback-box' id='throwback-box' style='display: none'>
          <div class='box-heading'>Throwback</div>
          <div class='box-content' id='throwback'></div>
      </div>
      <div id="log"></div>
    </page>
</body>
</html>
