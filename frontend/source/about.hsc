<!DOCTYPE html>
<html>
<html-header title='About'></html-header>
<body>
    <page section='About'>

<$macro binary-release url:string="" filename:string="" name:string>
<div class='binary'>
    <span class='binary-release-heading'>Release</span>:
    <span class='binary-release-name'>
        <$if COND=(filename = "")>
            <a href=(url)><(name)></a>
        <$else>
            <filelink filename=("binary/" + filename) label=(name)>
        </$if>
    </span>
</div>
</$macro>

<$macro block-what-is-jfpatch>
<section>
<h2>What is JFPatch?</h2>

<p>
    JFPatch started out as a way to apply assembly changes to binary executables. Essentially, it
    allowed you to say 'at this address, write this instruction'. It used the BBC BASIC assembler to
    provide the assembly language processor that was written into the patched binary. The tool
    became more powerful, and gained the ability not only to patch but to create utility files -
    essentially patching nothing and saving the output.
</p>

<p>
    The tool was extended to add the ability to create modules, with automated
    entry points and registrations of many of the necessary RISC OS interfaces. This came from a
    desire to get on with writing the functional parts of the code, and not messing with the
    boilerplate that was otherwise very common. Eventually, the tool also gained the ability to
    create AOF (linkable object files) and was thus usable with the rest of Acorn's DDE toolchain.
</p>

<p>
    The original version of JFPatch produced 26bit modules. The version used here supports building
    modules for 26bit and 32bit systems.
</p>

<p>
    Additionally, JFPatch has been modified slightly from the last working version from back in 2002 to add support for copying the output binary to the clipboard (which is used to pass the result back to the user, through the Python HTTP server outside the container).
</p>

