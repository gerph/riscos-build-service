<html>
<html-header title='API docs'></html-header>
<body>
    <page section='API documentation'>

<section>
<h2>Introduction</h2>
The build service operates on two separate protocols, which drive the underlying technology that provides the RISC OS building environment. The distinction between the protocols allows clients with different needs to get information in a different manners.

<ul>
    <li><b>HTTP protocol</b>: The HTTP protocol provides a blocking interface, where the client sends a POST request to the server, and there is no response until the build has completed. The protocol also has two variants - one where it responds with only the built binary (or an error report), and a second where it returns a structured JSON response from the build.</li>
    <li><b>WebSocket protocol</b>: The Web Socket protocol provides a streaming interface, where the client connects to the service, then issues commands to direct it to perform actions, and the server responds to those actions in real time.</li>
</ul>

The HTTP protocol is useful for clients that want the operation to be performed and get the result, and do not care about what is happening at the server side. The WebSocket protocol is useful for clients that wish to report on the progress, or perform a number of operations in series.

<h3>Principles</h3>

<p>
    The system is not complex, but it helps to understand how the service should be used. To function the service must be supplied source code, usually a JFPatch file. JFPatch files were originally intended to be used to patch a separate binary. In such cases, a zip archive can be supplied containing the files that are to be used for the build.
</p>

<p>
    Additional options may (in the future) be given to determine how the build should take place. No such options have been defined in the protocol as yet, so there's nothing to supply to configure the build.
</p>

<p>
    Once the source and any options have been supplied, the build can be started by the client. The cogs turn, archives are unpacked and the build tool (usually JFPatch) is invoked. Any character output is recorded, and sent back to the client as necessary. Throwback is captured and returned to the client as it happens (or buffered for the blocking protocols). Failures (exiting with an error, a non-0 return code, or an abort such as a data abort) cause the build to terminate and will be reported as non-0 return codes to the user. Successful build is recognised by copying the build file to the clipboard, which is then transferred to the client.
</p>

<p>
    Multiple output files are not currently supported.
</p>
</section>

<section>
<h2>HTTP protocol<small>: Blocking HTTP build service</small></h2>

<h3>Protocol</h3>
<p>
The HTTP build service allows building of RISC OS binaries through a POST request,
with the response format selectable through the URI.</p>

<p>
POST requests are <media-type>application/x-www-form-urlencoded</media-type> with the following parameters:</p>

<param-list>
    <param name='source'>the source data to build</param>
</param-list>

<p>The response depends on format selected by the URI. The following URIs are supported:</p>

<endpoint-list>
    <endpoint url='/build/binary' method='POST'>
        Outputs a binary file from the build when successful, with the content
        type <media-type>application/riscos</media-type>, supplying the filetype with the name. On a failed build a
        400 response will be given with a content type of <media-type>text/plain</media-type>, and a body describing
        the build messages.
    </endpoint>

    <endpoint url="/build/json" method='POST'>
        Outputs JSON encoded details of the build and output. The following
        dictionary keys are defined:
        <param-list>
            <param name='messages'>A list of build management messages, explaining what the system did to perform the build.</param>
            <param name='throwback'>A list of throwback event structures. Each structure is the same format as the 'throwback' server action in the WebSocket protocol.</param>
            <param name='output'>A list of text lines output by the build process.</param>
            <param name='data'>Base64 encoded binary which was built.</param>
            <param name='filetype'>RISC OS file type of the built binary.</param>
            <param name='rc'>Return code for the build. Usually 0 for success or 1 for failure.</param>
        </param-list>
    </endpoint>
</endpoint-list>
</section>

<section>
<h2>WebSocket protocol<small>: Streaming protocol</small></h2>

The WebSocket build protocol is based on messages to and from the server. Like the regular HTTP
protocol, it must be supplied with the source in order to build. This tool handles the requests
in a way that allows a very simple command line invocation of the tool and to obtain its binary
output from the clipboard.

<h3>Protocol</h3>

<p>The server and client communicate through messages. Each message is a JSON encoded list of two
items.</p>

