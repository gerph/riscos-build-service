<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>JFPatch as a Service: File Format</title>
  <link rel="stylesheet" type="text/css" href="site.css" />
</head>
<body>
    <page_title section='File Format'>
    <div class='content'>

<h2>Introduction</h2>

<pre>
*****************************************************************************
  &gt; Format                A description of the description file for JFPatch
************************************************* © Justin Fletcher, 1997 ***

Introduction
============
JFPatch files can contain up to seven distinct components :
 * Header     Describes what the file is going to do
   Pre        Pre-assembly basic code which is to bo included
   Workspace  Describes the workspace blocks to be used
   Module     Describes the module header
 * Code       The actual code to be assembled (may include patch offsets)
   Post       Post-assembly, prior to exiting for testing, and running code
   End        End inclusion, after assembly, but before the auto-included
              routines.

Those sections marked * are compulsory and must be include. These will be
described first, followed by the other sections.

*****************************************************************************
</pre>

<h2>Header section</h2>

<p>
The header describes what the patch file is going to do. Entries are
separated by one or more spaces, and are case insensitive:
</p>

<param-list label='Field' hasrequired>

<param name='APP'>Specify application name<br/>
The name will be used in system vars to create the correct code
Files required (!Create, !Run, !Help, and WSWI-Help may be copied)</param>

<param name='IN' required>Input file (MUST preceed OUT)<br/>
If <code>-</code>, no input file will be used.<br/>
If preceeded by <code>*</code>, the module whose name is given will be
extracted from memory and processed.</param>

<param name='OUT' required>Output file (ignored if output is AOF and file is in j directory)</param>

<param name='TYPE' required>Type of file to generated. Values which may be supplied:
    <param-list label="Type name">
        <param name='Module'>Relocatable Module, offsets start at 0, typed Module</param>
        <param name='Util'>Utility code, offsets start at 0, typed Utility</param>
        <param name='Utility'>As 'Util'</param>
        <param name='Absolute'>Absolute code, offsets start at &amp;8000, typed Absolute</param>
        <param name='Code'>Direct code, base address is as allocated in memory; load and exec address of the file will be the base address</param>
        <param name='Memory'>Stored to memory, ie no output file</param>
        <param name='AOF'>AOF format file</param>
        <param name='AOFModule'>An AOF format file, but with a Module header.</param>
    </param-list>
</param>

<param name='VER'>Code version number in the form 1.00a.<br/>
Each time the code is
assembled this will be incremented, but the file you are editing
will not change. This is so that you can check in a general way,
not how many times it has been tested, but how many times it has
been returned to.
</param>

<param name='MAX'>Maximum amount of memory to reserve in bytes (or suffix with K) for the generated code</param>

<param name='PC'>Start PC for file if not default</param>

<param name='{'>Start comment. See Code section for description.</param>
</param-list>

<p>
    If filenames are not full paths then the same path as the patch file is
    assumed, unless APP is specified, in which case, all references will be from
    that system variable (&lt;name&gt;$Dir).
</p>

<h2>Code section</h2>

<p>
Code lines are identified by a line outside <code>DEFINE</code> blocks which begins with a line starting with <code>.</code>
(full stop), <code>#</code> or <code>@</code>.
</p>

<p>
Code sections may be prefixed by symbols as the first
character on the line:
</p>

<param-list label='First Character'>

<param name='%'>Literal basic command, eg <code>% PRINT "HELLO"</code><br/>
      These may be used if additional debug is needed during assembly, or to add more
      complex processing, such as generated data tables.
</param>

<param name='@'>Change assembly offset<br/>
      Changes the assembly offset to an offset in the input file.
      The only use for this is when you are patching an input file.
      You may use <code>endofcode</code> to indicate that the code should be assembled
      after all other code. <code>endofcode</code> is always word aligned.
</param>

<param name='#'>Pre-assembler directive<br/>
      Allows you to do many special things. See later for more information.
</param>

<param name='{'>Start comment<br/>
      These comments are not included in the output file, and serve only to
      comment the code in large blocks (or remove sections of code) rather than
      using <code>;</code>. These comments are not nestable. End comments with space
      followed by <code>}</code>, or <code>}</code> alone on a line.
</param>

