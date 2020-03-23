<!DOCTYPE html>
<html>
<html-header title='History' codecolouring></html-header>
<body onload='setup_colouring({autosize: true, linenumbers: false});'>
    <page section='History'>

<section>
<h2>History</h2>

<$macro version-table /CLOSE>
<table class='versions'>
    <tr class='heading'>
        <th>Version</th>
        <th>Date</th>
        <th>Changes</th>
    </tr>
<$content>
</table>
</$macro>

<$macro version /CLOSE number:string/REQUIRED date:string=''>
    <tr class='row'>
        <td class='number'><(number)></td>
        <td class='date'><(date)></td>
        <td class='changes'><$content></td>
    </tr>
</$macro>

<h3>!JFPatch as a Service</h3>
<version-table>
FIXME: Put stuff in here.
</version-table>

<h3>!JFPatch RISC OS application and back end</h3>
<version-table>
    <version number='2.55ß' date=''>Note: (partial releases were 2.54ß)
        <ul>
<li> Multiple entries in 'Events' blocks now work - previously they did
  everything except claim the vector.</li>
<li> MemCpy routine added to AOF code.</li>
<li> EgCode added in case people want it.</li>
<li> Service call handler code isn't quite as intelligent as first thought.
  Produces things like :
<jfpatch>
   SUB     R0,R1,#&amp;00100000
   SUB     R0,R0,#&amp;00023000
   SUB     R0,R0,#&amp;0400
   SUB     R0,R0,#&amp;40
   SUB     R0,R0,#&amp;10
   SUB     R0,R0,#4
   TEQ     R0,#2
</jfpatch>
  For &amp;123456, which some might argue was slightly sub-optimal.
  Now slightly more optimal (move, and increased tap bits)
<jfpatch>
   SUB     R0,R1,#&amp;00120000
   SUB     R0,R0,#&amp;3400
   TEQ     R0,#&amp;56
</jfpatch>
  which is kinda better.<br/>
  Also, instead of re-starting the subtractions afresh each time, the value
  will only be recalculated if it would generate more than two subtractions.
  This may not be amazingly optimal, but without a full search it will
  suffice. Test includes miscellaneous ridiculous service numbers to test the
  optimisation code.<br/>
  To facilitate these changes the services list is now sorted and each
  routine requiring a service must supply two pieces of code, one for when
  the user specifies a service handler (now decrecated), and one for the
  auto-generated form. Autogeneration is much more preferable.</li>
<li> Ursula style module service blocks added. As the current dispatch handler
  <i>is</i> the reject handler in JFPatch modules, it is not possible to seperate
  them. However it is intended that this situation be changed in the near
  future.</li>
<li> Added choice of relocation routine in AOF modules with
<jfpatch>
    AOFRELOC   routine
</jfpatch></li>
<li> Added JB's cunning LDR/ADR :
<jfpatch>
    LDR    r#,|label|
    ADR    r#,|label|
</jfpatch>
  Note: These do NOT use LTORG as you may have used in other assemblers.</li>
