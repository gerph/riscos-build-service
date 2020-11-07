<!DOCTYPE html>
<html>
<html-header title='Builder' codecolouring>
  <script src="ansi_up.js" type="text/javascript"></script>
  <script src="builder.js" type="text/javascript"></script>
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

      <div class='workflow'>
          <div class='status' id='status'>
            Service status: <span class='status-value status-unknown' id='status-value'>Unknown</span>
          </div>

          <!-- Load document -->
          <label class='workflow-button' id='load-button' title="Load a file from examples">
              <button id='load' onclick="onLoad(); return false;"></button>
              <img src="icons/load.png" alt="[Load]"/>
          </label>

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
      <nav class='load-menu' id='load-menu-container' style='display: none;'>
          <ul class='load-menu-block' id='load-menu'>
          </ul>
      </nav>

      <div id='help' style='display: block;'>

        <h2>1. Load some source code</h2>
        <p>Either:
        </p>
        <ul>
            <li><img src='icons/load.png' alt='[Load]'/> Loads an example file.<br/>
                Examples, taken from the <a href="https://github.com/gerph/jfpatch-as-a-service-examples">supporting repository</a> are selectable here.</li>
            <li><img src='icons/create.png' alt='[Create]'/> Starts a new source file.<br/>
                Once you've finished editing, press the Send button to send the source to the server.</li>
            <li><img src='icons/upload.png' alt='[Upload]'/> Uploads a source file or zip archive
                from your computer.<br/>
                Zip archives may contain source files and any resources needed (for example, a JFPatch source
                and the binary that it is patching).<br/>
                Example source files can be found in a <a href="https://github.com/gerph/jfpatch-as-a-service-examples">supporting repository</a>.
            </li>
        </ul>

        <h2>2. Build the source</h2>
        <p><img src='icons/build.png' alt='[Build]'/> Starts the build on the server.<br/>
           A 'Build output' window will appear to show what the build is doing. If there is throwback output,
           this will appear in a separate window.<br/>
           If the build fails, the source editor can be used to edit the code and fix bugs.<br/>
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
