<!DOCTYPE html>
<html>
<html-header title='File format' codecolouring></html-header>
<body onload='setup_colouring({autosize: true, linenumbers: false});'>
    <page section='File Format'>

<section>
<h2>Introduction</h2>

<p>
JFPatch files can contain up to 8 distinct sections, of which 2 are required and must be present:
</p>

<param-list label='Section' hasrequired>
<param name='Header' required>Describes what the file is going to do</param>
<param name='Pre'>Pre-assembly basic code which is to bo included</param>
<param name='Workspace'>Describes the workspace blocks to be used</param>
<param name='Module'>Describes the module header</param>
<param name='Macros'>Describes the macro definitions</param>
<param name='Code' required>The actual code to be assembled (may include patch offsets)</param>
<param name='Post'>Post-assembly, prior to exiting for testing, and running code</param>
<param name='End'>End inclusion, after assembly, but before the auto-included
              routines.</param>
</param-list>

<p>
The required sections - the Header and the Code sections - are described first, below..
</p>
</section>

<section>
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
    that system variable (<code>&lt;name&gt;$Dir</code>).
</p>
</section>


<section>
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
.|label|
</jfpatch>

<p>
will export the label <code><i>label</i></code>. To rename the label when exported you can use :
</p>

<jfpatch>
.|label-&gt;export|
</jfpatch>

<p>
Label definitions in AOF may also be suffixed by <code>ENTRY</code> to indicate that they are
to be declared as the entrypoint, in the form:
</p>

<jfpatch>
.|label| ENTRY
</jfpatch>

<p>
To refer to a label you can use either <asm>BL</asm> (or <asm>XBL</asm>) or one of the
<asm>EQU</asm>
commands:
</p>

<jfpatch>
  BL     |label|
  EQUD   |label|
</jfpatch>


<p>
Dependant on the EQU used, the correct import type should be selected.
Calculations may be performed on labels, but you may NOT add labels
together :
</p>

<jfpatch>
  EQUD   |label| + constant
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

<$macro usage syntax:string/REQUIRED alternate:bool>
<div class='usage'><$if COND=(alternate)><$else>Usage:</$if><jfpatch><(syntax)></jfpatch></div>
</$macro>

<$macro usage-block /CLOSE alternate:bool>
<div class='usage'><$if COND=(alternate)><$else>Usage:</$if><jfpatch><$content></jfpatch></div>
</$macro>

<directive-list label="Macro">
<directive label="LADR##" summary="Long ADR">
    Long address assignment with an address range of 64k, rather than the 4k usually
         given by <asm>ADR</asm>. 2 instructions will always be assembled.
         <usage syntax="    LADRcc   reg, address or label">
</directive>

<directive label="LMOV##" summary="Long move">
         When MOV gives up and says 'argh, no more...' LMOV will do it's
         best to perform the specified function. Multiple instuctions will
         be used, variably according to the number given. Therefore, it is
         imperitive that the value is not an unassigned label (ie no forward
         references). You may also use -ve numbers.
         <usage syntax="    LMOV    reg,value">
</directive>

<directive label="LADD##" summary="Long addition">
         The complement to long move, long add performs addition on
         registers using multiple instructions.
         <usage syntax="    LADDcc  reg,reg,value">
</directive>

<directive label="XSWI##<br/>XBL##" summary="Extended SWI<br/>Extended BL">
         These are used to pass parameters to a <asm>SWI</asm> call or routine in a
         similar way to <code>SYS</code> and <code>CALL</code> in BASIC. As in BASIC, values may be
         ignore, by using <code>,</code> on it's own. Note that these values are all set in
         order, so if you want r0=r1 and r1=r0, you can't do it this way.
         You can preceed the value with <code>#</code> to do an explicit <asm>MOV</asm> when you have
         used a variable instead of a number. Preceeding a reference by <code>^</code> will
         use <asm>ADR</asm> to get it's address rather than it's absolute value.
         <usage syntax="    XSWIcc  &quot;name&quot;,value[,[value][,[value]...]">
         <usage syntax="    XBLcc   &quot;name&quot;,value[,[value][,[value]...]">
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
         <usage syntax="    REM     &quot;string&quot;">
         <usage syntax="    REMP    &quot;string&quot;" alternate>
         Note: All registers preserved, flags altered.