<ul>
<li>The first element (the 'action') of the list indicates how the message should be processed.</li>
<li>The second element (the 'data') contains any clarifying content for the action. Usually this
  is a string, but it may be a data structure for some actions.</li>
</ul>

<p>
When first connected, the server will send a 'welcome' message.
Each message from the client will be responded to with either a 'response' or 'error' message.
The server may send other messages to the client at any time to explain its progress.
</p>

<h3>Server actions</h3>

<param-list label='Action'>
<param name='welcome'>Introduces the server.<br/>
    Data is the server name and version number.
</param>

<param name='response'>Sent as a successful response to an action from the client.<br/>
    Data is a string giving an indication of how the action was processed.
</param>

<param name='error'>Sent as an unsuccessful response to an action from the client.<br/>
    Data is a message describing the failure.
</param>

<param name='message'>Build management message, sent to explain what the system is doing to manage the requested build.<br/>
    Data is a string explaining the action. All strings are complete statements, without a
    trailing newline.
</param>

<param name='output'>Text produced by the build process itself.<br/>
    Data is a string from the build. Each string may contain ANSI control characters. The
    strings will be delivered in a timely manner, but may have been concatenated in order
    to reduce protocol overheads. The RISC OS environment uses the Latin-1 encoding, which
    is converted to UTF-8 before transmission from the server - this output will always be
    in UTF-8.
</param>

<param name='throwback'>Information about a throwback event in the build system.<br/>
    Data is a dictionary containing the following keys:
    <param-list label='Key'>
        <param name='reason'>Throwback reason number (see DDEUtils documentation).</param>
        <param name='reason_name'>Human readable string for the reason number (or a number if the reason does not have a name). Usually 'Processing', 'Error' or 'Info'.</param>
        <param name='filename'>RISC OS filename to which this event applies.</param>
        <param name='lineno'>The line number in the given filename to which thie event applies.</param>
        <param name='severity'>Throwback severity number (see DDEUtils documentation).</param>
        <param name='severity_name'>Human readable string for the severity number (or a number if the severity does not have a name). Usually 'Error', 'Warning' or 'Serious Error'.</param>
        <param name='url'>A 'riscos' scheme URL for the file and line.</param>
        <param name='message'>Message reported by this event.</param>
    </param-list>
    There may be multiple errors or warnings from the build tool. The front end on this site ignores any throwback reasons of 'Processing'.
</param>

<param name='clipboard'>Built binary content (this is delivered by a clipboard copy operation internally).<br/>
    Data is a dictionary containing the following keys:
    <param-list label='Key'>
        <param name='filetype'>RISC OS filetype number for the content.</param>
        <param name='data'>Base64 encoded binary data.</param>
    </param-list>
</param>

<param name='rc'>Return code from the system (usually non-0 if a failure occurred)<br/>
    Data is a number, usually 0 or 1, but other return codes may be produced by different tools.
    The environment gives a return code of 125 for a failure with an abort.
</param>

<param name='complete'>Declares the build process complete.<br/>
    Data is a True value.
</param>
</param-list>



<h3>Client actions</h3>

<param-list label='Action'>

<param name='source'>Supplies the source code that should be built.<br/>
    Data is a base64 encoded source to build.
</param>

<param name='build'>Requests that the build starts.<br/>
    Data is ignored.
</param>
</param-list>
</section>

<section>
<h2>Example WebSocket communication</h2>

The following examples show the interaction between the client and the WebSocket server.

<$macro message-table /CLOSE title:string/REQUIRED>
<h3>Exchange for a successful build</h3>
<table class='msg-table'>
    <!-- <caption><(title)></caption> -->
    <thead>
        <tr>
            <th>Sender</th>
            <th>Action</th>
            <th>Content</th>
        </tr>
    </thead>
    <tbody>
<$content>
    </tbody>
</table>
</$macro>

<$macro message /CLOSE sender:string/REQUIRED
                       action:string/REQUIRED
                       content:string/REQUIRED>
<tr class=('msg-sender-'+sender)>
    <td class='msg-sender'><(sender)></td>
    <td class='msg-action'><(action)></td>
    <td class='msg-data'><div class='msg-body'><(content)></div>
        <div class='msg-annotation'><$content></div>
    </td>