<h3>How does JFPatch work?</h3>
<p>
    JFPatch is a preprocessor for the BASIC assembler. It's written in BASIC itself. It's not very
    good BASIC, but that's what it is. It takes your input file and parses the sections and
    assembly code to produce another BASIC program which will then build your code. It then runs
    that program. That program usually loads in the input file (if it's patching someting), or
    creates a header as declared in your module or AOF definitions, and then assembles the code.
    It then saves our the result to the output file specified and runs any post-processing code
    you specified.
</p>

<p>
    In this online version, the throwback is actually a HTTP POST to an internal web server to
    report the message, rather than an editor, as the user's editor isn't running on the cloud
    machine where JFPatch executes. Similarly, the cloud version doesn't just save the file,
    but also copies the output to the clipboard. The clipboard is also a HTTP POST to the
    internal server to supply the built binary.
</p>

<p>
    If you asked for throwback, it would generate warnings or errors through the throwback system.
    These would usually appear in a new window hosted by your editor, which allowed you to jump
    to the failure position. If you were running the tool from the desktop, it would also set
    special variables to indicate the status of the build, which the front end would use to display
    a pop-up message.
</p>

<h3>Where can I obtain it?</h3>

<p>
    JFPatch is accessible through the build service by submitting sources using the API,
    or through your browser. It is also available for download here, should you wish to use
    it on RISC OS. JFShared is also required.
</p>

<binary-release filename="jfpatch-app-2.57.41.zip" name="JFPatch application">
<binary-release filename="jfshared.zip" name="JFShared resource">

</section>
</$macro>

<$if COND=(service = 'jfpaas')>
<block-what-is-jfpatch>
<section>
<h2>Why would you need JFPatch as a service?</h2>

<p>
    Why wouldn't you?! Maybe you don't have JFPatch to hand, or you don't have RISC OS on your
    system, but you <em>need</em> to build a RISC OS utility? Or maybe... No. I can't do it... I
    don't know what might cause you to need JFPatch... But if you do, it now exists.
</p>
</section>
<$else>

<section id='build-environment'>
<h2>What is the RISC OS Build service?</h2>
<p>
    The RISC OS Build service is a general build service for building (and testing) RISC OS
    components using a cloud server. It does not require access to hardware running RISC OS,
    and can be triggered from anywhere.
</p>

<p>
    It was originally released under the moniker 'JFPatch-as-a-Service', and it is still heavily
    focused on using the JFPatch pre-processor for building components. However, it is able to
    build assembler, C and Pascal components, running builds under RISC OS. This is not cross-compiling.
    Build sources, makefiles and scripts intended for RISC OS can be run through the RISC OS build
    service.
</p>

<p>
    Standard AMU makefiles are supported, together with the Norcroft compiler and assembler, BBC
    BASIC, and a smattering of common development tools. More information about the support in the
    system can be found in the <a href=":robuildyaml.html">build documentation</a>.
</p>


<h3>Build environment</h3>

<p>
    The build environment that the service executes files within is a variant of RISC OS
    and can function as you might expect RISC OS to function. There are limitations, however,
    which are based on the implementation, the nature of the service and security. These
    limitations are subject to change at any time, but the following are the most significant:

    <ul>
        <li>There's no WindowManager. Wimp Tasks don't exist.</li>
        <li>The build service has no interactive components. You cannot type commands.</li>
        <li>There is no graphics system. That means no sprites and no frame buffer.</li>
        <li>There is no sound system.</li>
        <li>There is no printer or serial system.</li>
        <li>There is no FileCore. There's also no Fileswitch registerable filesystems.</li>
        <li>The filesystem is ephemeral. Every build job is independant from every other job.</li>
        <li>There is no boot sequence. That means that none of the variables you might see on a native system will exist.</li>
    </ul>
</p>

<p>
    The build environment has the following tools installed:

    <ul>
        <li><code>amu</code> -
            A Make Utility (RISC OS make tool).
             </li>

        <li><code>cc</code> -
            RISC OS ARM C compiler.
            </li>

        <li><code>libfile</code> -
            RISC OS ARM library management tool.
            </li>

        <li><code>link</code> -
            RISC OS ARM linker.
            </li>

        <li><code>objasm</code> -
            RISC OS ARM assembler.
            </li>

        <li><code>squeeze</code> -
            RISC OS absolute executable file compressor.
            </li>

        <li><code>CMunge</code> -
            Module header generator tool (CMHG replacement).
            </li>

        <li><code>perl</code> -
            Perl 5.0.0 interpreter.
            </li>

        <li><code>ResGen</code> -
            ResourceFS file creation tool.
            </li>

        <li><code>bison</code> -
            GNU Parser generator
            </li>

        <li><code>flex</code> -
            GNU Lexical parser generator
            </li>

        <li><code>sed</code> -
            GNU sed, a text stream editor.
            </li>

        <li><code>basic</code> -
            BBC Basic interpreter.
            </li>

        <li><code>jfpatch</code> -
            JFPatch, preprocessing ARM assembler.
            </li>

        <li><code>p2c</code> -
            Pascal to C conversion tool.
            </li>
    </ul>

    In addition to these tools, some of the standard RISC OS commands are available.
</p>

<p>
    There are libraries and headers for the C and Pascal libraries present.
</p>

</section>

<section>
<h2>Why would you need a RISC OS build service?</h2>

<p>
    The most obvious reason to have a RISC OS build service is so that you can run builds and
    tests automatically on submission of code. This form of automated testing can make it significantly
    safer to do releases - you catch problems that should be obvious without having to manually check
    them yourself every time.
</p>

<p>
    There are a number of examples that have been created which can be used as templates for building
    components. Look for '<a href="https://github.com/topics/riscos-ci">riscos-ci</a>' on GitHub. The repository <a href="https://github.com/gerph/riscos-ci-templates">riscos-ci-templates</a> contains just the templates for use with GitLab and GitHub.
</p>
<p>
    A guide to how you use the system can be found in the <a href=":ci-build.html">CI build documentation</a>. Some simple command line examples of building
    BASIC with the shell can be found in the <a href="https://github.com/gerph/riscos-build-basic-example">riscos-build-basic-example</a> repository.
</p>

<p>
    You might want to run tests after the build - the system can do that as well, just by adding extra
    commands to the build process to try to exercise the tool that you have built. These tests could
    exercise interfaces that might be dangerous to use on your development machine - so you protect your
    desktop system.
</p>

<p>
    You might, as has been done for a couple of the CI examples, construct a full release automatically
    when the code is pushed. Creating a release archive automatically when code is pushed guarantees that
    they will be built only with the code that was pushed and should be unaffected by anything in the
    developer's environment. It also ensures that what went into the build truly is what you meant.
</p>

</section>


</$if>


<section>
<h2>How does the service work?</h2>

<div class='howitworks'>
<a href='images/howitworks.png'><img src="images/howitworks.svg" alt="[Structure diagram]"/></a>
</div>

<p>
    The build is invoked by the HTTP and WebSocket services, which are running on machines
    inside AWS. These services run the internal servers and report the results back to the user
    using the <a href=':api.html'><service-name> APIs</a>. The services are written in Python
    and multithread to service multiple clients at once
    <$if COND=(service = 'jfpaas')>
     - it's better Python than the JFPatch BASIC is.
    </$if>
</p>

<p>
    The website is hosted through CloudFront, which performs the routing to the services. In theory
    the whole system would be able to be auto-scaled with more machines if ncessary, but this is a
    RISC OS service we're talking about, and even if both users hit it at once, the system can
    cope.
</p>
</section>

<section>
<h2>Technologies involved</h2>
<p>
    The front end uses <a href='https://codemirror.net/'>CodeMirror</a> to display source code, with a custom colouring modes for JFPatch, which includes ARM assembly instructions, BBC BASIC keywords, and the JFPatch structure colouring. The ANSI colouring output from the build is converted to HTML by the <a href="http://github.com/drudru/ansi_up">ansi_up</a> library.
</p>

<p>
    Communication with the back end is through CloudFront, which routes WebSocket and JSON requests to an EC2 instance. It could be autoscaled. I didn't see much point as this is unlikely to be a heavily used service.
</p>

<p>
    The WebSocket service is Python, and uses a <a href="https://github.com/Pithikos/python-websocket-server">Python Websocket Server</a> library for communication. The JSON server is also Python and uses <a href="https://github.com/pallets/flask">Flask</a> for its routing. Both servers use the same back end libraries to drive the build process. The throwback and clipboard server which RISC OS communicates non-output data through is a Python BaseHTTPServer.
</p>

<p>
    The build process is invoked through Docker containers to isolate build processes. Within these containers RISC OS is invoked, running the commands necessary to build the source. There might be multiple commands, as defined in the <a href=":robuildyaml.html">build configuration</a>.
</p>

</section>

<$if COND=(service = 'bro')>
<block-what-is-jfpatch>
</$if>

    </page>
</body>
</html>