</directive>


<directive label="DIV" summary="Divide routine (very sub-optimal)">
         Result is returned in top.
         <usage syntax="    DIV     rtop,rbottom">
         Note: Large amounts of code assembled.
</directive>

<directive label="RES" summary="Reserve space">
         If you need to reserve a lagrge block of memory, this is the
         easiest way to do it. The space will be initialised to 0.
         <usage syntax="    RES     bytes">
</directive>

<directive label="MODE##" summary="Set processor mode">
         Sometimes it is imperitive to use a particular processor mode.
         You are required to change to SVC mode in CallBack's so that
         r14_svc is preserved, and this macro gives you an easy means of
         doing this.
         <usage syntax="    MODEcc  USR | FIQ | IRQ | SVC[,reg1,reg2]">
         (<i>reg1</i> and <i>reg2</i> default to r8 and r9, and contain the flags
         <usage syntax="    MODEcc  [+|-]SVC [ ,reg1,reg2,[reg3] | ,reg3 ]">
         <i>reg1</i> and <i>reg2</i> default to r8 and r9, and contain the flags
         <i>reg3</i> is the stack pointer to use
</directive>

<directive label="LDRW##<br/>STRW##<br/>LDRBW##<br/>STRBW##" summary="Load register from workspace<br/>Store register in workspace<br/>Load register with byte from workspace<br/>Store register as byte in workspace">
         These are used by the Workspace module. If the registers are mapped
         correctly, then these will perform operations on workspaces just as
         <asm>LDR</asm>/<asm>STR</asm> do on inline addresses.
         <usage syntax="    LDRWcc   reg,offset">
</directive>

<directive label="ADRW##" summary="Address in workspace">
         This works like its inline counterpart, but used long adds, so has
         an infinite range.
         <usage syntax="    ADRcc    reg,offset">
</directive>

<directive label="SWAP##" summary="Swap two registers">
         How may times have you had the two registers around the wrong way?
         This gets around that with three lines of code (no temporary
         register).
         <usage syntax="    SWAPcc   reg1,reg2">
         Note: Do not confuse with the <asm>SWP</asm> ARM3 instruction.
</directive>

<directive label="EQUZ<br/>EQUZA" summary="Equate string with zero suffix<br/>Equate string with zero suffix, then align">
         Much easier than using <asm>EQUS "blah, blah"+CHR$0</asm>.
         <usage syntax="    EQUZ     &quot;string&quot;">
         <usage syntax="    EQUZA    &quot;string&quot;" alternate>
</directive>

<directive label="ERR" summary="Define an error block">
         Defines an error block, in the form of a 32bit error number and a message.
         <usage syntax="    ERR      number, &quot;message&quot;">
</directive>

<directive label="NOP##" summary="No operation">
         This is often used to remove lines from patched code, or to delay
         whilst register bank resync takes place. One instruction is
         assembled.
         <usage syntax="    NOPcc">
</directive>

<directive label="REMF##<br/>REMFP##" summary="FIXME: Not documented">
</directive>

<directive label="GETBIT##<br/>SETBIT##<br/>CLRBIT##" summary="FIXME: Not documented">
</directive>

<directive label="SETV##<br/>SETC##<br/>SETN##<br/>SETZ##" summary="FIXME: Not documented">
</directive>

</directive-list>

<h3>Pre-assembler directives</h3>

<p>
Pre-assembler directives are prefixed by <code>#</code> and consist of a command followed
by arguments:
</p>

<directive-list>
<directive label="#REM" summary="Enables/disables REM debug comments (not REMP though).">
         <usage syntax="#REM boolean">
</directive>
<directive label="#CODEPREFIX" summary="Enables/disables prefixes to sections of code.">
         The name of routines followed by a SWINV code to indicate the length
         of the name will be embedded prior to the start of the routine if
         this is enabled.
         <usage syntax="#CODEPREFIX boolean">
</directive>

<directive label="#LOAD" summary="Load a file in line into the code">
         <usage syntax="#LOAD &quot;filename&quot;, length">
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
         <usage syntax="#MAPWS blockname[,register]">
         if no register is specifed, the default is used.
</directive>

<directive label="#AREA" summary="Begin an AOF area for the following code">
         This declares the start of a named AOF area.
         <usage syntax="#Area &quot;areaname&quot; [flags]">
         The area flags are a space separated list of flags for the area:
         <param-list label='Flag'>
          <param name='CODE'>Area is for Code (otherwise it is a Data area)</param>
          <param name='32BIT'>Area contains 32bit code (otherwise it contains 26bit code)</param>
          <param name='READONLY'>Area is read only (otherwise it is writeable)</param>
          <param name='STACKCHECK'>Area is contains stack checked code (otherwise it is not stack limit checking)</param>
         </param-list>
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
               <usage syntax="#COND SET varname boolean">
</directive>

<directive label='#COND <i>varname</i> ' summary="Sets a condition variable according to user reply">
               In External mode, this will display a error box type message
               In Inline mode, the messages will be printed on the screen
               and a OS_Confirm used to get the reply.
               <usage syntax="#COND varname &quot;question&quot;">
</directive>

<directive label='#COND OF' summary="Starts a conditional assembly structure">
               The following code within this structure will be assembled if
               the named condition variable is true.
               <usage syntax="#COND OF varname">
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

<directive-list>
<directive label='CHECK STRING' summary='Check that a particular address contains a ctrl terminated string.'>
               <usage syntax='#CHECK STRING address string'>
               Note: The string may be enclosed in quotes.
</directive>

<directive label='CHECK WORD' summary='Check that a particular word contains a particular value'>
               <usage syntax='#CHECK WORD address value'>
</directive>

<directive label='CHECK LEN' summary='Check that the length of the file is a certain value'>
               <usage syntax='#CHECK LEN length'>
</directive>
</directive-list>


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

<jfpatch>
#LIBRARY "filename",[#]routine[[[.routine].routine]...]
</jfpatch>

<p>
<i>filename</i> is an absolute filename if there is a path, otherwise the
<code>JFPatch.Libraries</code> directory is searched.
<i>routine</i> may be * if you want all libraries to be included in a file - not
recommended.
</p>

<p>
The <code>#</code> symbol means that the libraries will be included at this point in the
code. Otherwise, a <code>#HERE LIBRARIES</code> directive will need to be issued.
</p>

<p>
The library files themselves consist of a first line which should be:
</p>

<jfpatch>
LIBRARY filename
</jfpatch>

<p>
Followed by the routines in the library. Local labels may be used, but
externally referenced variables may not due to the manner in which the
inclusion occurs. Inclusion is from the first <code>;</code> before the <code>.</code> prefix of the
routine name to the line before the first <code>;</code> before the next <code>.</code> (or the next <code>.</code>
if there is no <code>;</code>). See the Summary file for more details, and refer to
Strings for examples. FIXME
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

<jfpatch>
#INCLUDE "filename"
</jfpatch>

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

<directive-list>
<directive label='#HERE FOOTER' summary='Embed the Footer file at this point'>
               This might be used as DoggySoft use to place "Anything after
               this point is probably a virus")
</directive>

<directive label='#HERE LIBRARIES' summary='Embed all previously defined libraries'>
               You should probably not need to use this unless you are very
               organised. I use <code>LIBRARY <i>filename</i>,#[routine]</code> in preference.
</directive>

</directive-list>
</section>

<section>
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
Pre
  |label| = value
End Pre
</jfpatch>
</section>


<section>
<h2>Post-assembly section</h2>

<p>
This section is used for code which should be run after the code has been
assembled. The section is enclosed by #Post and #End (or the end of the
file). All the code given will be passed directly to Basic, unless it is
prefixed by a # symbol. In which case, the following apply:
</p>

