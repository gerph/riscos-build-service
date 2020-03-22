<!DOCTYPE html>
<html>
<html-header title='Colouring Example' codecolouring>
<script type='text/javascript'>
<!--
    loaded = false;
    function onload() {
        if (loaded)
            return;
        loaded = true;
        if (1) {
            setup_colouring({autosize: false, linenumbers: true, scroll: true});
        }
        else
        {
            areas = document.getElementsByClassName('source-code');
            for (i = 0; i < areas.length; i++) {
                var textarea = areas[i];
                var options = {
                        lineNumbers: true,
                        mode: 'text/x-jfpatch',
                        theme: 'liquibyte',
                        lineWrapping: true,
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
                var cm = CodeMirror.fromTextArea(textarea, options);
                var widget = document.getElementById('HELLO');
                cm.addLineWidget(3, widget);
                //alert(cm.getValue());
            }
        };
    }
    -->
</script>
</html-header>
<body onload='onload();'>
    <page section='Colouring Example'>
    <textarea class='source-code'>
In   -
Out  djf
Type Utility
Ver  1.02m

Pre

 REM LIBRARY "VersionBas":PROCinit_version
 REM module_version$=version_major$
 REM module_date$=version_date$

 module_version$="0.00"
 module_date$="Today"

End Pre

{
    A DJF tune player!
}

.playtune
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   MOV     r5,r1                         ; r5-&gt; command string
   XSWI    "Sound_QInit"                 ; reinit the sound system
   XSWI    "Sound_QTempo",&amp;800           ; set the tempo I want
   LDRB    r0,[r5]                       ; read first byte
   CMP     r0,#32                        ; is it ctrl ?
   ADRLT   r5,$`toplay                   ; if so, play what I want to play
   MOV     r8,#0                         ; r8 = 0 (beat to play on)

; the loop
$loop
   LDRB    r2,[r5],#1                    ; read a byte (pitch)
   CMP     r2,#32                        ; is it a terminator ?
   BLT     $exit                         ; if so, return
; find what pitch this is
   ADR     r4,$`notenums-1               ; the notes DB (less one)
   ADR     r3,$`notenums-37              ; the notes DB (again)
$getpitch
   LDRB    r1,[r4,#1]!                   ; read a byte
   TEQ     r1,#0                         ; is it not found ?
   TEQNE   r1,r2                         ; if not, is it the number we want ?
   BNE     $getpitch                     ; go around again if not...
   SUB     r4,r4,r3                      ; find the index
   ADD     r3,r4,r4,LSL #2               ; r3 = index * 5
   MOV     r3,r3,LSL #2                  ; r3 = (index * 5) * 4
   ADD     r3,r3,r3,LSL #4               ; r3 += (index * 5) * 16
   ADD     r3,r3,r4                      ; add original number (*&amp;155)
; now read the length of the note
   LDRB    r4,[r5],#1                    ; read a byte (length)
   CMP     r4,#32                        ; is it a terminator ?
   BLT     $exit                         ; if so, jump out
   SUBS    r4,r4,#48                     ; length
   BMI     $loop                         ; Dunno what that was, skip it
   ADDEQ   r4,r4,#ASC("G")-48            ; make it equivilent from G
   CMP     r4,#ASC("A")-48               ; is it A or higher ?
   SUBGE   r4,r4,#ASC("A")-48-10         ; make it 10 and higher
;    REM     "Play %&amp;3 for %r4%C"
;    REM     "%&amp;2,%&amp;3"
   ADD     r7,r4,r4,LSL #2               ; (beats) r7 = r3 * 5
;    REM     "%r4 = %r8"
   MOV     r4,r4,LSL #1                  ; double length
   SUB     r4,r4,#1                      ; take one
   MOV     r1,#0                         ; r1 = 0 (Sound_ControlPacked)
   TEQ     r2,#ASC("_")                  ; is it _ (silence) ?
   BEQ     $playnowt                     ; if so, skip 'play'
   LDR     r2,$ampchan                   ; if not, r2 = amplitide and channel
   ADD     r3,r3,r4,LSL #16              ; r3 = pitch + duration * &amp;10000
$tryagain
   MOV     r0,r8                         ; r0 = beat number
;    REM     "%&amp;0,%&amp;2,%&amp;3"
   SWI     "Sound_QSchedule"
   TEQ     r0,#0                         ; did we succeed ?
   BLT     $tryagain                     ; nope, so try once more
$playnowt
   ADD     r8,r8,r7                      ; beat number += beats
   B       $loop

$exit
   LDMFD   (sp)!,{r0-r5,pc}              ; if so, return

$ampchan
   EQUD    &amp;FFF10000+&amp;0001               ; volume -15, channel 1
$`notenums
   EQUZ    "azsxcfvgbnjmk,l.q2w3er5t6y7ui9o0p"

$`toplay
   EQUZ    ".3w6e2w2.226,6q6w2q2,2.3,2m4"
   ALIGN

#Post
REM  #Run &lt;CODE&gt;
</textarea>
<hr/>
    <textarea class='source-code'>
In   -
Out  DDEUtilsJF
Type Module

Define Workspace
 Name      module
 Default   r12
  `prefixlist    !   linked list of prefixes
  `clsize        !   command line size
  `clptr         !   pointer to command line buffer
  `throwhand     !   throwback task handle (or 0 to broadcast)
  `msgblk        !   workspace for message block

 Name      prefix
 Default   r5
  `next          !   the next entry
  `last          !   make it doubly linked for easy !
  `domain        !   the domain it's in
  `prefix        !   pointer to the prefix string
End Workspace

Define Module
 Name      DDEUtils
 Author    Justin Fletcher
 Commands
  Name     Prefix
  Code     com_prefix
  Max      1
  Min      0
  Help     ...
           *Prefix sets the current directory for the current context. Used
           with no parameters it resets the current directory to the global
           value.
  Syntax   Syntax: *Prefix [&lt;directory&gt;]

  Name     Prefixes
  Code     com_prefixes
  Help     *Prefixes lists prefixes currently defined.
 End commands
 Vectors
  FileV      filev
  GBPBV      gbpbv
  FindV      findv
  FSControlV fscontrolv
 End Vectors
 Services
  WimpCloseDown  wimp_closedown
 End Services
 SWIs
  Prefix     DDEUtils
  Base       &amp;42580
   0         Prefix    swi_prefix
   1         SetCLSize swi_setclsize
   2         SetCL     swi_setcl
   3         GetCLSize swi_getclsize
   4         GetCl     swi_getcl
   5         ThrowbackRegister   swi_throwbackregister
   6         ThrowbackUnRegister swi_throwbackunregister
   7         ThrowbackStart      swi_throwbackstart
   8         ThrowbackSend       swi_throwbacksend
   9         ThrowbackEnd        swi_throwbackend
 End SWIs
 Workspace *`len_module
 Init      init
 Final     final
End Module

Pre
 LIBRARY "VersionBas":PROCinit_version
 module_version$=version_major$
 module_date$=version_date$
End Pre

#Rem off
; *******************************************************************
; Subroutine:   init
; Description:  Initialise program, claiming spaces we need
; Parameters:   r12-&gt; workspace
; Returns:      none
; *******************************************************************
&gt;init
   STMFD   (sp)!,{r0-r2,link}            ; Stack registers
   XBL     claim,256                     ; claim space for message blk
   STRW    r0,`msgblk                    ; store in workspace
   LDMFD   (sp)!,{r0-r2,pc}              ; Return from call

; *******************************************************************
; Subroutine:   final
; Description:  Finalise program, releasing spaces we claimed
; Parameters:   r12-&gt; workspace
; Returns:      none
; *******************************************************************
&gt;final
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   LDRW    r0,`msgblk                    ; message workspace
   BL      release                       ; free it
   LDRW    r0,`clptr                     ; read command line pointer
   CMP     r0,#0                         ; did we claim some room ?
   BLNE    release                       ; if so, free it
   LDRW    r5,`prefixlist                ; read head of list
$loop
   CMP     r5,#0                         ; are we done ?
   BEQ     $done                         ; if so, jump out
   LDRW    r1,`next                      ; read 'next' pointer
   LDRW    r0,`prefix                    ; read prefix pointer
   BL      release                       ; release prefix
   XBL     release,r5                    ; release block itself
   MOV     r5,r1                         ; this=next
   B       $loop                         ; go around again
$done
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;findv
   B       replacevars                   ; OS_Find
&gt;fscontrolv
   TEQ     r0,#2                         ; is it 2 (New app starting) ?
   TEQNE   r0,#4                         ; or 4 (*Run file) ?
   MOVEQ   pc,link                       ; return if so
   TEQ     r0,#0                         ; is it set csd ?
   ORREQ   r12,r12,#1                    ; if so, mark us as being 'special'
   B       replacevars                   ; call replacement OS_FSControl

&gt;gbpbv
   CMP     r0,#5                         ; if it &lt;5 ? (std gbpb calls)
   MOVLTS  pc,link                       ; if so, return
   B       replacevars                   ; otherwise, replace OS_GBPB

&gt;filev
   B       replacevars                   ; OS_File

; *******************************************************************
; Subroutine:   wimp_closedown
; Description:  A domain is exiting, we must remove it's workspace
; Parameters:   r0 = 0 if it really is closing down
; Returns:      none
; *******************************************************************
&gt;wimp_closedown
   TEQ     r0,#0                         ; is it a 'real' closedown ?
   MOVNES  pc,link                       ; return if not
   STMFD   (sp)!,{r0,link}               ; Stack registers
   XBL     swi_prefix,0                  ; unset the prefix if one
   LDMFD   (sp)!,{r0,pc}^                ; Return from call

; *******************************************************************
; Subroutine:   swi_setclsize
; Description:  Set the Command Line length
; Parameters:   r0 = length to use
; Returns:      r0-&gt; destination block
; *******************************************************************
&gt;swi_setclsize
   STMFD   (sp)!,{r1-r5,link}            ; Stack registers
   MOV     r3,r0                         ; r1=length needed
   REM     "Set CL Size %r3"
   LDRW    r0,`clptr                     ; have we got an extended buffer ?
   TEQ     r0,#0                         ; is there one ?
   BLNE    release                       ; if so, release it
   XSWI    "XOS_Module",6                ; claim space
   MOVVS   r3,#0                         ; if failed, size = 0
   MOVVS   r2,#0                         ; and pointer = 0
   STRW    r3,`clsize                    ; store the size in ws
   STRW    r2,`clptr                     ; store the pointer in workspace
   MOVVC   r0,r2                         ; r0-&gt; block
   LDMFD   (sp)!,{r1-r5,pc}              ; Return from call

; *******************************************************************
; Subroutine:   swi_setcl
; Description:  Sets the command line string
; Parameters:   r0-&gt; string
; Returns:      none
; *******************************************************************
&gt;swi_setcl
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
; check clptr valid
   LDRW    r3,`clptr                     ; read the pointer
   TEQ     r3,#0                         ; is it set ?
   BEQ     $notset                       ; if not, jump out
; check cl short enough
;    BL      strlen                        ; find it's length
   LDRW    r2,`clsize                    ; read buffer length
;    CMP     r1,r2                         ; is it too small ?
;    BGE     $tooshort                     ; buffer not large enough
; copy string (from r0, to r3, length=r3)
$copy
   SUBS    r2,r2,#1                      ; decrement length
   BMI     $done                         ; if 0, then done
   LDRB    r4,[r0],#1                    ; read and inc
   CMP     r4,#32                        ; is it &lt; ' ' ?
   MOVLT   r4,#0                         ; if so, use 0 to terminate
   STRB    r4,[r3],#1                    ; write and inc
   REM     "Read %r4 (%a4)"
   B       $copy                         ; go for more
$done

   LDRW    r3,`clptr                     ; read the pointer
   REM     "Set CL '%$3'"

   LDMFD   (sp)!,{r0-r5,link}            ; restore regs
   BICS    pc,link,#vbit                 ; return with V clear

$notset
$tooshort
   LDMFD   (sp)!,{r0-r5,link}            ; restore registers
   ADR     r0,$`error                    ; read error
   ORRS    pc,link,#vbit                 ; return with V set
$`error
   EQUD    &amp;20601
   EQUZA   "DDEUtils buffer not set or too short"

; *******************************************************************
; Subroutine:   swi_getclsize
; Description:  Read the command line size
; Parameters:   none
; Returns:      r0 = length of command line
; *******************************************************************
&gt;swi_getclsize
   LDRW    r0,`clsize                    ; read it
   MOV     pc,link                       ; return

; *******************************************************************
; Subroutine:   swi_getcl
; Description:  Read the command line
; Parameters:   r0-&gt; buffer to copy into
; Returns:      none
; *******************************************************************
&gt;swi_getcl
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
; check clptr valid
   LDRW    r3,`clptr                     ; read the pointer
   TEQ     r3,#0                         ; is it set ?
   BEQ     $notset                       ; if not, jump out
   REM     "Get CL '%$3'"
; now copy the string
   LDRW    r2,`clsize                    ; read length of cli buffer
$copy
   SUBS    r2,r2,#1                      ; decrement length to read
   BMI     $done
   LDRB    r4,[r3],#1                    ; read and inc
   CMP     r4,#32                        ; is it &lt; ' ' ?
   MOVLT   r4,#0                         ; if so, use 0 to terminate
   STRB    r4,[r0],#1                    ; write and inc
   REM     "Read %r4 (%a4)"
   B       $copy
$done
   LDRW    r0,`clptr                     ; read the pointer
   BL      release                       ; release space
   MOV     r0,#0                         ; 0 for length
   STRW    r0,`clptr                     ; zero pointer
   STRW    r0,`clsize                    ; zero size
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

$notset
   LDMFD   (sp)!,{r0-r5,link}            ; restore registers
   ADR     r0,$`error                    ; read error
   ORRS    pc,link,#vbit                 ; return with V set
$`error
   EQUD    &amp;20601
   EQUZA   "DDEUtils buffer not set"

; *******************************************************************
; Subroutine:   swi_prefix
; Description:  Sets the prefix for the current directory (or unsets
;               it)
; Parameters:   r0-&gt; prefix name, or "" or 0 to unset
; Returns:      with error if can't do it
; *******************************************************************
&gt;swi_prefix
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   MOV     r3,r0                         ; r3-&gt; string
   CMP     r0,#0                         ; is r0 = 0 ?
   LDRNEB  r4,[r0]                       ; if not read first byte of r0
   CMPNE   r4,#32                        ; is it &lt;32 ?
   MOVLE   r4,#0                         ; if either, no args
   MOVGT   r4,#1                         ; else, r4 = 1 arg
; r3-&gt; args, r4 = 0 for no args (unset), 1 for 1 arg (set)
   REM     "SWI_Prefix %$3 (%r4)"
   LMOV    r0,#&amp;FF8                      ; address of domain Id
   LDR     r1,[r0]                       ; read our domain id
   LDRW    r5,`prefixlist                ; read list
   RAS     r5,r1,#`domain                ; create the list entry
   CMP     r5,#0                         ; is it valid ?
   BEQ     $createanew                   ; nope, so we create one specially
   LDRW    r0,`prefix                    ; re-read the prefix
   BL      release                       ; free the string
   B       $created                      ; now let's deal with it...

$createanew
   XBL     claim,`len_prefix             ; claim space for the block
   LDRW    r5,`prefixlist                ; read top of prefix list
   CMP     r5,#0                         ; is it 'valid' ?
   STRWNE  r0,`last                      ; store us as their 'last' pointer
   STRW    r0,`prefixlist                ; we are the head of the prefix list
   STR     r5,[r0,#`next]                ; link the list to us
   MOV     r5,r0                         ; r5-&gt; block
   MOV     r0,#0                         ; null the 'last' pointer
   STRW    r0,`last                      ; store it
$created
;    REM     "Created entry, r5-&gt;%&amp;5"
   CMP     r4,#0                         ; did they give any params ?
   BEQ     $deleteentry                  ; nope, so delete prefix
   BL      docanonicalisation            ; canonicalise it
   STRW    r0,`prefix                    ; store our prefix
   STRW    r1,`domain                    ; store our domainid
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

$deleteentry
   LDRW    r1,`last                      ; read 'last' pointer
   LDRW    r2,`next                      ; read 'next' pointer
   CMP     r1,#0                         ; is 'last' 0 ? (at head)
   STRWEQ  r2,`prefixlist                ; if so, store next as 'head'
   STRNE   r2,[r1,#`next]                ; otherwise, link it to us
   CMP     r2,#0                         ; is 'next' 0 ? (at tail)
   STRNE   r1,[r2,#`last]                ; if not, store our 'back' link
   XBL     release,r5                    ; free 'us'
;    REM     "Freed"

   LDMFD  (sp)!,{r0-r5,pc}               ; Return from call

; *******************************************************************
; Subroutine:   swi_throwbackregister
; Description:  Register a task for handling all throwback
; Parameters:   R0 = task handle
; Returns:      none
; *******************************************************************
&gt;swi_throwbackregister
   STRW    r0,`throwhand                 ; store the handle
   MOV     pc,link                       ; return nicely
&gt;swi_throwbackunregister
   STMFD   (sp)!,{r1,link}               ; Stack registers
   LDRW    r1,`throwhand                 ; read old handle
   CMP     r0,r1                         ; was it them who we knew ?
   MOVEQ   r1,#0                         ; if so, we need to null it
   STRWEQ  r1,`throwhand                 ;        and store it
   LDMFD   (sp)!,{r1,pc}                 ; Return from call

; *******************************************************************
; Subroutine:   swi_throwbackstart
; Description:  Start the throwback session
; Parameters:   none
; Returns:      none
; *******************************************************************
&gt;swi_throwbackstart
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   SUB     sp,sp,#20                     ; take off 20 from stack
   MOV     r0,#20                        ; length of message (0)
   MOV     r1,#0                         ; destination (4)
   MOV     r2,#0                         ; their ref (8)
   MOV     r3,#0                         ; our ref (12)
   LMOV    r4,#&amp;42580                    ; throwback start message
   STMIA   (sp),{r0-r4}                  ; place 'em in buffer
   LDRW    r2,`throwhand                 ; read the throwback handle
   XSWI    "XWimp_SendMessage",17,r13    ; send message
   ADD     sp,sp,#20                     ; add it back on
   LDMVCFD (sp)!,{r0-r5,pc}              ; Return from call
   LDMFD   (sp)!,{r0-r5,link}            ; restore registers
   ADR     r0,$`error                    ; read error
   ORRS    pc,link,#vbit                 ; return with V set
$`error
   EQUD    0
   EQUZA   "Throwback cannot be used outside the desktop"

; *******************************************************************
; Subroutine:   swi_throwbacksend
; Description:  Send a throwback message at the task
; Parameters:   r0 = reason (0=processing, 1=error, 2=info)
;               r2 = filename
;               r3 = line number
;               r4 = severity (0-2)
;               r5 = message
; Returns:      none
; *******************************************************************
&gt;swi_throwbacksend
   STMFD   (sp)!,{r0-r6,link}            ; Stack registers
   MOV     r6,r0                         ; r6 = reason (0, 1, 2)
   BL      canonicalise                  ; canonicalise and copy
   XBL     strlen,r2                     ; find length of string
   ADD     r1,r1,#4+20                   ; add on 4+20 (for block)
   BIC     r1,r1,#3                      ; word align
; build message block
   REM     "Reason = %r6, file = %$2"
   LDRW    r5,`msgblk                    ; address of message block
   STR     r1,[r5,#0]                    ; store length of block
   ADD     r1,r5,#20                     ; r1-&gt; filename dest
   BL      strcpy                        ; copy the string there
   XBL     release,r2                    ; release the canonicalise space
   MOV     r0,#0                         ; 0's for the ref's
   STR     r0,[r5,#8]                    ; store theirref
   STR     r0,[r5,#12]                   ; store ourref
   LMOV    r0,#&amp;42580                    ; base message number
   TEQ     r6,#0                         ; are we 'processing' ?
   ADDEQ   r0,r0,#1                      ; if so, make &amp;42581
   TEQ     r6,#1                         ; are we 'erroring' ?
   ADDEQ   r0,r0,#2                      ; if so, make &amp;42582
   TEQ     r6,#2                         ; are we 'infoing' ?
   ADDEQ   r0,r0,#5                      ; if so, make &amp;45585
   STR     r0,[r5,#16]                   ; store it in block
; now send it (file message)
   LDRW    r2,`throwhand                 ; read throwback handler
   XSWI    "XWimp_SendMessage",17,r5     ; send it
   BVC     $noerr
   REM     "%E0"                         ; error!
$noerr
   TEQ     r6,#0                         ; was it 'processing' ?
   BEQ     $done                         ; yep, so we're done !
; build details block
   LDR     r0,[r5,#16]                   ; read message number
   ADD     r0,r0,#1                      ; add one to it (for details)
   STR     r0,[r5,#16]                   ; and store back
   STR     r3,[r5,#20]                   ; store line number
   STR     r4,[r5,#24]                   ; store severity
   LDR     r0,[sp,#4*5]                  ; re-read message pointer
   BL      strlen                        ; find it's length
   CMP     r1,#227                       ; is it &gt;227 ?
   MOVGE   r1,#227                       ; if so, reduce to 227
   ADDLT   r1,r1,#1                      ; if not, bump up by one
   ADD     r3,r1,#4+28                   ; add four to it (and block offset)
   BIC     r3,r3,#3                      ; word align
   STR     r3,[r5]                       ; store as block len
   MOV     r3,#0                         ; zero terminate dest
   ADD     r4,r5,#28                     ; r4-&gt; message dest
   STRB    r3,[r4,r1]                    ; store as terminator
$msgloop
   SUBS    r1,r1,#1                      ; decrement counter
   BMI     $donemsg                      ; if -ve, we're done
   LDRB    r3,[r0,r1]                    ; read byte
   STRB    r3,[r4,r1]                    ; store byte
   B       $msgloop                      ; and go for more
$donemsg
; now send the details
   XSWI    "XWimp_SendMessage",17,r5     ; send it
$done
   LDMFD   (sp)!,{r0-r6,pc}              ; Return from call

; *******************************************************************
; Subroutine:   canonicalise
; Description:  Canonicalise a path
; Parameters:   r2-&gt; filename
; Returns:      r2-&gt; canonical filename, in memory buffer
; *******************************************************************
&gt;canonicalise
   STMFD   (sp)!,{r0-r1,r3-r5,link}      ; Stack registers
   MOV     r1,r2                         ; r1-&gt; filename to convert
   XSWI    "XOS_FSControl",37,,0,0,0,0   ; find length of filename
   RSB     r5,r5,#0                      ; r5=length needed
   ADD     r5,r5,#1                      ; add on one for terminator
   XBL     claim,r5                      ; claim that much
   MOV     r2,r0                         ; r2-&gt; buffer
   XSWI    "XOS_FSControl",37,,,0,0      ; decode it to buffer
   LDMFD   (sp)!,{r0-r1,r3-r5,pc}        ; Return from call

; *******************************************************************
; Subroutine:   swi_throwbackend
; Description:  End a throwback session
; Parameters:   none
; Returns:      none
; *******************************************************************
&gt;swi_throwbackend
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   SUB     sp,sp,#20                     ; take off 20 from stack
   MOV     r0,#16                        ; length of message (0)
   MOV     r1,#0                         ; destination (4)
   MOV     r2,#0                         ; their ref (8)
   MOV     r3,#0                         ; our ref (12)
   LMOV    r4,#&amp;42584                    ; throwback end message
   STMIA   (sp),{r0-r4}                  ; place 'em in buffer
   LDRW    r2,`throwhand                 ; read the throwback handle
   XSWI    "XWimp_SendMessage",17,sp     ; send message
   ADD     sp,sp,#20                     ; add it back on
   LDMFD   (sp)!,{r0-r5,pc}^             ; Return from call

; *******************************************************************
; Subroutine:   com_prefixes
; Description:  Display the prefixes currently set
; Parameters:   r12-&gt; private word (not = private word!)
; Returns:      none
; *******************************************************************
&gt;com_prefixes
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   LDR     r12,[r12]                     ; read our workspace
   LDRW    r5,`prefixlist                ; read head of list
$loop
   CMP     r5,#0                         ; done ?
   BEQ     $done
   LDRW    r0,`next                      ; read next
   LDRW    r1,`last                      ; read last
   LDRW    r2,`domain                    ; read domainid
   LDRW    r3,`prefix                    ; read prefix
   LDRB    r4,[r3],#4                    ; r4 = length of 'fs'
   ADD     r4,r4,r3                      ; add on to base
   ADD     r4,r4,#1                      ; skip terminator
   REMP    "This=%&amp;5, Next=%&amp;0, Last=%&amp;1"
   REMP    "Domain=%&amp;2, FS=%$3, CSD=%$4"
   MOV     r5,r0                         ; this=next
   B       $loop                         ; and go some more
$done
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

; *******************************************************************
; Subroutine:   com_prefix
; Description:  Sets the current prefix
; Parameters:   r0 = cli
; Returns:      none
; *******************************************************************
&gt;com_prefix
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   LDR     r12,[r12]                     ; read our workspace
   BL      swi_prefix                    ; process it (quickly?)
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

; *******************************************************************
; Subroutine:   docanonicalisation
; Description:  Canonicalise, claim space for, and return result in
;               r0
; Parameters:   r3-&gt; thing to canonicalise
; Returns:      r0-&gt; new strdup'd string
; *******************************************************************
&gt;docanonicalisation
   STMFD   (sp)!,{r1-r5,link}            ; Stack registers
   XBL     strdup,r3                     ; copy the string
   MOV     r1,r0                         ; r1-&gt; copied string
$rdloop
   LDRB    r3,[r0],#1                    ; read and inc
   CMP     r3,#32                        ; is that it ?
   BGT     $rdloop                       ; if not, keep going
   LDRB    r3,[r0,#-2]                   ; read the last but one char ?
   CMP     r3,#ASC(".")                  ; is it a '.' ?
   MOVEQ   r3,#0                         ; if so, remove it
   STREQB  r3,[r0,#-2]                   ; store over it
   XSWI    "XOS_FSControl",37,,0,0,0,0   ; find it's length
   RSB     r5,r5,#0                      ; r5=length needed
   ADD     r5,r5,#1                      ; add on one for terminator
   ADD     r0,r5,#4                      ; add on 'fs len space'
   XBL     claim                         ; claim that much
;    TEQ     r0,#0                         ; check enough space (N/A)
   ADD     r2,r0,#4                      ; r2-&gt; buffer for result
   XSWI    "XOS_FSControl",37,,,0,0      ; decode it to buffer
   XBL     release,r1                    ; free the strdup'd name
   REM     "Canonicalised to %$2, returned r5=%r5"
   MOV     r1,#0                         ; 0 bytes into it
$findcolonloop
   LDRB    r0,[r2,r1]                    ; read a byte
   CMP     r0,#32                        ; is it 'term' ?
   MOVEQ   r1,#0                         ; if so, the string is 0 long
   BEQ     $found                        ; and pretend we found it
   CMP     r0,#ASC(":")                  ; is it a colon ?
   ADDNE   r1,r1,#1                      ; if not, next char
   BNE     $findcolonloop                ; and go around more
; r2-&gt; canonicalised name, r1 = offset of colon in string
$found
   MOV     r3,#0                         ; terminate at it
   STRB    r3,[r2,r1]                    ; store over the colon
   STRB    r1,[r2,#-4]!                  ; store the length and decrment
   ADD     r0,r2,r1                      ; r0-&gt; terminator
   ADD     r0,r0,#1                      ; r0-&gt; after terminator
   XBL     strlen                        ; find strlen
   STRB    r1,[r2,#1]                    ; store at offset 1
   MOV     r0,r2                         ; r0-&gt; block
   LDMFD   (sp)!,{r1-r5,pc}              ; Return from call

; *******************************************************************
; Subroutine:   replacevars
; Description:  Replaces FS$CurrentFS and FS$&lt;currentfs&gt;$csd for the
;               duration of the call, then restores them afterwards
; Parameters:   as vector
; Returns:      as vector, having postprocessed it
; *******************************************************************
&gt;replacevars
   STMFD   (sp)!,{r0-r10,link}           ; Stack registers
; check 'special' markers
   TST     r12,#3                        ; is b0 or b1 set in ws ?
   AND     r9,r12,#3                     ; r9='marker'
   BICNE   r12,r12,#3                    ; clear it if so

   LDRW    r10,`prefixlist               ; r10-&gt; our list
   LMOV    r0,#&amp;FF8                      ; address of domain Id
   LDR     r0,[r0]                       ; read our domain id
   RAS     r10,r0,#`domain               ; find if it's in the list
   TEQ     r10,#0                        ; did we find it

;    STRNE   r10,[r10,#`domain]            ; kill the next recurrance

$nothingdone
   LDMEQFD (sp)!,{r0-r10,pc}             ; nope, so return nicely
; find len of CurrentFilingSystem
   XSWI    "XOS_ReadVarVal",^$`fscsfs,-1,-1,0,0 ; find len of current fs
   TEQ     r2,#0                         ; was there a variable ?
   MOVEQ   r8,#0                         ; if none, no current fs
   BEQ     $gotoldfs
   RSB     r2,r2,#0                      ; r0=length to claim
   ADD     r2,r2,#1                      ; 1 more, to be sure !
   XBL     claim,r2                      ; claim it
   TEQ     r0,#0                         ; did it work ?
   BEQ     $nothingdone                  ; if not, we failed - abort !
   MOV     r8,r0                         ; r8-&gt; fs
; read CurrentFilingSystem
   XSWI    "XOS_ReadVarVal",^$`fscsfs,r8,,0,0 ; read current fs
   MOV     r0,#0
   STR     r0,[r8,r2]                    ; store terminator after string
$gotoldfs
   MOV     r0,#(fscsd_leftlen+fscsd_rightlen+1) ; base length of string
   LDR     r4,[r10,#`prefix]             ; read pointer to prefix
   LDRB    r4,[r4,#0]                    ; read length of FS
   ADD     r2,r4,#1                      ; add one for luck
   ADD     r0,r0,r2                      ; add on the number of bytes read
   BL      claim                         ; claim space for variable name
   TEQ     r0,#0                         ; did it fail ?
   BEQ     $nothingdone                  ; if so, panic !
   MOV     r6,r0                         ; r6-&gt; csd variable name
   MOV     r1,#fscsd_leftlen             ; r1 = len to copy
   ADR     r3,$`fscsd_left               ; address to copy from
$leftloop
   SUBS    r1,r1,#1                      ; go down by one
   BMI     $leftdone                     ; if -ve, we're done
   LDRB    r2,[r3,r1]                    ; read byte
   STRB    r2,[r6,r1]                    ; store in new buffer
   B       $leftloop                     ; and do again
; copied the left side
$leftdone
   LDR     r0,[r10,#`prefix]             ; read pointer to prefix data
   ADD     r0,r0,#4                      ; skip the fs len, r0-&gt; fs
   ADD     r1,r6,#fscsd_leftlen          ; add on leftlen (-&gt; fsname)
   XBL     strcpy,,r1                    ; copy it on
   ADD     r1,r1,r4                      ; add on fslen
   XBL     strcpy,^$`fscsd_right         ; and the right side
; read csd var len
   XSWI    "XOS_ReadVarVal",r6,-1,-1,0,0 ; find length of it's var
   TEQ     r2,#0                         ; was there a variable ?
   MOVEQ   r7,#0                         ; if none, no current directory
   BEQ     $gotblks
; now read val itself
   RSB     r2,r2,#0                      ; r0=length to claim
   ADD     r2,r2,#2                      ; 1 more, to be sure !
   XBL     claim,r2                      ; claim it
   TEQ     r0,#0                         ; did it work ?
   BEQ     $nothingdone                  ; if not, we failed - abort !
   MOV     r7,r0                         ; r7-&gt; fs value
   XSWI    "XOS_ReadVarVal",r6,r7,,0,0   ; read current fs
   MOV     r0,#0
   STRB    r0,[r7,r2]                    ; store terminator after string
$gotblks ; temporary until we're got it working
   REM     "FS was %$8"
   REM     "FSCSD Var = %$6"
   REM     "FSCSD = %$7"
; now to set the vars
   LDR     r5,[r10,#`prefix]             ; read pointer to prefix block
   LDRB    r2,[r5,#0]                    ; read length of FS
   ADD     r1,r5,#4                      ; r1-&gt; value to set
   REM     "Setting FS to %$1"
   XSWI    "XOS_SetVarVal",^$`fscsfs,,,0,0 ; set current fs
   LDRB    r2,[r5,#0]                    ; read length of FS
   ADD     r1,r5,r2                      ; r1-&gt; value to set
   ADD     r1,r1,#5                      ; skip the 'length' data
   LDRB    r2,[r5,#1]                    ; read length of csd
   REM     "Setting CSD to %$1"
   XSWI    "XOS_SetVarVal",r6,,,0,0      ; set csd
; now to pass on to original caller
   LDMFD   (sp)!,{r0-r5}                 ; restore 'normal' registers
   STMFD   (sp),{r6,r7,r8,r9}            ; stack 'our' registers (nowb)
   LDMFD   (sp),{r6-r10}                 ; re-read old registers
   SUB     sp,sp,#4*4                    ; move down to our bottom of stack
; on stack now, r6,r7,r8,r9,or6,or7,or8,or9,or10,return to address
   STMFD   (sp)!,{pc}                    ; store our pc so we know we return
   ADD     r12,sp,#4*10                  ; read return point
   LDMFD   r12,{pc}                      ; return there

; we drop to here on return
   NOP
   STMFD   (sp)!,{r0-r9,pc}              ; stack regs 0-8 and pc
   MOV     r0,pc                         ; r0=pc
   REM     "Called on exit"
   ADD     r5,sp,#4*11                   ; skip the registers we just stacked
   LDMIA   r5,{r6,r7,r8,r9}              ; re-read the regs we hung on to
; r6-&gt; csd var, r7-&gt; csd, r8-&gt; csfs, r9= 'special' marker
; first perform special functions
   TEQ     r9,#1                         ; is it 'set csd' ?
   BNE     $notspecial                   ; if not, skip this
   TST     r0,#vbit                      ; is v set (was there an error) ?
   BNE     $notspecial                   ; if error, abort
   XSWI    &amp;62580,^$`thisdir             ; call the swi marking new dir
$notspecial
; restore current filing system
   CMP     r8,#0                         ; is csfs 0 ?
   XBLNE   strlen,r8                     ; if not, read it's length
   MVNEQ   r2,#NOT -1                    ; if so, use -1 to delete
   MOVNE   r2,r1                         ; otherwise, r2=length
   REM     "Restoring FS %$8"
   XSWI    "XOS_SetVarVal",^$`fscsfs,r8,,0,0 ; set it (restore current fs)
; restore csd variable
   CMP     r7,#0                         ; is csd 0 ?
   XBLNE   strlen,r7                     ; if not, read it's length
   MVNEQ   r2,#NOT -1                    ; if so, use -1 to delete
   MOVNE   r2,r1                         ; otherwise, r2=length
   REM     "Restoring CSD %$7"
   XSWI    "XOS_SetVarVal",r6,r7,,0,0    ; set it (restore csd)
; release the space !
   CMP     r8,#0                         ; is r8 (fs) valid ?
   XBLNE   release,r8                    ; if so, release it
   XBL     release,r6                    ; release the csd var
   CMP     r7,#0                         ; is r7 (csd) valid ?
   XBLNE   release,r7                    ; if so, release it
; now return nicely
   REM     "Returning"
   LDMFD   (sp)!,{r0-r9,link}            ; restore registers
   ADD     sp,sp,#4*10                   ; add on the 9 regs to skip
   TST     link,#vbit                    ; was v set
   LDMFD   (sp)!,{link}                  ; re-read link
   ORRNES  pc,link,#vbit                 ; if so, return with vset
   BICEQS  pc,link,#vbit                 ; else, don't

$`thisdir
   EQUZA   "@"
$`fscsfs
%fscsd_leftlen=LEN("FileSwitch$")
%fscsd_rightlen=LEN("$CSD")
$`fscsd_left
   EQUZA   "FileSwitch$CurrentFilingSystem"
$`fscsd_right
   EQUZA   "$CSD"

#Library "Memory",claim.release.strdup
#Library "Strings",strlen.strcpy
#Here Libraries
#Post
#Run &lt;CODE&gt;
</textarea>
<hr/>


<textarea class='source-code'>
In   -
Out  EE
Type AOF
Max  16k

Pre
 S_None=0:REM We're outside the states !
 S_AwaitAck=1:REM Awaiting acknowledgement of EE
 S_AwaitSaveAck=2:REM Awaiting a save ack
 S_AwaitLoadAck=3:REM Awaiting a load ack (also 'middle' state)
 S_AwaitESave=4:REM Awaiting an EditDataSave
 S_AwaitLoad=5:REM Awaiting a DataLoad
 S_SendReturn=8:REM Request from application to return data
 S_SendAbort=9:REM Request from application to abort
 TW_Morite=&amp;808C4:REM Sent to task to kill it
 TW_Input=&amp;808C0:REM Sent to give keypresses to it
 DataSaveAck=2:REM Save ok
 DataLoad=3:REM Load this
 DataLoadAck=4:REM Loaded ok
 Ret_None=&amp;1000:REM Result = Not returning yet (if returned is an error)
 Ret_Updated=0:REM Result = 'updated'     (ok)
 Ret_Unchanged=1:REM Result = 'unchanged' (ok)
 Ret_Failed=2:REM Result = 'failed' ;-(   (error)
 Ret_Killed=3:REM Result = 'killed' ;-(   (error)
End Pre

#Rem Off
#Area "EECode" Code ReadOnly
; *******************************************************************
; Subroutine:   external_edit
; Description:  Edit a file
; Parameters:   r0-&gt; filename to edit
;               r1 = filetype (or -1 for none)
;               r2-&gt; edit name
;               r3-&gt; program name
; Returns:      r0 = return code
;                    0 = updated
;                    1 = unchanged
;                    2 = failed \_ these can be treated as
;                    3 = killed /  pretty much identical
; *******************************************************************
&gt;|external_edit|
   MOV     ip,sp                         ; APCS
   STMFD   (sp)!,{a1-a4,v1-v6,fp,ip,lr,pc}     ; Stack registers
   SUB     fp,ip,#4                      ; points as saved pc
   SUB     ip,sp,#1024*3                 ; we're going to need a big stack
   CMP     ip,sl                         ; is it below stack limit
   BLLT    |__rt_stkovf_split_small|
   REM     "Filename : %$0"
   REM     "Filetype : %&amp;1"
   REM     "Editname : %$2"
   REM     "Program : %$3"
   STR     r3,`parent                    ; store progname as 'parent'
   STR     r2,`editname                  ; store editname
   MOV     r7,r1                         ; r7 = type to edit as
   STR     r0,`filename                  ; store the filename used
   MOV     r1,r0                         ; r1-&gt; filename
   XSWI    "OS_File",20                  ; get the info for it
   CMP     r0,#0                         ; was it 'not found' ?
   BEQ     exit_failed                   ; if so, return as 'failed'
; now the type stuff
   CMN     r7,#1                         ; if -1, then we use the type given
   MOVEQ   r7,r6                         ; edit filetype = real filetype
   STR     r7,`filetype                  ; store filetype
   STR     r6,`oldtype                   ; the original type (to restore)
   XSWI    "OS_Byte",229,1,0             ; disable escape
   STR     r1,`oldescape                 ; store the escape state
$restart
   LDR     r1,$`TASK                     ; the 'TASK' word
   LDR     r2,`parent                    ; taskname = parent
   REM     "Taskname = %$2"
   XSWI    "XWimp_Initialise",200        ; initialise us as a task
   MOVVS   r0,#0                         ; if error, task handle = 0
   STR     r0,`taskhandle                ; store handle
   MOV     r1,r0                         ; hang on to the handley thing
; check taskwindow
   SWI     "TaskWindow_TaskInfo"         ; are we in a task ?
   CMP     r0,#0                         ; well?
   MOVNE   r0,#1                         ; marks us as a taskwindow
   CMP     r0,#0                         ; are we outside taskwindow ?
   CMPEQ   r1,#0                         ; and did the init fail ?
   BNE     $notatshellcli
   SWI     "XWimp_CloseDown"             ; close us down
   B       $restart
$notatshellcli
   STR     r0,`intaskwindow              ; mark it
   REM     "Taskwindow: %r0"
   BL      addfilter                     ; add our filter
   REM     "Filter added"
   BL      ee_initiate                   ; start the first ee
   REM     "Initiated EE"
   LDR     r0,`intaskwindow
   CMP     r0,#0                         ; are we in taskwindow ?
   BEQ     $notintw                      ; nope, so jump out
   SWI     "OS_WriteS"                   ; write string
   EQUZA   "Press R to return data, A to abort"
   SWI     "OS_NewLine"
$waitloop
; check state
   LDR     r0,`returnstate               ; read return state
   CMP     r0,#Ret_None                  ; is it 'none' ?
   BNE     taskend                       ; if not, exit
; now check keys
   XSWI    "XOS_Byte",&amp;81,25,0           ; read a character (25cs)
   CMP     r2,#255                       ; was it valid ?
   BEQ     $waitloop                     ; nope, so try again

   CMP     r1,#ASC("R")                  ; was it 'r' to return ?
   CMPNE   r1,#ASC("r")
   MOVEQ   r0,#S_SendReturn              ; let's return
   STREQ   r0,`filterstate               ; store it as the state

   CMP     r1,#ASC("A")                  ; was it 'a' to abort ?
   CMPNE   r1,#ASC("a")
   CMPNE   r1,#27                        ; or escape?
   MOVEQ   r0,#S_SendAbort               ; let's abort
   STREQ   r0,`filterstate               ; store it as the state

   B       $waitloop                     ; go again

; not in a taskwindow
$notintw
   REM     "Non-taskwindow poll"
$pollloop
; check state
   LDR     r0,`returnstate               ; read return state
   CMP     r0,#Ret_None                  ; is it 'none' ?
   BNE     taskend                       ; if not, exit
; now poll
   ADR     r1,`blk                       ; address of our block
   XSWI    "Wimp_Poll",0                 ; poll the wimp
   ADR     link,$pollloop                ; where to return to
   CMP     r0,#17                        ; is it usermessage?
   CMPNE   r0,#18                        ; or usermessagerecorded?
   LDREQ   r0,[r1,#16]                   ; read message type
   CMPEQ   r0,#0                         ; is it 'quit' ?
   MOVEQ   r0,#Ret_Killed                ; mark us as killed
   STREQ   r0,`returnstate               ; store as returnstate
   BEQ     taskend                       ; if so, end nicely
   B       $pollloop                     ; jump back to poll again

$`TASK
   EQUS    "TASK"                        ; word 'task'

&gt;taskend
   BL      removefilter                  ; remove the filter
   LDR     r0,`taskhandle                ; read the taskhandle
   CMP     r0,#0                         ; was it valid ?
   SWINE   "Wimp_CloseDown"              ; yep, so shut us down
   LDR     r1,`oldescape                 ; read old escape state
   XSWI    "OS_Byte",229,,0              ; restore it
   LDR     r0,`returnstate               ; read the return code
   REM     "Exiting... code = %r0"
   REM     ""
   LDMDB   (fp),{v1-v6,fp,lr,pc}^        ; return

.exit_failed
   REM     "Returning: failed"
   MOV     r0,#Ret_Failed                ; return 'failed' value
   LDMDB   (fp),{v1-v6,fp,lr,pc}^        ; return

.`oldescape
   EQUD    0                             ; old escape state
.`taskhandle
   EQUD    0                             ; task handle, or 0 if 'inside' task
.`realtaskhandle
   EQUD    0                             ; real task handle
.`intaskwindow
   EQUD    0                             ; 1 if we're in a taskwindow

&gt;addfilter
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   MOV     r0,#Ret_None                  ; make sure we can do multiple ee's
   STR     r0,`returnstate               ; store as return state
   LADR    r0,`ee_msgs
   XSWI    "XWimp_AddMessages"           ; add the messages we need
   XSWI    "Wimp_ReadSysInfo",5          ; read task handle
   STR     r0,`realtaskhandle            ; store real task handle
   MOV     r3,r0                         ; r3 = task handle
   LADR    r0,`filtername                ; filter name
   BL      strdup                        ; copy it to the module area
   STR     r0,`filtername_ptr            ; store it for later
   LADR    r1,filter                     ; filter code
   XSWI    "Filter_RegisterPostFilter",,,0,,0 ; install it
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;removefilter
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   XSWI    "Wimp_ReadSysInfo",5          ; read task handle
   MOV     r3,r0                         ; r3 = task handle
   LDR     r0,`filtername_ptr            ; filter name pointer
   CMP     r0,#0                         ; is it 0 ?
   BEQ     $exit                         ; if so, we've already released
   LADR    r1,filter
   XSWI    "Filter_DeRegisterPostFilter",,,0,,0 ; remove
   BL      release                       ; release the filtername block
   MOV     r0,#0
   STR     r0,`filtername_ptr            ; zero the name pointer
$exit
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;ee_initiate
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   ADR     r5,`blk                       ; the block base
   LDR     r0,`editname                  ; the name for the editor
   BL      strlen                        ; find len to r1
   ADD     r1,r1,#52+3+1                 ; 52 for base, 3 to align, 1 term
   BIC     r1,r1,#3                      ; align
   STR     r1,[r5,#0]                    ; store as block length
   REM     "Block size=%r1"
   LDR     r3,`ee_editrq
   STR     r3,[r5,#16]                   ; store as message
   ADD     r1,r5,#52                     ; r1-&gt; block + 52
   BL      strcpy                        ; copy edit name there
   REM     "Initiating EE for %$1"
   LDR     r0,`parent                    ; read -&gt; parent name
   ADD     r1,r5,#32                     ; r1-&gt; block + 32
   BL      strcpy                        ; copy parent name there
   REM     "Parent=%$1"
   LDR     r0,`filetype                  ; filetype
   STR     r0,[r5,#20]                   ; store as datatype
   SWI     "OS_ReadMonotonicTime"
   BIC     r0,r0,#&amp;FF000000              ; clear top bits
   BIC     r0,r0,#&amp;00FF0000              ; clear top-mid bits
   STR     r0,[r5,#24]                   ; store as job handle
   MOV     r0,#0                         ; just edit and return on save
   STR     r0,[r5,#28]                   ; store as flags
   STR     r0,[r5,#12]                   ; store as ourref
   XSWI    "Wimp_SendMessage",18,^`blk,0 ; broadcast recorded
; set new state
   MOV     r0,#S_AwaitAck                ; awaiting 'ack' message
   STR     r0,`filterstate               ; store it
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

.`parent
   EQUD    0
.`editname
   EQUD    0
.`filename
   EQUD    0
.`filetype
   EQUD    &amp;FFF                          ; text file
.`oldtype
   EQUD    &amp;FFF                          ; it's original type
.`tempname
   EQUZA   "&lt;Wimp$Scrap&gt;"

; Messages we /need/ to receive to work properly
.`ee_msgs
   EQUD    2                             ; datasaveack (for returns)
   EQUD    3                             ; dataload (for sends)
   EQUD    4                             ; dataloadack (for returns)
.`ee_editrq
   EQUD    &amp;45d80                        ; Message_EditRq
.`ee_editack
   EQUD    &amp;45d81                        ; Message_EditAck
.`ee_return
   EQUD    &amp;45d82                        ; Message_EditReturn
.`ee_abort
   EQUD    &amp;45d83                        ; Message_EditAbort
.`ee_datasave
   EQUD    &amp;45d84                        ; Message_EditDataSave
; end of list
   EQUD    0

.`ee_jobhandle
   EQUD    0                             ; the job handle
.`ee_taskhandle
   EQUD    0                             ; their task handle

.`filtername_ptr
   EQUD    0                             ; name pointer (for release)
.`filterstate
   EQUD    0                             ; the state of the filter manager
.`returnstate
   EQUD    Ret_None                      ; the state we're returning
.`filtername
   EQUZA   "ExternalEdit filter"

.`blk
   RES     256                           ; just a few bytes

; abort the edit
&gt;ee_abort
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "Sending abort message"
   ADR     r5,`blk                       ; our workspace
   MOV     r0,#28                        ; length of message
   STR     r0,[r5,#0]                    ; store len
   MOV     r0,#0
   STR     r0,[r5,#20]                   ; store 0 value
   LDR     r0,`ee_jobhandle
   STR     r0,[r5,#24]                   ; store job handle
   LDR     r0,`ee_abort                  ; edit abort
   STR     r0,[r5,#16]                   ; store it
   LDR     r2,`ee_taskhandle             ; their handle
   XSWI    "Wimp_SendMessage",17,r5      ; send it
; set new state
   MOV     r0,#S_None                    ; we're not in any state
   STR     r0,`filterstate               ; store it
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

; try to return the file to us
&gt;ee_return
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "Attempting get data back from Zap"
   MOV     r5,r1                         ; r5-&gt; block
   LDR     r0,`filetype                  ; filetype
   STR     r0,[r5,#20]                   ; store that
   MOV     r0,#0                         ; not reply
   STR     r0,[r5,#12]                   ; store as ourref
   LDR     r0,`ee_jobhandle
   STR     r0,[r5,#24]                   ; store job handle
   LDR     r0,`ee_return                 ; return request
   STR     r0,[r5,#16]                   ; store it
   LDR     r2,`ee_taskhandle             ; their handle
   XSWI    "Wimp_SendMessage",17,r5      ; send it
; set new state
   MOV     r0,#S_AwaitESave              ; awaiting 'editdatasave' message
   STR     r0,`filterstate               ; store it
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

; try to send the file
&gt;ee_startsendfile
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "Attempting to send a file at Zap"
   MOV     r5,r1                         ; r5-&gt; block
   LDR     r0,`editname                  ; the name to use
   BL      strlen                        ; find it's len (to r1)
   ADD     r2,r1,#44+3+1                 ; len+ base + align + term
   BIC     r2,r2,#3                      ; align now!
   STR     r2,[r5,#0]                    ; store as blk len
   ADD     r1,r5,#44                     ; base
   BL      strcpy                        ; copy leafname
   LDR     r0,`filetype                  ; filetype
   STR     r0,[r5,#40]                   ; store that
   MOV     r0,#0                         ; unknown size
   STR     r0,[r5,#36]                   ; store as size
   STR     r0,[r5,#12]                   ; store as ourref
   LDR     r0,`ee_jobhandle
   STR     r0,[r5,#20]                   ; store job handle
   LDR     r0,`ee_datasave               ; datasave request
   STR     r0,[r5,#16]                   ; store it
   LDR     r2,`ee_taskhandle             ; their handle
   XSWI    "Wimp_SendMessage",18,r5      ; send it
; set new state
   MOV     r0,#S_AwaitSaveAck            ; awaiting 'ack' message
   STR     r0,`filterstate               ; store it
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

; try to give them a file to save to (for return)
&gt;ee_sendsaveack
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   ADR     r1,`tempname                  ; the temporary name to use
   XSWI    "XOS_File",6                  ; delete it
   LDR     r5,[sp,#4*1]                  ; re-read r1
   MOV     r0,r1                         ; r1
   BL      strlen                        ; find it's len (to r1)
   ADD     r2,r1,#44+3+1                 ; len+ base + align + term
   BIC     r2,r2,#3                      ; align now!
   STR     r2,[r5,#0]                    ; store as blk len
   ADD     r1,r5,#44                     ; base
   BL      strcpy                        ; copy leafname
   REM     "Attempting to send save to Zap"
   MVN     r0,#NOT -1                    ; not safe
   STR     r0,[r5,#36]                   ; store as size
   LDR     r0,`filetype                  ; filetype
   STR     r0,[r5,#40]                   ; store as size
   LDR     r0,[r5,#8]                    ; their ref
   STR     r0,[r5,#12]                   ; store as ourref
   MOV     r0,#DataSaveAck               ; datasave request
   STR     r0,[r5,#16]                   ; store it
   LDR     r2,`ee_taskhandle             ; their handle
   XSWI    "Wimp_SendMessage",17,r5      ; send it
; set new state
   MOV     r0,#S_AwaitLoad               ; awaiting 'ack' message
   STR     r0,`filterstate               ; store it
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;ee_sendloadack
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   MOV     r5,r1                         ; r1-&gt; workspace
   ADD     r1,r5,#44                     ; pointer to filename
   REM     "Attempting to copy file to original location"
   LDR     r2,`filename                  ; -&gt; filename
   XSWI    "XOS_FSControl",26,,,%10000011
   BVS     $failed                       ; argh.
   MOV     r1,r2                         ; r1-&gt; filename
   LDR     r2,`oldtype                   ; read the original type
   XSWI    "XOS_File",18
   LDR     r0,[r5,#8]                    ; their ref
   STR     r0,[r5,#12]                   ; store as ourref
   MOV     r0,#DataLoadAck               ; dataload request
   STR     r0,[r5,#16]                   ; store it
   LDR     r2,`ee_taskhandle             ; their handle
   XSWI    "Wimp_SendMessage",17,r5      ; send it
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call
$failed
   REM     "LoadAck copy failed"
   XBL     returnfromfilter,Ret_Failed   ; we failed to launch edit
   XBL     ee_abort                      ; and send the abort
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

; try to give them the file to load
&gt;ee_sendload
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   MOV     r5,r1                         ; r1-&gt; workspace
   ADD     r2,r5,#44                     ; pointer to filename
   REM     "Attempting to send load to Zap"
   LDR     r1,`filename                  ; read -&gt; filename
   XSWI    "XOS_FSControl",26,,,%11
   BVS     $failed                       ; argh.
   MOV     r0,#0                         ; unknown size
   STR     r0,[r5,#36]                   ; store as size
   LDR     r0,[r5,#8]                    ; their ref
   STR     r0,[r5,#12]                   ; store as ourref
   MOV     r0,#DataLoad                  ; dataload request
   STR     r0,[r5,#16]                   ; store it
   LDR     r2,`ee_taskhandle             ; their handle
   XSWI    "Wimp_SendMessage",17,r5      ; send it
; set new state
   MOV     r0,#S_AwaitLoadAck            ; awaiting 'ack' message
   STR     r0,`filterstate               ; store it
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call
$failed
   REM     "Load copy failed"
   XBL     returnfromfilter,Ret_Failed   ; we failed to launch edit
   XBL     ee_abort                      ; and send the abort
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

; the filter to handle things
&gt;filter
   STMFD   (sp)!,{r1-r5,link}            ; Stack registers
   STR     r0,`reason                    ; hang on to reason
   REM     "%c04%c30Filter: reason= %r0"
   ADR     link,$return                  ; address to return to
   CMP     r0,#0                         ; is it null ?
   BEQ     null                          ; handle it
   CMP     r0,#17                        ; is it usermessage ?
   CMPNE   r0,#18                        ; or usermessagerecorded ?
   BEQ     usermessage                   ; it's a usermessage
   CMP     r0,#19                        ; is it usermessageack ?
   BEQ     usermessageack
$return
   LDR     r0,`reason                    ; re-read reason
   REM     "Returning reason %r0"
   LDMFD   (sp)!,{r1-r5,pc}^             ; Return from call

.`reason
   EQUD    0                             ; reason for it all

&gt;null
   STMFD   (sp)!,{r0,link}               ; Stack registers
   LDR     r0,`filterstate               ; read state
   CMP     r0,#S_SendReturn              ; we need to return
   XBLEQ   ee_return                     ; send the 'editreturn'
   CMP     r0,#S_SendAbort               ; we need to abort and return
   XBLEQ   returnfromfilter,Ret_Unchanged ; the file wasn't changed
   XBLEQ   ee_abort                      ; and send the abort
   LDMFD   (sp)!,{r0,pc}                 ; Return from call

&gt;usermessageack
   LDR     r2,[r1,#16]                   ; read message type

   MOV     r4,link
   REM     "ReceivedAck message %&amp;2"
   MOV     link,r4

   LDR     r3,`ee_editrq                 ; EditRq bounced ?
   CMP     r2,r3                         ; was that it ?
   BEQ     um_editrq_bounced             ; ok, so deal with it
   LDR     r3,`ee_datasave               ; EditDataSave bounced ?
   CMP     r2,r3                         ; was that it ?
   BEQ     um_editds_bounced             ; ok, so deal with it
   MOV     pc,link

&gt;um_editrq_bounced
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "EditRq bounced"
   LDR     r0,`filterstate               ; read the state
   CMP     r0,#S_AwaitAck                ; are we waiting for ack ?
   XBLEQ   returnfromfilter,Ret_Failed   ; with the code 'failed'
   REM     "Back to Editrq_bounced"
   MVN     r0,#NOT -1                    ; don't pass on
   STR     r0,`reason                    ; store as reason
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;um_editds_bounced
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "EDS bounced"
   LDR     r0,`filterstate               ; read the state
   CMP     r0,#S_AwaitSaveAck            ; are we waiting for saveack ?
   XBLEQ   returnfromfilter,Ret_Failed   ; we've failed
   XBLEQ   ee_abort                      ; and send the abort
   MVN     r0,#NOT -1                    ; don't pass on
   STR     r0,`reason                    ; store as reason
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;usermessage
   LDR     r2,[r1,#16]                   ; read message type

   MOV     r4,link
   REM     "Received message %&amp;2"
   MOV     link,r4

   CMP     r2,#0                         ; is it 'quit' ?
   LDRNE   r3,$`TW_Morite                ; have to read as a word
   CMPNE   r2,r3                         ; or tw_morite ?
   BEQ     um_quit                       ; we've been told to quit
   LDR     r3,`ee_editack                ; EditAck
   CMP     r2,r3                         ; was that it ?
   BEQ     um_editack                    ; yeah, we got it !
   LDR     r3,`ee_abort                  ; EditAbort
   CMP     r2,r3                         ; was that it ?
   BEQ     um_editabort                  ; yeah, we got it !
   LDR     r3,`ee_datasave               ; EditDataSave
   CMP     r2,r3                         ; was that it ?
   BEQ     um_editds                     ; yeah, we got it !
   CMP     r2,#DataSaveAck               ; is it DataSaveAck ?
   BEQ     um_datasaveack                ; ooh, ok !
   CMP     r2,#DataLoad                  ; is it DataLoad ?
   BEQ     um_dataload                   ; hey, things returing !
   MOV     pc,link

$`TW_Morite
   EQUD    TW_Morite

&gt;um_editds
   STMFD   (sp)!,{link}                  ; Stack registers
   ADD     r3,r1,#44
   LDR     r4,[r1,#40]
   REM     "Their filename was %$3, type=%&amp;4"
   LDR     r0,`filterstate               ; read filterstate
   REM     "Received EditDataSave, state=%r0"
   CMP     r0,#S_AwaitLoadAck            ; are we awaiting a save ? (middle)
   CMPNE   r0,#S_AwaitESave              ; or explicitly awaiting one ?
   LDMNEFD (sp)!,{pc}                    ; if not, return
   BL      ee_sendsaveack                ; send a datasaveack at the task
   MVN     r0,#NOT -1                    ; don't pass on
   STR     r0,`reason                    ; store as reason
   LDMFD   (sp)!,{pc}                    ; Return from call

&gt;um_editabort
   STMFD   (sp)!,{r0,link}               ; Stack registers
   XBL     returnfromfilter,Ret_Unchanged ; the file wasn't changed
   MVN     r0,#NOT -1                    ; don't pass on
   STR     r0,`reason                    ; store as reason
   LDMFD   (sp)!,{r0,pc}                 ; Stack registers

&gt;um_datasaveack
   STMFD   (sp)!,{link}                  ; Stack registers
   LDR     r0,`filterstate               ; read filterstate
   REM     "Received SaveAck, state=%r0"
   CMP     r0,#S_AwaitSaveAck            ; are we awaiting a save ?
   LDMNEFD (sp)!,{pc}                    ; if not, return
   BL      ee_sendload                   ; send a dataload at the task
   MVN     r0,#NOT -1                    ; don't pass on
   STR     r0,`reason                    ; store as reason
   LDMFD   (sp)!,{pc}                    ; Return from call

&gt;um_dataload
   STMFD   (sp)!,{link}                  ; Stack registers
   LDR     r0,`filterstate               ; read filterstate
   REM     "Received Load, state=%r0"
   CMP     r0,#S_AwaitLoad               ; are we awaiting a save ?
   LDMNEFD (sp)!,{pc}                    ; if not, return
   BL      ee_sendloadack                ; send a dataloadack at the task
   XBL     returnfromfilter,Ret_Updated  ; the file WAS changed
   MVN     r0,#NOT -1                    ; don't pass on
   STR     r0,`reason                    ; store as reason
   LDMFD   (sp)!,{pc}                    ; Return from call

&gt;um_editack
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   LDR     r0,`filterstate               ; read filterstate
   REM     "Received Ack, state=%r0"
   CMP     r0,#S_AwaitAck                ; are we awaiting an ack ?
   LDMNEFD (sp)!,{r0-r5,pc}              ; if not, return
   REM     "Storing handles and things"
   LDR     r0,[r1,#24]                   ; read jobhandle
   STR     r0,`ee_jobhandle              ; store it
   LDR     r0,[r1,#4]                    ; read taskhandle
   STR     r0,`ee_taskhandle             ; store it
   BL      ee_startsendfile              ; send the file
   MVN     r0,#NOT -1                    ; don't pass on
   STR     r0,`reason                    ; store as reason
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;um_quit
   STMFD   (sp)!,{link}                  ; Stack registers
   BL      ee_abort                      ; send an abort
   BL      removefilter                  ; remove the filter
   MVN     r0,#NOT -1                    ; don't pass on
   STR     r0,`reason                    ; store as reason
   LDMFD   (sp)!,{pc}                    ; Return from call

; call this to return to main program
&gt;returnfromfilter
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   STR     r0,`returnstate               ; store the return state
   REM     "Attempting to send 'done' message %r0"
   LDMFD   (sp)!,{r0-r5,pc}^             ; Return from call

#library "strings",strlen.strcpy
#library "memory",strdup.release.claim
#Here Libraries
</textarea>
<hr/>

    <textarea class='source-code'>
In    -
Out   NoCoverIB
Type  Module

Define Module
 Name    NoCoverIB
 Author  Justin Fletcher
 WimpSWIs
  SWI    Wimp_OpenWindow
  Pre    openwin
 End WimpSWIs
 Commands
  Name   NoCoverIB
  Help   ...
         The NoCoverIB module forces the Wimp to obey the 'don't cover
         iconbar' flag in CMOS RAM. If you wish to cover the iconbar,
         then hold shift whilst performing any drags.|M|M
         Note: The toggle has had to be simulated, and therefore it does
         not work totally correctly. I cannot (legally) code around this
         as I do not know the how to read previous size. Sorry about that.
 End Commands
 Workspace *160
End Module

Pre

 LIBRARY "VersionBas":PROCinit_version
 module_version$=version_major$
 module_date$=version_date$

 ibtop=128
 REM # Cond Inline
 REM # Cond ctrl Do you want Ctrl-Shift to cancel Shift action
 # Cond Set ctrl TRUE
End Pre

#Rem Off
; Replaces Wimp_OpenWindow
.openwin
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "%c04Open window, number = %&amp;1"
   LDR     r3,[r12,#124]                 ; get flag
   ADD     r3,r3,#1                      ; increment flag
   STR     r3,[r12,#124]                 ; store back
   CMP     r3,#1                         ; is it 0 ? (process)
   BNE     $exit                         ; if not, exit
   MOV     r5,r1                         ; r5=pointer to window block
   XSWI    "OS_Byte",161,28              ; get CMOS byte
   TST     r2,#&amp;10                       ; is bit set ?
   BEQ     $exit                         ; if not, exit
   XSWI    "OS_Byte",121,0 EOR &amp;80       ; get shift status
   CMP     r1,#&amp;FF                       ; is it pressed ?
# Cond Of Ctrl
   BNE     $notshift
   XSWI    "OS_Byte",121,1 EOR &amp;80       ; get ctrl status
   CMP     r1,#&amp;FF                       ; is it also pressed ?
   BNE     $exit                         ; if not, exit
# Cond Else
   BEQ     $exit
# Cond EndIf
$notshift
   REM     "Can process"

   LDR     r2,[r5,#28]                   ; get window behind
   CMN     r2,#3                         ; is it iconised ?
   BEQ     $exit                         ; if so, exit
   MOV     r1,r12                        ; r1=pointer to WS, and set b0
   LDR     r2,[r5]                       ; get window handle
   STR     r2,[r1]                       ; store in block
   ORR     r1,r1,#1                      ; set b0
   SWI     "Wimp_GetWindowInfo"          ; get data, bar icons
   REM     "Got info"
   LDR     r0,[r12,#32]                  ; get flags
   STR     r0,[r12,#120]                 ; store flags for later
   TST     r0,#1&lt;&lt;29                     ; has it got adjust size ?
   TSTNE   r0,#1&lt;&lt;28                     ; if so, has it got vertical scroll?
   BEQ     $exit                         ; if not, exit

   TST     r0,#1&lt;&lt;16                     ; is it open ?
   BNE     $notopen
   MOV     r1,r5                         ; no, re-get pointer to block,
   REM     "Call second routine"
   SWI     "Wimp_OpenWindow"             ; Œ open it as specifed,
   REM     "Exitted second"
;    BL      Display
   LDR     r4,[r5,#32]                   ; Œ read old offset 32
   SWI     "Wimp_GetWindowState"         ; Œ get new location,
   STR     r4,[r5,#32]                   ; Œ restore old offset 32
;    BL      Display
   ORR     r1,r12,#1                     ; Œ set b0 to return just header,
   SWI     "Wimp_GetWindowInfo"          ; Œ and get the info again
$notopen
   ADD     r1,r12,#96                    ; add#96 as offset for outline blk
   STR     r2,[r1]                       ; store window handle
   SWI     "Wimp_GetWindowOutline"       ; get outline
   LDR     r0,[r12,#8]                   ; get VWA bottom
   LDR     r2,[r12,#96+8]                ; get bottom of window
   SUB     r0,r0,r2                      ; r0=size of scroll bar
   ADD     r4,r0,#ibtop                  ; add to iconbar top
   LDR     r0,[r5,#28]                   ; get position in stack
   CMN     r0,#2                         ; is it at back ?
   BEQ     $exit
   LDR     r0,[r5,#8]                    ; get bottom
   LDR     r1,[r5,#16]                   ; get top
   CMP     r1,r4                         ; is top below iconbar ?
   BLT     $exit                         ; if so, then skip
   CMP     r0,r4                         ; is bottom below iconbar ?
   MOVLT   r0,r4                         ; if so, move it above iconbar
   STR     r0,[r5,#8]                    ; and store back in block
   BL      checktoggle
   LDR     r0,[r12,#120]                 ; get original flags
   TST     r0,#1&lt;&lt;21                     ; did it need forcing to screen ?
   BNE     $forcetoscreen                ; if so, make sure
   TST     r0,#1&lt;&lt;16                     ; was it open before ?
   BNE     $exit                         ; if not, then forget
   LDR     r0,[r12,#32]                  ; get flags
   TST     r0,#1&lt;&lt;6                      ; is it no bounds ?
   BNE     $exit
$forcetoscreen
   LDR     r3,[r12,#16]                  ; get win top
   LDR     r2,[r12,#96+16]               ; get outline top
   SUB     r4,r2,r3                      ; r4=title bar height
   LDR     r3,[r5,#16]                   ; get new win top
   BL      keeponscreen
$exit
   REM     "End filter"
   LDR     r0,[r12,#124]                 ; get flag
   SUB     r0,r0,#1                      ; decrement flag
   STR     r0,[r12,#124]                 ; store back

   LDMFD   (sp)!,{r0-r5,pc}^             ; Return from call

.checktoggle
   STMFD   (sp)!,{r0-r6,link}            ; Stack registers
   REM     "Toggle check"
   LDR     r0,[r12,#32]                  ; get flags
   TST     r0,#1&lt;&lt;27                     ; toggle icon ?
   BEQ     $exit                         ; if not, exit
   TST     r0,#1&lt;&lt;18                     ; already full size ?
   BNE     $exit                         ; if so, exit
   REM     "%c04Toggle icon?"
   SWI     "OS_Mouse"                    ; get position
   TST     r2,#%101                      ; is select or adjust pressed ?
   BEQ     $exit                         ; if not, then just passing over - exit
   LDR     r2,[r12,#12]                  ; get win right
   LDR     r3,[r12,#96+12]               ; get outline right
   CMP     r2,r0                         ; compare win right with mousex
   BGT     $exit                         ; if &gt;, exit
   CMP     r3,r0                         ; compare outline right with mousex
   BLT     $exit                         ; if &lt;, exit
   LDR     r2,[r12,#16]                  ; get win top
   LDR     r3,[r12,#96+16]               ; get outline top
   CMP     r2,r1                         ; compare win top with mousey
   BGT     $exit                         ; if &gt;, exit
   CMP     r3,r1                         ; compare outline top with mousey
   BLT     $exit                         ; if &lt;, exit
   REM     "Yes"
   SUB     r4,r3,r2                      ; r4=title bar height
   LDR     r2,[r12,#56]                  ; get maxy
   LDR     r3,[r12,#48]                  ; get miny
   SUB     r2,r2,r3                      ; r2=total height
   LDR     r3,[r5,#8]                    ; get bottom of window
   REM     "Bottom=%r3"
   REM     "Total height=%r2"
   ADD     r3,r3,r2                      ; add height
   BL      keeponscreen
$exit
   LDMFD   (sp)!,{r0-r6,pc}              ; Return from call

; &gt; r3=win top
;   r4=title bar height
.keeponscreen
   STMFD   (sp)!,{r0-r6,link}            ; Stack registers
   REM     "Keep on screen, top=%r3, %r4"
   XSWI    "OS_ReadModeVariable",-1,12   ; get YWindLimit
   MOV     r6,r2                         ; r6=YWindLimit
   XSWI    "OS_ReadModeVariable",-1,5    ; get YEigFactor
   MOV     r6,r6,LSL r2                  ; shift YWindLimit by YEigFactor
   ADD     r0,r3,r4                      ; what will be location of titlebar?
   CMP     r0,r6                         ; &gt; top of screen ?
   SUBGT   r3,r6,r4                      ; if so, top=scrtop-title height
   MOVGT   r0,#1                         ; get 1 pixel to add to top
   ADDGT   r3,r3,r0,LSL r2               ; add pixel to make title at top
   STR     r3,[r5,#16]                   ; store back in block
   REM     "Top=%r3"
$exit
   LDMFD   (sp)!,{r0-r6,pc}              ; Return from call

; .Display
;    STMFD   (sp)!,{r0-r9,link}            ; Stack registers
;    LDMIA   r5,{r0-r8}                    ; read block
;    REM     "Display :"
;    REM     "%R"
;    LDMFD   (sp)!,{r0-r9,pc}              ; Return from call

#Post
REM #Run &lt;CODE&gt;
REM *Filer_Run Resources:$.Apps.!Draw
REM *Son
</textarea>
<hr/>

<textarea class='source-code'>
In   -
Out  ControlAMPlayer
Type Module
Max  32k

Define Workspace
 Name      workspace
 Default   r12
  `key       !   the key they pressed
  `ignore    !   are we ignoring a character
  `sprshow   !   sprite being shown, or 0 if none
  `sprpend   !   sprite pending (if we're in a panic)
  `sprites   !   our sprite area
  `sprlen    !   our sprite area length
  `grabbed   !   grabbed sprite area
  `grablen   !   grabbed sprite length
  `grabx     !   x coord
  `graby     !   y coord

  `cuespeed  !   speed at which changes take place
  `cuespeedthing !

  `ontime    !   time placed on the screen
  `usekeyv   !   Should we be handling KeyV events ? (-&gt; ws if we should)

  `fadestart !   the fade start position

  `gc_vdustate ! current VDU state
  `gc_textx    ! text x position
  `gc_texty    ! text y position

  `gc_GWLCol !   Graphics window
  `gc_GWBRow !
  `gc_GWRCol !
  `gc_GWTRow !
  `gc_TWLCol !   Text window
  `gc_TWBRow !
  `gc_TWRCol !
  `gc_TWTRow !

  `gc_OrgX   !             x coord of graphics Origin
  `gc_OrgY   !             y coord of graphics Origin

  `gc_OlderCsX !           Oldest gr. Cursor X coord
  `gc_OlderCsY !           Oldest gr. Cursor Y coord
  `gc_OldCsX   !           Previous gr. Cursor X coord
  `gc_OldCsY   !           Previous gr. Cursor Y coord
  `gc_GCsIX    !           Graphics Cursor X coord
  `gc_GCsIY    !           Graphics Cursor Y coord

  `repeats     !           Number of repeats taken (when 0, do it)

  `colours     %256        colour translation table
  `searchdir   %512        search directory - the directory we are in
  `searchname  %256        search filename - the file we looked at last
  `searchws    %256        some workspace for the search
  `albumqueue  %256        the next album we queue
  `searchcnt   !           count of the files left to search
End Workspace

Define Module
 Name      ControlAMPlayer
 Extra     "+modtype$+"
 Author    Justin Fletcher
 Workspace *`len_workspace
 Vectors
  KeyV     keyv
 End Vectors
 Vectors
  ByteV            byte
 End Vectors
 Init      init
 Final     final
 Workspace *`len_workspace
 PostFilter
  Name     AMPEG queueing
  Task     -
  Accept   UserMessage
  Accept   UserMessageRecorded
  Code     postfilter
 End Filter
 Services
  ModeChanging   modechanging
  AMPlayer       amplayer_service
 End Services
 Commands
  Name     AMSearch
  Code     search

  Name     AMKeypad
  Code     keypad
  Syntax   Syntax: *AMKeypad -on | -off
  Min      1
  Max      1
 End Commands
End Module

Pre

 LIBRARY "VersionBas":PROCinit_version
 module_version$=version_major$
 module_date$=version_date$

 airboard%=FALSE
 IF airboard% THEN
  REM Transition key numbers (Airboard)
  key_rew=206
  key_pause=207
  key_skip=208
  key_stop=209
  key_ffwd=210
  key_down=211
  key_up=212
  key_queue=205:REM U/P
  key_open=214:REM Display
  modtype$="Airboard variant"
 ELSE
  key_rew=72:REM k4
  key_pause=36:REM k*
  key_skip=35:REM k/
  key_stop=91:REM k2
  key_ffwd=74:REM k6
  key_down=58:REM k-
  key_up=75  :REM k+
  key_queue=102:REM k.
  key_open=103:REM kEnter
  modtype$="Standard keyboard variant"
 ENDIF

 Pressed=2
 Released=1

 oldstyle%=FALSE
 repeattime=5
 initialrepeatdelay=10:REM * repeattime
 delaytime=100
 shortdelay=1
 dirscantime=100:REM Time between dir scan updates
 speedbase=20
 speedinc=2
 cuedelay=100
 PROCinitvols
End Pre

#rem off

&gt;init
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   STRW    r12,`usekeyv
   XSWI    "XOS_File",5,^$`spritefile

   TEQ     r0,#1
   BNE     $nofiles

   ADD     r4,r4,#4
   XBL     claim,r4                      ; claim some space
   TEQ     r0,#0
   BEQ     $nospace
   STRW    r0,`sprites
   STRW    r4,`sprlen

   STR     r4,[r0],#4                    ; store area length
   MOV     r2,r0
   XSWI    "XOS_File",255,^$`spritefile,,0
   REM     "Loaded sprites"

; now try to plot one
;    LDR     r0,$`sprite
;    BL      showsprite

; initialise the auto-queue
   BL      dosearch_call

   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

$nofiles
   LDMFD   (sp)!,{r0-r5,link}            ; restore registers
   ADR     r0,$`error1                   ; read error
   ORRS    pc,link,#vbit                 ; return with V set

$nospace
   LDMFD   (sp)!,{r0-r5,link}            ; restore registers
   ADR     r0,$`error2                   ; read error
   ORRS    pc,link,#vbit                 ; return with V set
$`error1
   ERR     0,"Couldn't find sprites file"
$`error2
   ERR     0,"No memory"

$`spritefile
   EQUZA   "&lt;ControlAMPlayer$Dir&gt;.Sprites"

$`sprite
   EQUZ    "ply"

&gt;final
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   LDRW    r0,`sprites
   BL      release
   LDRW    r0,`grabbed
   TEQ     r0,#0
   BLNE    release
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;modechanging
   STMFD   (sp)!,{r0-r1,link}            ; Stack registers
   BL      ditchallsprites
   LDMFD   (sp)!,{r0-r1,pc}              ; Return from call

&gt;amplayer_service
   TEQ     r0,#2                         ; Start playing
   TEQNE   r0,#4                         ; Stop playing
   MOVNE   pc,link
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   BL      dosearch_call
   LDMFD   (sp)!,{r0-r5,pc}^             ; Return from call


; check for a bank switch - definately in svc mode
&gt;byte
   TEQ     r0,#112
   TEQNE   r0,#113
   MOVNES  pc,link
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   BL      ditchallsprites
   LDMFD   (sp)!,{r0-r5,pc}^             ; Return from call

; r0 = transition state (1 up / 2 down)
&gt;keyv
   LDRW    r12,`usekeyv
   TEQ     r12,#0
   MOVEQ   pc,link

   TEQ     r0,#Released ; released?
   TEQNE   r0,#Pressed  ; pressed?
   MOVNE   pc,link

; first the press/release auto-repeaters
   TEQ     r1,#key_rew
   TEQNE   r1,#key_ffwd
   BEQ     cueing

   TEQ     r1,#key_up
   TEQNE   r1,#key_down
   BEQ     volume

; now the ones that are press triggered
   TEQ     r0,#Pressed   ; pressed ?
   MOVNE   pc,link

   TEQ     r1,#key_pause
   BEQ     pauseplay

   TEQ     r1,#key_queue
   BEQ     queuenoqueue

   TEQ     r1,#key_skip
   BEQ     skiptrack

   TEQ     r1,#key_stop
   BEQ     stop

   TEQ     r1,#key_open
   BEQ     open

   MOV     pc,link

&gt;cueing
   STMFD   (sp)!,{r0,r1,link}
   STRW    r1,`key
   TEQ     r0,#Pressed
   MOVEQ   r14,#speedbase
   STRWEQ  r14,`cuespeed
   MOV     r1,r0
   XBL     autorepeat,^calldospin
   LDMFD   (sp)!,{r0,r1,link,pc}  ; Claim

&gt;calldospin
   STMFD   (sp)!,{r0-r1,r8,r9,link}            ; Stack registers
   LDRW    r0,`repeats
   TEQ     r0,#0
   SUBNE   r0,r0,#1
   STRWNE  r0,`repeats
   LDMNEFD (sp)!,{r0-r1,r8,r9,pc}

   MODE    +svc
   LADR    r0,dospin
   XSWI    "XOS_AddCallBack",,r12
   MODE    -svc
   LDMFD   (sp)!,{r0-r1,r8,r9,pc}

&gt;volume
   STMFD   (sp)!,{r0,r1,link}
;    REM     "%r2,%r1"
   STRW    r1,`key
   MOV     r1,r0
   XBL     autorepeat,^calldovolume
   LDMFD   (sp)!,{r0,r1,link,pc}  ; Claim

&gt;calldovolume
   STMFD   (sp)!,{r0-r1,r8,r9,link}            ; Stack registers
   LDRW    r0,`repeats
   TEQ     r0,#0
   SUBNE   r0,r0,#1
   STRWNE  r0,`repeats
   LDMNEFD (sp)!,{r0-r1,r8,r9,pc}^
   MODE    +svc
   LADR    r0,changevolume
   XSWI    "XOS_AddCallBack",,r12
   MODE    -svc
   LDMFD   (sp)!,{r0-r1,r8,r9,pc}^

; cause routine at r0 repeat
; r0-&gt; routine
; r1 = Pressed to start repeat, Released to stop
&gt;autorepeat
   TEQ     r1,#Released
   BNE     $start

; end repeat
   STMFD   (sp)!,{r0-r1,r8,r9,link}
   MODE    +svc
   XSWI    "XOS_RemoveTickerEvent",,r12   ; a release, so end calling
   MODE    -svc
   LDMFD   (sp)!,{r0,r1,r8,r9,pc}^  ; Claim call

; start repeat
$start
   STMFD   (sp)!,{r0-r2,r8,r9,link}
   MODE    +svc
   MOV     r1,r0
   XSWI    "XOS_CallEvery",#repeattime,,r12   ; a press, so start calling
   MOV     r0,#0
   STRW    r0,`repeats
   ORR     link,pc,#3 ; svc mode
   MOV     pc,r1
   NOP
   MOV     r0,#initialrepeatdelay
   STRW    r0,`repeats
   MODE    -svc
   LDMFD   (sp)!,{r0-r2,r8,r9,pc}^  ; Claim call

&gt;queuenoqueue
   STMFD   (sp)!,{r0,r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^togglequeue,r12
   MODE    -svc
   LDMFD   (sp)!,{r0,r1,r8,r9,link,pc}   ; Claim call

&gt;pauseplay
   STMFD   (sp)!,{r0,r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^togglepause,r12
   MODE    -svc
   LDMFD   (sp)!,{r0,r1,r8,r9,link,pc}   ; Claim call

&gt;skiptrack
   STMFD   (sp)!,{r0,r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^doskip,r12
   MODE    -svc
   LDMFD   (sp)!,{r0,r1,r8,r9,link,pc}   ; Claim call

&gt;stop
   STMFD   (sp)!,{r0,r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^dostop,r12
   MODE    -svc
   LDMFD   (sp)!,{r0,r1,r8,r9,link,pc}   ; Claim call

&gt;open
   STMFD   (sp)!,{r0,r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^doopen,r12
   MODE    -svc
   LDMFD   (sp)!,{r0,r1,r8,r9,link,pc}   ; Claim call

&gt;togglequeue
   STMFD   (sp)!,{r0,r1,link}            ; Stack registers
   LDRBW   r1,`searchdir
   TEQ     r1,#1                         ; is queueing on ?
   MOVEQ   r1,#0                         ; if not, mark it as on
   MOVNE   r1,#1                         ; if so, mark it as off
   STRBW   r1,`searchdir
   LDREQ   r0,$`qon
   LDRNE   r0,$`qoff
   BLEQ    dosearch_call
   MOV     r1,#0
   STRBW   r1,`albumqueue                ; stop queuing next album
   BL      showsprite
   XSWI    "XAMPlayer_Play",%1,0         ; stop the queued track
   LDMFD   (sp)!,{r0,r1,pc}^             ; Return from call

$`qoff
   EQUZA   "qof"
$`qon
   EQUZA   "qon"

&gt;togglepause
   STMFD   (sp)!,{r0-r4,link}            ; Stack registers
   SWI     "XAMPlayer_Info"              ; read status
   BVS     $exit
   TEQ     r0,#3                         ; playing
   TEQNE   r0,#2                         ; or locating
   TEQNE   r0,#4                         ; or paused ?
   BNE     $exit
   MOV     r0,r0,LSR #2                  ; 0 if playing, 1 if paused
   SWI     "XAMPlayer_Pause"
   BVS     $exit
   TST     r0,#1 ; pause
   LDREQ   r0,$`paused
   LDRNE   r0,$`playing
   BL      showsprite
$exit
   LDMFD   (sp)!,{r0-r4,pc}^             ; Return from call

$`paused
   EQUZ    "pse"
$`playing
   EQUZ    "ply"

&gt;dostop
   STMFD   (sp)!,{r0-r4,link}            ; Stack registers
   XSWI    "XAMPlayer_Stop",%0
   BVS     $exit
; and the sprite
   LDR     r0,$`stop
   BL      showsprite
$exit
   LDMFD   (sp)!,{r0-r4,pc}^             ; Return from call

$`stop
   EQUZA   "stp"

&gt;doopen
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   SWI     "XAMPlayer_Info"
   BVS     $nothingtodo
   TEQ     r0,#1
   TEQNE   r0,#2
   TEQNE   r0,#3
   TEQNE   r0,#4
   TEQNE   r0,#5
   TEQNE   r0,#6
   TEQNE   r0,#7
   BNE     $nothingtodo

   MOV     r0,r1
   BL      findlastdot
   TEQ     r0,#0                         ; no dot - can't find!
   BEQ     $nothingtodo

   ADRW    r2,`searchws                  ; safe to use here ;-)
   ADR     r14,$`filer_opendir
   LDMIA   r14,{r3,r4,r5,r14}
   STMIA   r2!,{r3,r4,r5,r14}
   SUB     r3,r0,r1                      ; r3 = offset of last .
   MOV     r0,r1                         ; r0-&gt; filename
   SUB     r1,r2,#2                      ; r1-&gt; end of filer_opendir
   BL      strcpy
   MOV     r0,#0
   STRB    r0,[r1,r3]                    ; zero the string
   ADRW    r0,`searchws
; NOTE: This isn't always safe
   SWI     "XTaskManager_StartTask"

$nothingtodo
   LDMFD   (sp)!,{r0-r5,pc}^             ; Return from call

$`filer_opendir
   EQUZA   "Filer_OpenDir "
           ;333344445555EEEE

&gt;doskip
   STMFD   (sp)!,{r0-r4,link}            ; Stack registers
   XSWI    "XAMPlayer_Control",0,-1
   BVS     $exit
   MOV     r2,r1
   LDRW    r0,`fadestart
   REM     "Fade = %r0, current = %r1"
   TEQ     r0,#0
   BEQ     $startfade
   TST     r0,#1&lt;&lt;8
   BNE     $fadeout
; fading in
   ADD     r2,r2,#2
   CMP     r2,r0
   MOVHS   r2,r0
$setvolume
   AND     r1,r2,#(1&lt;&lt;8)-1
   XSWI    "XAMPlayer_Control",0
   LDRW    r0,`fadestart
   CMP     r1,r0
   MOVCS   r2,#0
   STRWCS  r2,`fadestart
   BHS     $exit
$reschedule
   XSWI    "XOS_CallAfter",1,^$reskiptrack,r12
$exit
   LDMFD   (sp)!,{r0-r4,pc}^             ; Return from call

$startfade
   ORR     r2,r2,#1&lt;&lt;8
   STRW    r2,`fadestart
$fadeout
   REM     "  out = %r2"
   SUBS    r2,r2,#2
   BHS     $setvolume
; change track
   XSWI    "XAMPlayer_Info",0
   BVS     $cantchange
   TEQ     r0,#2      ; locating
   TEQNE   r0,#3      ; playing
   TEQNE   r0,#4      ; paused
   BNE     $cantchange
   XSWI    "XAMPlayer_Stop",%1           ; skip to next track
   BVS     $cantchange
; and the sprite
   LDR     r0,$`next
   BL      showsprite

$cantchange
   LDRW    r0,`fadestart
   BIC     r0,r0,#1&lt;&lt;8
   STRW    r0,`fadestart
   MOV     r2,#2
   REM     "  FadeIn"
   B       $setvolume

$reskiptrack
   STMFD   (sp)!,{r0,r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^doskip,r12
   MODE    -svc
   LDMFD   (sp)!,{r0,r1,r8,r9,pc}        ; Restore registers call

$`next
   EQUZ    "nxt"

&gt;changevolume
   STMFD   (sp)!,{r0-r3,link}            ; Stack registers
   LDRW    r3,`key
   TEQ     r3,#key_up
   ADREQ   r2,uptable
   ADRNE   r2,downtable
   XSWI    "XAMPlayer_Control",0,-1
   LDMVSFD (sp)!,{r0-r3,pc}^             ; if screwed, return from call
   CMP     r1,#0
   MOVMI   r1,#0
   CMP     r1,#127
   MOVHI   r1,#127
   MOV     r3,r1
   LDRB    r1,[r2,r1]
   XSWI    "XAMPlayer_Control",0
; and now display the right sprite
   ADD     r2,r2,#128
   LDRB    r1,[r2,r1] ; read the name offset lamp for the new volume
   ADR     r0,$`lampnames
   LDR     r0,[r0,r1]
   BL      showsprite
   LDMFD   (sp)!,{r0-r3,pc}^             ; Return from call

$`lampnames
   EQUZA   "v1"
   EQUZA   "v1"
   EQUZA   "v2"
   EQUZA   "v3"
   EQUZA   "v4"
   EQUZA   "v5"
   EQUZA   "v6"
   EQUZA   "v7"
   EQUZA   "v8"
   EQUZA   "v9"
   EQUZA   "v10"
   EQUZA   "v11"
   EQUZA   "v12"
   EQUZA   "v13"
   EQUZA   "v14"
   EQUZA   "v15"

.downtable
   FNchangevol(-1)
.uptable
   FNchangevol(+1)

&gt;resetcue
   STMFD   (sp)!,{r0,link}               ; Stack registers
   MOV     r0,#0
   STRW    r0,`cuespeed
   LDMFD   (sp)!,{r0,pc}^                ; Return from call

&gt;dospin
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers

   LDRW    r5,`cuespeed
   TEQ     r5,#0
   MOVEQ   r5,#speedbase
   ADDNE   r5,r5,#speedinc
   STRW    r5,`cuespeed

   XSWI    "XOS_RemoveTickerEvent",^resetcue,r12
   XSWI    "XOS_CallAfter",#cuedelay,^resetcue,r12

   LDRW    r5,`key
   TEQ     r5,#key_rew
   LDRW    r5,`cuespeed
   RSBEQ   r5,r5,#0
   XSWI    "XAMPlayer_Info",0
   BVS     $exit
   TEQ     r0,#2      ; locating
   TEQNE   r0,#3      ; playing
   TEQNE   r0,#4      ; paused
   BNE     $exit
   MOV     r1,r2
   LDR     r14,[r1]   ; read flags
   TST     r14,#2     ; is elapsed time valid ?
   BEQ     $exit      ; if not, we're screwed
   TST     r14,#1     ; is total time valid ?
   MVNEQ   r2,#NOT -1 ; if not, use -1 (massive number)
   LDRNE   r2,[r1,#8] ; if so, use total time
   TEQ     r0,#2      ; are we locating ?
   MOVEQ   r1,r4      ; if so, use the locate position as the base
   LDRNE   r1,[r1,#12]; if not, use current time
   ; r2 = end of track
   ; r1 = current position
   ADDS    r1,r1,r5   ; add on direction
   STRW    r5,`cuespeedthing
   MOVVS   r1,#0      ; if -ve, move to 0
   CMP     r1,r2
   BLHI    doskip     ; if &gt; end, skip to next track
   BHI     $exit
   XSWI    "XAMPlayer_Locate",0
   BVS     $exit

; set up the sprite
   CMP     r5,#0
   LDRGT   r0,$`fwd
   LDRLE   r0,$`rew
   BL      showsprite

$exit
   LDMFD   (sp)!,{r0-r5,pc}^             ; Return from call

$`fwd
   EQUZA   "fwd"
$`rew
   EQUZA   "rew"

&gt;ditchallsprites
   STMFD   (sp)!,{r0-r1,link}            ; Stack registers
; mark as not got anything
   MOV     r0,#0
   STRW    r0,`grabx

   BL      ditchplotremove
   LDMFD   (sp)!,{r0-r1,pc}              ; Return from call

&gt;ditchplotremove
   STMFD   (sp)!,{r0-r1,link}            ; Stack registers
; and all the ticker events
   LADR    r0,removesprite
   XSWI    "XOS_RemoveTickerEvent",,r12
   LADR    r0,delayedremovesprite
   XSWI    "XOS_RemoveTickerEvent",,r12
   LADR    r0,delayedshow
   XSWI    "XOS_RemoveTickerEvent",,r12

; and all the callbacks
   LADR    r0,doremovesprite
   XSWI    "XOS_RemoveCallBack",,r12
   LADR    r0,dodelayedshow
   XSWI    "XOS_RemoveCallBack",,r12
   LDMFD   (sp)!,{r0-r1,pc}              ; Return from call


; We weren't in a safe position to show the graphic last time... let's
; retry!
&gt;delayedshow
   STMFD   (sp)!,{r0-r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^dodelayedshow,r12
   MODE    -svc
   LDMFD   (sp)!,{r0-r1,r8,r9,pc}        ; Return from call

&gt;dodelayedshow
   STMFD   (sp)!,{r0,link}               ; Stack registers
   LDRW    r0,`sprpend
   BL      showsprite
   LDMFD   (sp)!,{r0,pc}                 ; Return from call

; r0 = sprite to show
&gt;showsprite
   STMFD   (sp)!,{r0-r7,link}            ; Stack registers

   LDRW    r14,`sprshow
   TEQ     r14,#0
   BEQ     $nothingshown                 ; is nothing shown ?
   TEQ     r14,r0
   BEQ     $shown                        ; use the same sprite - update time

   BL      ditchplotremove

$nothingshown
; ok, we need to show sprite $r0 - this may not be easy!

; Check that we have a good graphics context
   SWI     "XTaskWindow_TaskInfo"
   TEQ     r0,#0
   BEQ     $ingoodcontext

; we're not in a good context, so reschedule
   XSWI    "XOS_RemoveCallBack",^delayedshow,r12
   XSWI    "XOS_CallAfter",#shortdelay,^delayedshow,r12
   LDR     r0,[sp]
   STRW    r0,`sprpend
   REM     "-P-"
   B       $willbeshownwhenoutofcontext

$ingoodcontext
   LDR     r0,[sp]
   STRW    r0,`sprshow

   BL      preservecontext

; read sprite sizes
   ADRW    r2,`sprshow
   LMOV    r0,#&amp;128
   LDRW    r1,`sprites
   XSWI    "XOS_SpriteOp"                ; find width/height/mode
   BVS     $failed

   REM     "Sprite %$2, %r3x%r4, mode %r6"

; find as OS units
   XSWI    "XOS_ReadModeVariable",r6,4   ; read xeig for sprite
   MOV     r3,r3,LSL r2
   XSWI    "XOS_ReadModeVariable",,5     ; read yeig for sprite
   MOV     r4,r4,LSL r2

   REM     "In OS units %r3x%r4"

; now the current mode
   XSWI    "XOS_ReadModeVariable",-1,11  ; read width-1 for this mode
   ADD     r5,r2,#1                      ; r5 = pix width
   XSWI    "XOS_ReadModeVariable",,4     ; read xeig for this mode
   MOV     r5,r5,LSL r2                  ; r5 = OS width

   XSWI    "XOS_ReadModeVariable",-1,12  ; read height-1 for this mode
   ADD     r6,r2,#1                      ; r6 = pix height
   XSWI    "XOS_ReadModeVariable",,5     ; read yeig for this mode
   MOV     r6,r6,LSL r2                  ; r6 = OS height

   REM     "Screen %r5x%r6"

; r3 = OS unit sprite width
; r4 = OS unit sprite height
; r5 = OS unit screen width
; r6 = OS unit screen height

   SUB     r5,r5,#16
   SUB     r6,r6,#16
   SUB     r5,r5,r3
   SUB     r6,r6,r4

; r5, r6 = bottom left of sprite

; *** grab what is currently there
   STMFD   (sp)!,{r5,r6}

   LDRW    r0,`grabx
   TEQ     r0,#0
   BNE     $alreadygrabbed

; claim some space (or ensure there is enough)
   MUL     r2,r3,r4
   MOV     r2,r2,LSL #2 ; multiply by four to be safe ;)
   ADD     r2,r2,#2048 ; plus a bit of breathing space
   BIC     r2,r2,#3    ; and align that

   REM     "Grab: need %r2"

   LDRW    r1,`grablen
   REM     "Currently: %r1"
   CMP     r1,r2
   BGT     $gotenoughroom
   LDRW    r0,`grabbed
   TEQ     r0,#0
   BLNE    release ; lose the old space

   MOV     r0,r2
   BL      claim
   TEQ     r0,#0
   STRWEQ  r0,`grablen
   STRWEQ  r0,`grabbed
   BEQ     $nomemory

   STRW    r0,`grabbed
   STRW    r2,`grablen
   STR     r2,[r0] ; mark the area size
   REM     "Claimed space at %&amp;0"

$gotenoughroom
; got the block... now initialise it
   LDRW    r0,`grabbed
   MOV     r1,#0 ; no sprites
   MOV     r2,#16 ; offset of sprite
   MOV     r7,#16 ; offset of free
   ADD     r0,r0,#4
   STMIA   r0,{r1,r2,r7}

   REM     "Area initialised"

   ADD     r7,r6,r4 ; top
   ADD     r6,r5,r3 ; right
   LDMFD   (sp),{r4,r5} ; bottom, left
   MOV     r0,#&amp;110
   LDRW    r1,`grabbed
   ADR     r2,`grabspr
   MOV     r3,#0 ; no palette
   SWI     "XOS_SpriteOp"
   BVS     $failed

   REM     "Grabbed memory ok"

$alreadygrabbed
   LDMFD   (sp)!,{r2,r3}

; *** plot the sprite
   STRW    r2,`grabx
   STRW    r3,`graby
   LDRW    r0,`sprites
   ADRW    r1,`sprshow
   BL      plotsprite
   BVS     $failed

   BL      restorecontext

; now schedule the removal
   XSWI    "XOS_CallAfter",#delaytime,^removesprite,r12
   XSWI    "XOS_ReadMonotonicTime"
   STRW    r0,`ontime

   LDMFD   (sp)!,{r0-r7,pc}              ; Return from call

; it's already displayed, so re-schedule
$shown
   XSWI    "XOS_RemoveTickerEvent",^removesprite,r12
   XSWI    "XOS_CallAfter",#delaytime,^removesprite,r12
   XSWI    "XOS_ReadMonotonicTime"
   STRW    r0,`ontime
$willbeshownwhenoutofcontext
   LDMFD   (sp)!,{r0-r7,pc}              ; Return from call

$failed
   REM     "Sprite plot failed %E0"
   BL      restorecontext
   LDMFD   (sp)!,{r0-r7,pc}              ; Return from call

$nomemory
   REM     "Could not claim space for grab"
   BL      restorecontext
   LDMFD   (sp)!,{r0-r7,pc}              ; Return from call

.`grabspr
   EQUZA   "grabbed"

; r0-&gt; sprite area
; r1-&gt; sprite name
; r2 = x
; r3 = y
&gt;plotsprite
   STMFD   (sp)!,{r0-r7,link}            ; Stack registers

   REM     "Plotting %$1"

; set up translation table

   LDMIA   sp,{r0,r1}
   ADRW    r4,`colours
   XSWI    "XColourTrans_SelectTable",,,-1,-1,,%00
   BVS     $failed

   REM     "ColourTranslation ok"

; plot sprite

   LMOV    r0,#&amp;134
   LDMIA   sp,{r1,r2,r3,r4}
   REM     "Plot %$2 to %r3,%r4"
   MOV     r5,#8 ; plot with mask
   MOV     r6,#0
   ADRW    r7,`colours
   SWI     "XOS_SpriteOp"
   BVS     $failed
   REM     "Sprite plotted ok"
   XLDMFD  (sp)!,{r0-r7,pc}              ; Return from call
$failed
   REMF    "Plotsprite: %E0"
   XLDMFD  (sp)!,{r0-r7,pc}              ; Return from call

&gt;removesprite
   STMFD   (sp)!,{r0-r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^doremovesprite,r12
   MODE    -svc
   LDMFD   (sp)!,{r0-r1,r8,r9,pc}        ; Return from call

&gt;delayedremovesprite
   STMFD   (sp)!,{r0-r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^doremovesprite,r12
   MODE    -svc
   LDMFD   (sp)!,{r0-r1,r8,r9,pc}        ; Return from call

&gt;doremovesprite
   STMFD   (sp)!,{r0-r3,link}            ; Stack registers

; Check that we have a good graphics context
   SWI     "XTaskWindow_TaskInfo"
   TEQ     r0,#0
   BEQ     $ingoodcontext

; we're not in a good context, so reschedule
   XSWI    "XOS_RemoveCallBack",^delayedremovesprite,r12
   XSWI    "XOS_CallAfter",#shortdelay,^delayedremovesprite,r12
   REM     "-R-"
   B       $willbeshownwhenoutofcontext

; we have a context we can use
$ingoodcontext
   BL      preservecontext

   REM     "Removing sprite"
; ensure we don't know there's a sprite plotted
   MOV     r0,#0
   STRW    r0,`sprshow

; now plot the old sprite
   LDRW    r0,`grabbed
   TEQ     r0,#0
   BEQ     $ohshit

   REM     "Area = %&amp;0"
   ADR     r1,`grabspr

   LDRW    r2,`grabx
   TEQ     r2,#0
   BEQ     $ohshit

   LDRW    r3,`graby
   REM     "Position = %r2,%r3"
   BL      plotsprite
   MOV     r14,#0
   STRW    r14,`grabx
   BVC     $ok
   REM     "Failed to plot %E0"
$ok
$ohshit

   BL      restorecontext
$willbeshownwhenoutofcontext
   LDMFD   (sp)!,{r0-r3,pc}^             ; Return from call

; store the graphics context for restoring later
&gt;preservecontext
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   ADRW    r1,`gc_GWLCol
   XSWI    "XOS_ReadVduVariables",^$`vars
   XSWI    "XOS_Byte",165 ; read text position
   STRW    r1,`gc_textx
   STRW    r2,`gc_texty
   XSWI    "XOS_Byte",117
   STRW    r1,`gc_vdustate
   SWI     &amp;100+26
   TST     r1,#1&lt;&lt;7 ; VDU21 mode ?
   SWINE   &amp;100+6   ; if so, restore output
   TST     r1,#1&lt;&lt;0 ; VDU2 mode ?
   SWINE   &amp;100+3   ; if so, turn off momentarily
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

$`vars
; internal coords
   EQUD &amp;80 ; GWLCol              Graphics Window
   EQUD &amp;81 ; GWBRow
   EQUD &amp;82 ; GWRCol
   EQUD &amp;83 ; GWTRow
   EQUD &amp;84 ; TWLCol              Text Window
   EQUD &amp;85 ; TWBRow
   EQUD &amp;86 ; TWRCol
   EQUD &amp;87 ; TWTRow

; external, but relative to 0,0
   EQUD &amp;88 ; OrgX                x coord of graphics Origin
   EQUD &amp;89 ; OrgY                y coord of graphics Origin

; internal coords
   EQUD &amp;8C ; OlderCsX            Oldest gr. Cursor X coord
   EQUD &amp;8D ; OlderCsY            Oldest gr. Cursor Y coord
   EQUD &amp;8E ; OldCsX              Previous gr. Cursor X coord
   EQUD &amp;8F ; OldCsY              Previous gr. Cursor Y coord
   EQUD &amp;90 ; GCsIX               Graphics Cursor X coord
   EQUD &amp;91 ; GCsIY               Graphics Cursor Y coord

   EQUD -1

&gt;restorecontext
   STMFD   (sp)!,{r0-r6,link}            ; Stack registers

; get the eigen factors so that we can restore the internal coords
   XSWI    "XOS_ReadModeVariable",-1,4   ; read xeig for mode
   MOV     r5,r2                         ; r5 = xeig
   XSWI    "XOS_ReadModeVariable",,5     ; read yeig for mode
   MOV     r6,r2                         ; r6 = yeig

; now restore things in the correct order - first the oldest coord (ic)
   LDRW    r1,`gc_OlderCsX
   LDRW    r2,`gc_OlderCsX
   MOV     r1,r1,LSL r5
   MOV     r2,r2,LSL r6
   XSWI    "XOS_Plot",4                  ; move to older coords

; second the old coord (ic)
   LDRW    r1,`gc_OldCsX
   LDRW    r2,`gc_OldCsX
   MOV     r1,r1,LSL r5
   MOV     r2,r2,LSL r6
   XSWI    "XOS_Plot",4                  ; move to older coords

; third the current coord (ic)
   LDRW    r1,`gc_GCsIX
   LDRW    r2,`gc_GCsIX
   MOV     r1,r1,LSL r5
   MOV     r2,r2,LSL r6
   XSWI    "XOS_Plot",4                  ; move to older coords

; now the graphics window
   LDRW    r1,`gc_GWLCol
   LDRW    r2,`gc_GWBRow
   MOV     r1,r1,LSL r5
   MOV     r2,r2,LSL r6
   SWI     &amp;20100+24 ; set graphics window

   AND     r0,r1,#&amp;FF
   SWI     "XOS_WriteC"
   MOV     r0,r1,LSR #8 ; that's x0
   SWI     "XOS_WriteC"
   AND     r0,r2,#&amp;FF
   SWI     "XOS_WriteC"
   MOV     r0,r2,LSR #8 ; and y0
   SWI     "XOS_WriteC"

   LDRW    r1,`gc_GWRCol
   LDRW    r2,`gc_GWTRow
   MOV     r1,r1,LSL r5
   MOV     r2,r2,LSL r6

   AND     r0,r1,#&amp;FF
   SWI     "XOS_WriteC"
   MOV     r0,r1,LSR #8 ; that's x1
   SWI     "XOS_WriteC"
   AND     r0,r2,#&amp;FF
   SWI     "XOS_WriteC"
   MOV     r0,r2,LSR #8 ; and y1
   SWI     "XOS_WriteC"

; phew - that was fun, wasn't it ? Now the text window (if needed)
   LDRW    r2,`gc_vdustate
   TST     r2,#1&lt;&lt;3
   BEQ     $notextwindow
   SWI     &amp;20100+28 ; set text window
   LDRW    r0,`gc_TWLCol
   SWI     "XOS_WriteC"
   LDRW    r0,`gc_TWBRow
   SWI     "XOS_WriteC"
   LDRW    r0,`gc_TWRCol
   SWI     "XOS_WriteC"
   LDRW    r0,`gc_TWTRow
   SWI     "XOS_WriteC"
$notextwindow

; set the graphics origin
   LDRW    r1,`gc_OrgX
   LDRW    r2,`gc_OrgY
   MOV     r1,r1,LSL r5
   MOV     r2,r2,LSL r6
   SWI     &amp;20100+29 ; set graphics origin

   AND     r0,r1,#&amp;FF
   SWI     "XOS_WriteC"
   MOV     r0,r1,LSR #8 ; that's x0
   SWI     "XOS_WriteC"
   AND     r0,r2,#&amp;FF
   SWI     "XOS_WriteC"
   MOV     r0,r2,LSR #8 ; and y0
   SWI     "XOS_WriteC"

; now set up text position
   SWI     &amp;20100+31
   LDRW    r0,`gc_textx
   SWI     "XOS_WriteC"
   LDRW    r0,`gc_texty
   SWI     "XOS_WriteC"

; and finally the VDU State
   LDRW    r2,`gc_vdustate
   TST     r2,#1&lt;&lt;5
   SWINE   &amp;100+5 ; if needed, switch to VDU 5 mode
   TST     r2,#1&lt;&lt;2
   SWINE   &amp;100+14 ; if needed, switch to VDU 14 mode
   TST     r2,#1&lt;&lt;0
   SWINE   &amp;100+2 ; if needed, switch to VDU 2 mode
   TST     r2,#1&lt;&lt;7
   SWINE   &amp;100+21 ; if needed, switch to VDU 2 mode
   LDMFD   (sp)!,{r0-r6,pc}              ; Return from call


; *******************************************************************
; Subroutine:   keypad
; Description:  Change usage of the keypad
; Parameters:   r0-&gt; command tail
; Returns:      r0-&gt; error if V set
; *******************************************************************
&gt;keypad
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   LDR     r12,[r12]
   SUB     sp,sp,#256
   MOV     r1,r0
   XSWI    "XOS_ReadArgs",^$`syntax,,r13,256
   BVS     $error
   MOV     r3,#-1
   LDR     r0,[r2,#0] ; check on
   TEQ     r0,#0
   MOVNE   r3,r12
   LDR     r0,[r2,#4] ; check off
   TEQ     r0,#0
   MOVNE   r3,#0
   CMP     r3,#-1
   STRWNE  r3,`usekeyv
   BNE     $exit
$error
   LDRW    r3,`usekeyv
   TEQ     r3,#0
   ADREQ   r0,$`off
   ADRNE   r0,$`on
   REMP    "Keypad %$0"
$exit
   ADD     sp,sp,#256
   LDMFD   (sp)!,{r0-r5,pc}^             ; Return from call
$`syntax
   EQUZ    "on/S,off/S"
$`off
   EQUZ    "off"
$`on
   EQUZA   "on"

; #rem on

; *******************************************************************
; Subroutine:   search
; Description:  Search for the next track along
; Parameters:   none
; Returns:      none
; Note:         `search contains the file we looked at last
; *******************************************************************
&gt;search
   LDR     r12,[r12]                     ; read workspace pointer
   STMFD   (sp)!,{r0,link}               ; Stack registers
   MOV     r0,#0
   STRBW   r0,`searchdir                 ; mark us as starting a search
$retry
   BL      dosearch
   LDRBW   r0,`searchdir                 ; are we searching ?
   TEQ     r0,#0
   BEQ     $done
   TEQ     r0,#1
   BNE     $retry
   REMP    "Couldn't find a track to play"
$done
   LDMFD   (sp)!,{r0,pc}                 ; Return from call

&gt;dosearch_call
   STMFD   (sp)!,{r0-r1,r8,r9,link}      ; Stack registers
   MODE    +svc
   XSWI    "XOS_AddCallBack",^dosearch,r12
   MODE    -svc
   LDMFD   (sp)!,{r0-r1,r8,r9,pc}        ; Return from call

&gt;dosearch
   STMFD   (sp)!,{r0-r7,link}            ; Stack registers
   LDRBW   r0,`searchdir                 ; are we searching ?
   TEQ     r0,#1
   BEQ     $nothingtodo
   TEQ     r0,#0
   BNE     $alreadysearching

   SWI     "XAMPlayer_Info"
   BVS     $nothingtodo
   REM     "%c04Play state = %r0"
   TEQ     r0,#2
   TEQNE   r0,#3
   TEQNE   r0,#4
   BNE     $nothingtodo

; we know there's a track playing...
   REM     "Currently playing %$1"
   TEQ     r2,#0
   BEQ     $nothingtodo

; is there one queued ?
   LDR     r0,[r2,#0]
   TST     r0,#1&lt;&lt;5
   BNE     $nothingtodo                  ; we've already got a queued entry

   REM     "Search starting..."

; start a search - set our max file counter
   MOV     r0,#40
   STRW    r0,`searchcnt

; now copy things to the right place
   MOV     r0,r1
   ADRW    r1,`searchdir
   BL      strcpy                        ; searchdir = file playing

   MOV     r0,r1
   BL      findlastdot                   ; find the last . in it
   TEQ     r0,#0
   BEQ     $canthandle
   MOV     r1,#0
   STRB    r1,[r0],#1                    ; terminate dir, and move to file

   ADRW    r1,`searchname
   BL      strcpy

$alreadysearching
; `searchdir = the directory we are in
; `searchname = the last file we looked at

; 0. check we've not exceeded the max files to search
   LDRW    r0,`searchcnt
   CMP     r0,#0
   BLE     $canthandle
   REM     "Entries left to go = %r0"

; 1. find the file in the directory
; 2. look for the next file along
; [ we now do these operations together ]
   MOV     r4,#0                         ; first call
   MOV     r7,#0                         ; is this the entry we're looking
                                         ; for ? (when we match, we set it
                                         ; to 1)

$findfileloop
   ADRW    r1,`searchdir
   ADRW    r2,`searchws
   MOV     r3,#256
   MOV     r5,#256
   MOV     r6,#0                         ; files *
   XSWI    "XOS_GBPB",12
   BVS     $canthandle

   TEQ     r3,#0
   BEQ     $nothingread

$checknextloop
   TEQ     r7,#0
   BEQ     $lookingforcurrent

; look at the next entry - check that it's one we can handle
   LDR     r1,[r2,#16]                   ; object type
   TST     r1,#2                         ; is it a dir ?
   BNE     $godowndir

   LDRW    r0,`searchcnt
   SUB     r0,r0,#1
   STRW    r0,`searchcnt

; it's a file - is it an MP3 ?
   LDR     r14,[r2,#20]                  ; object type
   SUB     r14,r14,#&amp;AD
   TEQ     r14,#&amp;100                     ; is it &amp;1ad ?
   ADDNE   r1,r2,#24                     ; r1-&gt; filename
   BNE     $notmatchedyet                ; nope - so go on

; we need to build up a full pathname...
   ADRW    r0,`searchdir
   BL      strlen
   MOV     r14,#ASC(".")
   STRB    r14,[r0,r1]!
   ADD     r1,r0,#1
   ADD     r0,r2,#24
   BL      strcpy
; now queue it
   ADRW    r1,`searchdir
$foundfile
   REM     "Found file to play next %$1"
   XSWI    "XAMPlayer_Play",%1
   BVS     $canthandle
   MOV     r0,#0
   STRBW   r0,`searchdir     ; mark as not searching yet

   LDR     r0,$`que
   BL      showsprite
   B       $done

; stuff to look for the 'current' file
$lookingforcurrent
   ADRW    r0,`searchname
   ADD     r1,r2,#24                     ; filename in dir
   REM     "Comparing %$0 and %$1"
   BL      cmpstringi
   BNE     $notmatchedyet
; we've found the current file
   MOV     r7,#1
   ADRW    r0,`searchdir
   REM     "Yay, found it in entry block ending %r4 in %$0"

$notmatchedyet
; not found, so look at the next in the directory
   MOV     r0,r1
   BL      strlen
   REM     "Skipping %r1 characters @ %&amp;0"
   ADD     r0,r0,r1
   ADD     r0,r0,#4
   BIC     r2,r0,#3
   SUBS    r3,r3,#1
   BNE     $checknextloop

$nothingread
   TEQ     r7,#1
   BNE     $nextfile_findcurrent
   LDRW    r0,`searchcnt
   SUBS    r0,r0,#1
   STRW    r0,`searchcnt
;    SWI     "XHourglass_Percentage"
;    MOVS    r0,r0
   BMI     $canthandle                   ; ran out of files

   REM     "[find next] Next seqno = %r4"
   CMN     r4,#1                         ; -1 = end of list
   BNE     $findfileloop
   B       $reachedendofdir

$nextfile_findcurrent
   REM     "[find current] Next seqno = %r4"
   CMN     r4,#1                         ; -1 = end of list
   BNE     $findfileloop

; we've reached the end of the directory looking for the file - help!
   B       $canthandle



; we found a directory - we ought to go down it!
$godowndir
   ADRW    r0,`searchdir
   BL      strlen
   MOV     r14,#ASC(".")
   STRB    r14,[r0,r1]!
   ADD     r1,r0,#1
   ADD     r0,r2,#24
   BL      strcpy
   MOV     r4,#0
   B       $findfileloop

$reachedendofdir
; we've not found anything - go up a directory
   REM     "End of dir, checking queued album"

   LDRBW   r0,`albumqueue
   TEQ     r0,#0
   BEQ     $noalbumqueued
   ADRW    r0,`albumqueue
   ADRW    r1,`searchdir
   BL      strcpy
   MOV     r0,#0
   STRBW   r0,`albumqueue                ; no longer an album queued
   B       $foundfile

$noalbumqueued
   REM     "No album queued, going up"

   ADRW    r0,`searchdir
   BL      findlastdot
   TEQ     r0,#0
   BEQ     $canthandle

   MOV     r1,#0
   STRB    r1,[r0],#1                    ; terminate and skip

   ADRW    r1,`searchname
   BL      strcpy

   LADR    r1,dosearch_call
   XSWI    "XOS_CallAfter",#dirscantime,,r12
   B       $done                         ; we can't find anything - wait

$nothingtodo
$done
   LDMFD   (sp)!,{r0-r7,pc}              ; Return from call

$canthandle
   REM     "Help, no I can't handle it"
   MOV     r0,#1
   STRBW   r0,`searchdir
   B       $nothingtodo

$`que
   EQUZA   "que"


; *******************************************************************
; Subroutine:   findlastdot
; Description:  Find the last . in a string
; Parameters:   r0-&gt; string
; Returns:      r0-&gt; . or 0 if not there
; *******************************************************************
&gt;findlastdot
   STMFD   (sp)!,{r1,link}            ; Stack registers
   MOV     r1,#0
$loop
   LDRB    r14,[r0],#1
   TEQ     r14,#ASC(".")
   SUBEQ   r1,r0,#1
   TEQ     r14,#0
   BNE     $loop
   MOV     r0,r1
   LDMFD   (sp)!,{r1,pc}              ; Return from call


; *******************************************************************
; Subroutine:   postfilter
; Description:  Post filter wimp events
; Parameters:   as Wimp_Poll
; Returns:      none
; *******************************************************************
&gt;postfilter
   TEQ     r0,#17
   TEQNE   r0,#18
   MOVNE   pc,link
   STMFD   (sp)!,{r0-r6,link}            ; Stack registers
   LDR     r0,[r1,#16]
;    REM     "%c04Postfilter message, %&amp;0"
   TEQ     r0,#5                         ; DataOpen
   BNE     $exit
   LDR     r0,[r1,#40]
   REM     "%c04Postfilter dataopen, type %&amp;0"
   ADD     r0,r0,#1
   TEQ     r0,#&amp;1000
   BNE     $exit
   ADD     r1,r1,#44
   REM     "%c04Reading details for %$1"
   XSWI    "XOS_File",17
   BVS     $exit
   TEQ     r0,#1
   BNE     $exit      ; MUST be a file
   MOV     r6,r0
   XSWI    "XOS_FSControl",38
   BVS     $exit
   REM     "%c04File type is %&amp;2"
   EOR     r2,r2,#&amp;AD
   TEQ     r2,#&amp;100
   BNE     $exit
; Ok, we now know that someone has shift-double clicked an AMPEG file
; by knowing that these appear as text loading types but really have
; the filetype of &amp;1AD.
   MOV     r6,r1                         ; hang on to the filename
   XSWI    "XOS_Byte",&amp;81,1 EOR &amp;FF,&amp;FF
   TEQ     r1,#255
   BEQ     $queuealbum                   ; they pressed ctrl, so queue album
   XSWI    "XAMPlayer_Play",%01,r6
   BVS     $exit

   REM     "%c04Queued"

   LDR     r0,$`que
   BL      showsprite

$ackmessage
   SUB     r1,r1,#44
   LDR     r2,[r1,#4]
   LDR     r0,[r1,#8]
   STR     r0,[r1,#12]
   XSWI    "XWimp_SendMessage",19

   MVN     r0,#NOT -1
   STR     r0,[sp,#0]

$exit
   LDMFD   (sp)!,{r0-r6,pc}              ; Return from call

$queuealbum
   REM     "%c04Queing album %$6"
   ADRW    r1,`albumqueue
   XBL     strcpy,r6
   MOV     r1,r6

   LDR     r0,$`qua
   BL      showsprite

   B       $ackmessage

$`que
   EQUZA   "que"
$`qua
   EQUZA   "qua"

#Library "memory",claim.release
#library "strings",strcpy.strlen.cmpstringi
#here libraries

#post
REM #run &lt;CODE&gt;
#end

DEFPROCtest
PROCinitvols
DIM mem% 256,mem2% 256
O%=mem%
PRINTFNchangevol(1)
O%=mem2%
PRINTFNchangevol(-1)

start%=0:last%=0
light%=0
MODE MODE
:
REM Up
GCOL 255,255,255
MOVE 0,0
REPEAT
 last%=start%
 start%=mem%?start%
 light%=mem%?(start%+128)/4
 PRINTstart%,light%
 DRAW light%*64,start%*8
UNTIL start%=last%
:
REM Down
GCOL 255,255,255
MOVE 0,0
REPEAT
 last%=start%
 start%=mem2%?start%
 light%=mem2%?(start%+128)/4
 PRINTstart%,light%
 DRAW light%*64,start%*8
UNTIL start%=last%
:
REM Up
GCOL 255,255,255
MOVE 0,0
REPEAT
 last%=start%
 start%=mem%?start%
 light%=mem%?(start%+128)/4
 PRINTstart%,light%
 DRAW light%*64,start%*8
UNTIL start%=last%
:
PRINT
GCOL 255,255,0
MOVE 0,0
factor=8
scale=(factor+1)/factor
FORlight=0TO15
 start%=((factor^(light/15)-1)*scale)*128/factor
 REM PRINTlight,start%
 DRAW light*64,start%*8
NEXT
:
GCOL 0,255,0
MOVE 0,0
FORI=0TO127
 light=Lamp%?I
 DRAW light*64,I*8
NEXT
END
ENDPROC
:
REM Many thanks to Thomas Olsson
DEFPROCinitvols
IF oldstyle% THEN
 DIM Lamp% 256
 FORL%=0TO15
  READdB%
  B%=219+dB%*6
  IFB%&lt;0B%=0
  FORI%=B%TO255:Lamp%?I%=L%:NEXT
 NEXT
 FORI%=0TO255:PRINTLamp%?I%,I%:NEXT
ELSE
 DIM Lamp% 128
 REM 8 approximates Zappo's code
 factor=8
 scale=(factor+1)/factor
 FORL%=1TO15
  B%=((factor^(L%/15)-1)*scale)*128/factor
  IF L%=1 THENB%=0
  FORI%=B%TO128:Lamp%?I%=L%:NEXT
 NEXT
 REM FORI%=0TO127:PRINTLamp%?I%,I%:NEXT
ENDIF
ENDPROC
:
DATA -42,-36,-33,-30,-27,-24,-21,-18,-15,-12,-9,-6,-4,-2,-1,0
:
DEFFNchangevol(C%)
IF oldstyle% THEN
 REM Once for each of the volumes to scale it...
 FOR I=0TO127
  D%=219+120*LOG((I+1)/128):IFD%&lt;0D%=0
  L%=Lamp%?D%+C%
  IFL%&lt;0L%=0
  IFL%&gt;15L%=15
  FORI%=255TO0STEP-1
   IFLamp%?I%=L%D%=I%:I%=0
  NEXT
  V%=128*10^((D%-219)/120)-.5
  IFV%&gt;127V%=127
  IFV%&lt;0V%=0
  ?O%=V%:O%+=1:P%+=1
 NEXT
 REM And then once for the LEDs to use (for the sprite)
 FOR I=0TO127
  D%=219+120*LOG((I+1)/128):IFD%&lt;0THEND%=0
  L%=Lamp%?D%+C%
  IFL%&lt;1L%=1 ELSEIFL%&gt;15L%=15
  ?O%=L%*4:O%+=1:P%+=1
 NEXT
ELSE
 os%=O%
 FOR I=0TO127
  L%=Lamp%?I+C%
  IF L%&lt;1 THENL%=1 ELSEIFL%&gt;15 THENL%=15
  FORI%=127TO0STEP-1
   IFLamp%?I%=L%D%=I%:I%=0
  NEXT
  REM PRINT I;" -&gt; ";D%;" (";L%;")"
  ?O%=D%:O%+=1:P%+=1
 NEXT
 FOR I=0TO127
  D%=os%?I
  L%=Lamp%?D%
  IFL%&lt;1L%=1 ELSEIFL%&gt;15L%=15
  ?O%=L%*4:O%+=1:P%+=1
 NEXT
ENDIF
=0
</textarea>

<hr/>

<textarea class='source-code'>
In   -
Out  test
Type Module
Ver  1.03d

{
  &amp;123458    null
  &amp;123459    null
  &amp;12345a    null
  &amp;12345b    null
}

Define Module
 Name      JFS
 Author    Justin Fletcher
 PostFilter
  Name     TestFilter
  Task     -
  Mask     0
  Code     MouseClick    click
  Code     unknown
 End PostFilter
 Services
  Error      null
  &amp;902C0     null
  &amp;902C1     null
  &amp;903BF     null
  &amp;912D0     null
  &amp;123456    null
  &amp;123457    null
  &amp;1234560   null
  &amp;1234561   null
  &amp;08510000  null
  &amp;08511000  null
  &amp;08511001  null
  &amp;08511101  null
 End Services
 Init      test
 Resources
  run!     and.hide
  !Help    Apps.My!Help
 End Resources
 SWIs
  Prefix   test
  Base     &amp;8000
   0       code   null
 End SWIs
 ImageFS
  Type     &amp;123
  Open     open
  Close    close
  Args     args
  Get      get
  Put      put
  Func     func
  File     file
  Flags    -TellWhenFlushing
 End ImageFS
 FS
  Name     JFS
  Startup  JFS
  Number   88
  Files    Infinite
  Flags    ReadOnly NoDirs
 End FS
End Module

Define Macros
 Command WIBBLE
 CONDS   Never
 Mask    @ra, @rb
 Code
    ADD     @ra, @rb, #66
 End Code
End Macros

; imagefs stuff
&gt;open
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "Open"
   MOV     r0,#0                         ; unable to open
   STR     r0,[sp,#4]                    ; store as r1
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;close
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "Close"
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;func
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "Func"
   CMP     r0,#14                        ; is it read entries ?
   CMPNE   r0,#15                        ; is it read entries with info?
   BEQ     $readentries
$readentries
   MOV     r0,#0                         ; no entries
   STR     r0,[sp,#4*3]                  ; store as r3
   MVN     r0,#NOT -1                    ; end of list
   STR     r0,[sp,#4*4]                  ; store as r4
$exit
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;args
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "args"
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;get
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "Get"
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;put
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "Put"
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;file
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "File"
   CMP     r0,#0                         ; is it save file ?
   BEQ     $save
   CMP     r0,#1                         ; is it write cat info ?
   BEQ     $writecatinfo
   CMP     r0,#5                         ; is it read cat info ?
   BEQ     $readcatinfo
   B       $exit

$readcatinfo
   MOV     r0,#0                         ; doesn't exist
   STR     r0,[sp,#0]                    ; store as r0
$save
$writecatinfo
$exit
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

.null
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "MyNull"
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;click
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
;    SWI     &amp;107
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

&gt;unknown
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   REM     "%c04%c30Unknown reason code %r0"
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

.test
   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
   ADR     r2,$`error+4
   ADR     r0,$`error
   REM     "%E0"
   MOV     r0,#0
   CMP     r0,#0
   MOV     r3,link
   MOV     r1,pc
   AND     r1,r1,#&amp;FC000003
   REM     "Flags = %&amp;1 %&amp;3 %$2"
   MOV     r3,link
   MOV     r1,pc
   AND     r1,r1,#&amp;FC000003
   REM     "Flags = %&amp;1 %&amp;3 %$2"
   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call

$`error
   EQUD    &amp;657
   EQUZA   "Test message"

   EQUZA   "TEST CODE (RAS)"
   RAS     r1,r2,#4
   EQUZA   "TEST CODE (CAS)"
   CAS     r1,r2,#4,#16                   ; specifying length (no r0's)
   EQUZA   "TEST CODE (CAS2)"
   CAS     r0,r2,#4,#16                   ; specifying length (r0 as rx)
   EQUZA   "TEST CODE (CAS3)"
   CAS     r1,r0,#4,#16                   ; specifying length (r0 as ry)
   EQUZA   "TEST CODE (CAS4)"
   CAS     r1,r0,#4,#16,claim             ; length and claimer

&gt;er
   ERR     99,"error"

#Library "Memory",claim
#Here Libraries
</textarea>


<span id='HELLO'>^^^^ WARNING: HELLO!</span>
</page>
</body>
</html>