<li> Multiple post filter reason codes can now be filtered off and combined with
  unknown reason code processors (which no longer worked in 2.53 :-( )</li>
</ul>
</version>

<version number='2.53ß'>partial releases were 2.52ß2<br/>
<ul>
<li> Filenames localised differently; most places that include filenames (eg In,
  Out, #Include, #Load) now use a generic 'localfile' routine meaning that
  any filename with no path information in it (ie no .'s or :'s) will be
  assumed to be in the source file directory; those with path information are
  assumed to be absolute, /except/ those starting with @ which are localised
  to the source file directory. It makes more sense when you use it than
  written down !</li>
<li> Added MessageFile fix (Johnathan Brady) - what did I write last time ? Was
  it complete cack or am I just imagining the code I saw ? :-)</li>
<li> Added Resources block (Johnathan Brady) :
<jfpatch>
    Resources
      local-file  resource-file
    End Resources
</jfpatch>
  Note: 2nd parameter is the filename of the resource file, if you give this
  a different leaf name to the local file then it'll use that leaf name.<br/>
  Note 2: If you use a directory it'll include that directory as the resource
  file name and all of it's children.<br/>
  Local files follow the same regime as the In and Out directives described
  above.<br/>
  #Here Resources will include the resources at a particular location, or at
  the end of the code if not specified.<br/>
  JB's routines slightly optimised at basic sides.</li>
<li> Expanded list of people beta-testing to :
    Chris Johns,
    Phil Norman,
    Jonathan Brady,
    (Is matt interested?)<br/>
  Will other people wishing to test <i>please</i> contact me to be added to this
  list. Similarly, suggestions for people who wouldn't mind would be good.
  Testing means that you're happy to put up with more bugs than usual in
  JFPatch and suggest both ideas and possible fixes. Not all will be
  implemented but that's true of anything.</li>
<li> Workspace checks now include <code>`len_<i>wsname</i></code> (Johnathan Brady), but I don't
  see much of a use for this except in the context of ADRW when creating an
  FD stack. These routines will soon be moved elsewhere to cope with CAS/RAS.</li>
<li> FNshowreg improved to use ConvertInteger instead of adding a - and calling
  ConvertCardinal; this saves all of three instructions per REM "%r#" call
  (!).</li>
<li> Output buffering doubled to 16k (text) and 4k (debug).</li>
<li> 'Flags Token' now added to definition of commands.</li>
<li> In Post-Filter code, the 'Code' entry may now be of two forms :
<jfpatch>
     Code    label
</jfpatch>
  The standard form, with usage as before, and also
<jfpatch>
     Code    reason    label
</jfpatch>
  The extended form with all the checking of the conditions done for you.
  Mask/Accept need not be specified, but if it is /must/ preceed the Code
  entries. Multiple entries of the form /are/ allowed and will be cumulative.
  Use of the standard form and the extended form are allowed, but you will
  need to use '<code>Mask <i>value</i></code>' or '<code>Accept <i>reason</i></code>' if you wish to use these
  as otherwise you will never actually see the reasons. Similarly, the
  standard form will never see those codes catered for by the extended codes.</li>
<li> Tiny optimisation means that Modules with the same name as their SWI prefix
  will only include one instance of the name.</li>
<li> ImageFS handling blocks added :
<jfpatch>
   ImageFS
    Type     filetype
    Open     label
    Close    label
    Args     label
    Get      label
    Put      label
    Func     label
    File     label
    Flags    flags
   End ImageFS
</jfpatch>
  Only 'Type' is required, but without the rest it won't do much.
  'Flags' may be given many times, and may be preceeded by - to negate.<br/>
    Flag                  bit to set (see manuals)<br/>
    TellWhenFlushing             27<br/>
  This has not been tested hardly; use at your own risk :-)</li>
<li> Normal filing system block added :
<jfpatch>
   FS
    Name     fs name
    Startup  fs startup text | -
    Number   fs number
    Files    number of open files | Infinite
    Open     label
    Close    label
    Args     label
    Get      label
    Put      label
    Func     label
    File     label
    GBPB     label
    Flags    flags
   End FS
</jfpatch>
  'Name', 'Number' and 'Files' are required. Startup text of - will use Func
  17 to display FS name.<br/>
  'Flags' may be given many times, and may be preceeded by - to negate.
    Flag                  bit to set (see manuals)<br/>
    SpecialFields                31<br/>
    InteractiveStreams           30<br/>
    NullFilenames                29<br/>
    AlwaysOpenFiles              28<br/>
    TellWhenFlushing             27<br/>
    SupportsFile9                26<br/>
    SupportsFunc20               25<br/>
    SupportsFunc18               24<br/>
    SupportsImageFS              23<br/>
    UseURDLib                    22<br/>
    NoDirectories / NoDirs       21<br/>
    NeverLoad / UseOpenGetClose  20<br/>
    NeverSave / UseOpenPutClose  19<br/>
    UseFunc9                     18<br/>
    ReadOnly                     16<br/>
    SupportsFile34               ext 0<br/>
    SupportsCat                  ext 1<br/>
    SupportsEx                   ext 2<br/>
  This has not been tested hardly; use at your own risk :-)<br/>
  FS names has been optimised to use the module name <i>if</i> this is the same;
  similarly the startup text.</li>
<li> Fixed bug in module help worker-outer to append more tabs if required. The</li>
  code's been there since /really/ early versions but has only ever fired on
  single character module names because it was severely broken.
</ul>
</version>

<version number='2.52ß'>
    <ul>
<li> Changed the function of the ERR macro. This used to embed an
  'OS_GenerateError' block into some code. Now it embeds an error block;
  syntax is :
<jfpatch>
    ERR  number,string
</jfpatch></li>

<li> Added REMF and REMFP variants of the REM macro; these /will/ preserve the</li>
  flags and the link register...
</ul>
</version>

<version number='2.51ß'>
<ul>
<li> Output buffering added. This isn't at all impressive, but seemed like an</li>
  interesting and useful optimisation to have. Maybe it won't thrash the
  drive on Chris' machine, or maybe it will - I'll have to see.
<li> Output buffering on debug data added. As above this appears to make very</li>
  little difference to the performance, but as I'm timing things using the
  seconds numbers on !Alarm I reserve the right to be wrong. For those of
  interest, the buffers are 8k for the main BasTxt file and 2k for the debug
  data. Since BasTxt files tend to be rather large I may up this some time
  soon.
<li> Bug fixes in 2.50ß's dictionary encoding code, and optimised encoding's now</li>
  mean that entries including the token 0 will not fail to be compressed to
  their minimal form.
<li> Release to Chris Johns and Phil Norman. I don't actually know who else uses</li>
  it... I wish people would contact me - if only to report bugs !
</ul>
</version>

<version number='2.50ß'>
<ul>
<li> printf improved to include %d for cmj</li>
<li> memcpy added (suboptimal but works!) (currently only on cmj's machine)</li>
<li> Pre/PostFilter code handlers in AOF mode didn't work previously - now fixed</li>
<li> WimpSWIs didn't work since about 2.46ß where I tried optimising the code;
  both WimpSWIs and Filter code should be vaguely optimal</li>
<li> SWIs block now allows for 'Pre' and 'Post' handler code - this should allow
  you to do things before we check the SWI number and after we return from the
  SWI call</li>
<li> Extra info string has been added (for Module block) to allow you to describe
  a module more fully (eg, ARM3 variant, etc) on the help line.</li>
<li> Syntax strings will now have the OS dictionary for RO3.1 substituted into
  them</li>
<li> Looks like strings can have embedded variable expressions in them (I've no
  idea when I added this); things like Help blocks can have <code>{expr}</code> to
  indicate that the <code>expr</code> can be embedded - eg, This was compiled {TIME$}
  Just goes to show what you can learn when you read your own programs!</li>
</ul>
</version>

<version number='2.49ß'>
<ul>
<li> Added Phil Norman's divide routine to the 'Libraries' directory (at last!),
  as well as another Divide routine I got from 'jonboy' on IRC.</li>
<li> Partial messages file support added ('jonboy')</li>
<li> InsBranch library added; similar to Patch, but useful when you don't care
  what you've patched, or need to patch a branch table, etc... ('jonboy')</li>
<li> Strings library updated to use 'nice-upper' code extracted from RiscOS :-)</li>
<li> SWI out of range now uses MessageTrans rather than 'knowing' the error
  ('jonboy')</li>
<li> Added 'printf' library for making debugging in C easier (yay!)</li>
<li> Fixed and optimised a few string routines.</li>
</ul>
</version>

<version number='2.48ß'>
<ul>
<li> 'Type AOFModule' is now depreciated; you should use 'Type AOF Module'
  instead; new syntax is '<code>Type AOF [subtype [subtype]...]</code>' where
  'subtype' may be Module or Debug.
  The current implementation of Debug, whilst looking correct seems to
  crash DDT; I recommend that you avoid the debug option for the time being.</li>
<li> Released to Chris Johns, Phil Norman and 'jonboy' (who I've forgotten the
  name of!)</li>
</ul>
</version>

<version number='2.47ß'>
<ul>
<li> REM storage space moved onto stack rather than inside code. This should
  allow you to /really/ say READONLY in AOF with REM's in them.</li>
<li> WARNING: Do NOT use WimpSWI Post trap code prior to this version; pretrap
  code will be called instead !!!!</li>
<li> In AOF, any exported label followed by the word ENTRY will be made the
  execution entry point for this file.</li>
</ul>
</version>


<version number='2.46ß'>
<ul>
<li> Minor bugs in AOF handling fixed</li>
<li> Fixed bug with $$ - this now translates to $ correctly if macros are not in
  use</li>
</ul>
</version>

<version number='2.45ß'>
<ul>
<li> Arrgghh... fixed nasty bug in the WimpSWIve claim routines ;-(
  This should stop the table being included twice and r0 being corrupted
  randomly in the init code !</li>
<li> Don't even think about using |'s around WimpSWIve stuff - it doesn't work,
  I've got to work out how to get the right addresses in there - atm it's
  using offsets for normal variables, and addresses for |'s - I need a
  consistant interface internally - I don't want conversions on the fly if I
  can help it ;-(</li>
<li> CAS and RAS macros added. Don't expect anything special from them though.</li>
<li> I think CodePrefix actually works now... Need to check this really though.</li>
<li> TaskWindow error handling improved.</li>
<li> Includes now work correctly (inline, rather than at end)</li>
</ul>
</version>

<version number='2.44ß'>
<ul>
<li> Multiple areas now supported correctly.</li>
<li> AOFModule now allows |label| style labels for the most part - if there's one</li>
  I've missed please tell me :-)
<li> Relocation of symbols where they are both exported and local now works if the</li>
  first instance was a reference and not a definition.
<li> Filters /may/ not work on AOFModules. This is untested.</li>
<li> WimpSWIs /do/ work with AOFModules.</li>
<li> <code>EQUD |routine|</code> will store the /absolute/ address, not the relative one -
  ideas as to how to fiddle this are greatfully appreciated :-)</li>
<li> strdup added to j.memory.</li>
<li> astrcmp added - this is an assembler style string compare - it returns EQ,</li>
<li> LT, GT, etc rather than -1,0,+1 as in C. There is no C header for this.</li>
<li> Events, Services, Vectors, init, final &amp; service have not been tested for use
  with AOF functions.</li>
<li> Some re-organisation of the internals of the filters code means that it is no
  longer restricted to the 64k previously available - this takes one extra
  word and I'm not happy with it - I'd rather the use of that style of function
  was restricted to AOFModule only, then standard Module types could have the
  luxury of an extra instruction with the knowledge that they cannot exceed 64k
  of code (!)</li>
</ul>

Notes:
<ul>
<li> Remember: strcpy copies from r1 to r0 NOT r0 to r1.</li>
<li> Filters using Accept are unstable - be careful to check <i>explicitly</i> for the
  reason you want. Unfortunately ToolBox passes ridiculously big reasons down
  to the application - it's difficult to mask reason 17 million if you've
  only got a 32 bit word to use :-(</li>
<li> Am considering making the jfplib functions into a seperate area each - the
  overheads will be minimal and non-existant when linked, but <i>only</i> the
  required routines will be linked and link can ditch those we don't want.</li>
</ul>
</version>


<version number='2.43ß'>
<ul>
<li> Added &gt; macro command to embed function name before routine</li>
<li> <code>#CodePrefix bool</code> will modify this variable.</li>
<li> <code>bool</code> is now allowed to be <code>=file</code> which evaluates to TRUE if the file
  exists but is empty, and the boolean value of the contents of that file
  otherwise. The latter form is prefered.</li>
<li> Matthew Godbolt's main routine included in the jfplib library,
  SkipWhitespace and SkipNonWhitespace added to string.j, puts (writes a
  string), putnl (new line), updated headers.</li>
</ul>
</version>


<version number='2.41ß'>
<ul>
<li> Fixed bug in Event handler code (DON'T use workspace in events prior to this
  version :-( )</li>
<li> Added LO and HS to the list of conditionals accepted.</li>
</ul>
</version>


<version number='2.40ß'>Changes in 2.40ß over 2.33
<ul>
<li> Macros are slightly more stable - still not brilliant though.</li>
<li> AOF compilation now possible - again, not brilliant, but it works !</li>
<li> REM's now optimised; should cut quite a size off debugging code.</li>
<li> Minor modifications to allow tabs - not complete but getting there.</li>
<li> Error handling slightly improved - now allows errors returned using ABEX.</li>
</ul>
</version>
</version-table>

<h3>JFPatch back end</h3>

<version-table>
<version number='2.00' date='25 Feb 1995'>no application making</version>
<version number='2.02' date='18 Mar 1995'>application making added</version>
<version number='2.03' date='03 May 1995'>internal version numbering</version>
<version number='2.04' date='06 May 1995'>bug fix for stamping</version>
<version number='2.05' date='11 Jun 1995'>Workspace added; Long MOV; Local labels</version>
<version number='2.06' date='22 Jun 1995'>VDUStream forcing</version>
<version number='2.07' date='20 Jul 1995'>XSWI and XBL added</version>
<version number='2.08' date='09 Aug 1995'>Flag setting added</version>
<version number='2.09' date='10 Aug 1995'>NOP instructiXon added</version>
<version number='2.10' date='18 Aug 1995'>; comments remove :'s</version>
<version number='2.11' date='18 Aug 1995'>LADD instruction added</version>
<version number='2.12' date='20 Aug 1995'>MODE instruction added</version>
<version number='2.13' date='30 Aug 1995'>EXAMINE post assembly added</version>
<version number='2.14' date='02 Sep 1995'>CAPTURE post assembly added</version>
<version number='2.15' date='05 Sep 1995'>XLDMFD added for errors</version>
<version number='2.16' date='05 Sep 1995'>Library file reorganisation</version>
<version number='2.17' date='08 Sep 1995'>-ve LMOVs implemented</version>
<version number='2.18' date='29 Dec 1995'>SWAP instruction added</version>
<version number='2.19' date='28 Jan 1996'>Tabs in source file added</version>
<version number='2.20' date='19 Feb 1996'>includes and Compile_A added</version>
<version number='2.21' date='14 Apr 1996'>Compile_A removed to allow vague Make support</version>
<version number='2.22' date='15 Apr 1996'>Throwback support added</version>
<version number='2.23' date='09 May 1996'>Damned tiny bug fixed !</version>
<version number='2.24' date='22 May 1996'>Fixed naff handling of TB</version>
<version number='2.25' date='22 May 1996'>Fixed no DDEUtils bug</version>
<version number='2.26' date='28 May 1996'>Added macro support</version>
<version number='2.27' date='25 Jul 1996'>Added hourglass option</version>
<version number='2.28' date='30 Oct 1996'>Added export of locals</version>
<version number='2.29' date='14 Nov 1996'>Modified Conditionals for 3.1</version>
<version number='2.30' date='21 Dec 1996'>Directory structure changed</version>
<version number='2.31' date='19 Jan 1997'>fixed REM &amp;, added OS_NewLine!</version>
<version number='2.32' date='22 Jan 1997'>^ and # in XSWI supported</version>
<version number='2.33' date='05 Feb 1997'>Added E REM message</version>
<version number='2.34' date='06 Mar 1997'>PROCGetRegs 'r' bug fixed !</version>
<version number='2.35' date='08 Mar 1997'>version$ added to code</version>
<version number='2.36' date='09 Mar 1997'>FNmess improved</version>
<version number='2.37' date='08 Apr 1997'>;'s for comments in Pre/Post</version>
<version number='2.38' date='08 Apr 1997'>AOF support</version>
<version number='2.39' date='09 Apr 1997'>Pre support (constants)</version>
<version number='2.40' date='09 Apr 1997'>XBL/XSWI supports apcs</version>
<version number='2.41' date='25 Apr 1997'>Cond Set fixed</version>
<version number='2.42' date='29 Apr 1997'>&gt; macro for code prefixes</version>
<version number='2.43' date='16 May 1997'>&gt; is a function, new bool</version>
<version number='2.44' date='28 May 1997'>AOFModule header allows AOF</version>
<version number='2.45' date='29 May 1997'>Includes work inline</version>
<version number='2.46' date='11 Aug 1997'>$$ now translates to $</version>
<version number='2.47' date='09 Sep 1997'>REM's now use stack as ws</version>
<version number='2.48' date='26 Sep 1997'>AOF Debug support</version>
<version number='2.49' date='22 Oct 1997'>Many module changes</version>
<version number='2.50' date='15 Nov 1997'>AOF module filter/wimpswis fix</version>
<version number='2.51' date='18 Nov 1997'>Output buffering added</version>
<version number='2.52' date='05 Dec 1997'>ERR changed and REMF[P] added</version>
<version number='2.53' date='26 Dec 1997'>Fixed bugs in REM, Resources, Workspace changes, PostFilter improvements, optimisations for modules, ImageFS and FS blocks, Module help improved.</version>
<version number='2.54' date='07 Apr 1998'>Service entry fixed, Code-in fixed now. Other things.</version>
<version number='2.55' date='09 Apr 1999'>JB's modifications added</version>
<version number='2.56' date='02 Mar 2020'>Added ClipboardHolder operation</version>
</version-table>

<h3>Module generation</h3>
<version-table>
<version number='2.00' date='11 Jun 1995'></version>
<version number='2.01' date='20 Jun 1995'></version>
<version number='2.02' date='22 Jun 1995'></version>
<version number='2.03' date='08 Aug 1995'></version>
<version number='2.04' date='26 Aug 1995'></version>
<version number='2.05' date='05 Nov 1996'>Services added</version>
<version number='2.06' date='21 Dec 1996'>Services moved into Resources</version>
<version number='2.07' date='05 Feb 1997'>Events and Vectors added</version>
<version number='2.08' date='09 Mar 1997'>Extra info added</version>
<version number='2.09' date='08 Apr 1997'>AOF compliant code added</version>
<version number='2.10' date='26 Apr 1997'>Event code was completely buggered</version>
<version number='2.11' date='28 May 1997'>AOF imports for header added</version>
<version number='2.12' date='09 Sep 1997'>WimpSWIve post trap code fixed</version>
<version number='2.13' date='22 Oct 1997'>Messages files</version>
<version number='2.14' date='15 Nov 1997'>SWI Pre/Post, bug fixes for WimpSWI/Filter</version>
<version number='2.15' date='15 Nov 1997'>Dictionary tokenisation added</version>
<version number='2.16' date='14 Dec 1997'>Messages file fix, resource file blocks</version>
<version number='2.17' date='15 Dec 1997'>Filter 'Code' now allows reasons</version>
<version number='2.18' date='16 Dec 1997'>ImageFS support added</version>
<version number='2.19' date='30 Mar 1998'>Service handler code improved</version>
<version number='2.20' date='31 Mar 1998'>Ursula style service table</version>
<version number='2.21' date='01 Apr 1998'>Module initialisation error handling improved</version>
<version number='2.22' date='23 Apr 1998'>Wimp poll reason codes moved to file, new filter system, aof startcode, init, final, service and swihandler entries fixed.</version>
<version number='2.23' date='27 Apr 1998'>WimpSWIve AOF code fixed, new filter system AOF code fixed</version>
<version number='2.24' date='14 Jul 1998'>Rect, PostRect and PostIcon filters added.</version>
<version number='2.25' date='05 Sep 1998'>Some ADRs changed to LADRs in initialisation code (JB)</version>
<version number='2.26' date='09 Jun 2000'>Removed the dictionary encoding as this changed between OS versions.</version>
<version number='2.27' date='13 Feb 2001'>Added fast service reject code</version>
<version number='2.28' date='13 Feb 2001'>Added 'lightning fast service' code</version>
<version number='2.29' date='27 Feb 2001'>Can explicitly set version with module_version$ (and date with module_date$)</version>
<version number='2.30' date='16 Mar 2001'>WimpSWIve registration now uses multiple instructions (BASIC problem ?)</version>
<version number='2.31' date='24 May 2001'>Service handler code completely re-written to cope correctly with high-service numbers. Totally removed code for encoding using dictionary</version>
<version number='2.32' date='24 May 2001'>Added support for 'duplicate service handlers' which may help when using auto-added handlers</version>
</version-table>

<h3>Workspace</h3>
<version-table>
<version number='1.01' date='18 Aug 1995'></version>
<version number='1.02' date='13 Jan 1996'>| Union loop id added</version>
<version number='1.03' date='30 Oct 1996'>Fix for MapWS returning default</version>
<version number='1.04' date='14 Dec 1997'>`len_<i>name</i> in ADRW works</version>
</version-table>


<h3>AOF generation</h3>
<version-table>
<version number='1.00' date='08 Apr 1996'>started, simple aof support</version>
<version number='1.01' date='09 Apr 1997'>fixed module code and swstk</version>
<version number='1.02' date='09 Apr 1997'>EQUD works, Pre added</version>
<version number='1.03' date='16 May 1997'>multiple areas work</version>
<version number='1.04' date='28 May 1997'>functions to do jumps/offsets</version>
<version number='1.05' date='26 Sep 1997'>entry points</version>
<version number='1.06' date='26 Sep 1997'>debug data</version>
<version number='1.07' date='22 Jul 1998'>area data now works</version>
<version number='1.07' date='15 Apr 1998'>ADR (JB)</version>
<version number='1.08' date='06 Nov 1998'>LDR, conditional ADR (JB)</version>
<version number='1.09' date='02 Feb 2003'>Added specifier for 32Bit areas</version>
</version-table>

<h3>Macros</h3>
<version-table>
<version number='1.00' date='28 May 1996'>Base macros</version>
<version number='1.01' date='28 May 1996'>Embedded macros (ie one calls another)</version>
<version number='1.02' date='08 Jan 1998'>Constants (JB)</version>
</version-table>


</section>

    </page>
</body>
</html>