<directive-list>
<directive label='#RUN' summary='Runs a particular file'>
        If the file specified is <code>&lt;CODE&gt;</code> (note: upper case), then the output file is run.
        If <code>&lt;THISDIR&gt;</code> is included, then it is replaced by the directory the Patch file is in.
        <usage-block>
#Post
    #RUN filename
    #RUN FS::disc.$.pathname
    #RUN &lt;THISDIR&gt;.filename
    #RUN &lt;CODE&gt;
</usage-block>
</directive>

<directive label='#WIMPRUN' summary='Performs the same as RUN, except that the file is Filer_Run.'>
</directive>

<directive label='#EXAMINE' summary='Used to examine memory to check that it is what you expect it to be.'>
        Usually this is used after executing the code. The output is saved to
        a file and loaded as a text file.
        <usage syntax='#EXAMINE address address'>
        <usage syntax='#EXAMINE address +length' alternate>
</directive>

<directive label='#CAPTURE' summary='Captures all output into a spool file.'>
        This is usually used where the output cannot be captured in a TaskWindow.
        <usage syntax='#CAPTURE boolean'>
        Default is ON
</directive>

<directive label='#END' summary='End section, start End section'>
</directive>
</directive-list>

</section>

<section>
<h2>End section</h2>

<p>
All text in the end section will be appended to the file and never be
executed, unless it is called as a PROCedure or FuNction.
</p>