<param name=';'>Embedded comment line.<br/>
      These are unlike <code>;</code>'s within code lines because
      they are stripped of all <code>:</code>'s which may cause errors in the assembly.
</param>

<param name='.'>Routine or data start.<br/>
      These are just the same as basic labels.
</param>

<param name='&gt;'>Code routine start.<br/>
      These are preceeded with a C style routine name (if CodePrefix is
      enabled). Otherwise they are identical to <code>.</code> labels.
</param>

<param name='$'>Local label.<br/>
      Labels a point locally, which is only available to the routine within
      which it occurs (ie from <code>.</code> label to the next <code>.</code> label, or <code>#Post</code>/<code>#End</code>)
</param>
</param-list>

<p>
All lines which are not prefixed by these characters are checked for being predefined
macros before being passed on to the basic assembler.
</p>


<h3>Labels</h3>

<p>
    It is recommended that you use purely textual names for both routines and
local labels (numerical initial characters are not allowed), <code>`</code> prefixed names
for variables - ie numbers or strings, and <code>_</code> prefixed names for local labels
which are local to a group of routines. eg <code>.decimal</code>, <code>$`textstring</code>,
<code>._filename</code>. This is merely a recommendation, and is not coded into the
file format.
</p>

<p>
Local labels are defined as for normal labels, but instead of a <code>.</code> prefix,
<code>$</code>
is used. To reference such labels within the code, use the same form (ie
<code>$<i>variable name</i></code>. These will be expanded during compilation.
</p>

<p>
Whilst compiling AOF code any lines with a <code>|</code> in are checked for exports or
imports. Exports are achieved by using labels in the usual way:
</p>

<jfpatch>
.|<i>label</i>|
</jfpatch>

<p>
will export the label <code><i>label</i></code>. To rename the label when exported you can use :
</p>

<jfpatch>
.|<i>label</i>-&gt;<i>export</i>|
</jfpatch>

<p>
To refer to a label you can use either <asm>BL</asm> (or <asm>XBL</asm>) or one of the
<asm>EQU</asm>
commands:
</p>

<jfpatch>
  BL     |<i>label</i>|
  EQUD   |<i>label</i>|
</jfpatch>


<p>
Dependant on the EQU used, the correct import type should be selected.
Calculations may be performed on labels, but you may NOT add labels
together :
</p>

<jfpatch>
  EQUD   |<i>label</i>| + <i>constant</i>
</jfpatch>



<h3>Predefined macros</h3>

<p>
    These are used in much the same manner as standard instuctions, and may for
the most part be considered as normal instructions. Where <code>##</code> is given, the
instruction may be given a conditional code:
</p>

<$macro directive-list /CLOSE label:string="Directive">
<param-list label=(label)>
<$content>
</param-list>
</$macro>

<$macro directive /CLOSE label:string/REQUIRED
                         summary:string/REQUIRED>
<param name=(label)><div class='directive-summary'><(summary)></div>
<$content>
</param>
</$macro>

<$macro usage syntax:string/REQUIRED>
<div class='usage'>Usage: <asm><(syntax)></asm></div>
</$macro>

<directive-list label="Macro">
<directive label="LADR##" summary="Long ADR">
    Long address assignment with an address range of 64k, rather than the 4k usually
         given by <asm>ADR</asm>. 2 instructions will always be assembled.
         <usage syntax="LADR##   reg, address or label">
</directive>

<directive label="LMOV##" summary="Long move">
         When MOV gives up and says 'argh, no more...' LMOV will do it's
         best to perform the specified function. Multiple instuctions will
         be used, variably according to the number given. Therefore, it is
         imperitive that the value is not an unassigned label (ie no forward
         references). You may also use -ve numbers.
         <usage syntax="LMOV    <i>reg</i>,<i>value</i>">
</directive>

<directive label="LADD##" summary="Long addition">
         The complement to long move, long add performs addition on
         registers using multiple instructions.
         <usage syntax="LADD##   <i>reg</i>,<i>reg</i>,<i>value</i>">
</directive>

<directive label="XSWI##<br/>XBL##" summary="Extended SWI<br/>Extended BL">
         These are used to pass parameters to a <asm>SWI</asm> call or routine in a
         similar way to <code>SYS</code> and <code>CALL</code> in BASIC. As in BASIC, values may be
         ignore, by using <code>,</code> on it's own. Note that these values are all set in
         order, so if you want r0=r1 and r1=r0, you can't do it this way.
         You can preceed the value with <code>#</code> to do an explicit <asm>MOV</asm> when you have
         used a variable instead of a number. Preceeding a reference by <code>^</code> will
         use <asm>ADR</asm> to get it's address rather than it's absolute value.
         <usage syntax="XSWI##  &quot;<i>name</i>&quot;,<i>value</i>[,[value][,[value]...]">
         <usage syntax="XBL##   &quot;<i>name</i>&quot;,<i>value</i>[,[value][,[value]...]">
         (here, <i>value</i> may be a number or register prefixed by r, a or v)
</directive>

<directive label="XLDMFD" summary="Extended unstack.">
         Sometimes you will need to return from a routine with, either the
         registers preserved, or with <asm>VS</asm> and r0 pointing to an error string.
         By using <asm>XLDMFD</asm>, you can exit from a routine using just one line.
</directive>

<directive label="REM<br/>REMP" summary="Remark for debugging<br/>Permanent remark (not removed by #REM OFF)">
         Whilst debugging you will find it extremely useful to be able to
         display messages about the progress of the code. REM includes an
         inline set of routines to display a message. Within the string, a
         group of control codes may be used:
         <param-list label='Control'>
           <param name='%%'>Display a percent symbol.</param>
           <param name='%r#'>Display register # in decimal (# is the register number in hex)</param>
           <param name='%&amp;#'>Display register # in hex</param>
           <param name='%$#'>Display the string pointered to by register #</param>
           <param name='%a#'>Display register # as an output character (<asm>OS_WriteC</asm> it)</param>
           <param name='%E#'>Display error message pointed to by register #</param>
           <param name='%R'>Display all registers in hex</param>
           <param name='%I'>Ignored</param>
           <param name='%C'>Don't append newline to the end of the string, if you want to
                split the message over sections of code</param>
           <param name='%c##'> embed a control character, <code>##</code> in decimal. Useful if you are
                displaying things in the desktop, eg <code>%c04</code> for text cursor.</param>
         </param-list>
         All messages will by terminated by newline, unless <code>%C</code> specified.
         If you specify streaming in the front-end, output will be streamed.
         If <code>#REM OFF</code> is specified, <code>REM</code>'s will be embedded in the BASIC as
         <code>;</code> comments.
         <usage syntax="REM <i>string</i>">
         Note: All registers preserved, flags altered.
</directive>

<directive label="DIV" summary="Divide routine (very sub-optimal)">
         Result is returned in top.
         <usage syntax="DIV <i>top</i>,<i>bottom</i>">
         Note: Large amounts of code assembled.
</directive>

<directive label="RES" summary="Reserve space">
         If you need to reserve a lagrge block of memory, this is the
         easiest way to do it. The space will be initialised to 0.
         <usage syntax="RES    <i>bytes</i>">
</directive>

<directive label="MODE##" summary="Set processor mode">
         Sometimes it is imperitive to use a particular processor mode.
         You are required to change to SVC mode in CallBack's so that
         r14_svc is preserved, and this macro gives you an easy means of
         doing this.
         <usage syntax="MODE##  USR | FIQ | IRQ | SVC[,<i>reg1</i>,<i>reg2</i>]">
         (<i>reg1</i> and <i>reg2</i> default to r8 and r9, and contain the flags
         <usage syntax="MODE##  [+|-]SVC [ ,<i>reg1</i>,<i>reg2</i>,[<i>reg3</i>] | ,<i>reg3</i> ]">
         <i>reg1</i> and <i>reg2</i> default to r8 and r9, and contain the flags
         <i>reg3</i> is the stack pointer to use
</directive>

<directive label="LDRW##<br/>STRW##<br/>LDRBW##<br/>STRBW##" summary="Load register from workspace<br/>Store register in workspace<br/>Load register with byte from workspace<br/>Store register as byte in workspace">
         These are used by the Workspace module. If the registers are mapped
         correctly, then these will perform operations on workspaces just as
         <asm>LDR</asm>/<asm>STRM</asm> do on inline addresses.
         <usage syntax="<i>cmd</i>[B]W##  <i>reg</i>,<i>offset</i>">
</directive>

<directive label="ADRW##" summary="Address in workspace">
         This works like its inline counterpart, but used long adds, so has
         an infinite range.
         <usage syntax="ADR##   <i>reg</i>,<i>offset</i>">
</directive>

<directive label="SWAP##" summary="Swap two registers">
         How may times have you had the two registers around the wrong way?
         This gets around that with three lines of code (no temporary
         register).
         <usage syntax="SWAP##  <i>reg1</i>,<i>reg2</i>">
         Note: Do not confuse with the <asm>SWP</asm> ARM3 instruction.
</directive>

<directive label="EQUZ<br/>EQUZA" summary="Equate string with zero suffix<br/>Equate string with zero suffix, then align">
         Much easier than using <asm>EQUS "blah, blah"+CHR$0</asm>.
         <usage syntax="EQUZ[A]   <i>string</i>">
</directive>

<directive label="NOP##" summary="No operation">
         This is often used to remove lines from patched code, or to delay
         whilst register bank resync takes place. One instruction is
         assembled.
         <usage syntax="NOP##">
</directive>

</directive-list>

<h3>Pre-assembler directives</h3>

<p>
Pre-assembler directives are prefixed by <code>#</code> and consist of a command followed
by arguments:
</p>

<directive-list>
<directive label="#REM" summary="Enables/disables REM debug comments (not REMP though).">
         <usage syntax="#REM <i>boolean</i>">
</directive>
<directive label="#CODEPREFIX" summary="Enables/disables prefixes to sections of code.">
         The name of routines followed by a SWINV code to indicate the length
         of the name will be embedded prior to the start of the routine if
         this is enabled.
         <usage syntax="#CODEPREFIX <i>boolean</i>">
</directive>

<directive label="#LOAD" summary="Load a file in line into the code">
         <usage syntax="#LOAD <i>filename</i>, <i>length</i>">
         If length is -1, then just the length of the file will be reserved
</directive>

<directive label="#POST" summary="Start of post assembly section; whatever follows is post assembly code">
         This code can be used for testing the routines you have written so
         that you can be sure that they work before running the complete
         code.
         <usage syntax="#POST">
</directive>

<directive label="#END" summary="End of code; whatever follows will be appended varbatum to the file.">
        <usage syntax="#END">
</directive>

<directive label="#COND" summary="Conditional assembly, see later"></directive>
<directive label="#CHECK" summary="Verification of code validity, see later"></directive>
<directive label="#LIBRARY" summary="Install library routines, see later"></directive>
<directive label="#INCLUDE" summary="Install a local file, see later"></directive>
<directive label="#HERE" summary="Locate objects, see later"></directive>

<directive label="#MAPWS" summary="Map workspace block to a register">
         This changes the default mapping for a workspace block.
         <usage syntax="#MAPWS <i>block name</i>[,<i>register</i>]">
         if no register is specifed, the default is used.
</directive>

</directive-list>

<p>
<i>boolean</i> can be one of <code>ON</code>, <code>TRUE</code>, <code>ENABLED</code>,
<code>OFF</code>, <code>FALSE</code>, <code>DISABLED</code> or <code>=<i>file</i></code> to
take the value from a particular file.
</p>



<h3>Conditional assembly</h3>

<p>
    Conditional assembly allows you to cater for different possible
configurations of the code so that it may be set up by the user to do
different things.
</p>

<p>
    Conditional assembly can take place in two forms. The first, default, form is
for the pre-assembler to remove all non-required code, leaving just that
which is required to be assembled. This is called external conditional
assembly because the conditionals are evaluated externally to the
code.
</p>

<p>
    The second form is inline conditional assembly. This is where all the code
is created in the BASIC file, and the conditionals are evaluated at assembly
time. The external method is useful for debugging, whilst the inline method
is more useful if the code has options which the user may select.
</p>

<p>
Conditionals in both forms are nestable, though you may become confused when
trying to read such code:
</p>

<p>
    The directives are:
</p>

<directive-list>
<directive label='#COND INLINE' summary="Selects inline conditional assembly"></directive>
<directive label='#COND EXTERNAL' summary="Selects external conditional assembly"></directive>

<directive label='#COND SET' summary="Sets a condition variable to a value">
               <usage syntax="#COND SET <i>varname</i> <i>boolean</i>">
</directive>

<directive label='#COND <i>varname</i> ' summary="Sets a condition variable according to user reply">
               In External mode, this will display a error box type message
               In Inline mode, the messages will be printed on the screen
               and a OS_Confirm used to get the reply.
               <usage syntax="#COND <i>varname</i> <i>question</i>">
</directive>

<directive label='#COND OF' summary="Starts a conditional assembly structure">
               The following code within this structure will be assembled if
               the named condition variable is true.
               <usage syntax="#COND OF <i>varname</i>">
</directive>

<directive label='#COND ELSE' summary="Else clause in structure">
</directive>

<directive label='#COND END' summary="End conditional assembly structure">
</directive>

<directive label='#COND ENDIF' summary="ditto">
</directive>
</directive-list>

<h3>Checking the validity of code</h3>

<p>
When you are writing patches, it is useful to perform check on the code you
are acting on to ensure that it is the correct version. The checks are :
</p>

CHECK STRING   Check that a particular address contains a ctrl terminated
               string.
               Usage: #CHECK STRING &lt;address&gt; &lt;string&gt;
               Note: The string may be enclosed in quotes

CHECK WORD     Check that a particular word contains a particular value
               Usage: #CHECK WORD &lt;address&gt; &lt;value&gt;

CHECK LEN      Check that the length of the file is a certain value
               Usage: #CHECK LEN &lt;length&gt;


<h3>Including libraries of routines</h3>

<p>
Library files are used when it is rather pointless to code the same thing
over and over again. They are held within the JFPatch directory in the file
Libraries. The only library provided is the Strings library - a set of
routines I have collected, modified and written (the string comparison
routines are my own work, and though probably not optimal, suffice for the
most part).
</p>

<p>
The syntax of the library inclusion command is :
</p>

LIBRARY <i>filename</i>,[#]<i>routine</i>[[[.routine].routine]...]

<p>
<i>filename</i> is an absolute filename if there is a path, otherwise the
JFPatch.Libraries directory is searched.
<i>routine</i> may be * if you want all libraries to be included in a file - not
recommended.
</p>

<p>
The # symbol means that the libraries will be included at this point in the
code. Otherwise, a #HERE LIBRARIES directive will need to be issued.
</p>

<p>
The library files themselves consist of a first line of LIBRARY <i>filename</i>
followed by the routines in the library. Local labels may be used, but
externally referenced variables may not due to the manner in which the
inclusion occurs. Inclusion is from the first ; before the . prefix of the
routine name to the line before the first ; before the next . (or the next .
if there is no ;). See the Summary file for more details, and refer to
Strings for examples.
</p>


<h3>Including code files</h3>

<p>
Just as library routines can be included in your code, so can files be
included in the code. These can be used where you can't be bothered to code a
section a number of times, but it is too specific for a full library.
</p>

<p>
The syntax of the include command is :
</p>

INCLUDE <i>filename</i>

<p>
NOTE: This is still an experimental function. Please report problems or
queries to Justin. (Note in 2020: He doesn't know how well this works)
</p>

<h3>Here directives (object location)</h3>

<p>
At some future point there may be more HERE directives to include pre-defined
things (I'm not sure what yet, but in AOF there seems to be a lot of scope
for that sort of thing...) Currently, however only two directives exist :
</p>

HERE FOOTER    Embed the Footer file at this point
               This might be used as DoggySoft use to place "Anything after
               this point is probably a virus")

HERE LIBRARIES Embed all previously defined libraries
               You should probably not need to use this unless you are very
               organised. I use LIBRARY <i>filename</i>,#[routine] in preference.

<h2>Pre-assembly section</h2>

<p>
    The pre-assembly section is used to define constants to be used, and other
various actions which occur to the programmer. Usually #CHECK and #COND set
up directives are included here. The section is preceeded by PRE, and
terminated by END PRE.
</p>

<p>
    The only pre-assembler directives which make any sense are the #COND and
#CHECK directives.
</p>

<p>
If you are assembling AOF code you may assign constants here by using the
form :
</p>

<jfpatch>
  |<i>label</i>| = <i>value</i>
</jfpatch>


<h2>Post-assembly section</h2>

This section is used for code which should be run after the code has been
assembled. The section is enclosed by #Post and #End (or the end of the
file). All the code given will be passed directly to Basic, unless it is
prefixed by a # symbol. In which case, the following apply :

RUN     Runs a particular file, if the file specified is <i>CODE</i> (note: upper
        case), then the output file is run. If <i>THISDIR</i> is included, then it
        is replaced by the directory the Patch file is in.
        Usage: RUN <i>filename</i> | <i>pathname</i> | <i>THISDIR</i>.<i>filename</i> | <i>CODE</i>

WIMPRUN Performs the same as RUN, except that the file is Filer_Run.

EXAMINE Used to examine memory to check that it is what you expect it to be.
        Usually this is used after executing the code. The output is saved to
        a file and loaded as a text file.
        Usage: EXAMINE <i>start</i> <i>end</i> | +<i>length</i>

CAPTURE Captures all output into a spool file.
        This is usually used where the output cannot be captured in a
        TaskWindow.
        Usage: CAPTURE [ ON | OFF ]
        Default is ON

END     End section, start End section


<h2>End section</h2>

<p>
All text in the end section will be appended to the file and never be
executed, unless it is called as a PROCedure or FuNction.
</p>

<p>
This is useful for including information about the author, or program.
However, it's real purpose is to allow functions to be used as macros.
</p>


<h2>Workspace</h2>

<p>
What is the point of using workspace blocks ? Well, it's easier to see a
reference:
</p>

<jfpatch>
   LDRW   r0,`taskhandle   means get the taskhandle
</jfpatch>

<p>
Is simpler to understand than:
</p>

<jfpatch>
   LDR    r0,[r12,#8]
</jfpatch>

<p>
Begin a workspace block with DEFINE WORKSPACE and end it with END WORKSPACE.
Within these blocks, you should use the following commands :
</p>

NAME     Sets the name of the block
PREFIX   Allows you to specify a prefix to use within this block variables,
         so a variable named x0 with a prefix of win becomes winx0. When
         used, ` prefixes to the original name are retained, so `x0 would
         become `winx0.
DEFAULT  Sets the default register to use for the workspace.

<p>
All other lines are treated in one of two ways. The first of these is the
offset format, and the second is the relative format. Both give the same
structure types, but the offset format gives the absolute offsets into the
block. It is not recommended that you mix blocks.
</p>

<h3>Offset format</h3>
<p>
This can be used when you know all the offsets will be fixed, or if the
lengths of the blocks are so awkward that you can't be bothered to do it by
reference. In this form, the definitions are :
</p>

  <i>offset</i><i>spaces</i><i>identifier</i>[<i>spaces</i><i>comment</i>]
where <i>offset</i> is either a decimal number, or a hex number prefixed by &amp;.


<h3>Relative format</h3>
<p>
    This is a much more powerful format for creating workspace structures, and is
similar (though in no way compatible) to that used by ObjAsm. In this form,
the definitions are :
</p>

  [=]<i>variable</i><i>spaces</i><i>type</i>[repetitions][<i>spaces</i><i>comment</i>]
where <i>type</i> is :
  !  an integer word (ie 4 bytes)
  %  a byte
  $  a string (<i>repetitions</i> is the number of characters including terminator)
  ^  structure reference in the form
     ^<i>name</i>[<i>space</i><i>repetitions</i>]

<p>
<i>repititions</i> is the number of times the space is repeated (ie four words
would be !4.
</p>

<p>
Within this structure, blocks may be repeated, or "unioned" by using brackets
to group the items. Placing a ( alone on a line begins a grouping, ) alone
ends a grouping, and ) followed by a number sets a number repetitions for the
block.
</p>

<p>
Within a grouping, | on its own on a line sets a union. This means
that the relative pointer is reset to the start of that group so that an
alternate set of names may be given. This is used in ObjAsm OSLib header
files to define things like the Wimp_SendMessage blocks where the data is
dependant on the code.
</p>

<p>
    Such unions should be of equal length under the current version, or if not,
the last union MUST be the largest. Later versions may remove this
constraint, but should not be relied upon.
</p>

<h3>Using workspace</h3>
<p>
    To use workspace within the code, use [ LDR|STR ][B]W or ADRW commands. To
find the length of a block of workspace, use `len_<i>name</i>.
</p>

*****************************************************************************
Yes, last section, and woooo, it's a biggy...

<h2>Module section</h2>
==============

Modules are easy to write. You may not think that now, but after using
JFPatch for some time to create modules, you will find that modules are so
simple to program that you may have to get a life to fill the time you would
have spent struggling ;-) Only kidding poeple...

Module definitions are enclosed by DEFINE MODULE and END MODULE, and within
this, the fields are :

NAME       Module name as used in *Modules command (default=Untitled)
VERSION    Version number to use in help string (default=1.00, or the version
           in the header.
AUTHOR     Author name to use in help string (default=not used)
HELP       Name to use in *Help Modules (default=<i>NAME</i>)
INIT       Initialisation address or label (default=no code)
FINAL      Finalisation address or label (default=no code)
START      Start address or label (default=no code)
SERVICE    Service handler
SERVICES   Begin services definition (instead of a user handler
EVENTS     Begin events definition
VECTORS    Begin vectors definition
COMMANDS   Begin OSCLI/Help/Configure commands definition
SWIHANDLER SWI handler code (default=handled automatically)
SWIS       Begin SWI call definition
WORKSPACE  Length of workspace to claim in r12, prefix with * to initialise 0
WIMPSWIS   Begin WimpSWIVe handler definition (WimpSWIVe © Andrew Clover)
PREFILTER  Begin a Pre-Poll filter
POSTFILTER Begin a Post-Poll filter

<p>
The only one which really ought to be defined is NAME, although all are
optional.
</p>

<h3>Init, final and service code</h3>
<p>
    Whilst you may not have defined some of these, they may be created for you by
JFPatch to implement other features. The cases are as follows :
</p>

Workspace used:   Init used to claim workspace, Final used to release it
Filters used:     Init used to register, Final used to deregister, Service
                  used to claim on FilterManager start up.
WimpSWIs used:    Init used to claim, Final used to release.
Services used:    Service handler caught /before/ 'Service' entry.
Vectors used:     Init used to claim, Final used to release.
Events used:      Init used to claim, Final used to release.


<h3>Module workspace (private word)</h3>

<p>
    Within each module there is a private word which is usually used to store the
address of the modules workspace. Because of the way in JFPatch works (ie.
creating it's own handlers), it is easier for these handlers to pass the
address of the workspace to your routines, rather than a pointer to the
workspace's address. This only applies if workspace is claimed; otherwise,
r12 is a pointer to your private word just as normal.
</p>

<p>
If workspace is claimed, the following will have r12 pointing to the private
space :
</p>

  Init
  Final
  Service
  Services (definition type)
  Events
  Vectors
  SWIs
  WimpSWIs
  Filters

<p>
Commands will NOT receive r12 -&gt; workspace, but r12 -&gt; private word,
which contains the pointer to the workspace. Therefore, you should use
<jfpatch>
  LDR    r12,[r12]
</jfpatch>
</p>

<p>
    to get the pointer to the workspace. This is VERY important,
otherwise you'll overwrite lots of very important pieces of data in the
system heap.
</p>

<h3>Services</h3>
<p>
    Services can be handled manually with the 'Service' entry, but a much easier
way exists to do this by means of a definition block. Lines are in the form:
</p>

<jfpatch>
  <i>service</i>   <i>code</i>
</jfpatch>

<p>
Where <i>service</i> can be a decimal or hex number, or any string from the
!JFPatch.Resources.Services file. This contains the service names
(approximately) as given in OSLib header files. The block should be ended
with:
</p>

<jfpatch>
  End Services
</jfpatch>


<h3>Vectors</h3>

<p>
Vectors can be claimed and released manually using init and final code, but
by using a definition block many of the problems you may come across are
removed and things look a bit clearer. The lines are of the form :
</p>

<jfpatch>
  <i>vector</i>   <i>code</i>
</jfpatch>

<p>
Where <i>vector</i> can be a decimal or hex number, or any string from the
!JFPatch.Resources.Vectors file. This contains the vector names
(approximately) as given in OSLib header files. The block should be ended
with :
</p>

<jfpatch>
  End Vectors
</jfpatch>

<h3>Events</h3>

<p>
    Whilst you can trap events using the Vectors call or manually, it's probably
easier to have these in a seperate section. The lines are of the form :
</p>

<jfpatch>
  <i>event</i>   <i>code</i>
</jfpatch>

<p>
    Where <i>event</i> is a decimal or hex number, or a string from the
!JFPatch.Resources.Events file. This contains the vector names as given in
OSLib headers files except that I've prepended the module name if there is
one. The block should end with :
</p>

<jfpatch>
  End Events
</jfpatch>


<h3>Commands</h3>

<p>
    Commands are denoted by COMMANDS to start, and END COMMANDS to end. Entries
within this block, the fields are :
</p>

NAME      The command name
CODE      Code to execute when called (default= no code)
MAX       Maximum number of parameters which may be passed
MIN       Minimum number of parameters which may be passed
TYPE      Type of command (default=command!)
          Options : FS, CONFIG
FLAGS     Value of the command flags. Overrides the max, min and type
          settings.
SYNTAX    Syntax of the command (defaults to no message)
HELP      Help on the command (defaults to no message)

<p>
<code>SYNTAX</code> and <code>HELP</code> may be followed by a single line, or alternatively by <code>...</code>.
In the latter form (three <code>.</code> characters), the next lines will be taken as being the message,
terminating when the indentation reduce past that at the first line. To embed
control strings, use <code>GSTrans</code> format.
</p>

<p>
Note again that r12 is not passed as the workspace, but as a pointer to the
private word if the workspace is set.
</p>

<h3>SWIs</h3>

SWI blocks, like command blocks are surrounded by SWIs and END SWIs. Within
this block, the following two fields are allowed :
BASE     Sets the base number of the SWI calls, prefix with &amp; for hex
PREFIX   Sets the prefix for all the calls. Omit the trailling _.

All other lines should be in the form :
  <i>number</i> <i>spaces</i> <i>alias</i> <i>spaces</i> <i>code</i>


<h3>WimpSWIs</h3>

WimpSWIve is a gorgeous little module written by Andrew Clover which allows
you to replace certain Wimp calls with other, much nicer calls :-)
For more information, read the WSWI-Help documentation in Applics. Again, the
section is surrounded by WIMPSWIS and END WIMPSWIS. And the fields are :

SWI      Full name of WimpSWI to replace
PRE      Pre-handler code (before real call being called)
POST     Post-handler code (after real call being called)

Either the Pre-Handler or the post handler may be prefixed by the ^ symbol.
In which case, the code will have the high priority bit set. Mixed priority
SWI handlers are not allowed, and you must use two seperate definitions if
you wish to do that.

<h3>Filters</h3>

<p>
Filters are one of the most useful of the features of RO3 (to the programmer
at least). Filters allow you to trap calls Wimp_Poll in much the same way
that WimpSWIs do for the other calls. There are two types of Filters which
can be used, Pre- and Post-poll filters. These are in seperate sections,
delimited by [PRE | POST]FILTER and END [PRE | POST]FILTER, and both are
handled in a similar manner:
</p>

NAME     *  Name for the filter (for the list)
CODE     *  Filter handler code
MASK        Wimp_Poll mask (only post-filters)
ACCEPT      An alternate way of specifying the filter mask
TASK     *  Task name to apply filter to (or - for all tasks)

<p>
Those marked * must be specified for both pre- and post-filters plus,
post-filters must have either MASK or ACCEPT specified. ACCEPT commands must
be given on seperate lines, and the names are :
</p>

<pre>
 Primary name     Secondary name            Tertiary name
 --------------------------------------------------------
 Null
 Redraw
 OpenWindow
 CloseWindow
 PointerLeaving
 PointerEntering
 MouseClick
 UserDragBox      DragDropped
 KeyPress         KeyPressed
 Menu             MenuSelection
 Scroll           ScrollRequest
 LoseCaret
 GainCaret
 PollWord
 UserMsg          UserMessage               Message
 UserMsgRec       UserMessageRecorded       MessageRec
 UserMsgAck       UserMessageAcknowledged   MessageAck
</pre>

    </div>
    <page_footer>
</body>
</html>
