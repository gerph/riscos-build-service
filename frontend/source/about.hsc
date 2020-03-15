<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>JFPatch as a Service: About</title>
  <link rel="stylesheet" type="text/css" href="site.css" />
</head>
<body>
    <page_title section='About'>
    <div class='content'>

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

<h2>Why would you need JFPatch as a service?</h2>

<p>
    Why wouldn't you?! Maybe you don't have JFPatch to hand, or you don't have RISC OS on your
    system, but you <em>need</em> to build a RISC OS utility? Or maybe... No. I can't do it... I
    don't know what might cause you to need JFPatch... But if you do, it now exists.
</p>

<h2>How does it work?</h2>

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
    If you asked for throwback, it would generate warnings or errors through the throwback system.
    These would usually appear in a new window hosted by your editor, which allowed you to jump
    to the failure position. If you were running the tool from the desktop, it would also set
    special variables to indicate the status of the build, which the front end would use to display
    a pop-up message.
</p>

<p>
    In this online version, the throwback is actually a HTTP POST to an internal web server to
    report the message, rather than an editor, as the user's editor isn't running on the cloud
    machine where JFPatch executes. Similarly, the cloud version doesn't just save the file,
    but also copies the output to the clipboard. The clipboard is also a HTTP POST to the
    internal server to supply the built binary.
</p>

<p>
    JFPatch itself is invoked by the HTTP and WebSocket services, which are running on machines
    inside AWS. These services run the internal servers and report the results back to the user
    using the <a href=':api.html'>JFPatch as service APIs</a>. The services are written in Python
    and multithread to service multiple clients at once - it's better Python than the JFPatch
    BASIC is.
</p>

<p>
    The website is hosted through CloudFront, which performs the routing to the services. In theory
    the whole system would be able to be auto-scaled with more machines if ncessary, but this is a
    RISC OS service we're talking about, and even if both users hit it at once, the system can
    cope.
</p>

    </div>
    <page_footer>
</body>
</html>