</tr>
</$macro>


<!-- Build successful -->
<message-table title='WebSocket exchange for a successful build'>
<message sender='server' action='welcome'
         content="'Linking over Internet with RISCOS Pyromaniac Agent version 1.04'">
     Server announcement and version number.
</message>

<message sender='client' action='source'
         content="&lt;base64 source data&gt;">
     Client supplies source data to be processed.
</message>

<message sender='server' action='response'
         content="'Source loaded'">
     Server acknowledges receipt of the source. This does not mean that the source is buildable by the service.
</message>

<message sender='client' action='build'
         content="None">
     Client requests that the build start.
</message>

<message sender='server' action='response'
         content="'Started build'">
     Server acknowledges the request to start a build and begins processing it.
</message>

<message sender='server' action='message'
         content="'Build tool selected: JFPatch'">
     Server has determined the build tool to use; if the source was not understood a different message would be produced, and the exchange would report the build completion.
</message>

<message sender='server' action='output'
         content="'JFPatch ARM assembler v2.56\xdf (02 Mar 2020) [Justin Fletcher]\r\n'">
     Output from the build tool.
</message>

<message sender='server' action='output'
         content="'Pre-processing...\r\n'">
</message>

<message sender='server' action='output'
         content="'Assembling...\r\n'">
</message>

<message sender='server' action='clipboard'
         content="{'filetype': 4092, 'data': &lt;base64 data&gt;}">
     The output file is supplied, together with its RISC OS filetype.

</message>

<message sender='server' action='rc'
         content="0">
     A return code of 0 indicating that the tool exited without error. This is the machine readable format, which is followed by a human-readable message...
</message>

<message sender='server' action='message'
         content="'Return code: 0'">
</message>

<message sender='server' action='complete'
         content="True">
     The server has finished the build and is now waiting for more source.
</message>
</message-table>


<!-- Build with errors -->
<message-table title='WebSocket exchange for a build with errors'>
<message sender='server' action='welcome'
         content="'Linking over Internet with RISCOS Pyromaniac Agent version 1.04'">
     Server announcement and version number.
</message>

<message sender='client' action='source'
         content="&lt;base64 source data&gt;">
     Client supplies source data to be processed.
</message>

<message sender='server' action='response'
         content="'Source loaded'">
     Server acknowledges receipt of the source. This does not mean that the source is buildable by the service.
</message>

<message sender='client' action='build'
         content="None">
     Client requests that the build start.
</message>

<message sender='server' action='response'
         content="'Started build'">
     Server acknowledges the request to start a build and begins processing it.
</message>

<message sender='server' action='message'
         content="'Build tool selected: JFPatch'">
     Server has determined the build tool to use; if the source was not understood a different message would be produced, and the exchange would report the build completion.
</message>

<message sender='server' action='output'
         content="'JFPatch ARM assembler v2.56\xdf (02 Mar 2020) [Justin Fletcher]\r\n'">
     Output from the build tool.
</message>

<message sender='server' action='output'
         content="'Pre-processing...\r\n'">
</message>

<message sender='server' action='output'
         content="'Assembling...\r\n'">
</message>

<message sender='server' action='throwback'
         content="{'severity': 2, 'url': 'riscos:///source#70', 'filename': 'source', 'reason': 1, 'severity_name': 'Serious Error', 'lineno': 70, 'message': 'Unknown or missing variable', 'reason_name': 'Error'}">
     An error was found whilst trying to assemble the file. The structured data in the throwback report indicates what type of errors were seen.
</message>

<message sender='server' action='output'
         content="'Error: Unknown or missing variable (Error number &amp;1a)\n'">
     Further character output from the build tool, describing the error message.
</message>

<message sender='server' action='rc'
         content="1">
     A return code of 1 indicating that the tool failed. This is the machine readable format, which is followed by a human-readable message...
</message>

<message sender='server' action='message'
         content="'Return code: 1'">
</message>

<message sender='server' action='complete'
         content="True">
     The server has finished the build and is now waiting for more source.
</message>
</message-table>
</section>

    </page>
</body>
</html>