<p>
This is useful for including information about the author, or program.
However, it's real purpose is to allow functions to be used as macros.
</p>
</section>


<section>
<h2>Workspace</h2>

<p>
What is the point of using workspace blocks ? Well, it's easier to see a
reference:
</p>

<jfpatch>
   LDRW   r0,`taskhandle
</jfpatch>

<p>
It is easier see that it means get the task handle from workspace than:
</p>

<jfpatch>
   LDR    r0,[r12,#8]
</jfpatch>

<p>
Begin a workspace block with DEFINE WORKSPACE and end it with END WORKSPACE.
Within these blocks, you should use the following commands :
</p>

<directive-list>
<directive label='NAME' summary='Sets the name of the block'>
</directive>
<directive label='PREFIX' summary='Allows you to specify a prefix to use within this block'>
         A variable named <code>x0</code> with a prefix of <code>win</code> becomes <code>winx0</code>. When
         used, <code>`</code> prefixes to the original name are retained, so <code>`x0</code> would
         become <code>`winx0</code>.
</directive>
<directive label='DEFAULT' summary='Sets the default register to use for the workspace.'>
</directive>
</directive-list>

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

<pre>
  <i>offset</i>  <i>identifier</i>[  <i>comment</i>]
</pre>

<p>
where <i>offset</i> is either a decimal number, or a hex number prefixed by <code>&amp;</code>.
</p>


<h3>Relative format</h3>
<p>
    This is a much more powerful format for creating workspace structures, and is
similar (though in no way compatible) to that used by ObjAsm. In this form,
the definitions are :
</p>

<pre>
  [=]<i>variable</i>  <i>type</i>[repetitions][  <i>comment</i>]
</pre>

<p>
where <i>type</i> is :
</p>

<param-list label='type'>
  <param name='!'>an integer word (ie 4 bytes)</param>
  <param name='%'>a byte</param>
  <param name='$'>a string (<i>repetitions</i> is the number of characters including terminator)</param>
  <param name='^'>a structure reference in the form
<pre>
     ^<i>name</i>[  <i>repetitions</i>]
</pre>
</param>
</param-list>

<p>
<i>repetitions</i> is the number of times the space is repeated (ie four words
would be !4).
</p>

<p>
Within this structure, blocks may be repeated, or "unioned" by using brackets
to group the items. Placing a <code>(</code> alone on a line begins a grouping, <code>)</code> alone
ends a grouping, and <code>)</code> followed by a number sets a number repetitions for the
block.
</p>

<p>
Within a grouping, <code>|</code> on its own on a line sets a union. This means
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
    To use workspace within the code, use <code>[ LDR|STR ][B]W</code> or <code>ADRW</code> commands. To
