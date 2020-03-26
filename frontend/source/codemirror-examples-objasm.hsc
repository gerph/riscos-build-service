<!DOCTYPE html>
<html>
<html-header title='Colouring Example (objasm)' codecolouring>
<script type='text/javascript'>
<!--
    loaded = false;
    function onload() {
        if (loaded)
            return;
        loaded = true;
        if (1) {
            setup_colouring({autosize: false, linenumbers: true, scroll: true, mode: 'text/x-arm-objasm'});
        }
    }
    -->
</script>
</html-header>
<body onload='onload();'>
    <page section='Colouring ObjAsm'>
    <textarea class='source-code'>
        SUBT    =&gt; SysDAs

; System Dynamic Areas

   [ DAforFixedAreas

; DA Handler which rejects everything
DynAreaHandler_ROM         * DynAreaHandler_NoChange
DynAreaHandler_SWIDispatch * DynAreaHandler_NoChange
DynAreaHandler_SVCStack    * DynAreaHandler_NoChange
DynAreaHandler_IRQStack    * DynAreaHandler_NoChange
DynAreaHandler_UNDStack    * DynAreaHandler_NoChange
DynAreaHandler_L2PT        * DynAreaHandler_NoChange
DynAreaHandler_SoftCam     * DynAreaHandler_NoChange
DynAreaHandler_PageZero    * DynAreaHandler_NoChange
DynAreaHandler_SystemInit  * DynAreaHandler_NoChange

DynAreaHandler_NoChange SIGNATURE
        TEQ     r0, #DAHandler_PreGrow
        TEQNE   r0, #DAHandler_PreShrink
        MOVEQ   r0, #0
        ADRNE   r0, DynAreaHandler_CannotChange
        SETV
        MOV     pc, lr

DynAreaHandler_CannotChange
        DCD     ErrorNumber_ChDynamNotAllMoved
        =       "Operation not permitted on system dynamic area",0
        ALIGN


InitROMSpaceTable
        &amp;       ChangeDyn_ROM                   ; number
        &amp;       ROM                             ; base address
        &amp;       AP_ROM                          ; flags
        &amp;       OSROM_ImageSize*1024            ; init size
        &amp;       OSROM_ImageSize*1024            ; max size
        &amp;       0                               ; no workspace needed
        &amp;       DynAreaHandler_ROM              ; our handler
        &amp;       DAROMString                     ; title

InitSVCStackSpaceTable
        &amp;       ChangeDyn_SVCStack              ; number
        &amp;       SVCStackBase                    ; base address
        &amp;       AP_SVCStack                     ; flags
        &amp;       SVCStackSize                    ; init size
        &amp;       SVCStackSize                    ; max size
        &amp;       0                               ; no workspace needed
        &amp;       DynAreaHandler_SVCStack         ; our handler
        &amp;       DASVCStackString                ; title

InitIRQStackSpaceTable
        &amp;       ChangeDyn_IRQStack              ; number
        &amp;       IRQStackBase                    ; base address
        &amp;       AP_IRQStack                     ; flags
        &amp;       IRQStackSize                    ; init size
        &amp;       IRQStackSize                    ; max size
        &amp;       0                               ; no workspace needed
        &amp;       DynAreaHandler_IRQStack         ; our handler
        &amp;       DAIRQStackString                ; title

InitUNDStackSpaceTable
        &amp;       ChangeDyn_UNDStack              ; number
        &amp;       UNDStackBase                    ; base address
        &amp;       AP_UNDStack                     ; flags
        &amp;       UNDStackSize                    ; init size
        &amp;       UNDStackSize                    ; max size
        &amp;       0                               ; no workspace needed
        &amp;       DynAreaHandler_UNDStack         ; our handler
        &amp;       DAUNDStackString                ; title

InitSWIDispatchSpaceTable
        &amp;       ChangeDyn_SWIDispatch           ; number
        &amp;       SWIDispatchBase                 ; base address
        &amp;       AP_SWIDispatch                  ; flags
        &amp;       SWIDispatchSize                 ; init size
        &amp;       SWIDispatchSize                 ; max size
        &amp;       0                               ; no workspace needed
        &amp;       DynAreaHandler_SWIDispatch      ; our handler
        &amp;       DASWIDispatchString             ; title

InitL2PTSpaceTable
        &amp;       ChangeDyn_L2PT                  ; number
        &amp;       L2PT                            ; base address
        &amp;       AP_L2PT                         ; flags
        &amp;       0                               ; init size
        &amp;       4*1024*1024                     ; max size
        &amp;       0                               ; no workspace needed
        &amp;       DynAreaHandler_L2PT             ; our handler
        &amp;       DAL2PTString                    ; title

InitSoftCamSpaceTable
        &amp;       ChangeDyn_SoftCam               ; number
        &amp;       SoftCamBase                     ; base address
        &amp;       AP_SoftCam                      ; flags
        &amp;       0                               ; init size
        &amp;       SoftCamMaxSize                  ; max size
        &amp;       0                               ; no workspace needed
        &amp;       DynAreaHandler_SoftCam          ; our handler
        &amp;       DASoftCamString                 ; title

   [ PageZeroDA
InitPageZeroSpaceTable
        &amp;       ChangeDyn_PageZero              ; number
        &amp;       0                               ; base address
        &amp;       AP_PageZero                     ; flags
        &amp;       &amp;8000                           ; init size
        &amp;       &amp;8000                           ; max size
        &amp;       0                               ; no workspace needed
        &amp;       DynAreaHandler_PageZero         ; our handler
        &amp;       DAPageZeroString                ; title
   ]

InitSystemInitSpaceTable
        &amp;       ChangeDyn_SystemInit            ; number
        &amp;       SystemInitWSBase                ; base address
        &amp;       AP_SystemInit                   ; flags
        &amp;       0                               ; init size
        &amp;       SystemInitWSSize                ; max size
        &amp;       0                               ; no workspace needed
        &amp;       DynAreaHandler_SystemInit       ; our handler
        &amp;       DASystemInitString              ; title

DAROMString
        =       "OS: ROM", 0
DASWIDispatchString
        =       "OS: SWI dispatcher", 0
DASVCStackString
        =       "OS: SVC stack", 0
DAIRQStackString
        =       "OS: IRQ stack", 0
DAUNDStackString
        =       "OS: UND stack", 0
DAL2PTString
        =       "OS: Processor page tables", 0
DASoftCamString
        =       "OS: OS page tables", 0
   [ PageZeroDA
DAPageZeroString
        =       "OS: Page zero", 0
   ]
DASystemInitString
        =       "OS: SystemInit workspace", 0
        ALIGN


; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; InitDA_FixedAreas
; Initialise the fixed dynamic areas
; In:  none
; Out: none
InitDA_FixedAreas SIGNATURE
        Entry   "r0"

        ADR     r0, InitROMSpaceTable
        BL      DynArea_DirectInitArea

        ADR     r0, InitSWIDispatchSpaceTable
        BL      DynArea_DirectInitArea

        ADR     r0, InitSVCStackSpaceTable
        BL      DynArea_DirectInitArea

        ADR     r0, InitIRQStackSpaceTable
        BL      DynArea_DirectInitArea

        ADR     r0, InitUNDStackSpaceTable
        BL      DynArea_DirectInitArea

        ADR     r0, InitL2PTSpaceTable
        BL      DynArea_DirectInitArea

        ADR     r0, InitSoftCamSpaceTable
        BL      DynArea_DirectInitArea
; Fix up the node to use the correct size
        MOV     r14, #0
        LDR     r14, [r14, #MaxCamEntry]
        MOV     r14, r14, LSL #3             ; *8 (2 words per entry)
        LDR     r0, =PageSize-1
        ADD     r14, r14, r0
        BIC     r14, r14, r0
        STR     r14, [r2, #DANode_Size]

   [ PageZeroDA
        ADR     r0, InitPageZeroSpaceTable
        BL      DynArea_DirectInitArea
   ]

        ADR     r0, InitSystemInitSpaceTable
        BL      DynArea_DirectInitArea

        EXIT

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; DynArea_DirectInitArea
; Initialise the ROM dynamic area
; In:  R0-&gt; our table of initialisation values
; Out: R2-&gt; node allocated
DynArea_DirectInitArea
        Entry   "r0-r1,r3-r10"
    [ DebugAny
        LDR     lr, [r0, #7*4]
        Debug_WriteF "DynArea_DirectInitArea: %$E\n"
    ]

; Our string won't actually be pointed to by this node (use the static string)
        MOV     r3, #DANode_NodeSize
        BL      ClaimSysHeapNode                ; out: r2 -&gt; node
        BVS     %FT90

; Initialise the node
        LDR     r0, [sp, #Proc_RegOffset]
        LDMIA   r0, {r0-r1,r3-r8}
        STMIB   r2, {r0-r1,r3-r8}
        Debug_WriteF "  area = %r0, base = %&amp;1, flags = %&amp;3, init/max=%&amp;4/%&amp;5\n"
        Debug_WriteF "  ws = %&amp;6, handler = %&amp;7, name = %$8\n"
        ASSERT  DANode_Title = 8*4
        MOV     r14, #0
        STR     r14, [r2, #DANode_SubLink]     ; NEVER shrinkable area
        STR     r14, [r2, #DANode_SparseHWM]   ; NEVER sparse area
        ; SortLink needs initialising
        STR     r14, [r2, #DANode_LockCode]    ; No lock code (but still locked)
        STR     r14, [r2, #DANode_Domain]      ; NEVER domain area

; Now we need to link it
        BL      DynArea_PutAreaOnList
  [ DynArea_QuickHandles
        BL      DynArea_PutOnAlphaList
        BL      DynArea_UpdateQuickHandles
  ]
        EXIT

90
    [ DebugAny
        ADD     lr, r0, #4
        Debug_WriteF "DynArea_DirectInitArea: failed %$E\n"
    ]
        STR     r0, [sp]
        EXIT                                    ; errors should
   ]

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; InitDA_RMA
; Initialise the RMA dynamic area
; In:  none
; Out: none

InitDA_RMA SIGNATURE
        Entry   "r0-r12"
        MOV     r1, #ChangeDyn_RMA      ; Area number
        MOV     r2, #4096               ; Initial size
        LDR     r3, =RMAAddress         ; Base address
        MOV     r4, #AP_RMA             ; Area flags
        LDR     r5, =RMAMaxSize         ; Maximum size
        ADRL    r6, DynAreaHandler_RMA  ; Pointer to handler
        MOV     r7, r3                  ; Workspace ptr points at area itself
        ADRL    r8, AreaName_RMA        ; Title string - node will have to be reallocated
                                        ; after module init, to internationalise it
        BL      DynArea_Create          ; ignore any error, we're stuffed if we get one!
        EXIT

;
;       DynAreaHandler_SysHeap - Dynamic area handler for system heap
;       DynAreaHandler_RMA     - Dynamic area handler for RMA
;
; in:   r0 = reason code (0=&gt;pre-grow, 1=&gt;post-grow, 2=&gt;pre-shrink, 3=&gt;post-shrink)
;       r12 -&gt; base of area
;

DynAreaHandler_SysHeap SIGNATURE
DynAreaHandler_RMA
        ROUT
        CMP     r0, #4
        ADDCC   pc, pc, r0, LSL #2
        B       UnknownHandlerError
        B       PreGrow_Heap
        B       PostGrow_Heap
        B       PreShrink_Heap
        B       PostShrink_Heap

PostGrow_Heap SIGNATURE
PostShrink_Heap
        STR     r4, [r12, #:INDEX:hpdend] ; store new size

; and drop thru to...

PreGrow_Heap
        CLRV                            ; don't need to do anything here
        MOV     pc, lr                  ; so just exit

PreShrink_Heap SIGNATURE
        Entry   "r0"
        PHPSEI  lr                      ; disable IRQs round this bit
        LDR     r0, [r12, #:INDEX:hpdbase]      ; get minimum size
        SUB     r0, r4, r0              ; r0 = current-minimum = max shrink
        CMP     r3, r0                  ; if requested shrink &gt; max
        MOVHI   r3, r0                  ; then limit it
        SUB     r0, r5, #1              ; r0 = page mask
        BIC     r3, r3, r0              ; round size change down to page multiple
        SUB     r0, r4, r3              ; area size after shrink
        STR     r0, [r12, #:INDEX:hpdend] ; update size

        PLP     lr                      ; restore IRQ status
        CLRV
        EXIT

AreaName_RMA
        =       "OS: Module area", 0
AreaName_Kbuffs
        =       "OS: Kernel buffers", 0
  [ ReadOnlyModules
AreaName_RMA2
        =       "OS: RO module area", 0
  ]
        ALIGN

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; InitDA_RMA2
; Initialise the Read Only Module Area  dynamic area
; In:  none
; Out: none

  [ ReadOnlyModules
InitDA_RMA2 SIGNATURE
        Entry   "r0-r12"
        MOV     r1, #ChangeDyn_RMA2     ; Area number
        MOV     r2, #0                  ; Initial size
        MOV     r3, #RMA2Address        ; Base address
        MOV     r4, #AP_RMA2            ; Area flags
        MOV     r5, #RMA2MaxSize        ; Maximum size
        ADRL    r6, DynAreaHandler_RMA2 ; Pointer to handler
        MOV     r7, r3                  ; Workspace ptr points at area itself
        ADRL    r8, AreaName_RMA2       ; Title string - node will have to be reallocated
                                        ; after module init, to internationalise it
        BL      DynArea_Create          ; ignore any error, we're stuffed if we get one!
        EXIT

;       DynAreaHandler_RMA2     - Dynamic area handler for RMA2
;
; in:   r0 = reason code (0=&gt;pre-grow, 1=&gt;post-grow, 2=&gt;pre-shrink, 3=&gt;post-shrink)
;       r12 -&gt; base of area
;

DynAreaHandler_RMA2  SIGNATURE
        ROUT
        CMP     r0, #4
        ADDCC   pc, pc, r0, LSL #2
        B       UnknownHandlerError
        B       PreGrow_RMA2
        B       PostGrow_RMA2
        B       PreShrink_RMA2
        B       PostShrink_RMA2

PostGrow_RMA2
PostShrink_RMA2
PreGrow_RMA2
PreShrink_RMA2
        CLRV                            ; don't need to do anything here
        MOV     pc, lr                  ; so just exit

  ]


; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; InitDA_KernelBuffers
; Initialise the kernel buffers dynamic area
; In:  none
; Out: none

InitDA_KernelBuffers SIGNATURE
        ;sort out the Kernel buffers dynamic area
        Entry   "r0-r12"
        MOV     r1, #ChangeDyn_Kbuffs   ; Area number
        LDR     r2, =KbuffsSize         ; Initial (and in fact permanent) size
        LDR     r3, =KbuffsBaseAddress  ; Base address
        MOV     r4, #AP_Kbuffs          ; Area flags
        MOV     r5, #KbuffsMaxSize      ; Maximum size
        MOV     r6, #0                  ; no handler
        MOV     r7, #0
        ADRL    r8, AreaName_Kbuffs     ; Title string - node will have to be reallocated
                                        ; after module init, to internationalise it
        BL      DynArea_Create          ; ignore any error, we're stuffed if we get one!
        EXIT



  [ AbortSVCStackCopy
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; InitDA_AbortSVCStackCopy
; Initialise the area we use to dump SVC aborts
; In:  none
; Out: none
InitDA_AbortSVCStackCopy SIGNATURE
        Entry    "r0-r8"
        MOV      r0,#DAReason_Create
        MOV      r1,#ChangeDyn_AbortStackCopy
        LDR      r2,=SVCStackSize + IRQStackSize
        MOV      r3,#-1
        LDR      r4,=AP_AbortStackCopy
        MOV      r5,r2
        MOV      r6,#0
        MOV      r7,#0
        ADRL     r8,AbortStackCopy_DAname
        SWI      XOS_DynamicArea                ;create the DA area for rescueing VRAM pages in use
        MOVVS    r1, #0
        MOVVS    r3, #0
        MOV      r14, #0
        STR      r1, [r14, #SVCStackCopyDA]
        STR      r3, [r14, #SVCStackCopyAddress]
        EXIT

AbortStackCopy_DAname
        =        "OS: SVC/IRQ stack copy",0
        ALIGN
  ]

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; InitDA_SysHeapResize
; Resize the system heap according to the CMOS settings.
; In:  none
; Out: none
InitDA_SysHeapResize SIGNATURE
        Entry
        MOV     R0, #0                  ; shrink sysheap as far as will go.
        SUB     R1, R0, #4*1024*1024
        SWI     XOS_ChangeDynamicArea
        MOV     R0, #ReadCMOS
        MOV     R1, #SysHeapCMOS
        SWI     XOS_Byte
        AND     R2, R2, #2_111111       ; mask to same size as status
        MOV     R3, R2, LSL #PageSizeShift ; size spare wanted
        BL      ClaimSysHeapNode
        MOV     R0, #HeapReason_Free
        SWI     XOS_Heap
        EXIT

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; InitDA_AppSpaceUpdate
; Update the application space to reflect the current state of the system
; during initialisation
; In:  none
; Out: none
InitDA_AppSpaceUpdate SIGNATURE
        Entry
        LDR     R0, =(AplWorkMaxSize-32*1024):SHR:12    ; maximum number of pages in aplspace
        MOV     R3, #32*1024            ; aplwork start
        LDR     R1, =AplWorkSize        ; aplwork size
        MOV     r11, #AP_AppSpace
        Debug_WriteF "Extending application space from FreePool\n"
        BL      ExtendDAFromFreePool    ; put as much as possible in aplspace

; forcibly indicate that the memory is there - no need for vectors as we have no modules yet
        MOV     R0, #0
        LDR     R1, [R0, #AplWorkSize]
        ADD     R1, R1, #32*1024
        STR     R1, [R0, #AplWorkSize]
        STREnv  R1, MemLimit
        EXIT

        END
</textarea>
<hr/>
    <textarea class='source-code'>
;
; OS_Memory constants
;
                                              ^ 0
OSMemoryReason_Convert                        # 1 ; 0
OSMemoryReason_Reserved                       # 5 ; 1,2,3,4,5
OSMemoryReason_ReadPhysicalTableSize          # 1 ; 6 ; deprecated
OSMemoryReason_ReadPhysicalTable              # 1 ; 7 ; deprecated
OSMemoryReason_Amounts                        # 1 ; 8
OSMemoryReason_IOSpace                        # 1 ; 9
OSMemoryReason_LockFreePool                   # 1 ; 10
OSMemoryReason_Reserved11                     # 1 ; 11
OSMemoryReason_RecommendPage                  # 1 ; 12
OSMemoryReason_Reserved13                     # 4 ; 13,14,15,16
OSMemoryReason_Reserved17                     # 7 ; 17,18,19,20,21,22,23
OSMemoryReason_ValidateAccess                 # 1 ; 24
OSMemoryReason_IOSpacePhysical                # 1 ; 25


; OS_Memory 0 flags
OSMemoryReason_Convert_PPNProvided            * (1&lt;&lt;8)
OSMemoryReason_Convert_LogProvided            * (1&lt;&lt;9)
OSMemoryReason_Convert_PhyProvided            * (1&lt;&lt;10)
OSMemoryReason_Convert_PPNRequired            * (1&lt;&lt;11)
OSMemoryReason_Convert_LogRequired            * (1&lt;&lt;12)
OSMemoryReason_Convert_PhyRequired            * (1&lt;&lt;13)
OSMemoryReason_Convert_CacheUnchanged         * (0&lt;&lt;14)
                                              ; (1&lt;&lt;14) = unchanged
OSMemoryReason_Convert_CacheDisable           * (2&lt;&lt;14)
OSMemoryReason_Convert_CacheEnable            * (3&lt;&lt;14)


; OS_Memory 8 types
OSMemoryReason_Amounts_DRAM                   * (1&lt;&lt;8)
OSMemoryReason_Amounts_VRAM                   * (2&lt;&lt;8)
OSMemoryReason_Amounts_ROM                    * (3&lt;&lt;8)
OSMemoryReason_Amounts_IOSpace                * (4&lt;&lt;8)
OSMemoryReason_Amounts_SoftROM                * (5&lt;&lt;8)


; OS_Memory 9 and 25 types
OSMemoryReason_IOSpace_EASIAccessSpeedControl * (0&lt;&lt;8)
OSMemoryReason_IOSpace_EASI                   * (1&lt;&lt;8)
OSMemoryReason_IOSpace_VIDC1                  * (2&lt;&lt;8)
OSMemoryReason_IOSpace_VIDC20                 * (3&lt;&lt;8)
OSMemoryReason_IOSpace_SSpace                 * (4&lt;&lt;8) ; Pace OS only
OSMemoryReason_IOSpace_ExtensionROM           * (5&lt;&lt;8) ; Pace OS only
; Note: Many omitted to leave space for other undocumented CTL changes
OSMemoryReason_IOSpace_PrimaryROM             * (32&lt;&lt;8)
OSMemoryReason_IOSpace_IOMD                   * (33&lt;&lt;8)
OSMemoryReason_IOSpace_FDC37C665              * (34&lt;&lt;8) ; or similar

; OS_Memory 12 flags
OSMemoryReason_RecommendPage_DMAable          * (1&lt;&lt;8)


; OS_Memory 24 return flags
OSMemoryReason_ValidateAccess_All_USR_Read    * (1&lt;&lt;0)
OSMemoryReason_ValidateAccess_All_USR_Write   * (1&lt;&lt;1)
OSMemoryReason_ValidateAccess_All_SVC_Read    * (1&lt;&lt;2)
OSMemoryReason_ValidateAccess_All_SVC_Write   * (1&lt;&lt;3)
OSMemoryReason_ValidateAccess_Part_USR_Read   * (1&lt;&lt;4)
OSMemoryReason_ValidateAccess_Part_USR_Write  * (1&lt;&lt;5)
OSMemoryReason_ValidateAccess_Part_SVC_Read   * (1&lt;&lt;6)
OSMemoryReason_ValidateAccess_Part_SVC_Write  * (1&lt;&lt;7)
OSMemoryReason_ValidateAccess_All_Physical    * (1&lt;&lt;8)
OSMemoryReason_ValidateAccess_All_Abortable   * (1&lt;&lt;9)
; bit 10,11 spare
OSMemoryReason_ValidateAccess_Part_Physical   * (1&lt;&lt;12)
OSMemoryReason_ValidateAccess_Part_Abortable  * (1&lt;&lt;13)
; bit 14,15 spare


        END
</textarea>
<hr/>


<textarea class='source-code'>
       SUBT     Useful APCS procedure entry/exit macros =&gt; &amp;.Hdr.ProcAPCS

OldOpt SETA     {OPT}
       OPT      OptNoList+OptNoP1List

       GBLS     ProcAPCS_RegList    ; Which registers to preserve
       GBLA     ProcAPCS_LocalStack ; And any ADJSP on entry/exit for local vars

   [ :DEF: UsingAASM
; won't check stack if using AASM
     [ :LNOT: :DEF: ProcAPCS_CheckStack
       GBLL     ProcAPCS_CheckStack ; Should we check the stack or not
ProcAPCS_CheckStack SETL {FALSE}
     ]
     [ :LNOT: :DEF: ProcAPCS_Config
       GBLA     ProcAPCS_Config     ; APCS configuration
ProcAPCS_Config     SETA 32
     ]
   |
       IMPORT   __rt_stkovf_split_small
       IMPORT   __rt_stkovf_split_big

     [ :LNOT: :DEF: ProcAPCS_CheckStack
       GBLL     ProcAPCS_CheckStack ; Should we check the stack or not
ProcAPCS_CheckStack SETL :LNOT: BUILD_ZM
     ]
     [ :LNOT: :DEF: ProcAPCS_Config
       GBLA     ProcAPCS_Config     ; APCS configuration
ProcAPCS_Config SETA {CONFIG}
     ]
   ]


; if you want the Proc debugging, use the SIGNATURE macro

; ***************************************************************************
; *** Keep a note of local stack and register use at the routine entry    ***
; *** point so that an exit may be effected anywhere in the body without  ***
; *** remembering how many (and which) registers to destack and ADJSP.    ***
; *** Also ensures that the code entry label is word-aligned.             ***
; ***************************************************************************
; Syntax:
; ;
;  &lt;label&gt;    APCSEntry  &lt;registers to pass&gt; [, &lt;bytes to reserve on stack&gt;
;                        [, &lt;bytes to ensure available on stack&gt; ] ]
; --- The bytes reserved on the stack will be available at [sp,#...]
;     The space ensured may be 'nostackcheck' to remove any form of checking
;
;  &lt;label&gt;    APCSEntry  in_&lt;register&gt; [, &lt;bytes to reserve on stack&gt;
; --- This form of APCS entry sequence just uses the register specified
;     to hold the return address.
;
        MACRO
$label  APCSEntry $reglist,$framesize,$ensuresize
        ALIGN
        LCLA    Ensure
ProcAPCS_RegList SETS "$reglist"
 [ "$framesize" = ""
ProcAPCS_LocalStack SETA 0
 |
ProcAPCS_LocalStack SETA $framesize
 ]
 [ "$ensuresize" = "" :LOR: "$ensuresize" = "nostackcheck"
Ensure  SETA    0 + ProcAPCS_LocalStack
 |
Ensure  SETA    $ensuresize + ProcAPCS_LocalStack
 ]
$label  ROUT

 [ "$ProcAPCS_RegList   " :LEFT: 3 = "in_"
; simple APCS entry, just holding on to the return point in a register
        LCLS    InReg
InReg   SETS    "$ProcAPCS_RegList" :RIGHT: (:LEN: "$ProcAPCS_RegList" - 3)
        MOV     $InReg, lr

 |
; full APCS style entry sequence
        MOV     ip, sp
   [ "$ProcAPCS_RegList" = ""
        STMFD   sp!,{fp,ip,lr,pc}
   |
        STMFD   sp!,{$ProcAPCS_RegList,fp,ip,lr,pc}
   ]
        SUB     fp, ip, #4
   [ ProcAPCS_CheckStack :LAND: "$ensuresize" &lt;&gt; "nostackcheck"
     [ Ensure &lt;&gt; 0
        SUB     ip, sp, #Ensure
        CMP     ip, sl
        BLLT    __rt_stkovf_split_big              ; ensure sufficient stack space
     |
        CMP     sp, sl
        BLLT    __rt_stkovf_split_small            ; ensure sufficient stack space
     ]
   ]
 ]

 [ ProcAPCS_LocalStack &lt;&gt; 0
        SUB     sp, sp, #ProcAPCS_LocalStack
 ]
        MEND

; ***************************************************************************
; *** Exit procedure, restore stack and saved registers to values on entry***
; ***************************************************************************
        MACRO
$label  APCSExit    $cond
$label
 [ ProcAPCS_LocalStack &lt;&gt; 0
        ADD$cond      sp, sp, #ProcAPCS_LocalStack
 ]

 [ "$ProcAPCS_RegList   " :LEFT: 3 = "in_"
; simple APCS exit, returning to a register
        LCLS    InReg
InReg   SETS    "$ProcAPCS_RegList" :RIGHT: (:LEN: "$ProcAPCS_RegList" - 3)
     [ ProcAPCS_Config=32
        MOV$cond      pc, $InReg
     |
        MOV$cond.S    pc, $InReg
     ]
 |
   [ "$ProcAPCS_RegList" = ""
     [ ProcAPCS_Config=32
        LDM$cond.DB   fp,{fp,sp,pc}
     |
        LDM$cond.DB   fp,{fp,sp,pc}^
     ]
   |
     [ ProcAPCS_Config=32
        LDM$cond.DB   fp,{$ProcAPCS_RegList,fp,sp,pc}
     |
        LDM$cond.DB   fp,{$ProcAPCS_RegList,fp,sp,pc}^
     ]
   ]
 ]
        MEND

; ***************************************************************************

        OPT     OldOpt
        END
</textarea>
<hr/>

<textarea class='source-code'>
</textarea>
<hr/>

<textarea class='source-code'>

</textarea>

<hr/>

<textarea class='source-code'>
</textarea>


<span id='HELLO'>^^^^ WARNING: HELLO!</span>
</page>
</body>
</html>
