<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>JFPatch as a Service</title>
  <link rel="stylesheet" type="text/css" href="site.css" />
</head>
<body onload="init();">
    <page_title section='API documentation'>

    <div class='content'>

<h2>HTTP protocol<small>: Blocking HTTP build service</small></h2>


FIXME: Insert words about why you use this protocol.

<h4>Protocol</h4>
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

<h2>WebSocket protocol<small>: Streaming protocol</small></h2>

The WebSocket build protocol is based on messages to and from the server. Like the regular HTTP
protocol, it must be supplied with the source in order to build. This tool handles the requests
in a way that allows a very simple command line invocation of the tool and to obtain its binary
output from the clipboard.

<h4>Protocol</h4>

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

<h4>Server actions</h4>

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
    Data is a string from the build. Each string may contain RISC OS control characters. The
    strings will be delivered in a timely manner, but may have been concatenated in order
    to reduce protocol overheads.
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



<h4>Client actions</h4>

<param-list label='Action'>

<param name='source'>Supplies the source code that should be built.<br/>
    Data is a base64 encoded source to build.
</param>

<param name='build'>Requests that the build starts.<br/>
    Data is ignored.
</param>
</param-list>

    </div>
</body>
</html>