find the length of a block of workspace, use `len_<i>name</i>.
</p>
</section>

<section>
<h2>Module section</h2>

<p>
Modules are easy to write. You may not think that now, but after using
JFPatch for some time to create modules, you will find that modules are so
simple to program that you may have to get a life to fill the time you would
have spent struggling... Only kidding people...
</p>

<p>
Module definitions are enclosed by <code>DEFINE MODULE</code> and <code>END MODULE</code>. Within these statements, the fields are:
</p>

<param-list label='Field'>
<param name='NAME'>Module name as used in *Modules command (default=Untitled)</param>
<param name='VERSION'>Version number to use in help string (default=1.00, or the version in the header.</param>
<param name='AUTHOR'>Author name to use in help string (default=not used)</param>
<param name='HELP'>Name to use in *Help Modules (default=<i>NAME</i>)</param>
<param name='EXTRA'>Extra text to append after the date in *Help Modules (default=none)</param>
<param name='INIT'>Initialisation address or label (default=no code)</param>
<param name='FINAL'>Finalisation address or label (default=no code)</param>
<param name='START'>Start address or label (default=no code)</param>
<param name='SERVICE'>Service handler label</param>
<param name='SERVICES'>Begin services definition (instead of a user handler</param>
<param name='EVENTS'>Begin events definition</param>
<param name='VECTORS'>Begin vectors definition</param>
<param name='COMMANDS'>Begin OSCLI/Help/Configure commands definition</param>
<param name='SWIHANDLER'>SWI handler code (default=handled automatically)</param>
<param name='SWIS'>Begin SWI call definition</param>
<param name='WORKSPACE'>Length of workspace to claim in r12, prefix with * to initialise 0</param>
<param name='WIMPSWIS'>Begin WimpSWIVe handler definition (WimpSWIVe © Andrew Clover)</param>
<param name='PREFILTER'>Begin a Pre-Poll filter definition</param>
<param name='POSTFILTER'>Begin a Post-Poll filter definition</param>
<param name='RECTFILTER'>Begin a Pre-Rectangle redraw filter definition</param>
<param name='POSTRECTFILTER'>Begin a Post-Rectangle redraw filter definition</param>
<param name='COPYFILTER'>Begin a Copy region filter definition</param>
<param name='POSTICONFILTER'>Begin a Post-icon redraw filter definition</param>
<param name='MESSAGEFILE'>Declare the name of the messages file to use for commands (default=none)</param>
<param name='RESOURCES'>Begin a ResourceFS files definition</param>
<param name='IMAGEFS'>Begin an Image Filing System definition</param>
<param name='FS'>Begin a full Filing System definition</param>
</param-list>


<p>
The only one which really ought to be defined is NAME, although all are
optional.
</p>

<h3>Init, final and service code</h3>
<p>
    Whilst you may not have defined some of these, they may be created for you by
JFPatch to implement other features. The cases are as follows :
</p>

<param-list label='Fields&nbsp;used'>
<param name='Workspace used'>Init used to claim workspace, Final used to release it</param>
<param name='Filters used'>Init used to register, Final used to deregister, Service used to claim on FilterManager start up.</param>
<param name='WimpSWIs used'>Init used to claim, Final used to release.</param>
<param name='Services used'>Service handler caught <em>before</em> 'Service' entry.</param>
<param name='Vectors used'>Init used to claim, Final used to release.</param>
<param name='Events used'>Init used to claim, Final used to release.</param>
</param-list>


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

<ul>
<li>Init</li>
<li>Final</li>
<li>Service</li>
<li>Services (definition type)</li>
<li>Events</li>
<li>Vectors</li>
<li>SWIs</li>
<li>WimpSWIs</li>
<li>Filters</li>
</ul>

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

<pre>
  <i>service</i>   <i>code</i>
</pre>

<p>
Where <i>service</i> can be a decimal or hex number, or any string from the
!JFPatch.Resources.Services file. This contains the service names
(approximately) as given in OSLib header files. The block should be ended
with:
</p>

<pre>
  End Services
</pre>


<h3>Vectors</h3>

<p>
Vectors can be claimed and released manually using init and final code, but
by using a definition block many of the problems you may come across are
removed and things look a bit clearer. The lines are of the form :
</p>

<pre>
  <i>vector</i>   <i>code</i>
</pre>

<p>
Where <i>vector</i> can be a decimal or hex number, or any string from the
!JFPatch.Resources.Vectors file. This contains the vector names
(approximately) as given in OSLib header files. The block should be ended
with :
</p>

<pre>
  End Vectors
</pre>

<h3>Events</h3>

<p>
    Whilst you can trap events using the Vectors call or manually, it's probably
easier to have these in a seperate section. The lines are of the form :
</p>

<pre>
  <i>event</i>   <i>code</i>
</pre>

<p>
    Where <i>event</i> is a decimal or hex number, or a string from the
!JFPatch.Resources.Events file. This contains the vector names as given in
OSLib headers files except that I've prepended the module name if there is
one. The block should end with :
</p>

<pre>
  End Events
</pre>


<h3>Commands</h3>

<p>
    Commands are denoted by COMMANDS to start, and END COMMANDS to end. Entries
within this block, the fields are :
</p>

<param-list label='Field'>
<param name='NAME'>The command name</param>
<param name='CODE'>Code to execute when called (default= no code)</param>
<param name='MAX'>Maximum number of parameters which may be passed</param>
<param name='MIN'>Minimum number of parameters which may be passed</param>
<param name='TYPE'>Type of command (default=COMMAND). Options : FS, CONFIG</param>
<param name='FLAGS'>Value of the command flags. Overrides the max, min and type settings.</param>
<param name='SYNTAX'>Syntax of the command (defaults to no message)</param>
<param name='HELP'>Help on the command (defaults to no message)</param>
</param-list>

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

<p>
SWI blocks, like command blocks are surrounded by <code>SWIs</code> and END SWIs. Within
this block, the following two fields are allowed:
</p>

<param-list label='Field'>
<param name='BASE'>Sets the base number of the SWI calls, prefix with <code>&amp;</code> for hex</param>
<param name='PREFIX'>Sets the prefix for all the calls. Omit the trailling <code>_</code>.</param>
</param-list>

<p>
All other lines should be in the form :
</p>

<pre>
  <i>number</i>   <i>alias</i>   <i>code</i>
</pre>

<h3>WimpSWIs</h3>

<p>
WimpSWIve is a gorgeous little module written by Andrew Clover which allows
you to replace certain Wimp calls with other, much nicer calls :-)
For more information, read the WSWI-Help documentation in Applics. Again, the
section is surrounded by WIMPSWIS and END WIMPSWIS. And the fields are :
</p>

<param-list label='Field'>
<param name='SWI'>Full name of WimpSWI to replace</param>
<param name='PRE'>Pre-handler code (before real call being called)</param>
<param name='POST'>Post-handler code (after real call being called)</param>
</param-list>

<p>
Either the Pre-Handler or the post handler may be prefixed by the ^ symbol.
In which case, the code will have the high priority bit set. Mixed priority
SWI handlers are not allowed, and you must use two seperate definitions if
you wish to do that.
</p>

<h3>Filters</h3>

<p>
Filters are one of the most useful of the features of RO3 (to the programmer
at least). Filters allow you to trap calls Wimp_Poll in much the same way
that WimpSWIs do for the other calls. There are two types of Filters which
can be used, Pre- and Post-poll filters. These are in seperate sections,
delimited by opening and closing block statements. The filters which can be
registered are:
</p>

<ul>
    <li>Pre-poll filter.<br/>
        Begin block with <code>PREFILTER</code>.<br/>
        End block with <code>END PREFILTER</code> or <code>END FILTER</code>.
    </li>

    <li>Post-poll filter.<br/>
        Begin block with <code>POSTFILTER</code>.<br/>
        End block with <code>END POSTFILTER</code> or <code>END FILTER</code>.
    </li>

    <li>Pre-rectangle redraw filter.<br/>
        Begin block with <code>RECTFILTER</code>.<br/>
        End block with <code>END RECTFILTER</code> or <code>END FILTER</code>.
    </li>

    <li>Post-rectangle redraw filter.<br/>
        Begin block with <code>POSTRECTFILTER</code>.<br/>
        End block with <code>END POSTRECTFILTER</code> or <code>END FILTER</code>.
    </li>

    <li>Copy rectangle region filter (not currently implemented).
    </li>

    <li>Post-icon redraw filter.<br/>
        Begin block with <code>POSTICONFILTER</code>.<br/>
        End block with <code>END POSTICONFILTER</code> or <code>END FILTER</code>.
    </li>
</ul>

<p>
The fields within each of the blocks are declared with the following definitions:
</p>

<param-list label='Field'>
<param name='NAME'>Name for the filter (for the list)</param>
<param name='CODE'>Filter handler code</param>
<param name='MASK'>Wimp_Poll mask as a number (only post-filters)</param>
<param name='ACCEPT'>An alternate way of specifying the filter mask by giving names of poll reasons to accept (only post-filters)</param>
<param name='TASK'>Task name to apply filter to (or - for all tasks)</param>
<param name='METHOD'>How filter registration should be performed.
 <param-list label='Method'>
  <param name='ERROR'>If the task requested is not present, report an error and fail to initialise. This is the default.</param>
  <param name='MULTIPLE'>Register filters on tasks as they start up.</param>
 </param-list>
 </param>
</param-list>

<p>
Post-filters must have either MASK or ACCEPT specified. ACCEPT commands must
be given on seperate lines, and the names are :
</p>

<table class='filter-accept-list'>
     <tr class='heading'>
        <th>Primary name</th>
        <th>Secondary name</th>
        <th>Tertiary name</th>
    </tr>
<$macro filter-accept name1:string name2:string="" name3:string="">
     <tr class='row'>
        <td><(name1)></td>
        <td><(name2)></td>
        <td><(name3)></td>
    </tr>
</$macro>

<filter-accept name1="Null">
<filter-accept name1="Redraw">
<filter-accept name1="OpenWindow">
<filter-accept name1="CloseWindow">
<filter-accept name1="PointerLeaving">
<filter-accept name1="PointerEntering">
<filter-accept name1="MouseClick">
<filter-accept name1="UserDragBox" name2="DragDropped">
<filter-accept name1="KeyPress" name2="KeyPressed">
<filter-accept name1="Menu" name2="MenuSelection">
<filter-accept name1="Scroll" name2="ScrollRequest">
<filter-accept name1="LoseCaret">
<filter-accept name1="GainCaret">
<filter-accept name1="PollWord">
<filter-accept name1="UserMsg" name2="UserMessage" name3="Message">
<filter-accept name1="UserMsgRec" name2="UserMessageRecorded" name3="MessageRec">
<filter-accept name1="UserMsgAck" name2="UserMessageAcknowledged" name3="MessageAck">
</table>

<h3>Resources</h3>

<p>
Resources can be registered with ResourceFS when the module initialises by defining
them in the Resources definition. The fields within the <code>RESOURCES</code> block take the form:
</p>

<pre>
    <i>local-filename</i>    <i>resourcefs-filename</i>
</pre>

<p>
Note: It is possible that the Resources registration is non-functional at present.
</p>

<h3>ImageFSs</h3>

<p>
The entry points and registrations for an ImageFS filesystem can be registered with the ImageFS
block. The following fields are defined in the definition:
</p>

<param-list label='Field'>
<param name='TYPE<br/>FILETYPE'>Sets filetype which is handled by the ImageFS, which may be a hex value prefixed by <code>&amp;</code>, or a type name (or bare hex filetype)</param>
<param name='FLAGS'>Flags to set for the filesystem. Flags are space separated list of names, and may be prefixed by a <code>-</code> character to indicate the the flag is not set. The flags field may be specified multiple times, and will accumulate flags (or subtract them, if the <code>-</code> prefix is used. Flags currently known are:
    <param-list label='Flag name'>
        <param name='TELLFSWHENFLUSHING<br/>TELLWHENFLUSHING'>Sets bit 27 of the flags word</param>
    </param-list>
</param>

<param name='OPEN'>Entry point for ImageFS_Open</param>
<param name='CLOSE'>Entry point for ImageFS_Close</param>
<param name='GET<br/>GETBYTES'>Entry point for ImageFS_GetBytes</param>
<param name='PUT<br/>PUTBYTES'>Entry point for ImageFS_PutBytes</param>
<param name='ARGS'>Entry point for ImageFS_Args</param>
<param name='FILE'>Entry point for ImageFS_File</param>
<param name='FUNC'>Entry point for ImageFS_Func</param>

</param-list>


<h3>Full FSs</h3>

<p>
The entry points and registrations for a full filesystem can be registered with the FS
block. The following fields are defined in the definition:
</p>

<param-list label='Field' hasrequired>
<param name='NAME' required>Name of the filing system</param>
<param name='STARTUP'>Text to print on filing system selection</param>
<param name='NUMBER' required>Sets the filing system number for the filing system</param>
<param name='FILES'>Number of open files supported by the filing system, or <code>INFINITE</code> if not limited</param>
<param name='FLAGS' required>Flags to set for the filesystem. Flags are supplied as a space separated list of names, and may be prefixed by a <code>-</code> character to indicate that the flag is clear. The flags field may be specified multiple times, and will accumulate flags (or subtract them, if the <code>-</code> prefix is used. Flags currently known are:
    <param-list label='Flag name'>
        <param name="SPECIALFIELDS">Sets bit 31 in the flags</param>
        <param name="INTERACTIVESTREAMS<br/>INTERACTIVE">Sets bit 30 in the flags</param>
        <param name="NULLFILENAMES">Sets bit 29 in the flags</param>
        <param name="ALWAYSOPENFILES">Sets bit 28 in the flags</param>
        <param name="TELLFSWHENFLUSHING<br/>TELLWHENFLUSHING">Sets bit 27 in the flags</param>
        <param name="SUPPORTSFILE9">Sets bit 26 in the flags</param>
        <param name="SUPPORTSFUNC20">Sets bit 25 in the flags</param>
        <param name="SUPPORTSFUNC18">Sets bit 24 in the flags</param>
        <param name="SUPPORTSIMAGEFS">Sets bit 23 in the flags</param>
        <param name="USEURDLIB">Sets bit 22 in the flags</param>
        <param name="NODIRECTORIES<br/>NODIRS">Sets bit 21 in the flags</param>
        <param name="NEVERLOAD<br/>USEOPENGETCLOSE">Sets bit 20 in the flags</param>
        <param name="NEVERSAVE<br/>USEOPENPUTCLOSE">Sets bit 19 in the flags</param>
        <param name="USEFUNC9">Sets bit 18 in the flags</param>
        <param name="READONLY">Sets bit 16 in the flags</param>
        <param name="SUPPORTSFILE34">Sets bit 0 in the extra flags</param>
        <param name="SUPPORTSCAT">Sets bit 1 in the extra flags</param>
        <param name="SUPPORTSEX">Sets bit 2 in the extra flags</param>
    </param-list>
</param>

<param name='OPEN'>Entry point for FS_Open</param>
<param name='CLOSE'>Entry point for FS_Close</param>
<param name='GET<br/>GETBYTES'>Entry point for FS_GetBytes</param>
<param name='PUT<br/>PUTBYTES'>Entry point for FS_PutBytes</param>
<param name='ARGS'>Entry point for FS_Args</param>
<param name='FILE'>Entry point for FS_File</param>
<param name='FUNC'>Entry point for FS_Func</param>
<param name='GBPB'>Entry point for FS_GBPB</param>

</param-list>

<p>
Note: The extra flags setting may be broken in the current implementation.
</p>

</section>

<section>
<h2>Macros section</h2>

<p>
The macros section declares macros - templated blocks of instructions - which are to be
used within the assembly. The macros are not widely used and probably contain many bugs.
The macro section is started with <code>DEFINE MACROS</code> and ended with <code>END MACROS</code>. The fields within the section are:
</p>

<param-list label='Field' hasrequired>
    <param name='COMMAND'>Name of the macro, to be used in place of the instruction mnemonic</param>
    <param name='CONDS'>Which condition codes are allowed for this macro, as a space separated list, or a special word:
        <param-list label='Cond'>
            <param name='ALL'>All conditions are allowed</param>
            <param name='NEVER'>No conditions are allowed</param>
            <param name='INVERT'>All condition codes are allowed by inserting an inverted condition instruction to branch over the macro code</param>
        </param-list>
    </param>
    <param name='TEMPS'>Number of temporary registers required</param>
    <param name='MASK'>Parameters template for the macro. The template consists of a string which has substitution characters used to declare what parameters are passed to the macro. The substitutions are prefixed by <code>@</code> and take the form:
        <param-list label='Substitution'>
            <param name='@r<i>name</i>'>Names a single register parameter. <i>name</i> is a single character name for this parameter.</param>
            <param name='@g<i>name</i>'>Names a group of registers, in the form <code>{<i>registers</i>}</code>. <i>name</i> is a single character name for this parameter.</param>
            <param name='@c<i>name</i>'>Names a constant value prefixed by a <code>#</code> character. <i>name</i> is a single character name for this parameter.</param>
            <param name='@t<i>name</i>'>Names a register that may be used as a temporary. <i>name</i> is a single character name for this parameter. Not currently implemented.</param>
        </param-list>
    </param>
    <param name='CODE'>Begins the code to use for the macro, which ends at an <code>END CODE</code>.
    Within the <code>CODE</code> block, the names <code>@[r|g|c]<i>name</i></code> may be used to substitute in the invocation.
    </param>
</param-list>

<p>
Macros are not well used within JFPatch code, so there will be bugs, and it may not work as described or as expected.
</p>
</section>


    </page>
</body>
</html>
