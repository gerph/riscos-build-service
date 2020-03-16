<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>JFPatch as a Service</title>
  <link rel="stylesheet" type="text/css" href="site.css" />
  <script src="ansi_up.js" type="text/javascript"></script>
  <script type="text/javascript">
<!--

    var ws;
    var ansi_up = new AnsiUp;

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

      // Connect to Web Socket
      server = "ws://jfpatch.riscos.online/ws";
      if (window.location.protocol == "https:")
        server = server.replace('ws:', 'wss:')
      try {
        ws = new WebSocket(server);
      }
      catch (err)
      {
        alert("WebSockets aren't working: " + err);
        return;
      }

      // Set event handlers.
      ws.onopen = function() {
        debug("onopen");
      };

      ws.onmessage = function(e) {
        // e.data contains received string.
        debug("onmessage: " + e.data);
        var message = JSON.parse(e.data);
        var action = message[0];
        var data = message[1];
        if (action == 'output') {
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
      };

      ws.onerror = function(e) {
        debug("onerror: " + e);
        console.log(e)
      };

      // Ensure that the state is consistent when we load.
      show_clear();
    }

    function onSubmit() {
        var input = document.getElementById("input");
        var action = input.value;
        var data = null;
        var message = [action, data];
        ws.send(JSON.stringify(message));
        debug("send: " + input.value);
        input.value = "";
        input.focus();
    }

    function onBuild() {
        var action = 'build'
        var data = null;
        var message = [action, data];
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

    function onSourceLoad(data) {
        action = 'source';

        var message =[action, btoa(data)];
        ws.send(JSON.stringify(message));
        debug("send: " + message);

        show_clear();
        show_message('Source selected, size is ' + data.length + ' bytes');

        var bbutton = document.getElementById("build-button");
        bbutton.removeAttribute('disabled');
    }
    function onSourceError(data) {
        debug("error loading source");
        alert("Could not lost source");
        // FIXME: Report this to the user?
    }

    function onCloseClick() {
        ws.close();
    }

    // Clears all the state when we start a fresh build
    function show_clear(str) {
        var cdiv = document.getElementById("output");
        cdiv.innerHTML = '';

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
        html = "<div class='protoerror'>Protocol error: " + escapeHTML(str) + "</div>";
        cdiv.innerHTML += html;
    }

    function show_output(str) {
        html = ansi_up.ansi_to_html(str);
        var cdiv = document.getElementById("output");
        cdiv.innerHTML += html;
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
</head>

<body onload="init();">
    <page section='Build'>
      <!-- General command submission -->
      <form id='general' onsubmit="onSubmit(); return false;">
        <input type="text" id="input"/>
        <input type="text" id="data"/>
        <input type="submit" value="Send"/>
        <button onclick="onCloseClick(); return false;">close</button>
      </form>

      <div class='workflow'>
          <!-- File selection -->
          <form onsubmit="onSubmit(); return false;">
            <label id="source-button" title="Upload source file">
                <input type="file" id="source" onchange="onSourceChange(this.files)"/>
                <img src="icons/upload.png" alt="[Upload]"/>
            </label>
          </form>
          <span class='divider'></span>

          <label id='build-button' disabled='disabled' title="Build the sources in the cloud">
              <button id='build' onclick="onBuild(); return false;"></button>
              <img src="icons/build.png" alt="[Build]"/>
          </label>

          <span class='divider'></span>

          <label id='download-button' disabled='disabled' title="Download the built RISC OS binary">
              <button id='download' onclick="onDownload(); return false;"></button>
              <img src="icons/download.png" alt="[Download]"/>
              <span id='download-label'>
              </span>
          </label>
      </div>

      <div id='output-box'>
        <div id='output-heading'>Build output</div>
        <div id='output'></div>
      </div>
      <div id='throwback-box' style='display: none'>
          <div id='throwback-heading'>Throwback</div>
          <div id='throwback'></div>
      </div>
      <div id="log"></div>
    </page>
</body>
</html>
