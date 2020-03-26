<!DOCTYPE html>
<html>
<html-header title='Colouring Example (bbc basic)' codecolouring>
<script type='text/javascript'>
<!--
    loaded = false;
    function onload() {
        if (loaded)
            return;
        loaded = true;
        if (1) {
            setup_colouring({autosize: false, linenumbers: true, scroll: true, mode: 'text/x-basic-bbcbasic'});
        }
    }
    -->
</script>
</html-header>
<body onload='onload();'>
    <page section='Colouring BBC BASIC'>
    <textarea class='source-code'>
10REM &gt;MkModule
20REM Create extra code for a relocatable module
30REM v2.00 (11 Jun 1995)
40REM v2.01 (20 Jun 1995)
50REM v2.02 (22 Jun 1995)
60REM v2.03 (08 Aug 1995)
70REM v2.04 (26 Aug 1995)
80REM v2.05 (05 Nov 1996) Services added
90REM v2.06 (21 Dec 1996) Services moved into Resources
100REM v2.07 (05 Feb 1997) Events and Vectors added
110REM v2.08 (09 Mar 1997) Extra info added
120REM v2.09 (08 Apr 1997) AOF compliant code added
130REM v2.10 (26 Apr 1997) Event code was completely buggered
140REM v2.11 (28 May 1997) AOF imports for header added
150REM v2.12 (09 Sep 1997) WimpSWIve post trap code fixed
160REM v2.13 (22 Oct 1997) Messages files
170REM v2.14 (15 Nov 1997) SWI Pre/Post, bug fixes for WimpSWI/Filter
180REM v2.15 (15 Nov 1997) Dictionary tokenisation added
190REM v2.16 (14 Dec 1997) Messages file fix, resource file blocks
200REM v2.17 (15 Dec 1997) Filter 'Code' now allows reasons
210REM v2.18 (16 Dec 1997) ImageFS support added
220REM v2.19 (30 Mar 1998) Service handler code improved
230REM v2.20 (31 Mar 1998) Ursula style service table
240REM v2.21 (01 Apr 1998) Module initialisation error handling improved
250REM v2.22 (23 Apr 1998) Wimp poll reason codes moved to file, new filter system, aof startcode, init, final, service and swihandler entries fixed.
260REM v2.23 (27 Apr 1998) WimpSWIve AOF code fixed, new filter system AOF code fixed
270REM v2.24 (14 Jul 1998) Rect, PostRect and PostIcon filters added.
280REM v2.25 (05 Sep 1998) Some ADRs changed to LADRs in initialisation code (JB)
290REM v2.26 (09 Jun 2000) Removed the dictionary encoding as this changed between OS versions.
300REM v2.27 (13 Feb 2001) Added fast service reject code
310REM v2.28 (13 Feb 2001) Added 'lightning fast service' code
320REM v2.29 (27 Feb 2001) Can explicitly set version with module_version$ (and date with module_date$)
330REM v2.30 (16 Mar 2001) WimpSWIve registration now uses multiple instructions (BASIC problem ?)
340REM v2.31 (24 May 2001) Service handler code completely re-written to cope correctly with high-service numbers
350REM                     Totally removed code for encoding using dictionary
360REM v2.32 (24 May 2001) Added support for 'duplicate service handlers' which may help when using auto-added handlers
370ERROR 0,"Do not run MkModule in this way"
380:
390DEFPROCModule_Define
400Ursula=TRUE:REM Ursula service entry table
410LightningFastService=FALSE:REM Special code 1 ursula entry
420IF NOT Ursula THENLightningFastService=FALSE
430DIM swi$(63),swic$(63)
440maxcoml=15
450maxserv=32
460DIM com$(63),coms$(63,maxcoml),comf%(63),comh$(63,maxcoml),comc$(63)
470DIM wswi$(63,2),servn(maxserv),serv$(maxserv),vectn(16),vect$(16)
480DIM event$(16),eventn(16),resourcel$(16),resources$(16)
490maxbfilter=15:maxafilter=15:maxrfilter=15:maxprfilter=15:maxifilter=15
500DIM mod_bfname$(maxbfilter),mod_bfilter$(maxbfilter),mod_bftask$(maxbfilter),mod_bfmethod(maxbfilter)
510DIM mod_afname$(maxafilter),mod_afilter$(maxafilter),mod_aftask$(maxafilter),mod_afmask$(maxafilter),mod_filter$(maxafilter,20),mod_afreasons(maxafilter),mod_afmethod(maxafilter)
520DIM mod_rfname$(maxrfilter),mod_rfilter$(maxrfilter),mod_rftask$(maxrfilter),mod_rfmethod(maxrfilter)
530DIM mod_prfname$(maxprfilter),mod_prfilter$(maxprfilter),mod_prftask$(maxprfilter),mod_prfmethod(maxprfilter)
540DIM mod_ifname$(maxifilter),mod_ifilter$(maxifilter),mod_iftask$(maxifilter),mod_ifmethod(maxifilter)
550mod_start$="0":mod_init$="0":mod_final$="0":mod_serv$="0"
560mod_servnum=0
570mod_name$="Untitled":mod_author$="":mod_ver$="1.00"
580mod_help$="0":mod_helpstr$="":mod_extra$=""
590mod_swibase$="0":mod_swicode$="0"
600mod_swipre$="":mod_swipost$="":mod_swiprefix$=""
610mod_swihandler$="":mod_ws$="-":mod_wsinit=FALSE
620mod_img_type$="":mod_fs_name$=""
630IF intver&gt;0 THENmod_ver$=LEFT$(intvern$,4)
640mod_coms=0:mod_swis=0:mod_wswis=0
650REMmod_bfname$="":mod_bfilter$="":mod_bftask$=""
660mod_fltr_error=FALSE:mod_fltr_multi=FALSE:mod_fltr_alltasks=FALSE
670REMmod_afname$="":mod_afilter$="":mod_aftask$="":mod_afmask$=""
680REMmod_afreasons=FALSE
690mod_msgfile$=""
700mod_bfn=0:mod_afn=0:mod_rfn=0:mod_prfn=0:mod_ifn=0
710mod_vectn=0:mod_eventn=0:mod_resourcen=0:mod_resdone=FALSE
720REPEAT
730 a$=FNstrip(FNreadline)
740 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
750 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
760 CASE com$ OF
770  WHEN "NAME":PROCModule_Name
780  WHEN "VERSION":PROCModule_Version
790  WHEN "AUTHOR":PROCModule_Author
800  WHEN "EXTRA":PROCModule_Extra
810  WHEN "HELP":PROCModule_Help
820  WHEN "INIT":PROCModule_Init
830  WHEN "FINAL":PROCModule_Finalise
840  WHEN "START":PROCModule_Start
850  WHEN "SERVICE":PROCModule_Service
860  WHEN "SERVICES":PROCModule_ServiceBlock
870  WHEN "VECTORS":PROCModule_VectorBlock
880  WHEN "EVENTS":PROCModule_EventBlock
890  WHEN "SWIHANDLER":PROCModule_SWIHandler
900  WHEN "COMMANDS":PROCModule_Commands
910  WHEN "SWIS":PROCModule_SWIs
920  WHEN "WIMPSWIS":PROCModule_WimpSWIVe
930  WHEN "WORKSPACE":PROCModule_WS
940  WHEN "PREFILTER":PROCModule_PreFilter
950  WHEN "POSTFILTER":PROCModule_PostFilter
960  WHEN "RECTFILTER":PROCModule_RectFilter
970  WHEN "COPYFILTER":PROCModule_CopyFilter
980  WHEN "POSTRECTFILTER":PROCModule_PostRectFilter
990  WHEN "POSTICONFILTER":PROCModule_PostIconFilter
1000  WHEN "MESSAGEFILE":PROCModule_MessageFile
1010  WHEN "RESOURCES":PROCModule_ResourceBlock
1020  WHEN "IMAGEFS":PROCModule_ImageFS
1030  WHEN "FS":PROCModule_FS
1040  WHEN "":REM Ignore
1050  WHEN "END":REM Will be trapped in a mo
1060  OTHERWISE
1070   IF outaof THEN
1080    PROCAOF_define(com$,arg$)
1090   ELSE
1100    IF LEFT$(com$,1)="{" THEN
1110     PROCignorerems(a$)
1120    ELSE
1130     ERROR 999,"Bad module definition '"+com$+"'"
1140    ENDIF
1150   ENDIF
1160 ENDCASE
1170UNTILFNupper(a$)="END MODULE"
1180IF mod_helpstr$="" THENmod_helpstr$=mod_name$
1190IF LEN(mod_helpstr$)&lt;8 THEN
1200 mod_helpstr$+="""+CHR$9+CHR$9"
1210ELSE
1220 mod_helpstr$+="""+CHR$9"
1230ENDIF
1240mod_helpstr$+="+module_version$+"" (""+module_date$+"")"""
1250PROCputline("module_date$=MID$(TIME$,5,11)")
1260IF intver&gt;0 THEN
1270 PROCputline("module_version$=LEFT$(version$,4)")
1280ELSE
1290 PROCputline("module_version$="""+mod_ver$+"""")
1300ENDIF
1310IF mod_author$&lt;&gt;"" THEN
1320 IF mod_extra$&lt;&gt;"" THENmod_extra$+=" "
1330 mod_extra$+="© "+mod_author$
1340ENDIF
1350IF mod_extra$&lt;&gt;"" THEN
1360 mod_helpstr$+="+"" "+mod_extra$+""""
1370ENDIF
1380OSCLI("*Set JFPatch$ModName "+mod_name$)
1390OSCLI("*Set JFPatch$ModVersion "+mod_ver$)
1400ENDPROC
1410:
1420DEFPROCModule_Name:mod_name$=arg$:ENDPROC
1430DEFPROCModule_Author:mod_author$=arg$:ENDPROC
1440DEFPROCModule_Extra:mod_extra$=arg$:ENDPROC
1450DEFPROCModule_Version:mod_ver$=arg$:ENDPROC
1460DEFPROCModule_Help:mod_helpstr$=arg$:ENDPROC
1470DEFPROCModule_Init:mod_init$=arg$:ENDPROC
1480DEFPROCModule_Start:mod_start$=arg$:ENDPROC
1490DEFPROCModule_Finalise:mod_final$=arg$:ENDPROC
1500DEFPROCModule_Service:mod_serv$=arg$:ENDPROC
1510DEFPROCModule_SWIHandler:mod_swihandler$=arg$:ENDPROC
1520DEFPROCModule_MessageFile:mod_msgfile$=arg$:ENDPROC
1530DEFPROCModule_WS
1540IF LEFT$(arg$,1)="*" THENmod_wsinit=TRUE:arg$=MID$(arg$,2)
1550IF INSTR("&amp;1234567890",LEFT$(arg$,1))&gt;0 THEN
1560 mod_ws$="&amp;"+STR$~FNk(arg$)
1570ELSE
1580 mod_ws$=arg$
1590ENDIF
1600ENDPROC
1610:
1620DEFPROCModule_Assemble
1630initneeded=mod_ws$&lt;&gt;"-" OR mod_wswis&lt;&gt;0 OR mod_afn&gt;0 OR mod_bfn&gt;0 OR mod_vectn&gt;0 OR outaof OR mod_resourcen&lt;&gt;0 OR mod_img_type$&lt;&gt;"" OR mod_fs_name$&lt;&gt;""
1640:
1650IF mod_afn&gt;0 OR mod_bfn&gt;0 OR mod_rfn&gt;0 OR mod_prfn&gt;0 OR mod_ifn&gt;0 THEN
1660 IF mod_fltr_error OR mod_fltr_multi THEN
1670  PROCservice_add(&amp;53,"mod_svc_wimpclosedown")
1680 ENDIF
1690 PROCservice_add(&amp;87,"mod_svc_newfiltermgr")
1700ENDIF
1710IF mod_img_type$&lt;&gt;"" OR mod_fs_name$&lt;&gt;"" THEN
1720 PROCservice_add(&amp;40,"mod_svc_fsredeclare")
1730ENDIF
1740IF mod_resourcen&lt;&gt;0 THEN
1750 PROCservice_add(&amp;60,"mod_svc_resourcefsstarting")
1760ENDIF
1770:
1780svcneeded=(mod_ws$&lt;&gt;"-" AND mod_serv$&lt;&gt;"0")
1790svcneeded=svcneeded OR mod_servnum&gt;0
1800:
1810IF NOT outaof THEN
1820 PROCputline("PROCpatch_setpc(0)")
1830 PROCputline("[OPT pass%")
1840ELSE
1850 REM Create an area for us ;-)
1860 PROCAOF_ModuleArea
1870ENDIF
1880PROCputrem("**** Add module header ****")
1890IF LEFT$(mod_start$,1)&lt;&gt;"|"THEN
1900 PROCputline("   EQUD "+FNmod_align(mod_start$,0))
1910ELSE
1920 PROCputline("   EQUD "+FNmod_align("module_start",0))
1930ENDIF
1940IF NOT initneeded THEN
1950 IF LEFT$(mod_init$,1)&lt;&gt;"|"THEN
1960  PROCputline("   EQUD "+FNmod_align(mod_init$,1))
1970 ELSE
1980  PROCputline("   EQUD "+FNmod_align("module_init",1))
1990 ENDIF
2000 IF LEFT$(mod_final$,1)&lt;&gt;"|"THEN
2010  PROCputline("   EQUD "+FNmod_align(mod_final$,2))
2020 ELSE
2030  PROCputline("   EQUD "+FNmod_align("module_final",2))
2040 ENDIF
2050ELSE
2060 PROCputline("   EQUD "+FNmod_align("module_init",1))
2070 PROCputline("   EQUD "+FNmod_align("module_final",2))
2080ENDIF
2090IF NOT svcneeded THEN
2100 IF LEFT$(mod_serv$,1)&lt;&gt;"|"THEN
2110  PROCputline("   EQUD "+FNmod_align(mod_serv$,3))
2120 ELSE
2130  PROCputline("   EQUD "+FNmod_align("module_service",3))
2140 ENDIF
2150ELSE
2160 PROCputline("   EQUD "+FNmod_align("module_service",3))
2170ENDIF
2180PROCputline("   EQUD "+FNmod_align("module_title",4))
2190PROCputline("   EQUD "+FNmod_align("module_help",5))
2200IF mod_coms=0 THENa$="0" ELSEa$="module_commands"
2210PROCputline("   EQUD "+FNmod_align(a$,6))
2220IF mod_swibase$&lt;&gt;"0" THEN
2230 PROCputline("   EQUD "+FNmod_align(mod_swibase$,7))
2240 IF mod_swihandler$="" THEN
2250  PROCputline("   EQUD "+FNmod_align("module_swicode",8))
2260 ELSE
2270  IF LEFT$(mod_swihandler$,1)&lt;&gt;"|"THEN
2280   PROCputline("   EQUD "+FNmod_align(mod_swihandler$,8))
2290  ELSE
2300   PROCputline("   EQUD "+FNmod_align("module_swicode",8))
2310  ENDIF
2320 ENDIF
2330 PROCputline("   EQUD "+FNmod_align("module_switable",9))
2340 PROCputline("   EQUD "+FNmod_align("0",10))
2350 IF mod_msgfile$&lt;&gt;"" THENPROCputline("   EQUD "+FNmod_align("module_messagefile",21))
2360ELSE
2370 IF mod_msgfile$&lt;&gt;"" THEN
2380  PROCputline("   EQUD "+FNmod_align("0",7))
2390  PROCputline("   EQUD "+FNmod_align("0",8))
2400  PROCputline("   EQUD "+FNmod_align("0",9))
2410  PROCputline("   EQUD "+FNmod_align("0",10))
2420  PROCputline("   EQUD "+FNmod_align("module_messagefile",21))
2430 ENDIF
2440ENDIF
2450PROCputline(":")
2460IF LEFT$(mod_start$,1)="|"THEN
2470 PROCputline(".module_start")
2480 PROCputline("   B       "+FNmod_align(mod_start$,62))
2490 PROCputline(":")
2500ENDIF
2510IF mod_name$&lt;&gt;mod_swiprefix$ OR mod_swiprefix$="" THEN
2520 PROCputline(".module_title")
2530 PROCputline("   EQUS """+mod_name$+"""+CHR$0")
2540 PROCputline("   ALIGN")
2550 PROCputline(":")
2560ENDIF
2570PROCputline(".module_help")
2580PROCputline("   EQUS """+mod_helpstr$+"+CHR$0")
2590PROCputline("   ALIGN")
2600PROCputline(":")
2610IF mod_msgfile$&lt;&gt;"" THEN
2620 PROCputline(".module_messagefile")
2630 PROCputline("   EQUS """+mod_msgfile$+"""+CHR$0")
2640 PROCputline("   ALIGN")
2650 PROCputline(":")
2660ENDIF
2670IF NOT svcneeded THEN
2680 IF LEFT$(mod_serv$,1)="|"THEN
2690  PROCputline(".module_service")
2700  PROCputline("   B       "+FNmod_align(mod_serv$,65))
2710  PROCputline(":")
2720 ENDIF
2730ELSE
2740 IF Ursula THEN
2750  PROCputline("   EQUD    module_service_table")
2760  PROCputline(".module_service")
2770  PROCputline("   MOV     r0,r0      ; magic")
2780 ELSE
2790  PROCputline(".module_service")
2800 ENDIF
2810 IF mod_servnum&gt;0 THEN
2820  PROCModule_head_services
2830 ENDIF
2840 PROCputline(":")
2850 IF mod_img_type$&lt;&gt;"" OR mod_fs_name$&lt;&gt;"" THEN
2860  PROCputline(".mod_svc_fsredeclare")
2870  PROCputline("   STMFD   (sp)!,{r0-r4,link}     ; Stack registers")
2880  IF mod_img_type$&lt;&gt;"" THEN
2890   PROCputline("   BL      mod_imagefs_add")
2900  ENDIF
2910  IF mod_fs_name$&lt;&gt;"" THEN
2920   PROCputline("   BL      mod_fs_add")
2930  ENDIF
2940  PROCputline("   LDMFD   (sp)!,{r0-r4,pc}       ; Return from call")
2950  PROCputline(":")
2960 ENDIF
2970 IF Ursula AND svcneeded THEN
2980  PROCModule_head_servicetable
2990 ENDIF
3000 IF mod_img_type$&lt;&gt;"" THENPROCModule_head_imagefs_code
3010 IF mod_fs_name$&lt;&gt;"" THENPROCModule_head_fs_code
3020 IF mod_bfn&gt;0 OR mod_afn&gt;0 OR mod_rfn&gt;0 OR mod_prfn&gt;0 OR mod_ifn&gt;0 THEN
3030  PROCputline(".mod_svc_newfiltermgr")
3040  PROCputline("   STMFD   (sp)!,{r6,link}        ; Stack registers")
3050  PROCputline("   MOV     r6,#0")
3060  PROCputline("   BL      _mod_fltr_FilterTasks")
3070  PROCputline("   LDMFD   (sp)!,{r6,pc}^"):REMOtherwise infinite loop
3080  PROCputline(":")
3090  IF mod_fltr_error OR mod_fltr_multi THEN
3100   PROCputline(".mod_svc_wimpclosedown")
3110   PROCputline("   TEQ     r0,#0")
3120   PROCputline("   MOVNE   pc,link   ; If Wimp_CloseDown not called exit")
3130   PROCputline("   STMFD   (sp)!,{r0-r4,r6,link}")
3140   PROCputline("   MOV     r0,r2")
3150   PROCputline("   SWI     ""XTaskManager_TaskNameFromHandle""")
3160   PROCputline("   LDMVSFD (sp)!,{r0-r4,r6,pc}^")
3170   PROCputLADR("","1","`mod_filterblock")
3180   PROCputline("   MOV     r2,r0")
3190   PROCputline("   SUB     r4,r1,#16")
3200   PROCputline(".__mswcd_CheckLoop")
3210   PROCputline("   LDR     r3,[r4,#16]!           ; Read offset of task name to check")
3220   PROCputline("   CMN     r3,#1")
3230   PROCputline("   LDMEQFD (sp)!,{r0-r4,r6,pc}^")
3240   PROCputline("   BL      _mod_fltr_CheckName")
3250   PROCputline("   BNE     __mswcd_CheckLoop      ; If name doesn't match try next")
3260   PROCputline("   LDR     r3,[sp,#8]")
3270   PROCputline("   MOV     r6,#1")
3280   PROCputline("   BL      _mod_fltr_AddRemFilters")
3290   PROCputline("   B       __mswcd_CheckLoop")
3300   PROCputline(":")
3310  ENDIF
3320 ENDIF
3330 IF mod_resourcen&lt;&gt;0 THEN
3340  PROCputline(".mod_svc_resourcefsstarting")
3350  PROCputline("   STMFD   (sp)!,{r0,link}        ; Stack registers")
3360  PROCputLADR("","0","`module_resources")
3370  PROCputline("   MOV     link,pc")
3380  PROCputline("   MOV     pc,r2                  ; Call ResourceFS register routine")
3390  PROCputline("   LDMFD   (sp)!,{r0,pc}^"):REMOtherwise infinite loop
3400  PROCputline(":")
3410 ENDIF
3420ENDIF
3430IF NOT initneeded THEN
3440 IF LEFT$(mod_init$,1)="|"THEN
3450  PROCputline(".module_init")
3460  PROCputline("   B       "+FNmod_align(mod_init$,63))
3470  PROCputline(":")
3480 ENDIF
3490 IF LEFT$(mod_final$,1)="|"THEN
3500  PROCputline(".module_final")
3510  PROCputline("   B       "+FNmod_align(mod_final$,64))
3520  PROCputline(":")
3530 ENDIF
3540ELSE
3550 PROCputline(".module_init")
3560 PROCputline("   STMFD   (sp)!,{r0-r6,link}     ; Stack registers")
3570 IF outaof THENPROCAOF_ModuleInit
3580 IF mod_resourcen&lt;&gt;0 THEN
3590  PROCputLADR("","0","`module_resources")
3600  PROCputline("   SWI     ""XResourceFS_RegisterFiles""   ; Register resources")
3610  PROCputline("   ADDVS   sp,sp,#4                ; if error return r0")
3620  PROCputline("   LDMVSFD (sp)!,{r1-r6,pc}       ; return error")
3630 ENDIF
3640 IF mod_ws$&lt;&gt;"-" THEN
3650  PROCputline("   MOV     r0,#6")
3660  PROCputline(" FNLMOV("""",3,"+mod_ws$+")"):lmovused=TRUE
3670  PROCputline("   SWI     ""XOS_Module""           ; Claim private workspace")
3680  PROCputline("   ADDVS   sp,sp,#4               ; if error return r0")
3690  PROCputline("   LDMVSFD (sp)!,{r1-r6,pc}       ; return error")
3700  PROCputline("   STR     r2,[r12]               ; store in private word")
3710  PROCputline("   MOV     r12,r2                 ; r12=space")
3720  IF mod_wsinit THEN
3730   PROCputline("   MOV     r0,#0                  ; initialise to 0")
3740   PROCputline("   ADD     r3,r3,r2               ; end of block")
3750   PROCputline("._mod_ws_init")
3760   PROCputline("   STR     r0,[r2],#4             ; store and inc")
3770   PROCputline("   CMP     r2,r3                  ; at end ?")
3780   PROCputline("   BLT     _mod_ws_init           ; n = loop again")
3790  ENDIF
3800 ENDIF
3810 IF mod_wswis&gt;0 THENPROCModule_head_wswi("1")
3820 IF mod_bfn&gt;0 OR mod_afn&gt;0 OR mod_rfn&gt;0 OR mod_prfn&gt;0 OR mod_ifn&gt;0 THEN
3830  PROCputline("   MOV     r6,#0")
3840  PROCputline("   BL      _mod_fltr_FilterTasks")
3850  IF mod_fltr_error THEN
3860   PROCputline("   ADRVS   r1,mod_init_error_2")
3870   PROCputline("   BVS     mod_init_error")
3880  ENDIF
3890 ENDIF
3900 IF mod_img_type$&lt;&gt;"" THENPROCModule_head_imagefs_add
3910 IF mod_fs_name$&lt;&gt;"" THENPROCModule_head_fs_add
3920 IF mod_vectn&gt;0 THENPROCModule_head_vectors("Claim")
3930 IF mod_eventn&gt;0 THENPROCModule_head_events("Claim")
3940 IF mod_init$&lt;&gt;"0" THEN
3950  PROCputline("   LDMFD   (sp)!,{r0-r6}          ; restore registers")
3960  PROCputline("   BL      "+FNmod_call(mod_init$))
3970  PROCputline("   LDMVCFD (sp)!,{pc}             ; return if no error")
3980  PROCputline("   STMFD   (sp)!,{r0-r6}")
3990  PROCputline("   ADR     r1,_mod_init_error_3")
4000  REM No branch instruction needed as error handler follows on
4010 ELSE
4020  PROCputline("   LDMFD   (sp)!,{r0-r6,pc}       ; restore registers")
4030 ENDIF
4040 PROCputline(":")
4050 IF mod_wswis&gt;0 OR mod_fltr_error OR mod_init$&lt;&gt;"0" THEN
4060  PROCputline(".mod_init_error")
4070  PROCputline("   STR     r0,[sp]                ; store error pointer")
4080  PROCputline("   STMFD   (sp)!,{r0-r6,r12,pc}   ; set up stack and return address")
4090  PROCputline("   MOV     pc,r1                  ; call finalise code")
4100  PROCputline("   LDMFD   (sp)!,{r0-r6,link}")
4110  PROCputline("   ORRS    pc,link,#vbit          ; ensure vbit set")
4120  PROCputline(":")
4130 ENDIF
4140 IF mod_wswis&gt;0 THEN
4150  PROCputline(".`module_WSWIerr")
4160  PROCputline("   EQUD     &amp;0")
4170  PROCputline("   EQUS     """+mod_name$+" requires the WimpSWIVe module to be present""+CHR$0")
4180  PROCputline(".`module_WSWIname")
4190  PROCputline("   EQUS     ""WimpSWIVe""+CHR$0")
4200  PROCputline("   ALIGN")
4210  PROCputline(".`module_WSWIword")
4220  PROCputline("   EQUS     ""WSWI""")
4230  PROCputline(":")
4240 ENDIF
4250 PROCputline(".module_final")
4260 PROCputline("   STMFD   (sp)!,{r0-r6,r12,link} ; Stack registers")
4270 IF mod_ws$&lt;&gt;"-" THEN
4280  PROCputline("   LDR     r12,[r12]")
4290 ENDIF
4300 IF mod_final$&lt;&gt;"0" THEN
4310  PROCputline("   BL      "+FNmod_call(mod_final$))
4320  PROCputline("   ADDVS   sp,sp,#4")
4330  PROCputline("   LDMVSFD (sp)!,{r1-r6,r12,pc}    ; Return if error")
4340 ENDIF
4350 IF mod_init$&lt;&gt;"0" THENPROCputline("._mod_init_error_3")
4360 IF mod_eventn&gt;0 THENPROCModule_head_events("Release")
4370 IF mod_vectn&gt;0 THENPROCModule_head_vectors("Release")
4380 IF mod_fs_name$&lt;&gt;"" THENPROCModule_head_fs_remove
4390 IF mod_img_type$&lt;&gt;"" THENPROCModule_head_imagefs_remove
4400 IF mod_bfn&gt;0 OR mod_afn&gt;0 OR mod_rfn&gt;0 OR mod_prfn&gt;0 OR mod_ifn&gt;0 THEN
4410  PROCputline("   MOV     r6,#1")
4420  PROCputline("   BL      _mod_fltr_FilterTasks")
4430  PROCputline(".mod_init_error_2")
4440 ENDIF
4450 IF mod_wswis&gt;0 THEN
4460  PROCModule_head_wswi("0")
4470  PROCputline("._mod_init_error_1")
4480 ENDIF
4490 IF mod_ws$&lt;&gt;"-" THEN
4500  PROCputline("   MOV     r0,#7")
4510  PROCputline("   MOV     r2,r12")
4520  PROCputline("   SWI     ""XOS_Module""           ; Release workspace")
4530  REMPROCputline("   ADDVS   sp,sp,#4")
4540  REMPROCputline("   LDMVSFD (sp)!,{r1-r6,r12,pc}   ; Return if error")
4550 ENDIF
4560 IF mod_resourcen&lt;&gt;0 THEN
4570  PROCputLADR("","0","`module_resources")
4580  PROCputline("   SWI     ""XResourceFS_DeregisterFiles"" ; De-Register resources")
4590  REMPROCputline("   ADDVS   sp,sp,#4                ; if error return r0")
4600  REMPROCputline("   LDMVSFD (sp)!,{r1-r6,r12,pc}   ; return error")
4610 ENDIF
4620 PROCputline("   LDMFD   (sp)!,{r0-r6,r12,pc}   ; Return")
4630 PROCputline(":")
4640ENDIF
4650:
4660IF mod_coms&gt;0 THENPROCModule_AssembleComs
4670IF mod_swis&gt;0 THEN
4680 PROCModule_AssembleSWIs
4690ELSE
4700 IF LEFT$(mod_swihandler$,1)="|"THEN
4710  PROCputline(".module_swicode")
4720  PROCputline("   B       "+FNmod_align(mod_swicode$,66))
4730  PROCputline(":")
4740 ENDIF
4750ENDIF
4760IF mod_eventn&gt;0 THENPROCModule_AssembleEvents
4770IF mod_bfn&gt;0 OR mod_afn&gt;0 OR mod_rfn&gt;0 OR mod_prfn&gt;0 OR mod_ifn&gt;0 THENPROCModule_extra_filter
4780PROCputrem("**** End of module header ****")
4790PROCputline(":")
4800ENDPROC
4810:
4820REM Relocate the calls if necessary ;-)
4830DEFFNmod_call(a$)
4840IF NOT outaof THEN=a$
4850=FNAOF_jump(a$)
4860:
4870DEFFNmod_align(a$,n%):LOCAL a%,m$,t$
4880WHILE LEN(a$)&lt;18:a$+=" ":ENDWHILE
4890RESTORE +6
4900REPEAT
4910 READ a%,m$,t$
4920UNTILa%=n%
4930IF m$&lt;&gt;"" THENa$+=" ; "+m$
4940IF outaof THEN
4950 IF t$="O" THENa$=FNAOF_modoffset(a$)
4960 IF t$="J" THENa$=FNAOF_jump(a$)
4970ENDIF
4980=a$
4990REM O=jump offset, S=string, N=number, J=jump
5000DATA 0,Start offset,O
5010DATA 1,Initialisation offset,O
5020DATA 2,Finalisation offset,O
5030DATA 3,Service request offset,O
5040DATA 4,Title string offset,O
5050DATA 5,Help string offset,O
5060DATA 6,Help and command keyword table offset,O
5070DATA 7,SWI chunk base number,N
5080DATA 8,SWI handler code offset,O
5090DATA 9,SWI decoding table offset,O
5100DATA10,SWI decoding code offset,O
5110DATA11,Command name,S
5120DATA12,Code to call,O
5130DATA13,Flags,N
5140DATA14,Syntax pointer,O
5150DATA15,Help pointer,O
5160DATA16,SWI prefix,S
5170DATA17,Post-Filter code,O
5180DATA18,Pre-Filter code,O
5190REM WimpSWI PreFilter offset
5200DATA19,,O
5210REM WimpSWI PostFilter offset
5220DATA20,,O
5230DATA21,Message file,O
5240DATA22,SWI pre-handler,J
5250DATA23,SWI post-handler,J
5260DATA24,Post-Filter reason handler,J
5270DATA25,Post-Filter code,J
5280DATA40,ImageFS type,N
5290DATA41,ImageFS file open,O
5300DATA42,ImageFS get bytes,O
5310DATA43,ImageFS put bytes,O
5320DATA44,ImageFS control,O
5330DATA45,ImageFS file close,O
5340DATA46,ImageFS file ops,O
5350DATA47,ImageFS functions,O
5360DATA48,ImageFS infoword,N
5370DATA50,FS name,O
5380DATA51,FS file open,O
5390DATA52,FS get bytes,O
5400DATA53,FS put bytes,O
5410DATA54,FS control,O
5420DATA55,FS file close,O
5430DATA56,FS file ops,O
5440DATA57,FS functions,O
5450DATA58,FS GBPB,O
5460DATA59,FS infoword,N
5470DATA60,FS extra infoword,N
5480DATA61,FS startup text,O
5490DATA62,Start offset,J
5500DATA63,Initialisation offset,J
5510DATA64,Finalisation offset,J
5520DATA65,Service request offset,J
5530DATA66,SWI handler code offset,J
5540DATA67,Rect-Filter code,O
5550DATA68,PostRect-Filter code,O
5560DATA69,PostIcon-Filter code,O
5570:
5580DEFPROCModule_Commands
5590comname$="":comcode$="0":comsyntax$="":comhelp$=""
5600commax=0:commin=0:comtype=0
5610comflags=-1
5620REPEAT
5630 a$=FNstrip(FNreadline)
5640 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
5650 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
5660 IF FNupper(a$)&lt;&gt;"END COMMANDS" THEN
5670  CASE com$ OF
5680   WHEN "NAME"  :PROCModule_ComName
5690   WHEN "CODE"  :PROCModule_ComCode
5700   WHEN "MAX"   :PROCModule_ComMax
5710   WHEN "MIN"   :PROCModule_ComMin
5720   WHEN "TYPE"  :PROCModule_ComType
5730   WHEN "FLAGS" :PROCModule_ComFlags
5740   WHEN "SYNTAX":PROCModule_ComSyntax
5750   WHEN "HELP"  :PROCModule_ComHelp
5760  ENDCASE
5770 ENDIF
5780UNTILFNupper(a$)="END COMMANDS"
5790IFcomname$&lt;&gt;"" THENarg$="":PROCModule_ComName
5800ENDPROC
5810:
5820DEFPROCModule_ComName
5830IF comname$&lt;&gt;"" THEN
5840 com$(mod_coms)=comname$
5850 comc$(mod_coms)=comcode$
5860 IF comsyntax$&lt;&gt;"..." THENcoms$(mod_coms,0)=comsyntax$
5870 IF comhelp$&lt;&gt;"..." THENcomh$(mod_coms,0)=comhelp$
5880 IF comflags=-1 THEN
5890  comflags=(comtype&lt;&lt;24)+(commax&lt;&lt;16)+(0&lt;&lt;8)+(commin&lt;&lt;0)
5900 ENDIF
5910 comf%(mod_coms)=comflags
5920 mod_coms+=1
5930ENDIF
5940IF arg$="" THENENDPROC
5950comcode$="0":comsyntax$="":comhelp$=""
5960commax=0:commin=0:comtype=0
5970comflags=-1
5980comname$=arg$
5990ENDPROC
6000:
6010DEFPROCModule_ComCode
6020IF comname$="" THENERROR 999,"CODE definition without NAME"
6030comcode$=arg$
6040ENDPROC
6050:
6060DEFPROCModule_ComMax
6070IF comname$="" THENERROR 999,"MAX definition without NAME"
6080commax=EVAL(arg$)
6090ENDPROC
6100:
6110DEFPROCModule_ComMin
6120IF comname$="" THENERROR 999,"MIN definition without NAME"
6130commin=EVAL(arg$)
6140ENDPROC
6150:
6160DEFPROCModule_ComType
6170IF comname$="" THENERROR 999,"TYPE definition without NAME"
6180CASE FNupper(arg$) OF
6190 WHEN "FILING","FS"           :comtype=&amp;80
6200 WHEN "CONFIG","CONFIGURATION":comtype=&amp;40
6210 WHEN "CODE"                  :comtype=&amp;20:REM N/A as yet
6220 WHEN "TOKEN","TOKENISED"     :comtype=&amp;10
6230 OTHERWISE:ERROR 999,"TYPE '"+arg$+"' not known"
6240ENDCASE
6250ENDPROC
6260:
6270DEFPROCModule_ComSyntax
6280IF comname$="" THENERROR 999,"SYNTAX definition without NAME"
6290comsyntax$=arg$
6300IF comsyntax$="..." THEN
6310 a$=FNreadline:cs=1
6320 REPEAT:cs+=1:UNTILMID$(a$,cs)&lt;&gt;" ":cs-=1
6330 b$=MID$(a$,cs+1):IF FNupper(RIGHT$(b$,2))&lt;&gt;"|M" AND RIGHT$(b$,1)&lt;&gt;" " THENb$+=" "
6340 coms$(mod_coms,0)=b$:com=1
6350 REPEAT
6360  a$=FNreadline
6370  IF LEFT$(a$,cs)=STRING$(cs," ") THEN
6380   b$=MID$(a$,cs+1):IF FNupper(RIGHT$(b$,2))&lt;&gt;"|M" AND RIGHT$(b$,1)&lt;&gt;" " THENb$+=" "
6390   coms$(mod_coms,com)=b$:com+=1
6400  ENDIF
6410 UNTIL com=maxcoml OR LEFT$(a$,cs)&lt;&gt;STRING$(cs," ")
6420 PROCbackoneline
6430 IF com=maxcoml THENERROR 999,"SYNTAX definition too long"
6440ENDIF
6450ENDPROC
6460:
6470DEFPROCModule_ComHelp
6480IF comname$="" THENERROR 999,"HELP definition without NAME"
6490comhelp$=arg$
6500IF comhelp$="..." THEN
6510 a$=FNreadline:cs=1
6520 REPEAT:cs+=1:UNTILMID$(a$,cs,1)&lt;&gt;" ":cs-=1
6530 b$=MID$(a$,cs+1):IF FNupper(RIGHT$(b$,2))&lt;&gt;"|M" AND RIGHT$(b$,1)&lt;&gt;" " THENb$+=" "
6540 comh$(mod_coms,0)=b$:com=1
6550 REPEAT
6560  a$=FNreadline
6570  IF LEFT$(a$,cs)=STRING$(cs," ") THEN
6580   b$=MID$(a$,cs+1):IF FNupper(RIGHT$(b$,2))&lt;&gt;"|M" AND RIGHT$(b$,1)&lt;&gt;" " THENb$+=" "
6590   comh$(mod_coms,com)=b$:com+=1
6600  ENDIF
6610 UNTIL com=maxcoml OR LEFT$(a$,cs)&lt;&gt;STRING$(cs," ")
6620 PROCbackoneline
6630 IF com=maxcoml THENERROR 999,"HELP definition too long"
6640ENDIF
6650ENDPROC
6660:
6670DEFPROCModule_ComFlags
6680IF comname$="" THENERROR 999,"FLAGS definition without NAME"
6690comflags=EVAL(arg$)
6700ENDPROC
6710:
6720DEFPROCModule_AssembleComs
6730PROCputline("; ***** Module commands table")
6740PROCputline(".module_commands")
6750extra=FALSE
6760FORI=0TO mod_coms-1
6770 PROCputline("   EQUS "+FNmod_align(CHR$34+com$(I)+CHR$34,11))
6780 PROCputline("   EQUB 0:ALIGN")
6790 PROCputline("   EQUD "+FNmod_align(comc$(I),12))
6800 PROCputline("   EQUD "+FNmod_align("&amp;"+STR$~comf%(I),13))
6810 IF coms$(I,0)="" THENa$="0" ELSEa$="syntax_"+FNlower(com$(I))
6820 PROCputline("   EQUD "+FNmod_align(a$,14))
6830 IF comh$(I,0)="" THENb$="0" ELSEb$="help_"+FNlower(com$(I))
6840 PROCputline("   EQUD "+FNmod_align(b$,15))
6850 IF a$&lt;&gt;b$ THENextra=TRUE
6860NEXT
6870PROCputline("   EQUB 0")
6880PROCputline("   ALIGN")
6890PROCputline(":")
6900IF extra=FALSE THENENDPROC
6910PROCputline("; ***** Help and Syntax messages")
6920FORI=0TO mod_coms-1
6930 IFcoms$(I,0)&lt;&gt;"" THEN
6940  PROCputline(".syntax_"+FNlower(com$(I)))
6950  FORO=0TO9
6960   IF coms$(I,O)&lt;&gt;"" THEN
6970    PROCputline("   EQUS "+FNascstring(coms$(I,O)))
6980   ENDIF
6990  NEXT
7000  PROCputline("   EQUB 0")
7010 ENDIF
7020 IF comh$(I,0)&lt;&gt;"" THEN
7030  PROCputline(".help_"+FNlower(com$(I)))
7040  FORO=0TO9
7050   IF comh$(I,O)&lt;&gt;"" THEN
7060    PROCputline("   EQUS "+FNascstring(comh$(I,O)))
7070   ENDIF
7080  NEXT
7090  PROCputline("   EQUB 0")
7100 ENDIF
7110NEXT
7120PROCputline("   ALIGN")
7130PROCputline(":")
7140ENDPROC
7150:
7160DEFPROCModule_ServiceBlock
7170REPEAT
7180 a$=FNstrip(FNreadline)
7190 com$=FNupper(FNstrip(LEFT$(a$,INSTR(a$+" "," ")-1)))
7200 IF com$&lt;&gt;"END" THEN
7210  arg$=FNstrip(MID$(a$,INSTR(a$+" "," ")+1))
7220  IF INSTR("&amp;0123456789",LEFT$(com$,1))=0 THEN
7230   tempi%=OPENIN("&lt;JFPatch$Dir&gt;.Resources.Services"):serv=0
7240   IF tempi%&lt;&gt;0 THEN
7250    WHILE (NOT EOF#tempi%) ANDserv=0
7260     a$=GET$#tempi%
7270     IF LEFT$(a$,INSTR(a$," ")-1)=com$ THENserv=EVAL(MID$(a$,INSTR(a$," ")+1))
7280    ENDWHILE
7290    CLOSE#tempi%
7300    IF serv=0 THENERROR 999,"Service name '"+com$+"' not known"
7310   ELSE
7320    ERROR 999,"Could not find Services file"
7330   ENDIF
7340  ELSE
7350   serv=EVAL(com$)
7360  ENDIF
7370  PROCservice_add(serv,arg$)
7380 ENDIF
7390UNTIL FNupper(a$)="END SERVICES"
7400ENDPROC
7410:
7420DEFPROCservice_add(serv,arg$)
7430LOCAL servn
7440IF LEFT$(mod_serv$,1)&lt;&gt;"0" THENERROR 999,"Cannot add service &amp;"+STR$~serv+" whilst explicit service entry in use"
7450servn(mod_servnum)=serv:serv$(mod_servnum)=arg$
7460mod_servnum+=1
7470ENDPROC
7480:
7490DEFPROCModule_EventBlock
7500REPEAT
7510 a$=FNstrip(FNreadline)
7520 com$=FNupper(FNstrip(LEFT$(a$,INSTR(a$+" "," ")-1)))
7530 IF com$&lt;&gt;"END" THEN
7540  arg$=FNstrip(MID$(a$,INSTR(a$+" "," ")+1))
7550  IF INSTR("&amp;0123456789",LEFT$(com$,1))=0 THEN
7560   tempi%=OPENIN("&lt;JFPatch$Dir&gt;.Resources.Events"):event=-1
7570   IF tempi%&lt;&gt;0 THEN
7580    WHILE (NOT EOF#tempi%) ANDevent=-1
7590     a$=GET$#tempi%
7600     IF LEFT$(a$,INSTR(a$," ")-1)=com$ THENevent=EVAL(MID$(a$,INSTR(a$," ")+1))
7610    ENDWHILE
7620    CLOSE#tempi%
7630    IF event=-1 THENERROR 999,"Event name '"+com$+"' not known"
7640   ELSE
7650    ERROR 999,"Could not find Events file"
7660   ENDIF
7670  ELSE
7680   event=EVAL(com$)
7690  ENDIF
7700  eventn(mod_eventn)=event:event$(mod_eventn)=arg$:mod_eventn+=1
7710 ENDIF
7720UNTIL FNupper(a$)="END EVENTS"
7730IF mod_eventn&lt;&gt;0 THEN
7740 vectn(mod_vectn)=&amp;10:vect$(mod_vectn)="module_events"
7750 mod_vectn+=1
7760ENDIF
7770ENDPROC
7780:
7790DEFPROCModule_VectorBlock
7800REPEAT
7810 a$=FNstrip(FNreadline)
7820 com$=FNupper(FNstrip(LEFT$(a$,INSTR(a$+" "," ")-1)))
7830 IF com$&lt;&gt;"END" THEN
7840  arg$=FNstrip(MID$(a$,INSTR(a$+" "," ")+1))
7850  IF INSTR("&amp;0123456789",LEFT$(com$,1))=0 THEN
7860   tempi%=OPENIN("&lt;JFPatch$Dir&gt;.Resources.Vectors"):vect=-1
7870   IF tempi%&lt;&gt;0 THEN
7880    WHILE (NOT EOF#tempi%) ANDvect=-1
7890     a$=GET$#tempi%
7900     IF LEFT$(a$,INSTR(a$," ")-1)=com$ THENvect=EVAL(MID$(a$,INSTR(a$," ")+1))
7910    ENDWHILE
7920    CLOSE#tempi%
7930    IF vect=-1 THENERROR 999,"Vector name '"+com$+"' not known"
7940   ELSE
7950    ERROR 999,"Could not find Vectors file"
7960   ENDIF
7970  ELSE
7980   vect=EVAL(com$)
7990  ENDIF
8000  vectn(mod_vectn)=vect:vect$(mod_vectn)=arg$:mod_vectn+=1
8010 ENDIF
8020UNTIL FNupper(a$)="END VECTORS"
8030ENDPROC
8040:
8050DEFFNascstring(a$):LOCAL b$,c$,c,I:b$=CHR$34:I=1
8060WHILE MID$(a$,I,1)=" "
8070 MID$(a$,I,1)=CHR$160:I+=1
8080ENDWHILE
8090FORI=1TO LEN(a$)
8100 c$=MID$(a$,I,1)
8110 CASE c$ OF
8120  WHEN CHR$34:c$+=CHR$34
8130  WHEN "|"
8140   I+=1:c$=MID$(a$,I,1)
8150   CASE c$ OF
8160    WHEN "|","{":REM Is literal
8170    OTHERWISE:c$=CHR$34+"+CHR$"+STR$(ASC(c$) AND 31)+"+"+CHR$34
8180   ENDCASE
8190  WHEN "{"
8200   I+=1:c$=MID$(a$,I)
8210   c$=LEFT$(c$,INSTR(c$,"}")-1):I+=LEN(c$)
8220   c$=CHR$34+"+"+c$+"+"+CHR$34
8230 ENDCASE
8240 b$+=c$
8250NEXT:b$+=CHR$34
8260WHILE INSTR(b$,"+"+CHR$34+CHR$34)
8270 c=INSTR(b$,"+"+CHR$34+CHR$34)
8280 b$=LEFT$(b$,c-1)+MID$(b$,c+3)
8290ENDWHILE
8300WHILE INSTR(b$,CHR$34+CHR$34+"+")
8310 c=INSTR(b$,CHR$34+CHR$34+"+")
8320 b$=LEFT$(b$,c-1)+MID$(b$,c+3)
8330ENDWHILE
8340=b$
8350:
8360DEFPROCModule_PreFilter
8370LOCAL s,I
8380REPEAT
8390 a$=FNstrip(FNreadline)
8400 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
8410 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
8420 CASE com$ OF
8430  WHEN "NAME"  :IFmod_bfn&gt;(maxbfilter+1)THEN
8440    ERROR 999,"The maximum number of pre-filters has been reached"
8450   ELSE
8460    IFmod_bfn&gt;0THEN
8470     IFmod_bfilter$(mod_bfn-1)=""THEN
8480      ERROR999,"CODE expected in filter definition"
8490     ELSE
8500      IFmod_bftask$(mod_bfn-1)=""THENERROR999,"TASK expected in filter definition"
8510     ENDIF
8520    ENDIF
8530    mod_bfname$(mod_bfn)=arg$
8540    mod_bfn+=1
8550   ENDIF
8560  WHEN "TASK"  :IFmod_bfn&gt;0THEN
8570    IFmod_bfname$(mod_bfn-1)&lt;&gt;""ANDmod_bftask$(mod_bfn-1)=""THEN
8580     mod_bftask$(mod_bfn-1)=arg$
8590    ELSE
8600    IFmod_bfname$(modbfn-1)&lt;&gt;""THENERROR999,"NAME must be specified before TASK in filter definition"ELSEERROR999,"TASK already specified for filter definition"
8610    ENDIF
8620   ELSE
8630    ERROR 999,"NAME must be specified before TASK in filter definition"
8640   ENDIF
8650  WHEN "CODE"  :IFmod_bfn&gt;0THEN
8660    IFmod_bfname$(mod_bfn-1)&lt;&gt;""ANDmod_bfilter$(mod_bfn-1)=""THEN
8670     mod_bfilter$(mod_bfn-1)=arg$
8680    ELSE
8690    IFmod_bfname$(modbfn-1)&lt;&gt;""THENERROR999,"NAME must be specified before CODE in filter definition"ELSEERROR999,"CODE already specified for filter definition"
8700    ENDIF
8710   ELSE
8720    ERROR999,"NAME must be specified before CODE in filter definition"
8730   ENDIF
8740  WHEN "METHOD":IFmod_bfn&gt;0THEN
8750    IFmod_bfname$(mod_bfn-1)&lt;&gt;""THEN
8760     CASE FNupper(arg$) OF
8770      WHEN "ERROR" :mod_bfmethod(mod_bfn-1)=0
8780      WHEN "MULTIPLE":mod_bfmethod(mod_bfn-1)=1
8790      OTHERWISE    :ERROR999,"METHOD not known in filter definition"
8800     ENDCASE
8810    ELSE
8820     ERROR999,"NAME must be specified before METHOD in filter definition"
8830    ENDIF
8840   ELSE
8850    ERROR999,"NAME must be specified before METHOD in filter definition"
8860   ENDIF
8870 ENDCASE
8880UNTILFNupper(a$)="END PREFILTER" ORFNupper(a$)="END FILTER"
8890IFmod_bfn&gt;0THEN
8900 IFmod_bfname$(mod_bfn-1)=""THEN
8910  ERROR999,"NAME expected in filter definition"
8920 ELSE
8930  IFmod_bfilter$(mod_bfn-1)=""THEN
8940   ERROR999,"CODE expected in filter definition"
8950  ELSE
8960   IFmod_bftask$(mod_bfn-1)=""THENERROR999,"TASK expected in filter definition"
8970  ENDIF
8980 ENDIF
8990IF mod_fltr_multi THEN I=TRUE ELSE I=FALSE
9000 FORs=0TOmod_bfn-1
9010  IFmod_bftask$(s)="-"THEN
9020   mod_fltr_alltasks=TRUE
9030  ELSE
9040   IFmod_bfmethod(s)=0THENmod_fltr_error=TRUE
9050   IFmod_bfmethod(s)=1THENmod_fltr_multi=TRUE
9060  ENDIF
9070 NEXT
9080 IF (NOT I) AND mod_fltr_multi THEN
9090  arg$="Wimp_Initialise":PROCModule_WSWIname
9100  arg$="_mod_fltr_wimpinitpre":PROCModule_WSWIpre
9110  arg$="_mod_fltr_wimpinitpost":PROCModule_WSWIpost
9120  ENDIF
9130ENDIF
9140ENDPROC
9150:
9160DEFPROCModule_PostFilter
9170LOCAL a$,com$,arg$,b$,c$,s,I
9180REPEAT
9190 a$=FNstrip(FNreadline)
9200 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
9210 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
9220 CASE com$ OF
9230  WHEN "NAME"  :IFmod_afn&gt;(maxafilter+1)THEN
9240    ERROR 999,"The maximum number of post-filters has been reached"
9250   ELSE
9260    IFmod_afn&gt;0THEN
9270     IFmod_afilter$(mod_afn-1)=""THEN
9280      ERROR999,"CODE expected in filter definition"
9290     ELSE
9300      IFmod_aftask$(mod_afn-1)=""THEN
9310       ERROR999,"TASK expected in filter definition"
9320      ELSE
9330       IFmod_afmask$(mod_afn-1)=""THENERROR999,"MASK expected in filter definition"
9340      ENDIF
9350     ENDIF
9360    ENDIF
9370    mod_afname$(mod_afn)=arg$
9380    mod_afn+=1
9390   ENDIF
9400  WHEN "TASK"  :IFmod_afn&gt;0THEN
9410    IFmod_afname$(mod_afn-1)&lt;&gt;""ANDmod_aftask$(mod_afn-1)=""THEN
9420    mod_aftask$(mod_afn-1)=arg$
9430    ELSE
9440    IFmod_afname$(modafn-1)&lt;&gt;""THENERROR999,"NAME must be specified before TASK in filter definition"ELSEERROR 999,"TASK already specified for filter definition"
9450    ENDIF
9460   ELSE
9470    ERROR999,"NAME must be specified before TASK in filter definition"
9480   ENDIF
9490  WHEN "CODE"  :IFmod_afn&gt;0THEN
9500    IFmod_afname$(mod_afn-1)&lt;&gt;""THEN
9510     IF INSTR(arg$," ")=0 THEN
9520      IFmod_afilter$(mod_afn-1)=""ORmod_afilter$(mod_afn-1)="$"THEN
9530       mod_afilter$(mod_afn-1)+=arg$:REM Code    &lt;label&gt;
9540      ELSE
9550       ERROR999,"CODE already specified for filter definition"
9560      ENDIF
9570     ELSE
9580      REM Code       &lt;reason&gt;     &lt;label&gt;
9590      b$=LEFT$(arg$,INSTR(arg$+" "," ")-1)
9600      c$=FNstripc(MID$(arg$,INSTR(arg$+" "," ")+1))
9610      s=FNModule_PollReason(b$)
9620      IF s=-1 THENERROR999,"Unknown Code reason : "+b$
9630      mod_filter$(mod_afn-1,s)=c$
9640      IFmod_afmask$(mod_afn-1)=""THENmod_afmask$(mod_afn-1)="%"+STRING$(20,"1")
9650      IF LEFT$(mod_afmask$(mod_afn-1),1)&lt;&gt;"%" THEN
9660       mod_afmask$(mod_afn-1)="("+mod_afmask$(mod_afn-1)+") AND NOT (1&lt;&lt;"+STR$s+")"
9670      ELSE
9680       MID$(mod_afmask$(mod_afn-1),21-s,1)="0":REM unmask it
9690      ENDIF
9700      mod_afreasons(mod_afn-1)=TRUE
9710      IF LEFT$(mod_afilter$(mod_afn-1),1)&lt;&gt;"$"THENmod_afilter$(mod_afn-1)="$"+mod_afilter$(mod_afn-1)
9720     ENDIF
9730    ELSE
9740     ERROR999,"NAME must be specified before CODE in filter definition"
9750    ENDIF
9760   ELSE
9770    ERROR999,"NAME must be specified before CODE in filter definition"
9780   ENDIF
9790  WHEN "MASK"  :IFmod_afn&gt;0THEN
9800    IFmod_afname$(mod_afn-1)&lt;&gt;""THEN
9810     mod_afmask$(mod_afn-1)=arg$
9820    ELSE
9830     ERROR999,"NAME must be specified before MASK in filter definition"
9840    ENDIF
9850   ELSE
9860    ERROR999,"NAME must be specified before MASK in filter definition"
9870   ENDIF
9880  WHEN "ACCEPT":IFmod_afn&gt;0THEN
9890    IFmod_afname$(mod_afn-1)&lt;&gt;""THEN
9900     PROCModule_Faccept(arg$)
9910    ELSE
9920     ERROR999,"NAME must be specified before ACCEPT in filter definition"
9930    ENDIF
9940   ELSE
9950    ERROR999,"NAME must be specified before ACCEPT in filter definition"
9960   ENDIF
9970  WHEN "METHOD":IFmod_afn&gt;0THEN
9980    IFmod_afname$(mod_afn-1)&lt;&gt;""THEN
9990     CASE FNupper(arg$) OF
10000      WHEN "ERROR" :mod_afmethod(mod_afn-1)=0
10010      WHEN "MULTIPLE":mod_afmethod(mod_afn-1)=1
10020      OTHERWISE    :ERROR999,"METHOD not known in filter definition"
10030     ENDCASE
10040    ELSE
10050     ERROR999,"NAME must be specified before METHOD in filter definition"
10060    ENDIF
10070   ELSE
10080    ERROR999,"NAME must be specified before METHOD in filter definition"
10090   ENDIF
10100 ENDCASE
10110UNTILFNupper(a$)="END POSTFILTER" ORFNupper(a$)="END FILTER"
10120IFmod_afn&gt;0THEN
10130 IFmod_afname$(mod_afn-1)=""THEN
10140  ERROR 999,"NAME expected in filter definition"
10150 ELSE
10160  IFmod_afilter$(mod_afn-1)=""THEN
10170   ERROR999,"CODE expected in filter definition"
10180  ELSE
10190   IFmod_afmask$(mod_afn-1)=""THEN
10200    ERROR999,"MASK expected in filter definition"
10210   ELSE
10220    IFmod_aftask$(mod_afn-1)=""THENERROR999,"TASK expected in filter definition"
10230   ENDIF
10240  ENDIF
10250 ENDIF
10260IF mod_fltr_multi THEN I=TRUE ELSE I=FALSE
10270FORs=0TOmod_afn-1
10280IFmod_aftask$(s)="-"THEN
10290 mod_fltr_alltasks=TRUE
10300ELSE
10310 IFmod_afmethod(s)=0THENmod_fltr_error=TRUE
10320 IFmod_afmethod(s)=1THENmod_fltr_multi=TRUE
10330ENDIF
10340NEXT
10350IF (NOT I) AND mod_fltr_multi THEN
10360arg$="Wimp_Initialise":PROCModule_WSWIname
10370arg$="_mod_fltr_wimpinitpre":PROCModule_WSWIpre
10380arg$="_mod_fltr_wimpinitpost":PROCModule_WSWIpost
10390ENDIF
10400ENDIF
10410ENDPROC
10420:
10430DEFPROCModule_Faccept(a$)
10440IF LEFT$(mod_afmask$(mod_afn-1),1)&lt;&gt;"%" AND mod_afmask$(mod_afn-1)&lt;&gt;"" THENERROR999,"MASK and ACCEPT are mutually exclusive"
10450IF mod_afmask$(mod_afn-1)="" THENmod_afmask$(mod_afn-1)="%"+STRING$(20,"1")
10460a$+=" "
10470WHILE INSTR(a$," ")&gt;0
10480 b$=LEFT$(a$,INSTR(a$," ")-1)
10490 a$=MID$(a$,INSTR(a$," ")+1)
10500 IF b$&lt;&gt;"" THEN
10510  s=FNModule_PollReason(b$)
10520  IF s=-1 THENERROR999,"Unknown Filter mask Accept reason : "+b$
10530  MID$(mod_afmask$(mod_afn-1),21-s,1)="0"
10540 ENDIF
10550ENDWHILE
10560ENDPROC
10570:
10580DEFPROCModule_RectFilter
10590LOCAL s,I
10600REPEAT
10610 a$=FNstrip(FNreadline)
10620 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
10630 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
10640 CASE com$ OF
10650  WHEN "NAME"  :IFmod_rfn&gt;(maxrfilter+1)THEN
10660    ERROR 999,"The maximum number of rectangle filters has been reached"
10670   ELSE
10680    IFmod_rfn&gt;0THEN
10690     IFmod_rfilter$(mod_rfn-1)=""THEN
10700      ERROR999,"CODE expected in filter definition"
10710     ELSE
10720      IFmod_rftask$(mod_rfn-1)=""THENERROR999,"TASK expected in filter definition"
10730     ENDIF
10740    ENDIF
10750    mod_rfname$(mod_rfn)=arg$
10760    mod_rfn+=1
10770   ENDIF
10780  WHEN "TASK"  :IFmod_rfn&gt;0THEN
10790    IFmod_rfname$(mod_rfn-1)&lt;&gt;""ANDmod_rftask$(mod_rfn-1)=""THEN
10800     mod_rftask$(mod_rfn-1)=arg$
10810    ELSE
10820    IFmod_rfname$(modrfn-1)&lt;&gt;""THENERROR999,"NAME must be specified before TASK in filter definition"ELSEERROR999,"TASK already specified for filter definition"
10830    ENDIF
10840   ELSE
10850    ERROR 999,"NAME must be specified before TASK in filter definition"
10860   ENDIF
10870  WHEN "CODE"  :IFmod_rfn&gt;0THEN
10880    IFmod_rfname$(mod_rfn-1)&lt;&gt;""ANDmod_rfilter$(mod_rfn-1)=""THEN
10890     mod_rfilter$(mod_rfn-1)=arg$
10900    ELSE
10910    IFmod_rfname$(modrfn-1)&lt;&gt;""THENERROR999,"NAME must be specified before CODE in filter definition"ELSEERROR999,"CODE already specified for filter definition"
10920    ENDIF
10930   ELSE
10940    ERROR999,"NAME must be specified before CODE in filter definition"
10950   ENDIF
10960  WHEN "METHOD":IFmod_rfn&gt;0THEN
10970    IFmod_rfname$(mod_rfn-1)&lt;&gt;""THEN
10980     CASE FNupper(arg$) OF
10990      WHEN "ERROR" :mod_rfmethod(mod_rfn-1)=0
11000      WHEN "MULTIPLE":mod_rfmethod(mod_rfn-1)=1
11010      OTHERWISE    :ERROR999,"METHOD not known in filter definition"
11020     ENDCASE
11030    ELSE
11040     ERROR999,"NAME must be specified before METHOD in filter definition"
11050    ENDIF
11060   ELSE
11070    ERROR999,"NAME must be specified before METHOD in filter definition"
11080   ENDIF
11090 ENDCASE
11100UNTILFNupper(a$)="END RECTFILTER" ORFNupper(a$)="END FILTER"
11110IFmod_rfn&gt;0THEN
11120 IFmod_rfname$(mod_rfn-1)=""THEN
11130  ERROR999,"NAME expected in filter definition"
11140 ELSE
11150  IFmod_rfilter$(mod_rfn-1)=""THEN
11160   ERROR999,"CODE expected in filter definition"
11170  ELSE
11180   IFmod_rftask$(mod_rfn-1)=""THENERROR999,"TASK expected in filter definition"
11190  ENDIF
11200 ENDIF
11210IF mod_fltr_multi THEN I=TRUE ELSE I=FALSE
11220FORs=0TOmod_rfn-1
11230IFmod_rftask$(s)="-"THEN
11240 mod_fltr_alltasks=TRUE
11250ELSE
11260 IFmod_rfmethod(s)=0THENmod_fltr_error=TRUE
11270 IFmod_rfmethod(s)=1THENmod_fltr_multi=TRUE
11280ENDIF
11290NEXT
11300IF (NOT I) AND mod_fltr_multi THEN
11310arg$="Wimp_Initialise":PROCModule_WSWIname
11320arg$="_mod_fltr_wimpinitpre":PROCModule_WSWIpre
11330arg$="_mod_fltr_wimpinitpost":PROCModule_WSWIpost
11340ENDIF
11350ENDIF
11360ENDPROC
11370:
11380DEFPROCModule_CopyFilter
11390ENDPROC
11400:
11410DEFPROCModule_PostRectFilter
11420LOCAL s,I
11430REPEAT
11440 a$=FNstrip(FNreadline)
11450 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
11460 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
11470 CASE com$ OF
11480  WHEN "NAME"  :IFmod_prfn&gt;(maxprfilter+1)THEN
11490    ERROR 999,"The maximum number of post rectangle filters has been reached"
11500   ELSE
11510    IFmod_prfn&gt;0THEN
11520     IFmod_prfilter$(mod_prfn-1)=""THEN
11530      ERROR999,"CODE expected in filter definition"
11540     ELSE
11550      IFmod_prftask$(mod_prfn-1)=""THENERROR999,"TASK expected in filter definition"
11560     ENDIF
11570    ENDIF
11580    mod_prfname$(mod_prfn)=arg$
11590    mod_prfn+=1
11600   ENDIF
11610  WHEN "TASK"  :IFmod_prfn&gt;0THEN
11620    IFmod_prfname$(mod_prfn-1)&lt;&gt;""ANDmod_prftask$(mod_prfn-1)=""THEN
11630     mod_prftask$(mod_prfn-1)=arg$
11640    ELSE
11650    IFmod_prfname$(modprfn-1)&lt;&gt;""THENERROR999,"NAME must be specified before TASK in filter definition"ELSEERROR999,"TASK already specified for filter definition"
11660    ENDIF
11670   ELSE
11680    ERROR 999,"NAME must be specified before TASK in filter definition"
11690   ENDIF
11700  WHEN "CODE"  :IFmod_prfn&gt;0THEN
11710    IFmod_prfname$(mod_prfn-1)&lt;&gt;""ANDmod_prfilter$(mod_prfn-1)=""THEN
11720     mod_prfilter$(mod_prfn-1)=arg$
11730    ELSE
11740    IFmod_prfname$(modprfn-1)&lt;&gt;""THENERROR999,"NAME must be specified before CODE in filter definition"ELSEERROR999,"CODE already specified for filter definition"
11750    ENDIF
11760   ELSE
11770    ERROR999,"NAME must be specified before CODE in filter definition"
11780   ENDIF
11790  WHEN "METHOD":IFmod_prfn&gt;0THEN
11800    IFmod_prfname$(mod_prfn-1)&lt;&gt;""THEN
11810     CASE FNupper(arg$) OF
11820      WHEN "ERROR" :mod_prfmethod(mod_prfn-1)=0
11830      WHEN "MULTIPLE":mod_prfmethod(mod_prfn-1)=1
11840      OTHERWISE    :ERROR999,"METHOD not known in filter definition"
11850     ENDCASE
11860    ELSE
11870     ERROR999,"NAME must be specified before METHOD in filter definition"
11880    ENDIF
11890   ELSE
11900    ERROR999,"NAME must be specified before METHOD in filter definition"
11910   ENDIF
11920 ENDCASE
11930UNTILFNupper(a$)="END POSTRECTFILTER" ORFNupper(a$)="END FILTER"
11940IFmod_prfn&gt;0THEN
11950 IFmod_prfname$(mod_prfn-1)=""THEN
11960  ERROR999,"NAME expected in filter definition"
11970 ELSE
11980  IFmod_prfilter$(mod_prfn-1)=""THEN
11990   ERROR999,"CODE expected in filter definition"
12000  ELSE
12010   IFmod_prftask$(mod_prfn-1)=""THENERROR999,"TASK expected in filter definition"
12020  ENDIF
12030 ENDIF
12040IF mod_fltr_multi THEN I=TRUE ELSE I=FALSE
12050FORs=0TOmod_prfn-1
12060IFmod_prftask$(s)="-"THEN
12070 mod_fltr_alltasks=TRUE
12080ELSE
12090 IFmod_prfmethod(s)=0THENmod_fltr_error=TRUE
12100 IFmod_prfmethod(s)=1THENmod_fltr_multi=TRUE
12110ENDIF
12120NEXT
12130IF (NOT I) AND mod_fltr_multi THEN
12140arg$="Wimp_Initialise":PROCModule_WSWIname
12150arg$="_mod_fltr_wimpinitpre":PROCModule_WSWIpre
12160arg$="_mod_fltr_wimpinitpost":PROCModule_WSWIpost
12170ENDIF
12180ENDIF
12190ENDPROC
12200:
12210DEFPROCModule_PostIconFilter
12220LOCAL s,I
12230REPEAT
12240 a$=FNstrip(FNreadline)
12250 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
12260 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
12270 CASE com$ OF
12280  WHEN "NAME"  :IFmod_ifn&gt;(maxifilter+1)THEN
12290    ERROR 999,"The maximum number of post icon filters has been reached"
12300   ELSE
12310    IFmod_ifn&gt;0THEN
12320     IFmod_ifilter$(mod_ifn-1)=""THEN
12330      ERROR999,"CODE expected in filter definition"
12340     ELSE
12350      IFmod_iftask$(mod_ifn-1)=""THENERROR999,"TASK expected in filter definition"
12360     ENDIF
12370    ENDIF
12380    mod_ifname$(mod_ifn)=arg$
12390    mod_ifn+=1
12400   ENDIF
12410  WHEN "TASK"  :IFmod_ifn&gt;0THEN
12420    IFmod_ifname$(mod_ifn-1)&lt;&gt;""ANDmod_iftask$(mod_ifn-1)=""THEN
12430     mod_iftask$(mod_ifn-1)=arg$
12440    ELSE
12450    IFmod_ifname$(modifn-1)&lt;&gt;""THENERROR999,"NAME must be specified before TASK in filter definition"ELSEERROR999,"TASK already specified for filter definition"
12460    ENDIF
12470   ELSE
12480    ERROR 999,"NAME must be specified before TASK in filter definition"
12490   ENDIF
12500  WHEN "CODE"  :IFmod_ifn&gt;0THEN
12510    IFmod_ifname$(mod_ifn-1)&lt;&gt;""ANDmod_ifilter$(mod_ifn-1)=""THEN
12520     mod_ifilter$(mod_ifn-1)=arg$
12530    ELSE
12540    IFmod_ifname$(modifn-1)&lt;&gt;""THENERROR999,"NAME must be specified before CODE in filter definition"ELSEERROR999,"CODE already specified for filter definition"
12550    ENDIF
12560   ELSE
12570    ERROR999,"NAME must be specified before CODE in filter definition"
12580   ENDIF
12590  WHEN "METHOD":IFmod_ifn&gt;0THEN
12600    IFmod_ifname$(mod_ifn-1)&lt;&gt;""THEN
12610     CASE FNupper(arg$) OF
12620      WHEN "ERROR" :mod_ifmethod(mod_ifn-1)=0
12630      WHEN "MULTIPLE":mod_ifmethod(mod_ifn-1)=1
12640      OTHERWISE    :ERROR999,"METHOD not known in filter definition"
12650     ENDCASE
12660    ELSE
12670     ERROR999,"NAME must be specified before METHOD in filter definition"
12680    ENDIF
12690   ELSE
12700    ERROR999,"NAME must be specified before METHOD in filter definition"
12710   ENDIF
12720 ENDCASE
12730UNTILFNupper(a$)="END POSTICONFILTER" ORFNupper(a$)="END FILTER"
12740IFmod_ifn&gt;0THEN
12750 IFmod_ifname$(mod_ifn-1)=""THEN
12760  ERROR999,"NAME expected in filter definition"
12770 ELSE
12780  IFmod_ifilter$(mod_ifn-1)=""THEN
12790   ERROR999,"CODE expected in filter definition"
12800  ELSE
12810   IFmod_iftask$(mod_ifn-1)=""THENERROR999,"TASK expected in filter definition"
12820  ENDIF
12830 ENDIF
12840IF mod_fltr_multi THEN I=TRUE ELSE I=FALSE
12850FORs=0TOmod_ifn-1
12860IFmod_iftask$(s)="-"THEN
12870 mod_fltr_alltasks=TRUE
12880ELSE
12890 IFmod_ifmethod(s)=0THENmod_fltr_error=TRUE
12900 IFmod_ifmethod(s)=1THENmod_fltr_multi=TRUE
12910ENDIF
12920NEXT
12930IF (NOT I) AND mod_fltr_multi THEN
12940arg$="Wimp_Initialise":PROCModule_WSWIname
12950arg$="_mod_fltr_wimpinitpre":PROCModule_WSWIpre
12960arg$="_mod_fltr_wimpinitpost":PROCModule_WSWIpost
12970ENDIF
12980ENDIF
12990ENDPROC
13000:
13010DEFFNModule_PollReason(a$)
13020tempi%=OPENIN("&lt;JFPatch$Dir&gt;.Resources.WimpReason"):s=0
13030IF tempi%&lt;&gt;0 THEN
13040 com$=FNupper(a$)
13050 WHILE (NOT EOF#tempi%) ANDs=0
13060  a$=GET$#tempi%
13070  IF FNupper(LEFT$(a$,INSTR(a$," ")-1))=com$ THEN s=EVAL(MID$(a$,INSTR(a$," ")+1))
13080 ENDWHILE
13090 CLOSE#tempi%
13100 IF s=0 THENs=-1 ELSEIFs=-1 THENs=0
13110ELSE
13120 ERROR 999,"Could not find Wimp Reason Code file"
13130ENDIF
13140=s
13150:
13160DEFPROCModule_ImageFS
13170mod_img_open$="0":mod_img_close$="0"
13180mod_img_get$="0":mod_img_put$="0"
13190mod_img_args$="0":mod_img_file$="0":mod_img_func$="0"
13200mod_img_type$="":mod_img_flags%=0
13210REPEAT
13220 a$=FNstrip(FNreadline)
13230 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
13240 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
13250 CASE com$ OF
13260  WHEN "FLAGS"
13270   WHILE arg$&lt;&gt;""
13280    b$=LEFT$(arg$,INSTR(arg$+" "," ")-1)
13290    arg$=FNstripc(MID$(arg$,INSTR(arg$+" "," ")+1))
13300    dir=1:REM We're saying it's set
13310    IF LEFT$(b$,1)="-" THENb$=MID$(b$,2):dir=-1
13320    CASE FNupper(b$) OF
13330     WHEN "TELLFSWHENFLUSHING","TELLWHENFLUSHING":bit=27
13340     OTHERWISE
13350      ERROR 999,"Flag '"+b$+"' not known in ImageFS"
13360    ENDCASE
13370    IF dir=1 THENmod_img_flags%=mod_img_flags% OR (1&lt;&lt;bit) ELSEmod_img_flags%=mod_img_flags% AND NOT (1&lt;&lt;bit)
13380   ENDWHILE
13390  WHEN "TYPE","FILETYPE"
13400   IF LEFT$(arg$,1)&lt;&gt;"&amp;" THEN
13410    SYS "XOS_FSControl",31,arg$ TO ,,num;flags
13420    IF (flags AND 1) THENERROR 999,"Unknown filetype in ImageFS TYPE"
13430    arg$="&amp;"+STR$~num+" ; "+arg$
13440   ENDIF
13450   mod_img_type$=arg$
13460  WHEN "OPEN":mod_img_open$=arg$
13470  WHEN "CLOSE":mod_img_close$=arg$
13480  WHEN "GET","GETBYTES":mod_img_get$=arg$
13490  WHEN "PUT","PUTBYTES":mod_img_put$=arg$
13500  WHEN "ARGS":mod_img_args$=arg$
13510  WHEN "FILE":mod_img_file$=arg$
13520  WHEN "FUNC":mod_img_func$=arg$
13530 ENDCASE
13540UNTILFNupper(a$)="END IMAGEFS" ORFNupper(a$)="END FS"
13550IF mod_img_type$="" THENERROR 999,"TYPE not defined in ImageFS"
13560ENDPROC
13570:
13580DEFPROCModule_FS
13590LOCAL b$,a$,com$,arg$
13600mod_fs_open$="0":mod_fs_close$="0"
13610mod_fs_get$="0":mod_fs_put$="0":mod_fs_gbpb$="0"
13620mod_fs_args$="0":mod_fs_file$="0":mod_fs_func$="0"
13630mod_fs_name$="":mod_fs_flags%=0:mod_fs_eflags%=0
13640mod_fs_startup$=""
13650mod_fs_number=-1:mod_fs_files=-1
13660REPEAT
13670 a$=FNstrip(FNreadline)
13680 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
13690 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
13700 CASE com$ OF
13710  WHEN "FLAGS"
13720   WHILE arg$&lt;&gt;""
13730    b$=LEFT$(arg$,INSTR(arg$+" "," ")-1)
13740    arg$=FNstripc(MID$(arg$,INSTR(arg$+" "," ")+1))
13750    dir=1:REM We're saying it's set
13760    IF LEFT$(b$,1)="-" THENb$=MID$(b$,2):dir=-1
13770    CASE FNupper(b$) OF
13780     WHEN "SPECIALFIELDS":bit=31
13790     WHEN "INTERACTIVESTREAMS","INTERACTIVE":bit=30
13800     WHEN "NULLFILENAMES":bit=29
13810     WHEN "ALWAYSOPENFILES":bit=28
13820     WHEN "TELLFSWHENFLUSHING","TELLWHENFLUSHING":bit=27
13830     WHEN "SUPPORTSFILE9":bit=26
13840     WHEN "SUPPORTSFUNC20":bit=25
13850     WHEN "SUPPORTSFUNC18":bit=24
13860     WHEN "SUPPORTSIMAGEFS":bit=23
13870     WHEN "USEURDLIB":bit=22
13880     WHEN "NODIRECTORIES","NODIRS":bit=21
13890     WHEN "NEVERLOAD","USEOPENGETCLOSE":bit=20
13900     WHEN "NEVERSAVE","USEOPENPUTCLOSE":bit=19
13910     WHEN "USEFUNC9":bit=18
13920     REM 17 = extra word present
13930     WHEN "READONLY":bit=16
13940     WHEN "SUPPORTSFILE34":bit=32+0
13950     WHEN "SUPPORTSCAT":bit=32+1
13960     WHEN "SUPPORTSEX":bit=32+2
13970     OTHERWISE
13980      ERROR 999,"Flag '"+b$+"' not known in FS"
13990    ENDCASE
14000    IF bit&gt;31 THEN
14010     bit-=1
14020     IF dir=1 THENmod_fs_eflags%=mod_fs_eflags% OR (1&lt;&lt;bit) ELSEmod_fs_eflags%=mod_fs_eflags% AND NOT (1&lt;&lt;bit)
14030    ELSE
14040     IF dir=1 THENmod_fs_flags%=mod_fs_flags% OR (1&lt;&lt;bit) ELSEmod_fs_flags%=mod_fs_flags% AND NOT (1&lt;&lt;bit)
14050    ENDIF
14060   ENDWHILE
14070  WHEN "NAME":mod_fs_name$=arg$
14080  WHEN "STARTUP":mod_fs_startup$=arg$
14090  WHEN "NUMBER":mod_fs_number=EVAL(arg$)
14100  WHEN "OPEN":mod_fs_open$=arg$
14110  WHEN "CLOSE":mod_fs_close$=arg$
14120  WHEN "GET","GETBYTES":mod_fs_get$=arg$
14130  WHEN "PUT","PUTBYTES":mod_fs_put$=arg$
14140  WHEN "ARGS":mod_fs_args$=arg$
14150  WHEN "FILE":mod_fs_file$=arg$
14160  WHEN "FUNC":mod_fs_func$=arg$
14170  WHEN "GBPB":mod_fs_gbpb$=arg$
14180  WHEN "FILES"
14190   IF FNupper(arg$)="INFINITE" OR arg$="-" THENarg$="0"
14200   mod_fs_files=EVAL(arg$)
14210 ENDCASE
14220UNTIL FNupper(a$)="END FS"
14230IF mod_fs_name$="" THENERROR 999,"NAME not defined in FS"
14240IF mod_fs_number=-1 THENERROR 999,"NUMBER not defined in FS"
14250IF mod_fs_files=-1 THENERROR 999,"FILES not defined in FS"
14260ENDPROC
14270:
14280DEFPROCModule_WimpSWIVe
14290REPEAT
14300 a$=FNstrip(FNreadline)
14310 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
14320 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
14330 CASE com$ OF
14340  WHEN "SWI"   :PROCModule_WSWIname
14350  WHEN "PRE"   :PROCModule_WSWIpre
14360  WHEN "POST"  :PROCModule_WSWIpost
14370 ENDCASE
14380UNTILFNupper(a$)="END WIMPSWIS" ORFNupper(a$)="END WSWIS"
14390ENDPROC
14400:
14410DEFPROCModule_WSWIname
14420mod_wswis+=1:wswi$(mod_wswis,0)=arg$
14430ENDPROC
14440DEFPROCModule_WSWIpre:wswi$(mod_wswis,1)=arg$:ENDPROC
14450DEFPROCModule_WSWIpost:wswi$(mod_wswis,2)=arg$:ENDPROC
14460:
14470DEFPROCModule_SWIs
14480mod_swibase$="":mod_swiprefix$=""
14490REPEAT
14500 a$=FNstrip(FNreadline)
14510 com$=FNupper(LEFT$(a$,INSTR(a$+" "," ")-1))
14520 arg$=FNstripc(MID$(a$,INSTR(a$+" "," ")+1))
14530 IF FNupper(a$)&lt;&gt;"END SWIS"AND FNupper(a$)&lt;&gt;"END SWI"THEN
14540  CASE com$ OF
14550   WHEN "BASE"  :PROCModule_SWIBase
14560   WHEN "PREFIX":PROCModule_SWIPrefix
14570   WHEN "POST"  :PROCModule_SWIPost
14580   WHEN "PRE"   :PROCModule_SWIPre
14590   WHEN "{"     :PROCignorerems(a$)
14600   OTHERWISE    :PROCModule_SWICode
14610  ENDCASE
14620 ENDIF
14630UNTILFNupper(a$)="END SWIS" ORFNupper(a$)="END SWI"
14640ENDPROC
14650:
14660DEFPROCModule_SWIBase
14670IF mod_swibase$&lt;&gt;"" THENERROR 999,"SWI base already defined"
14680mod_swibase$="&amp;"+STR$~(EVAL(arg$))
14690ENDPROC
14700:
14710DEFPROCModule_SWIPrefix
14720IF mod_swiprefix$&lt;&gt;"" THENERROR 999,"SWI prefix already defined"
14730mod_swiprefix$=arg$
14740ENDPROC
14750:
14760DEFPROCModule_SWIPost
14770IF mod_swipost$&lt;&gt;"" THENERROR 999,"SWI post-handler already defined"
14780mod_swipost$=arg$
14790ENDPROC
14800:
14810DEFPROCModule_SWIPre
14820IF mod_swipre$&lt;&gt;"" THENERROR 999,"SWI pre-handler already defined"
14830mod_swipre$=arg$
14840ENDPROC
14850:
14860DEFPROCModule_SWICode
14870LOCAL ERROR
14880ON ERROR LOCAL:RESTORE ERROR:ERROR ERR,"Unrecognised command in SWI preprocessor ("+com$+")"
14890swi=EVAL(com$)
14900IF swi=0 AND INSTR(com$,"0")=0 THENERROR 999,"Unrecognised command in SWI preprocessor"
14910swi$(swi)=FNstrip(LEFT$(arg$,INSTR(arg$+" "," ")-1))
14920swic$(swi)=FNstrip(MID$(arg$,INSTR(arg$+" "," ")+1))
14930IF swi+1&gt;mod_swis THENmod_swis=swi+1
14940ENDPROC
14950:
14960DEFPROCModule_ResourceBlock
14970REPEAT
14980 a$=FNstrip(FNreadline)
14990 com$=FNupper(FNstrip(LEFT$(a$,INSTR(a$+" "," ")-1)))
15000 IF com$&lt;&gt;"END" THEN
15010  arg$=FNstrip(MID$(a$,INSTR(a$+" "," ")+1))
15020  resourcel$(mod_resourcen)=FNlocalisefile(com$):resources$(mod_resourcen)=arg$
15030  mod_resourcen+=1
15040 ENDIF
15050UNTIL FNupper(a$)="END RESOURCES"
15060ENDPROC
15070:
15080DEFPROCModule_AssembleEvents
15090PROCputline("; ***** Events dispatcher")
15100PROCputline(".module_events")
15110FORI=0TOmod_eventn-1
15120 PROCputline("   TEQ     r0,#"+STR$(eventn(I)))
15130 PROCputline("   BEQ     "+event$(I))
15140NEXT
15150PROCputline("   MOV     pc,link")
15160ENDPROC
15170:
15180DEFPROCModule_AssembleSWIs
15190PROCputline("; ***** SWI table")
15200REM A tiny optimisation !
15210IF mod_name$=mod_swiprefix$ THENPROCputline(".module_title")
15220PROCputline(".module_switable")
15230PROCputline("   EQUS "+FNmod_align(CHR$34+mod_swiprefix$+CHR$34,16))
15240PROCputline("   EQUB 0")
15250FORI=0TO mod_swis-1
15260 IF swi$(I)="" THENswi$(I)=STR$I
15270 PROCputline("   EQUS """+swi$(I)+"""+CHR$0")
15280NEXT
15290PROCputline("   EQUB 0")
15300PROCputline("   ALIGN")
15310PROCputline(":")
15320IF mod_swihandler$&lt;&gt;"" THENENDPROC
15330PROCputline("; ***** SWI handler code")
15340PROCputline(".module_swicode")
15350IF mod_ws$&lt;&gt;"-" THEN
15360 PROCputline("   LDR     r12,[r12]")
15370ENDIF
15380IF mod_swipre$&lt;&gt;"" OR mod_swipost$&lt;&gt;"" THEN
15390 PROCputline("   STR     link,[sp,#-4]!")
15400 IF mod_swipre$&lt;&gt;"" THEN
15410  PROCputline("   BL      "+FNmod_align(mod_swipre$,22))
15420 ENDIF
15430 IF mod_swipost$&lt;&gt;"" THEN
15440  PROCputline("   ADR     link,module_swipost")
15450 ELSE
15460  PROCputline("   LDR     link,[sp],#4")
15470 ENDIF
15480ENDIF
15490PROCputline("   CMP     r11,#"+STR$mod_swis)
15500PROCputline("   ADDLT   pc,pc,r11,LSL #2")
15510PROCputline("   B       module_swierror")
15520PROCputline("; ***** SWI jump table")
15530FORI=0TO mod_swis-1
15540 IF swic$(I)="" THENc$="MOV     pc,link" ELSEc$="B      "+FNmod_call(swic$(I))+" ; "+swic$(I)
15550 PROCputline("   "+c$)
15560NEXT
15570IF mod_swipost$&lt;&gt;"" THEN
15580 PROCputline(".module_swipost")
15590 PROCputline("   BL      "+FNmod_align(mod_swipost$,23))
15600 PROCputline("   LDR     pc,[sp],#4")
15610ENDIF
15620PROCputline(".module_swierror")
15630PROCputline("   STMFD   (sp)!,{r1-r4,link}")
15640PROCputline("   ADR     r0,`module_swierror")
15650PROCputline("   MOV     r1,#0")
15660PROCputline("   MOV     r2,#0")
15670PROCputline("   ADR     r4,module_title")
15680PROCputline("   SWI     ""XMessageTrans_ErrorLookup""")
15690PROCputline("   LDMFD   (sp)!,{r1-r4,link}")
15700PROCputline("   ORRS    pc,link,#vbit        ; set V flag and return")
15710PROCputline(".`module_swierror")
15720PROCputline("   EQUD    &amp;1E6")
15730PROCputline("   EQUS    ""BadSWI""+CHR$0")
15740PROCputline("   ALIGN")
15750PROCputline(":")
15760ENDPROC
15770:
15780DEFPROCModule_extra_filter
15790LOCAL s,I
15800PROCputline("; ***** Set up registers for filters")
15810PROCputline("._mod_fltr_FilterTasks")
15820PROCputline("   STMFD   (sp)!,{r0-r5,r7,link}")
15830PROCputline("   MOV     r0,#0")
15840PROCputline("   ADR     r1,`mod_filterblock")
15850PROCputline("   SUB     r4,r1,#16")
15860IF mod_fltr_error OR mod_fltr_multi THEN
15870 PROCputline("   ADR     r2,`_mod_fltr_TaskBlock")
15880 PROCputline("   STMFD   (sp)!,{r1-r2,r4}")
15890ENDIF
15900IF mod_fltr_error OR mod_fltr_alltasks THEN
15910 IF mod_fltr_error THEN
15920  IF NOT mod_fltr_alltasks THEN
15930   PROCputline("   TEQ     r6,#1")
15940   PROCputline("   BEQ     __mod_fltr_filttask_nexttask")
15950  ENDIF
15960  PROCputline("   MOV     r7,#0")
15970  PROCputline("   MVN     r5,#0")
15980  PROCputline(".__mod_fltr_filttask_errorsetup")
15990  PROCputline("   ADD     r5,r5,#1")
16000 ELSE
16010  PROCputline(".__mod_fltr_filttask_errorsetup")
16020 ENDIF
16030 PROCputline("   LDR     r3,[r4,#16]!")
16040 PROCputline("   CMN     r3,#1")
16050 PROCputline("   BEQ     __mod_fltr_filttask_nexttask")
16060 IF mod_fltr_alltasks THEN
16070  PROCputline("   TEQ     r3,#0")
16080  PROCputline("   BLEQ    _mod_fltr_AddRemFilters")
16090  IF mod_fltr_error THEN
16100   PROCputline("   BEQ     __mod_fltr_filttask_errorsetup")
16110   PROCputline("   TEQ     r6,#1")
16120   PROCputline("   BEQ     __mod_fltr_filttask_errorsetup")
16130  ENDIF
16140 ENDIF
16150 IF mod_fltr_error THEN
16160  PROCputline("   LDR     r3,[r4,#4]")
16170  PROCputline("   TST     r3,#&amp;0C000000")
16180  PROCputline("   BNE     __mod_fltr_filttask_errorsetup")
16190  PROCputline("   MOV     r3,#1")
16200  PROCputline("   ORR     r7,r7,r3,LSL r5")
16210 ENDIF
16220 PROCputline("   B       __mod_fltr_filttask_errorsetup")
16230ENDIF
16240PROCputline(".__mod_fltr_filttask_nexttask")
16250IF NOT (mod_fltr_error OR mod_fltr_multi) THEN
16260 PROCputline("   LDMFD   (sp)!,{r0-r5,r7,pc}^")
16270ELSE
16280 PROCputline("   LDR     r1,[sp,#4]")
16290 PROCputline("   MOV     r2,#16")
16300 PROCputline("   SWI     ""XTaskManager_EnumerateTasks""")
16310 PROCputline("   BVS     __mod_fltr_filttask_exit")
16320 PROCputline("   CMN     r0,#1")
16330 PROCputline("   BEQ     __mod_fltr_filttask_exit")
16340 PROCputline("   LDMFD   sp,{r1-r2,r4}")
16350 PROCputline("   LDR     r2,[r2,#4]")
16360 IF mod_fltr_error THEN
16370  PROCputline("   MVN     r5,#0")
16380  PROCputline(".__mod_fltr_filttask_checkloop")
16390  PROCputline("   ADD     r5,r5,#1")
16400 ELSE
16410  PROCputline(".__mod_fltr_filttask_checkloop")
16420 ENDIF
16430 PROCputline("   LDR     r3,[r4,#16]!")
16440 PROCputline("   CMN     r3,#1")
16450 PROCputline("   BEQ     __mod_fltr_filttask_nexttask")
16460 PROCputline("   BL      _mod_fltr_CheckName")
16470 PROCputline("   BNE     __mod_fltr_filttask_checkloop")
16480 PROCputline("   LDR     r3,[sp,#4]")
16490 PROCputline("   LDR     r3,[r3]")
16500 PROCputline("   BL      _mod_fltr_AddRemFilters")
16510 IF mod_fltr_error THEN
16520  PROCputline("   MOV     r3,#1")
16530  PROCputline("   BIC     r7,r7,r3,LSL r5")
16540 ENDIF
16550 PROCputline("   B       __mod_fltr_filttask_checkloop")
16560 PROCputline(".__mod_fltr_filttask_exit")
16570 IF mod_fltr_error THEN
16580  PROCputline("   TEQ     r6,#1")
16590  PROCputline("   TEQNE   r7,#0")
16600  PROCputline("   ADDEQ   sp,sp,#12")
16610  PROCputline("   LDMEQFD (sp)!,{r0-r5,r7,pc}^")
16620  PROCputline("   ADR     r0,`__mod_fltr_filttask_notask")
16630  PROCputline("   ADD     sp,sp,#16")
16640  PROCputline("   LDMFD   (sp)!,{r1-r5,r7,link}")
16650  PROCputline("   ORRS    pc,r14,#vbit")
16660  PROCputline(".`__mod_fltr_filttask_notask")
16670  PROCputline("   EQUD    0")
16680  PROCputline("   EQUS    """+mod_name$+" cannot find task to apply filter to""+CHR$(0)")
16690  PROCputline("   ALIGN")
16700 ELSE
16710  PROCputline("   ADD     sp,sp,#12")
16720  PROCputline("   LDMFD   (sp)!,{r0-r5,r7,pc}^")
16730 ENDIF
16740PROCputline(".`_mod_fltr_TaskBlock")
16750PROCputline("   EQUD    0")
16760PROCputline("   EQUD    0")
16770PROCputline("   EQUD    0")
16780PROCputline("   EQUD    0")
16790ENDIF
16800IF mod_fltr_multi THEN
16810 PROCputline("   EQUD    0")
16820 PROCputline(":")
16830 PROCputline("._mod_fltr_wimpinitpre")
16840 PROCputline("   STMFD   (sp)!,{r0-r4,link}")
16850 PROCputline("   LDRB    link,`_mod_fltr_TaskBlock+16")
16860 PROCputline("   TEQ     link,#0")
16870 PROCputline("   ADDNE   link,link,#1")
16880 PROCputline("   STRNEB  link,`_mod_fltr_TaskBlock+16")
16890 PROCputline("   LDMNEFD (sp)!,{r0-r4,pc}^")
16900 PROCputline("   ADR     r1,`mod_filterblock")
16910 PROCputline("   SUB     r4,r1,#16")
16920 PROCputline(".__mod_fltr_wimpinitpre_CheckLoop")
16930 PROCputline("   LDR     r3,[r4,#16]!")
16940 PROCputline("   CMN     r3,#1")
16950 PROCputline("   LDMEQFD (sp)!,{r0-r4,pc}^")
16960 PROCputline("   BL      _mod_fltr_CheckName")
16970 PROCputline("   BNE     __mod_fltr_wimpinitpre_CheckLoop")
16980 IF mod_fltr_error THEN
16990  PROCputline("   LDR     r3,[r4,#4]")
17000  PROCputline("   TST     r3,#&amp;0C000000")
17010  PROCputline("   BEQ     __mod_fltr_wimpinitpre_CheckLoop")
17020 ENDIF
17030 PROCputline("   MOV     r0,#1")
17040 PROCputline("   STRB    r0,`_mod_fltr_TaskBlock+16")
17050 PROCputline("   SUB     r4,r4,r1")
17060 PROCputline("   MOV     r4,r4,LSR #4")
17070 PROCputline("   STRB    r4,`_mod_fltr_TaskBlock+17")
17080 PROCputline("   LDMFD   (sp)!,{r0-r4,pc}^")
17090 PROCputline(":")
17100 PROCputline("._mod_fltr_wimpinitpost")
17110 PROCputline("   STMFD   (sp)!,{link}")
17120 PROCputline("   LDRB    link,`_mod_fltr_TaskBlock+16")
17130 PROCputline("   TEQ     link,#0")
17140 PROCputline("   LDMEQFD (sp)!,{pc}")
17150 PROCputline("   SUBS    link,link,#1")
17160 PROCputline("   STRB    link,`_mod_fltr_TaskBlock+16")
17170 PROCputline("   LDMFD   (sp)!,{link}")
17180 PROCputline("   MOVNES  pc,link")
17190 PROCputline("   TEQP    link,#0")
17200 PROCputline("   MOVVSS  pc,link")
17210 PROCputline("   STMFD   (sp)!,{r0-r6,link}")
17220 PROCputline("   ADR     r1,`mod_filterblock")
17230 PROCputline("   LDRB    r4,`_mod_fltr_TaskBlock+17")
17240 PROCputline("   ADD     r4,r1,r4,LSL #4")
17250 PROCputline("   LDR     r2,[r4]")
17260 PROCputline("   ADD     r2,r2,r1")
17270 PROCputline(".__mod_fltr_wimpinitpost_DoStuff")
17280 PROCputline("   LDR     r3,[sp,#4]")
17290 PROCputline("   MOV     r6,#0")
17300 PROCputline("   BL      _mod_fltr_AddRemFilters")
17310 PROCputline(".__mod_fltr_wimpinitpost_CheckLoop")
17320 PROCputline("   LDR     r3,[r4,#16]!")
17330 PROCputline("   CMN     r3,#1")
17340 PROCputline("   LDMEQFD (sp)!,{r0-r6,pc}^")
17350 PROCputline("   BL      _mod_fltr_CheckName")
17360 PROCputline("   BNE     __mod_fltr_wimpinitpost_CheckLoop")
17370 IF mod_fltr_error THEN
17380  PROCputline("  LDR     r3,[r4,#4]")
17390  PROCputline("  TST     r3,#&amp;0C000000")
17400  PROCputline("  BEQ     __mod_fltr_wimpinitpost_CheckLoop")
17410 ENDIF
17420 PROCputline("   B       __mod_fltr_wimpinitpost_DoStuff")
17430ENDIF
17440PROCputline(":")
17450IF mod_fltr_error OR mod_fltr_multi THEN
17460 PROCputline("._mod_fltr_CheckName")
17470 PROCputline("   STMFD   (sp)!,{r0-r3,link}")
17480 IF mod_fltr_alltasks THEN
17490  PROCputline("   TEQ     r3,#0")
17500  PROCputline("   BNE     __mod_fltr_chckname_skipneset")
17510  PROCputline("   TEQ     r1,r3")
17520  PROCputline("   B       __mod_fltr_chckname_notfound")
17530  PROCputline(".__mod_fltr_chckname_skipneset")
17540 ENDIF
17550 PROCputline("   ADD     r3,r3,r1")
17560 PROCputline(".__mod_fltr_chckname_checkname")
17570 PROCputline("   LDRB    r0,[r2],#1")
17580 PROCputline("   LDRB    r1,[r3],#1")
17590 PROCputline("   CMP     r0,#32")
17600 PROCputline("   MOVLT   r0,#0")
17610 PROCputline("   CMP     r1,#32")
17620 PROCputline("   MOVLT   r1,#0")
17630 PROCputline("   TEQ     r0,r1")
17640 PROCputline("   BNE     __mod_fltr_chckname_notfound")
17650 PROCputline("   TEQ     r0,#0")
17660 PROCputline("   BNE     __mod_fltr_chckname_checkname")
17670 PROCputline(".__mod_fltr_chckname_notfound")
17680 PROCputline("   LDMFD   (sp)!,{r0-r3,pc}")
17690 PROCputline(":")
17700ENDIF
17710PROCputline("._mod_fltr_AddRemFilters")
17720PROCputline("   STMFD   (sp)!,{r0-r5,link}")
17730PROCputline("   LDR     r5,[r4,#4]")
17740PROCputline("   BIC     r0,r5,#&amp;FC000000")
17750PROCputline("   ADD     r0,r0,r1")
17760PROCputline("   LDR     r2,[r4,#8]")
17770PROCputline("   TST     r5,#&amp;10000000")
17780PROCputline("   ADDEQ   r1,r2,r1")
17790PROCputline("   MOVNE   r1,r2")
17800PROCputline("   MOV     r2,r12")
17810PROCputline("   LDR     r4,[r4,#12]")
17820PROCputline("   MOV     r5,r5,LSR #29")
17830PROCputline("   TEQ     r6,#1")
17840PROCputline("   BEQ     __mod_fltr_addremflt_deregister")
17850PROCputline("   ADD     pc,pc,r5,LSL #3")
17860PROCputline("   EQUD    0")
17870PROCputline("   SWI     ""XFilter_RegisterPreFilter""")
17880PROCputline("   B       __mod_fltr_addremflt_exit")
17890PROCputline("   SWI     ""XFilter_RegisterPostRectFilter""")
17900PROCputline("   B       __mod_fltr_addremflt_exit")
17910PROCputline("   SWI     ""XFilter_RegisterRectFilter""")
17920PROCputline("   B       __mod_fltr_addremflt_exit")
17930PROCputline("   SWI     ""XFilter_RegisterCopyFilter""")
17940PROCputline("   B       __mod_fltr_addremflt_exit")
17950PROCputline("   SWI     ""XFilter_RegisterPostFilter""")
17960PROCputline("   B       __mod_fltr_addremflt_exit")
17970PROCputline("   SWI     ""XFilter_RegisterPostIconFilter""")
17980PROCputline("   B       __mod_fltr_addremflt_exit")
17990PROCputline(".__mod_fltr_addremflt_deregister")
18000PROCputline("   ADD     pc,pc,r5,LSL #3")
18010PROCputline("   EQUD    0")
18020PROCputline("   SWI     ""XFilter_DeRegisterPreFilter""")
18030PROCputline("   B       __mod_fltr_addremflt_exit")
18040PROCputline("   SWI     ""XFilter_DeRegisterPostRectFilter""")
18050PROCputline("   B       __mod_fltr_addremflt_exit")
18060PROCputline("   SWI     ""XFilter_DeRegisterRectFilter""")
18070PROCputline("   B       __mod_fltr_addremflt_exit")
18080PROCputline("   SWI     ""XFilter_DeRegisterCopyFilter""")
18090PROCputline("   B       __mod_fltr_addremflt_exit")
18100PROCputline("   SWI     ""XFilter_DeRegisterPostFilter""")
18110PROCputline("   B       __mod_fltr_addremflt_exit")
18120PROCputline("   SWI     ""XFilter_DeRegisterPostIconFilter""")
18130PROCputline(".__mod_fltr_addremflt_exit")
18140PROCputline("   LDMFD   (sp)!,{r0-r5,pc}^")
18150PROCputline(":")
18160PROCputline(".`mod_filterblock")
18170IFmod_bfn&gt;0THEN
18180 FORs=0 TO mod_bfn-1
18190  IFmod_bftask$(s)="-"THEN
18200   mod_bftask$(s)=""
18210   PROCputline("   EQUD    0")
18220  ELSE
18230   FORI=0 TO s
18240    IFmod_bftask$(s)=mod_bftask$(I)THEN
18250     PROCputline("   EQUD    `__mod_fltr_btask_"+STR$(I)+"-`mod_filterblock")
18260     IF s&lt;&gt;I THEN mod_bftask$(s)=""
18270     I=s
18280    ENDIF
18290   NEXT
18300  ENDIF
18310  FORI=0 TO s
18320   IFmod_bfname$(s)=mod_bfname$(I)THEN
18330    IF LEFT$(mod_bfilter$(s),1)&lt;&gt;"|"THEN
18340     CASE mod_bfmethod(s) OF
18350      WHEN0:PROCputline("   EQUD    `__mod_fltr_bname_"+STR$(I)+"-`mod_filterblock")
18360      WHEN1:PROCputline("   EQUD    `__mod_fltr_bname_"+STR$(I)+"-`mod_filterblock+&amp;04000000")
18370     ENDCASE
18380    ELSE
18390     CASE mod_bfmethod(s) OF
18400      WHEN0:PROCputline("   EQUD    `__mod_fltr_bname_"+STR$(I)+"-`mod_filterblock+&amp;10000000")
18410      WHEN1:PROCputline("   EQUD    `__mod_fltr_bname_"+STR$(I)+"-`mod_filterblock+&amp;14000000")
18420     ENDCASE
18430    ENDIF
18440    IF s&lt;&gt;I THEN mod_bfname$(s)=""
18450    I=s
18460   ENDIF
18470  NEXT
18480  IF LEFT$(mod_bfilter$(s),1)&lt;&gt;"|"THEN
18490   PROCputline("   EQUD    "+FNmod_align(mod_bfilter$(s)+"-`mod_filterblock",18))
18500  ELSE
18510   PROCputline("   EQUD    "+FNmod_align(mod_bfilter$(s),18))
18520  ENDIF
18530  PROCputline("   EQUD    0")
18540 NEXT
18550ENDIF
18560IFmod_afn&gt;0THEN
18570 FORs=0 TO mod_afn-1
18580  IFmod_aftask$(s)="-"THEN
18590   mod_aftask$(s)=""
18600   PROCputline("   EQUD    0")
18610  ELSE
18620   FORI=0 TO s
18630    IFmod_aftask$(s)=mod_bftask$(I)ANDmod_bftask$(I)&lt;&gt;""THEN
18640     PROCputline("   EQUD    `__mod_fltr_btask_"+STR$(I)+"-`mod_filterblock")
18650     mod_aftask$(s)=""
18660     I=s+1
18670    ENDIF
18680   NEXT
18690   IFI=s+1THEN
18700    FORI=0 TO s
18710     IFmod_aftask$(s)=mod_aftask$(I)ANDmod_aftask$(I)&lt;&gt;""THEN
18720      PROCputline("   EQUD    `__mod_fltr_atask_"+STR$(I)+"-`mod_filterblock")
18730      IF s&lt;&gt;I THEN mod_aftask$(s)=""
18740     ENDIF
18750    NEXT
18760   ENDIF
18770  ENDIF
18780  FORI=0 TO s
18790   IFmod_afname$(s)=mod_bfname$(I)THEN
18800    IF LEFT$(mod_afilter$(s),1)&lt;&gt;"|"THEN
18810     CASE mod_afmethod(s) OF
18820      WHEN0:PROCputline("   EQUD    `__mod_fltr_bname_"+STR$(I)+"-`mod_filterblock+&amp;80000000")
18830      WHEN1:PROCputline("   EQUD    `__mod_fltr_bname_"+STR$(I)+"-`mod_filterblock+&amp;84000000")
18840     ENDCASE
18850    ELSE
18860     CASE mod_afmethod(s) OF
18870      WHEN0:PROCputline("   EQUD    `__mod_fltr_bname_"+STR$(I)+"-`mod_filterblock+&amp;90000000")
18880      WHEN1:PROCputline("   EQUD    `__mod_fltr_bname_"+STR$(I)+"-`mod_filterblock+&amp;94000000")
18890     ENDCASE
18900    ENDIF
18910    mod_afname$(s)=""
18920    I=s+1
18930   ENDIF
18940  NEXT
18950  IFI=s+1THEN
18960   FORI=0 TO s
18970    IFmod_afname$(s)=mod_afname$(I)THEN
18980     IF LEFT$(mod_afilter$(s),1)&lt;&gt;"|"THEN
18990      CASE mod_afmethod(s) OF
19000       WHEN0:PROCputline("   EQUD    `__mod_fltr_aname_"+STR$(I)+"-`mod_filterblock+&amp;80000000")
19010       WHEN1:PROCputline("   EQUD    `__mod_fltr_aname_"+STR$(I)+"-`mod_filterblock+&amp;84000000")
19020      ENDCASE
19030     ELSE
19040      CASE mod_afmethod(s) OF
19050       WHEN0:PROCputline("   EQUD    `__mod_fltr_aname_"+STR$(I)+"-`mod_filterblock+&amp;90000000")
19060       WHEN1:PROCputline("   EQUD    `__mod_fltr_aname_"+STR$(I)+"-`mod_filterblock+&amp;94000000")
19070      ENDCASE
19080     ENDIF
19090     IF s&lt;&gt;I THEN mod_afname$(s)=""
19100     I=s
19110    ENDIF
19120   NEXT
19130  ENDIF
19140  IFmod_afreasons(s)THEN
19150   PROCputline("   EQUD    "+FNmod_align("__mod_fltr_reason_"+STR$(s)+"-`mod_filterblock",17))
19160  ELSE
19170   IF LEFT$(mod_afilter$(s),1)&lt;&gt;"|"THEN
19180    PROCputline("   EQUD    "+FNmod_align(mod_afilter$(s)+"-`mod_filterblock",17))
19190   ELSE
19200    PROCputline("   EQUD    "+FNmod_align(mod_afilter$(s),17))
19210   ENDIF
19220  ENDIF
19230 PROCputline("   EQUD    "+mod_afmask$(s))
19240 NEXT
19250ENDIF
19260IFmod_rfn&gt;0THEN
19270 FORs=0 TO mod_rfn-1
19280  IFmod_rftask$(s)="-"THEN
19290   mod_rftask$(s)=""
19300   PROCputline("   EQUD    0")
19310  ELSE
19320   FORI=0 TO s
19330    IFmod_rftask$(s)=mod_rftask$(I)THEN
19340     PROCputline("   EQUD    `__mod_fltr_rtask_"+STR$(I)+"-`mod_filterblock")
19350     IF s&lt;&gt;I THEN mod_rftask$(s)=""
19360     I=s
19370    ENDIF
19380   NEXT
19390  ENDIF
19400  FORI=0 TO s
19410   IFmod_rfname$(s)=mod_rfname$(I)THEN
19420    IF LEFT$(mod_rfilter$(s),1)&lt;&gt;"|"THEN
19430     CASE mod_rfmethod(s) OF
19440      WHEN0:PROCputline("   EQUD    `__mod_fltr_rname_"+STR$(I)+"-`mod_filterblock+&amp;40000000")
19450      WHEN1:PROCputline("   EQUD    `__mod_fltr_rname_"+STR$(I)+"-`mod_filterblock+&amp;44000000")
19460     ENDCASE
19470    ELSE
19480     CASE mod_rfmethod(s) OF
19490      WHEN0:PROCputline("   EQUD    `__mod_fltr_rname_"+STR$(I)+"-`mod_filterblock+&amp;50000000")
19500      WHEN1:PROCputline("   EQUD    `__mod_fltr_rname_"+STR$(I)+"-`mod_filterblock+&amp;54000000")
19510     ENDCASE
19520    ENDIF
19530    IF s&lt;&gt;I THEN mod_rfname$(s)=""
19540    I=s
19550   ENDIF
19560  NEXT
19570  IF LEFT$(mod_rfilter$(s),1)&lt;&gt;"|"THEN
19580   PROCputline("   EQUD    "+FNmod_align(mod_rfilter$(s)+"-`mod_filterblock",67))
19590  ELSE
19600   PROCputline("   EQUD    "+FNmod_align(mod_rfilter$(s),67))
19610  ENDIF
19620  PROCputline("   EQUD    0")
19630 NEXT
19640ENDIF
19650IFmod_prfn&gt;0THEN
19660 FORs=0 TO mod_prfn-1
19670  IFmod_prftask$(s)="-"THEN
19680   mod_prftask$(s)=""
19690   PROCputline("   EQUD    0")
19700  ELSE
19710   FORI=0 TO s
19720    IFmod_prftask$(s)=mod_prftask$(I)THEN
19730     PROCputline("   EQUD    `__mod_fltr_prtask_"+STR$(I)+"-`mod_filterblock")
19740     IF s&lt;&gt;I THEN mod_prftask$(s)=""
19750     I=s
19760    ENDIF
19770   NEXT
19780  ENDIF
19790  FORI=0 TO s
19800   IFmod_prfname$(s)=mod_prfname$(I)THEN
19810    IF LEFT$(mod_prfilter$(s),1)&lt;&gt;"|"THEN
19820     CASE mod_prfmethod(s) OF
19830      WHEN0:PROCputline("   EQUD    `__mod_fltr_prname_"+STR$(I)+"-`mod_filterblock+&amp;20000000")
19840      WHEN1:PROCputline("   EQUD    `__mod_fltr_prname_"+STR$(I)+"-`mod_filterblock+&amp;24000000")
19850     ENDCASE
19860    ELSE
19870     CASE mod_prfmethod(s) OF
19880      WHEN0:PROCputline("   EQUD    `__mod_fltr_prname_"+STR$(I)+"-`mod_filterblock+&amp;30000000")
19890      WHEN1:PROCputline("   EQUD    `__mod_fltr_prname_"+STR$(I)+"-`mod_filterblock+&amp;34000000")
19900     ENDCASE
19910    ENDIF
19920    IF s&lt;&gt;I THEN mod_prfname$(s)=""
19930    I=s
19940   ENDIF
19950  NEXT
19960  IF LEFT$(mod_prfilter$(s),1)&lt;&gt;"|"THEN
19970   PROCputline("   EQUD    "+FNmod_align(mod_prfilter$(s)+"-`mod_filterblock",68))
19980  ELSE
19990   PROCputline("   EQUD    "+FNmod_align(mod_prfilter$(s),68))
20000  ENDIF
20010  PROCputline("   EQUD    0")
20020 NEXT
20030ENDIF
20040IFmod_ifn&gt;0THEN
20050 FORs=0 TO mod_ifn-1
20060  IFmod_iftask$(s)="-"THEN
20070   mod_iftask$(s)=""
20080   PROCputline("   EQUD    0")
20090  ELSE
20100   FORI=0 TO s
20110    IFmod_iftask$(s)=mod_iftask$(I)THEN
20120     PROCputline("   EQUD    `__mod_fltr_itask_"+STR$(I)+"-`mod_filterblock")
20130     IF s&lt;&gt;I THEN mod_iftask$(s)=""
20140     I=s
20150    ENDIF
20160   NEXT
20170  ENDIF
20180  FORI=0 TO s
20190   IFmod_ifname$(s)=mod_ifname$(I)THEN
20200    IF LEFT$(mod_ifilter$(s),1)&lt;&gt;"|"THEN
20210     CASE mod_ifmethod(s) OF
20220      WHEN0:PROCputline("   EQUD    `__mod_fltr_iname_"+STR$(I)+"-`mod_filterblock+&amp;A0000000")
20230      WHEN1:PROCputline("   EQUD    `__mod_fltr_iname_"+STR$(I)+"-`mod_filterblock+&amp;A4000000")
20240     ENDCASE
20250    ELSE
20260     CASE mod_ifmethod(s) OF
20270      WHEN0:PROCputline("   EQUD    `__mod_fltr_iname_"+STR$(I)+"-`mod_filterblock+&amp;B0000000")
20280      WHEN1:PROCputline("   EQUD    `__mod_fltr_iname_"+STR$(I)+"-`mod_filterblock+&amp;B4000000")
20290     ENDCASE
20300    ENDIF
20310    IF s&lt;&gt;I THEN mod_ifname$(s)=""
20320    I=s
20330   ENDIF
20340  NEXT
20350  IF LEFT$(mod_ifilter$(s),1)&lt;&gt;"|"THEN
20360   PROCputline("   EQUD    "+FNmod_align(mod_ifilter$(s)+"-`mod_filterblock",69))
20370  ELSE
20380   PROCputline("   EQUD    "+FNmod_align(mod_ifilter$(s),69))
20390  ENDIF
20400  PROCputline("   EQUD    0")
20410 NEXT
20420ENDIF
20430PROCputline("   EQUD    -1")
20440PROCputline(":")
20450IFmod_bfn&gt;0THEN
20460 FORs=0 TO mod_bfn-1
20470  IFmod_bftask$(s)&lt;&gt;""THEN
20480   PROCputline(".`__mod_fltr_btask_"+STR$(s))
20490   PROCputline("   EQUS    """+mod_bftask$(s)+"""+CHR$(0)")
20500  ENDIF
20510  IFmod_bfname$(s)&lt;&gt;""THEN
20520   PROCputline(".`__mod_fltr_bname_"+STR$(s))
20530   PROCputline("   EQUS    """+mod_bfname$(s)+"""+CHR$(0)")
20540  ENDIF
20550 NEXT
20560ENDIF
20570IFmod_afn&gt;0THEN
20580 FORs=0 TO mod_afn-1
20590  IFmod_aftask$(s)&lt;&gt;""THEN
20600   PROCputline(".`__mod_fltr_atask_"+STR$(s))
20610   PROCputline("   EQUS    """+mod_aftask$(s)+"""+CHR$(0)")
20620  ENDIF
20630  IFmod_afname$(s)&lt;&gt;""THEN
20640   PROCputline(".`__mod_fltr_aname_"+STR$(s))
20650   PROCputline("   EQUS    """+mod_afname$(s)+"""+CHR$(0)")
20660  ENDIF
20670 NEXT
20680ENDIF
20690IFmod_rfn&gt;0THEN
20700 FORs=0 TO mod_rfn-1
20710  IFmod_rftask$(s)&lt;&gt;""THEN
20720   PROCputline(".`__mod_fltr_rtask_"+STR$(s))
20730   PROCputline("   EQUS    """+mod_rftask$(s)+"""+CHR$(0)")
20740  ENDIF
20750  IFmod_rfname$(s)&lt;&gt;""THEN
20760   PROCputline(".`__mod_fltr_rname_"+STR$(s))
20770   PROCputline("   EQUS    """+mod_rfname$(s)+"""+CHR$(0)")
20780  ENDIF
20790 NEXT
20800ENDIF
20810IFmod_prfn&gt;0THEN
20820 FORs=0 TO mod_prfn-1
20830  IFmod_prftask$(s)&lt;&gt;""THEN
20840   PROCputline(".`__mod_fltr_prtask_"+STR$(s))
20850   PROCputline("   EQUS    """+mod_prftask$(s)+"""+CHR$(0)")
20860  ENDIF
20870  IFmod_prfname$(s)&lt;&gt;""THEN
20880   PROCputline(".`__mod_fltr_prname_"+STR$(s))
20890   PROCputline("   EQUS    """+mod_prfname$(s)+"""+CHR$(0)")
20900  ENDIF
20910 NEXT
20920ENDIF
20930IFmod_ifn&gt;0THEN
20940 FORs=0 TO mod_ifn-1
20950  IFmod_iftask$(s)&lt;&gt;""THEN
20960   PROCputline(".`__mod_fltr_itask_"+STR$(s))
20970   PROCputline("   EQUS    """+mod_iftask$(s)+"""+CHR$(0)")
20980  ENDIF
20990  IFmod_ifname$(s)&lt;&gt;""THEN
21000   PROCputline(".`__mod_fltr_iname_"+STR$(s))
21010   PROCputline("   EQUS    """+mod_ifname$(s)+"""+CHR$(0)")
21020  ENDIF
21030 NEXT
21040ENDIF
21050IF mod_afn&gt;0 THEN
21060 PROCputline("   ALIGN")
21070 PROCputline(":")
21080 FORs=0 TO mod_afn-1
21090  IFmod_afreasons(s)THEN
21100   PROCputline(".__mod_fltr_reason_"+STR$(s))
21110   FORI=0TO20
21120    IFmod_filter$(s,I)&lt;&gt;""THEN
21130     PROCputline("   TEQ     r0,#"+STR$I)
21140     PROCputline("   BEQ     "+FNmod_align(mod_filter$(s,I),24))
21150    ENDIF
21160   NEXT
21170   IFmod_afilter$(s)="$"THEN
21180    PROCputline("   MOVS    pc,link")
21190   ELSE
21200    IF LEFT$(mod_afilter$(s),1)="$" THEN
21210     PROCputline("   B       "+MID$(FNmod_align(mod_afilter$(s),25),2))
21220    ELSE
21230     PROCputline("   B       "+FNmod_align(mod_afilter$(s),25))
21240    ENDIF
21250   ENDIF
21260   PROCputline(":")
21270  ENDIF
21280 NEXT
21290ENDIF
21300ENDPROC
21310:
21320DEFPROCModule_head_servicetable
21330IF LightningFastService THEN
21340 PROCputline(".module_service_lightningfast")
21350 IF mod_ws$&lt;&gt;"-" THEN
21360  PROCputline("   LDR     r12,[r12]")
21370 ENDIF
21380 PROCputline("   ADD     pc,pc,r1,LSL #2")
21390 PROCputline("   MOV     r0,r0")
21400 PROCputline("   MOVS    pc,link ; index 0 = 'claimed'")
21410 FORserv=0TO mod_servnum-1
21420  PROCputline("   B       "+FNmod_call(serv$(serv)))
21430 NEXT
21440 PROCputline(":")
21450ENDIF
21460PROCputline(".module_service_table")
21470IF LightningFastService THEN
21480 PROCputline("   EQUD    1    ; flag word (1 means index in r1)")
21490 PROCputline("   EQUD    module_service_lightningfast")
21500ELSE
21510 PROCputline("   EQUD    0    ; flag word")
21520 PROCputline("   EQUD    module_service_ursulaentry")
21530ENDIF
21540last=-1
21550FORserv=0TO mod_servnum-1
21560 IF servn(serv)&lt;&gt;last THEN
21570  last=servn(serv)
21580  PROCputline("   EQUD    &amp;"+STR$~servn(serv))
21590 ENDIF
21600NEXT
21610PROCputline("   EQUD    0    ; end of table")
21620PROCputline(":")
21630ENDPROC
21640:
21650REM Add service handler code
21660DEFPROCModule_head_services
21670:
21680REM I'm going to bubble sort them. So sue me
21690sub256=0:REM Number of service entries &lt; 256
21700sub256c=0:REM Number of /distinct/ service entries &lt; 256
21710dupes=0:REM Number of duplicated entries (multiple handlers)
21720lastserv=mod_servnum-1
21730IF mod_servnum&gt;1 THEN
21740 REPEAT
21750  changed=FALSE
21760  sub256=0:sub256c=0:dupes=0:lastserv=0
21770  FORserv=1TO mod_servnum-1
21780   IFservn(serv) &lt; servn(serv-1) THEN
21790    SWAP servn(serv),servn(serv-1)
21800    SWAP serv$(serv),serv$(serv-1)
21810    changed=TRUE
21820   ELSE
21830    IF servn(serv)&lt;256 THENsub256+=1:IF servn(serv)&lt;&gt;servn(serv-1) THENsub256c+=1
21840    IF servn(serv)=servn(serv-1) THENdupes+=1 ELSElastserv=serv
21850   ENDIF
21860  NEXT
21870 UNTIL changed=FALSE
21880ENDIF
21890IF servn(0)&lt;256 THENsub256+=1:sub256c+=1
21900:
21910done=FALSE
21920REM Do the Fast Reject code (if necessary)
21930IF sub256c&gt;0 THEN
21940 IF sub256c=1 AND Ursula THEN
21950  PROCputline(".module_service_ursulaentry")
21960 ENDIF
21970 cc$="  ":last=-1
21980 FORserv=0TO sub256-1
21990  IF servn(serv) &lt;&gt; last THEN
22000   last=servn(serv)
22010   PROCputline("   TEQ"+cc$+"   r1,#&amp;"+STR$~(servn(serv)))
22020   cc$="NE"
22030  ENDIF
22040 NEXT
22050 IF sub256=mod_servnum THEN
22060  PROCputline("   MOVNES  pc,link")
22070 ELSE
22080  REM Jump to the 'high number' match code
22090  PROCputline("   BNE     module_service_highmatch")
22100 ENDIF
22110 PROCputrem("End of fast service reject")
22120 IF sub256c&gt;1 AND Ursula THEN
22130  PROCputline(".module_service_ursulaentry")
22140 ENDIF
22150 IF mod_ws$&lt;&gt;"-" THEN
22160  PROCputline("   LDR     r12,[r12]")
22170 ENDIF
22180 REM Do the sub256 match
22190 IF sub256c&gt;1 OR LightningFastService THEN
22200  last=-1
22210  FORserv=0TO sub256-2
22220   IF servn(serv) &lt;&gt; last THEN
22230    last=servn(serv)
22240    PROCputline("   TEQ     r1,#&amp;"+STR$~(servn(serv)))
22250    PROCputline("   BEQ     "+FNmod_servcall(serv))
22260   ENDIF
22270  NEXT
22280  IF sub256 = mod_servnum THEN
22290   PROCputline("   B       "+FNmod_servcall(serv))
22300   done=TRUE
22310  ELSE
22320   PROCputline("   TEQ     r1,#&amp;"+STR$~(servn(serv)))
22330   PROCputline("   BEQ     "+FNmod_servcall(serv))
22340  ENDIF
22350 ELSE
22360  PROCputline("   B       "+FNmod_servcall(sub256-1))
22370  done=TRUE
22380 ENDIF
22390 IF NOT done THEN
22400  IF sub256 = mod_servnum THEN
22410   PROCputline("   MOVS    pc,link")
22420  ENDIF
22430 ENDIF
22440ELSE
22450 PROCputline(".module_service_ursulaentry")
22460ENDIF
22470:
22480IF sub256 &lt;&gt; mod_servnum THEN
22490 changed=FALSE
22500 lastc=0:lastv=0:d=1:c=0
22510 IF sub256c&lt;&gt;0 THEN
22520  PROCputline("   B       module_service_notlow256")
22530  PROCputrem("End of sub256 matching")
22540  PROCputline(".module_service_highmatch")
22550  IF mod_ws$&lt;&gt;"-" THEN
22560   PROCputline("   LDR     r12,[r12]")
22570  ENDIF
22580  PROCputline(".module_service_notlow256")
22590 ENDIF
22600 cc$="  ":last=-1
22610 FORserv=sub256 TO mod_servnum-1
22620  s=servn(serv)
22630  REM PROCputrem("service = &amp;"+STR$~s)
22640  REM PROCputrem("lastc = &amp;"+STR$~lastc)
22650  REM PROCputrem("lastv = &amp;"+STR$~lastv)
22660  IF s&lt;&gt;last THEN
22670   last=s
22680   IF s-lastv&lt;0 OR s-lastv&gt;255 THEN
22690    IF NOT changed THEN
22700     PROCputline("   STR     r0,[sp,#-4]!")
22710     changed=TRUE
22720    ENDIF
22730    s=servn(serv)-lastv
22740    IF s&gt;(&amp;FFFF&lt;&lt;c) THENs=servn(serv):d=1:lastv=0
22750    c=32-8
22760    WHILE (s AND ((1&lt;&lt;c)-1))&lt;&gt;0
22770     IF (s AND (3&lt;&lt;(c+6)))&gt;0 THEN
22780      PROCputline("   SUB     r0,r"+STR$d+",#&amp;"+STR$~((s AND (255&lt;&lt;c))))
22790      lastv+=(s AND (255&lt;&lt;c)):s-=(s AND (255&lt;&lt;c)):d=0
22800     ENDIF
22810     c-=2
22820    ENDWHILE
22830   ELSE
22840    c=lastc:d=0:s-=lastv
22850   ENDIF
22860   REM ----
22870   REM This is a minor optimisation which cuts out a single instruction
22880   REM on entries that would otherwise merely do a TEQ on a big number
22890   REM then have to sub it the next time.
22900   REM An example might be &amp;902c0 followed by 902c1
22910   REM Old method would generate :
22920   REM   SUB &amp;90000
22930   REM   TEQ &amp;2c0
22940   REM   ...
22950   REM   SUB &amp;2c0
22960   REM   TEQ 1
22970   REM New method generates :
22980   REM   SUB &amp;90000
22990   REM   SUBS &amp;2c0
23000   REM   ...
23010   REM   TEQ 1
23020   REM The optimisation ONLY applies to comparisons which are in the
23030   REM 0-256 range, so &amp;902c0 followed by &amp;903c1 would be generated as :
23040   REM   SUB &amp;90000
23050   REM   TEQ &amp;2c0
23060   REM   ...
23070   REM   SUB &amp;3c0
23080   REM   TEQ 4
23090   REM The changes that need to be made are equivilent to the above routine
23100   REM that does the WHILE loop in place of the IF statement, but it would
23110   REM be used /so/ rarely that it doesn't seem worthwhile
23120   IF serv&lt;&gt;lastserv THEN
23130    x=serv+1
23140    WHILE s=servn(x):x+=1:ENDWHILE
23150    IF servn(x)-servn(serv) &lt; 257 THEN
23160     PROCputline("   SUBS    r0,r"+STR$d+",#&amp;"+STR$~((s AND (255&lt;&lt;c))))
23170     lastv+=(s AND (255&lt;&lt;c)):s-=(s AND (255&lt;&lt;c)):d=0
23180     c=0
23190    ELSE
23200     PROCputline("   TEQ     r"+STR$d+",#&amp;"+STR$~((s AND (255&lt;&lt;c))))
23210    ENDIF
23220   ELSE
23230    PROCputline("   TEQ     r"+STR$d+",#&amp;"+STR$~((s AND (255&lt;&lt;c))))
23240   ENDIF
23250   lastc=c
23260   REM ----
23270   REM Old code:
23280   REM PROCputline("   TEQ     r"+STR$d+",#&amp;"+STR$~((s AND (255&lt;&lt;c))))
23290   REM ----
23300   IF changed THEN
23310    IF serv=lastserv THEN
23320     REM If it's the last one, restore it anyway
23330     PROCputline("   LDR     r0,[sp],#4")
23340    ELSE
23350     PROCputline("   LDREQ   r0,[sp],#4")
23360    ENDIF
23370   ENDIF
23380   PROCputline("   BEQ     "+FNmod_servcall(serv))
23390  ENDIF
23400 NEXT
23410ENDIF
23420IF NOT done THEN
23430 PROCputline("   MOVS    pc,link")
23440ENDIF
23450:
23460REM Now we need to do the duplicate checks
23470IF dupes THEN
23480 PROCputrem("Duplicate service number handling")
23490 last=-1
23500 done=TRUE
23510 REM Set if we're outside a duplicated entry -
23520 REM have we /done/ everything we need to
23530 FORserv=0 TO mod_servnum-1
23540  s=servn(serv)
23550  IF s=last THEN
23560   IF done THEN
23570    PROCputline(".module_service_"+STR$~s)
23580    PROCputline("   STMFD   (sp)!,{link}")
23590    PROCputline("   BL      "+FNmod_call(serv$(serv-1)))
23600   ENDIF
23610   IF serv=mod_servnum-1 OR servn(serv+1)&lt;&gt;s THEN
23620    done=TRUE
23630    PROCputline("   LDMFD   (sp)!,{link}")
23640    PROCputline("   B       "+FNmod_call(serv$(serv)))
23650   ELSE
23660    PROCputline("   BL      "+FNmod_call(serv$(serv)))
23670   ENDIF
23680  ELSE
23690   last=s
23700  ENDIF
23710 NEXT
23720ENDIF
23730ENDPROC
23740:
23750DEFFNmod_servcall(serv)
23760IF serv=mod_servnum-1 THEN=FNmod_call(serv$(serv))
23770IF servn(serv) = servn(serv+1) THEN="module_service_"+STR$~servn(serv)
23780=FNmod_call(serv$(serv))
23790:
23800REM Add vector handler code
23810DEFPROCModule_head_vectors(type$)
23820IF mod_ws$&lt;&gt;"-" THEN
23830 PROCputline("   MOV     r2,r12"):REM r12 will point to our block
23840ELSE
23850 PROCputline("   MOV     r2,#0"):REM r12 will be 0
23860ENDIF
23870FORvect=0TOmod_vectn-1
23880 PROCputline("   MOV     r0,#"+STR$vectn(vect))
23890 IF LEFT$(vect$(vect),1)="^" THEN
23900  PROCputLADR("","1",MID$(vect$(vect),2))
23910 ELSE
23920  PROCputline("   ADR     r1,"+vect$(vect))
23930 ENDIF
23940 PROCputline("   SWI     ""OS_"+type$+"""")
23950NEXT
23960ENDPROC
23970:
23980REM Add event handler code
23990DEFPROCModule_head_events(type$)
24000IF type$="Claim" THEN
24010 PROCputline("   MOV     r0,#14")
24020ELSE
24030 PROCputline("   MOV     r0,#13")
24040ENDIF
24050FORevent=0TOmod_eventn-1
24060 PROCputline("   MOV     r1,#"+STR$eventn(event))
24070 PROCputline("   SWI     ""OS_Byte""")
24080NEXT
24090ENDPROC
24100:
24110REM Add FS code
24120DEFPROCModule_head_fs_add
24130PROCputline("   BL      mod_fs_add")
24140ENDPROC
24150:
24160DEFPROCModule_head_fs_code
24170PROCputline(".mod_fs_add")
24180PROCputline("   STMFD   (sp)!,{r0-r3,link}")
24190PROCputline("   MOV     r0,#12 ; Add FS")
24200PROCputline("   ADR     r1,0")
24210PROCputline("   MOV     r2,#`mod_fs_info")
24220PROCputline("   MOV     r3,r12")
24230PROCputline("   SWI     ""OS_FSControl""")
24240PROCputline("   LDMFD   (sp)!,{r0-r3,pc}")
24250PROCputline(":")
24260PROCputline(".`mod_fs_info")
24270PROCputline("   EQUD    "+FNmod_align("`mod_fs_name",50))
24280IF mod_fs_startup$="" THEN
24290 PROCputline("   EQUD    "+FNmod_align("0",61))
24300ELSE
24310 IF mod_fs_startup$="-" THEN
24320  PROCputline("   EQUD    "+FNmod_align("-1",61))
24330 ELSE
24340  PROCputline("   EQUD    "+FNmod_align("`mod_fs_startup",61))
24350 ENDIF
24360ENDIF
24370PROCputline("   EQUD    "+FNmod_align(mod_fs_open$,51))
24380PROCputline("   EQUD    "+FNmod_align(mod_fs_get$,52))
24390PROCputline("   EQUD    "+FNmod_align(mod_fs_put$,53))
24400PROCputline("   EQUD    "+FNmod_align(mod_fs_args$,54))
24410PROCputline("   EQUD    "+FNmod_align(mod_fs_close$,55))
24420PROCputline("   EQUD    "+FNmod_align(mod_fs_file$,56))
24430IF mod_fs_eflags%&lt;&gt;0 THENmod_fs_flags%=mod_fs_flags% OR (1&lt;&lt;17)
24440PROCputline("   EQUD    "+FNmod_align(STR$mod_fs_number+"+("+STR$mod_fs_files+"&lt;&lt;8)+&amp;"+STR$~mod_fs_flags%,59))
24450PROCputline("   EQUD    "+FNmod_align(mod_fs_func$,57))
24460PROCputline("   EQUD    "+FNmod_align(mod_fs_gbpb$,58))
24470IF (mod_fs_flags% AND 17)&lt;&gt;0 THEN
24480 PROCputline("   EQUD    "+FNmod_align("&amp;"+STR$~mod_fs_eflags%,60))
24490ENDIF
24500PROCputline(":")
24510IF mod_fs_name$=mod_name$ THEN
24520 PROCputline("]:`mod_fs_name=module_title:[OPT pass%")
24530ELSE
24540 PROCputline(".`mod_fs_name")
24550 PROCputline("   EQUS    """+mod_fs_name$+"""+CHR$0")
24560ENDIF
24570IF mod_fs_startup$&lt;&gt;"" AND mod_fs_startup$&lt;&gt;"-" THEN
24580 IF mod_fs_startup$&lt;&gt;mod_fs_name$ THEN
24590  PROCputline(".`mod_fs_startup")
24600  PROCputline("   EQUS    """+mod_fs_startup$+"""+CHR$0")
24610 ELSE
24620  PROCputline("]:`mod_fs_startup=`mod_fs_name:[OPT pass%")
24630 ENDIF
24640ENDIF
24650PROCputline("   ALIGN")
24660PROCputline(":")
24670PROCputline(".fs_selectfs")
24680PROCputline("   STMFD   (sp)!,{r0-r1,link}            ; Stack registers")
24690PROCputline("   MOV     r0,#14 ; Select FS")
24700PROCputline("   ADR     r1,`mod_fs_name")
24710PROCputline("   SWI     ""XOS_FSControl""")
24720PROCputline("   LDMVCFD (sp)!,{r0-r1,pc}^             ; Return from call")
24730PROCputline("   ADD     sp,sp,#4")
24740PROCputline("   LDMFD   (sp)!,{r1,pc}                 ; Return with error")
24750PROCputline(":")
24760ENDPROC
24770:
24780REM Remove FS code
24790DEFPROCModule_head_fs_remove
24800PROCputline("   MOV     r0,#16 ; Remove FS")
24810PROCputline("   ADR     r1,`mod_fs_name")
24820PROCputline("   SWI     ""OS_FSControl""")
24830ENDPROC
24840:
24850REM Add ImageFS code
24860DEFPROCModule_head_imagefs_add
24870PROCputline("   BL      mod_imagefs_add")
24880ENDPROC
24890:
24900DEFPROCModule_head_imagefs_code
24910PROCputline(".mod_imagefs_add")
24920PROCputline("   STMFD   (sp)!,{r0-r3,link}")
24930PROCputline("   MOV     r0,#35 ; Add ImageFS")
24940PROCputline("   ADR     r1,0")
24950PROCputline("   MOV     r2,#`mod_imagefs_info")
24960PROCputline("   MOV     r3,r12")
24970PROCputline("   SWI     ""OS_FSControl""")
24980PROCputline("   LDMFD   (sp)!,{r0-r3,pc}")
24990PROCputline(":")
25000PROCputline(".`mod_imagefs_info")
25010PROCputline("   EQUD    "+FNmod_align("&amp;"+STR$~mod_img_flags%,48))
25020PROCputline("   EQUD    "+FNmod_align(mod_img_type$,40))
25030PROCputline("   EQUD    "+FNmod_align(mod_img_open$,41))
25040PROCputline("   EQUD    "+FNmod_align(mod_img_get$,42))
25050PROCputline("   EQUD    "+FNmod_align(mod_img_put$,43))
25060PROCputline("   EQUD    "+FNmod_align(mod_img_args$,44))
25070PROCputline("   EQUD    "+FNmod_align(mod_img_close$,45))
25080PROCputline("   EQUD    "+FNmod_align(mod_img_file$,46))
25090REM Why is this repeated ?
25100PROCputline("   EQUD    "+FNmod_align(mod_img_func$,47))
25110PROCputline("   EQUD    "+FNmod_align(mod_img_func$,47))
25120PROCputline(":")
25130ENDPROC
25140:
25150REM Remove ImageFS code
25160DEFPROCModule_head_imagefs_remove
25170PROCputline("   MOV     r0,#36 ; Remove ImageFS")
25180PROCputline("   LDR     r1,`mod_imagefs_info+4")
25190PROCputline("   SWI     ""OS_FSControl""")
25200ENDPROC
25210:
25220REM Initialise/remove WimpSWIve code
25230REM  r$=1 for claim, 0 for remove
25240DEFPROCModule_head_wswi(r$)
25250CASE r$ OF
25260 WHEN "0":PROCputline("; ***** WimpSWI release code")
25270 WHEN "1"
25280  PROCputline("; ***** WimpSWI claim code")
25290  PROCputline("   MOV     r0,#18")
25300  PROCputLADR("","1","`module_WSWIname")
25310  PROCputline("   SWI     ""XOS_Module""           ; Look up module name")
25320  PROCputLADR("VS","0","`module_WSWIerr")
25330  PROCputline("   ADRVS   r1,_mod_init_error_1")
25340  PROCputline("   BVS     mod_init_error")
25350ENDCASE
25360PROCputline("   LDR     r0,`module_WSWIword")
25370PROCputline("   MOV     r2,r12")
25380IF outaof THEN
25390 PROCputline("   ADR     r5,`module_wswioffsets")
25400ENDIF
25410FORI=1TO mod_wswis
25420 swi$=wswi$(I,0)
25430 swi=FNswinumber(swi$)-&amp;400C0
25440 IF swi&gt;64 OR swi&lt;0 THENERROR 999,"Unknown WimpSWI '"+swi$+"'"
25450 pre$=wswi$(I,1)
25460 post$=wswi$(I,2)
25470 IF pre$="" AND post$="" THENERROR 999,"No filter code for WimpSWI '"+swi$+"'"
25480 IFLEFT$(pre$,1)="^"ORLEFT$(post$,1)="^"THEN
25490  a$="%"+r$+"1"
25500  IF LEFT$(pre$,1)="^" THENpre$=MID$(pre$,2)
25510  IF LEFT$(post$,1)="^" THENpost$=MID$(post$,2)
25520 ELSE
25530  a$="%"+r$+"0"
25540 ENDIF
25550 REM This next line seems to give bad immediate constant - surely
25560 REM we can do it for all SWI numbers except those &gt;31 ?
25570 REM PROCputline("   MOV     r1,#"+STR$swi+"+("+a$+"&lt;&lt;30)")
25580 PROCputline("   MOV     r1,#"+STR$swi)
25590 PROCputline("   ORR     r1,r1,#("+a$+"&lt;&lt;30)")
25600 IF pre$&lt;&gt;"" THEN
25610  IF outaof THEN
25620   IFLEFT$(pre$,1)&lt;&gt;"|"THEN
25630    PROCputline("   ADR     r14,0"):REM address of module
25640    PROCputline("   LDR     r3,[r5],#4"):REM Read and inc
25650    PROCputline("   ADD     r3,r3,r14"):REM make into an address
25660   ELSE
25670    PROCputline("   LDR     r3,[r5],#4"):REM Read and inc
25680   ENDIF
25690  ELSE
25700   PROCputLADR("","3",pre$)
25710  ENDIF
25720 ELSE
25730  PROCputline("   MOV     r3,#0")
25740 ENDIF
25750 IF post$&lt;&gt;"" THEN
25760  IF outaof THEN
25770   IFLEFT$(post$,1)&lt;&gt;"|"THEN
25780    IFLEFT$(pre$,1)="|"THEN
25790     PROCputline("   ADR     r14,0"):REM address of module
25800    ENDIF
25810    PROCputline("   LDR     r4,[r5],#4"):REM Read address and inc
25820    PROCputline("   ADD     r4,r4,r14"):REM make into an address
25830   ELSE
25840   PROCputline("   LDR     r4,[r5],#4"):REM Read address and inc
25850   ENDIF
25860  ELSE
25870   PROCputLADR("","4",post$)
25880  ENDIF
25890 ELSE
25900  PROCputline("   MOV     r4,#0")
25910 ENDIF
25920 PROCputline("   SWI     ""Wimp_RegisterFilter""")
25930NEXT
25940IF r$="0" THEN
25950 PROCputline("   LDMFD   (sp),{r0-r5}           ; restore registers")
25960 REM Put the wswioffsets /after/ the release code !
25970 IF outaof THEN
25980  PROCputline("   B       _mod_init_error_1"):REM It would be interesting otherwise
25990  PROCputline(".`module_wswioffsets")
26000  FORI=1TO mod_wswis
26010   pre$=wswi$(I,1):IF LEFT$(pre$,1)="^" THENpre$=MID$(pre$,2)
26020   post$=wswi$(I,2):IF LEFT$(post$,1)="^" THENpost$=MID$(post$,2)
26030   IF pre$&lt;&gt;"" THEN
26040    PROCputline("   EQUD    "+FNmod_align(pre$,19))
26050   ENDIF
26060   IF post$&lt;&gt;"" THEN
26070    PROCputline("   EQUD    "+FNmod_align(post$,20))
26080   ENDIF
26090  NEXT
26100 ENDIF
26110ENDIF
26120ENDPROC
26130:
26140REM FNswinumber : Return the SWI number, given its string
26150DEFFNswinumber(swi$):LOCAL n
26160SYS "XOS_SWINumberFromString",,swi$ TO n;flags
26170IF (flags AND1)&gt;0 THENn=-1
26180=n
26190:
26200DEFFNModule_returncode
26210IF mod_wswis&gt;0 THEN="W"
26220=""
26230:
26240DEFPROCModule_Functions
26250ENDPROC
</textarea>
<hr/>


<textarea class='source-code'>
10REM &gt; Patch for memory compilation
20REM Created by JFPatch v2.50DRAW (15 Nov 1997) LEN Justin Fletcher
30REM Intermediate code file created 05 Dec 1997
40ON ERROR PROCError:END
50PROCpatch_loadfile
60version$="1.00f"
70sp=13:link=14:pc=15
80vbit=1&lt;&lt;28:cbit=1&lt;&lt;29:zbit=1&lt;&lt;30:nbit=1&lt;&lt;31
90P%=&amp;0:O%=MC%
100FOR pass%=4 TO 6 STEP2
110thisfile$="ADFS::Gerph.$.Apps.Utils.MCode.!JFPatch.Code.test.source"
120REM **** Start of main code ****
130PROCpatch_setpc(0)
140[OPT pass%
150          ; **** Add module header ****
160   EQUD 0                  ; Start offset
170   EQUD test               ; Initialisation offset
180   EQUD 0                  ; Finalisation offset
190   EQUD module_service     ; Service request offset
200   EQUD module_title       ; Title string offset
210   EQUD module_help        ; Help string offset
220   EQUD 0                  ; Help and command keyword table offset
230:
240.module_title
250   EQUS "test"+CHR$0
260   ALIGN
270:
280.module_help
290   EQUS "test"+CHR$9+"1.00 ("+MID$(TIME$,5,11)+") © Justin Fletcher"+CHR$0
300   ALIGN
310:
320.module_service
330   LDR     r12,[r12]
340   TEQ     r1,#&amp;6
350   BEQ     null
360   STR     r0,[sp,#-4]!
370   SUB     r0,r1,#&amp;90000
380   SUB     r0,r0,#&amp;2C0
390   TEQ     r0,#&amp;1
400   LDREQ   r0,[sp],#4
410   BEQ     null
420   TEQ     r0,#&amp;0
430   LDREQ   r0,[sp],#4
440   BEQ     null
450   TEQ     r0,#&amp;FF
460   LDR     r0,[sp],#4
470   BEQ     null
480   MOVS    pc,link
490:
500          ; **** End of module header ****
510:
520.null
530   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
540   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call
550:
560:
570.test
580   STMFD   (sp)!,{r0-r5,link}            ; Stack registers
590   ADR     r0,__z0_`error
600 FNmess("%E0",TRUE)
610   LDMFD   (sp)!,{r0-r5,pc}              ; Return from call
620:
630.__z0_`error
640   EQUD    &amp;657
650   EQUS    "Test message"+CHR$0
660   ALIGN
670:
680   EQUS    "TEST CODE (RAS)"+CHR$0
690   ALIGN
700          ; Find r2 from array at [r1,##4]
710   CMP     r1,#0           ; are we at the end
720   BEQ     P%+20           ; if so, we're done
730   LDR     r14,[r1,#4]  ; read the value
740   CMP     r14,r2          ; are they the same ?
750   LDRNE   r1,[r1]         ; read the next pointer
760   BNE     P%-20           ; jump back to the top
770   EQUS    "TEST CODE (CAS)"+CHR$0
780   ALIGN
790   STMFD   (sp)!,{r0}         ; Stack registers
800   MOV     r0,#16             ; space to claim
810   BL      claim             ; claim the space (to r0)
820   STR     r2,[r0,#4]        ; store the associater
830   STR     r1,[r0]            ; store the 'next' entry
840   MOV     r1,r0              ; r1-&gt; this block
850   LDMFD   (sp)!,{r0}         ; Restore registers
860          ; specifying length (no r0's)
870   EQUS    "TEST CODE (CAS2)"+CHR$0
880   ALIGN
890   STMFD   (sp)!,{r0,r2}      ; Stack registers
900   MOV     r0,#16             ; space to claim
910   BL      claim             ; claim the space (to r0)
920   STR     r2,[r0,#4]        ; store the associater
930   LDR     r2,[sp],#4         ; re-read r0, and inc after
940   STR     r2,[r0]            ; store the 'next' entry
950   LDMFD   (sp)!,{r2}         ; Restore registers
960          ; specifying length (r0 as rx)
970   EQUS    "TEST CODE (CAS3)"+CHR$0
980   ALIGN
990   STMFD   (sp)!,{r0,r1}      ; Stack registers
1000   MOV     r1,r0           ; hang on to r0
1010   MOV     r0,#16             ; space to claim
1020   BL      claim             ; claim the space (to r0)
1030   STR     r1,[r0,#4]        ; store the associater
1040   LDR     r1,[sp,#4*1]                  ; re-read rx
1050   STR     r1,[r0]                       ; store the 'next' entry
1060   STR     r0,[sp,#4*1]                  ; store back on the stack
1070   LDMFD   (sp)!,{r0,r1}         ; Restore registers
1080          ; specifying length (r0 as ry)
1090   EQUS    "TEST CODE (CAS4)"+CHR$0
1100   ALIGN
1110   STMFD   (sp)!,{r0,r1}      ; Stack registers
1120   MOV     r1,r0           ; hang on to r0
1130   MOV     r0,#16             ; space to claim
1140   BL      claim             ; claim the space (to r0)
1150   STR     r1,[r0,#4]        ; store the associater
1160   LDR     r1,[sp,#4*1]                  ; re-read rx
1170   STR     r1,[r0]                       ; store the 'next' entry
1180   STR     r0,[sp,#4*1]                  ; store back on the stack
1190   LDMFD   (sp)!,{r0,r1}         ; Restore registers
1200          ; length and claimer
1210:
1220 FNcodename("er")
1230.er
1240   EQUD    99
1250   EQUS    "error"+CHR$0
1260   ALIGN
1270:
1280:
1290          ; Library routine Memory.claim
1300 FNcodename("claim")
1310.claim
1320; *******************************************************************
1330; Subroutine;   claim
1340; Description;  claim some RMA to r0 (size=r0)
1350; Parameters;   r0 = size
1360; Returns;      r0 = address, or 0 if failed
1370; *******************************************************************
1380   STMFD   (sp)!,{r1-r3,link}            ; Stack registers
1390   MOV     r3,r0                         ; right register
1400   MOV     r0,#6
1410   SWI     "XOS_Module"
1420          ; claim space
1430   MOVVS   r0,#0                         ; if error, return 0
1440   MOVVC   r0,r2                         ; return address
1450   LDMFD   (sp)!,{r1-r3,pc}^             ; Return from call
1460:
1470          ; Library 'Memory' ends
1480]
1490REM **** End of main code ****
1500REM Set final pointer to find the length of the code
1510PROCpatch_setpc(0)
1520NEXT pass%
1530PROCpatch_savefile
1560END
1570:
1580REM **** Filing procedures ****
1590:
1600DEF PROCpatch_loadfile
1610codelen=0
1620DIM MC% &amp;1400
1630endofcode=(codelen+&amp;0+3) AND -4:max=codelen
1640L%=endofcode:__cap%=FALSE
1770ENDPROC
1780:
1790DEF PROCpatch_savefile
1800outfile$="&lt;test$Dir&gt;.test"
1810SYS "OS_File",10,outfile$,,,MC%,max+MC%
1820OSCLI("Settype "+outfile$+" Module")
1830patchdir$="&lt;test$Dir&gt;"
1880ENDPROC
1890:
1900REM **** Error Handler ****
1910:
1920DEFPROCError
1930LOCAL ERROR
1940ON ERROR LOCAL:RESTORE ERROR:ERROR EXT ERR,REPORT$+" whilst in error handler at line "+STR$ERL
2050ERROR EXT ERR,REPORT$+" at line "+STR$ERL
2060ENDPROC
2070:
2180REM **** Utility procedures ****
2190:
2200DEFPROCpatch_setpc(n)
2210IF P%-&amp;0&gt;max THENmax=P%-&amp;0
2220P%=n:O%=MC%+n-&amp;0
2230ENDPROC
2240:
2250DEFFNfindfreereg(a,b,c,d):LOCAL n:n=0
2260WHILE n=a OR n=b OR n=c OR n=d
2270 n+=1
2280ENDWHILE
2290=n
2300:
2310REM **** REM macro procedures ****
2320:
2330REM FNmess2 : Generate a textual message on the screen
2340REM Don't, however expand code 13 (allows control codes!)
2350REM Include % Codes
2360REM %%  Translate to %
2370REM %I  Ignore code (So that control string can be embedded)
2380REM %r# Display register number (followed by space)
2390REM %R  Display all registers (r## : ## &lt;CR&gt;&lt;LF&gt;)
2400DEFFNmess2(n$,f%):LOCAL l$,o,i
2410IF INSTR(n$,"%")=0 THEN
2420 [OPT pass%
2430 SWI "OS_WriteS"
2440 EQUS n$+CHR$0
2450 ALIGN
2460 ]
2470ELSE
2480 IF f% THEN[OPT pass%:STMFD (sp)!,{r0-r4,link,pc}:] ELSE[OPT pass%:STMFD (sp)!,{r0-r4}:]
2490 FORo=1TOLEN(n$)
2500  IF INSTR(n$+"%","%",o)-o &gt; 2 THEN
2510   [OPT pass%
2520   SWI "OS_WriteS"
2530   EQUS MID$(n$,o,INSTR(n$+"%","%",o)-o)+CHR$0
2540   ALIGN
2550   ]
2560   o=INSTR(n$+"%","%",o)-1
2570  ELSE
2580   l$=MID$(n$,o,1)
2590   IF l$=CHR$13 THEN
2600    IF MID$(n$,o+1,1)=CHR$10 THEN
2610    o+=1:[OPT pass%:SWI "OS_NewLine":]
2620    ELSE
2630     [OPT pass%:SWI &amp;100+13:]
2640    ENDIF
2650    l$=""
2660   ENDIF
2670   IF l$="%" THEN
2680    o+=1:l$=MID$(n$,o,1)
2690    CASE l$ OF
2700     WHEN "%":[OPT pass%:SWI &amp;100+ASC("%"):]
2710     WHEN "I":REM Ignore
2720     WHEN "a":REM Ascii of register
2730      o+=1:[OPT pass%
2740      MOV r0,EVAL("&amp;"+MID$(n$,o,1))
2750      SWI "OS_WriteC":LDMFD (sp),{r0}:]
2760     WHEN "c":REM Constant - ie embedded control
2770      o+=1:[OPT pass%:SWI &amp;100+VAL(MID$(n$,o,2)):]:o+=1
2780     WHEN "r":REM Print a register
2790      o+=1:dummy=FNshowreg(EVAL("&amp;"+MID$(n$,o,1)))
2800     WHEN "&amp;":REM Print a register
2810      o+=1:dummy=FNshowhex(EVAL("&amp;"+MID$(n$,o,1)))
2820     WHEN "$":REM Print a string
2830      o+=1:dummy=FNshowstrctrl(EVAL("&amp;"+MID$(n$,o,1)))
2840     WHEN "$":REM Print a string
2850      o+=1:dummy=FNshowstrctrl(EVAL("&amp;"+MID$(n$,o,1)))
2860     WHEN "E":REM Print an error message
2870      o+=1:[OPT pass%
2880      SWI "OS_WriteS"
2890      EQUS "Error ("+CHR$0
2900      ALIGN
2910      LDR r0,[EVAL("&amp;"+MID$(n$,o,1))]:]
2920      dummy=FNshowhex(EVAL("&amp;"+MID$(n$,o,1)))
2930      [OPT pass%
2940      SWI "OS_WriteS"
2950      EQUS ") "+CHR$0
2960      ALIGN
2970      LDMFD (sp),{r0}
2980      ADD EVAL("&amp;"+MID$(n$,o,1)),EVAL("&amp;"+MID$(n$,o,1)),#4:]
2990      dummy=FNshowstrctrl(EVAL("&amp;"+MID$(n$,o,1)))
3000      [OPT pass%:LDMFD (sp),{r0}:]
3010     WHEN "R":REM Print all registers
3020      FORi=0TO15
3030       dummy=FNmess2("r"+STR$i+" : "):dummy=FNshowhex(i)
3040       dummy=FNmess("%I")
3050      NEXT
3060    ENDCASE
3070   ELSE
3080    IF l$&lt;&gt;"" THEN
3090     [OPT pass%
3100     SWI &amp;100+ASC(l$)
3110     ]
3120    ENDIF
3130   ENDIF
3140  ENDIF
3150 NEXT
3160 IF f% THEN
3170  [OPT pass%:LDMFD (sp)!,{r0-r4}:LDR r14,[sp,#4]
3180  TEQP r14,#0
3190  LDR r14,[sp],#8
3200  ]
3210 ELSE
3220  [OPT pass%:LDMFD (sp)!,{r0-r4}:]
3230ENDIF
3240=pass%
3250:
3260REM FNmess : Print a message as above, but expand returns and add
3270REM a return to end
3280DEFFNmess(a$,f%)
3290IF INSTR(a$,"%C")=0 THENa$+=CHR$13
3300WHILE INSTR(a$,CHR$13)&gt;0
3310 a$=LEFT$(a$,INSTR(a$,CHR$13)-1)+CHR$0+CHR$10+MID$(a$,INSTR(a$,CHR$13)+1)
3320ENDWHILE
3330WHILE INSTR(a$,CHR$0)&gt;0
3340 MID$(a$,INSTR(a$,CHR$0),1)=CHR$13
3350ENDWHILE
3360=FNmess2(a$,f%)
3370:
3380REM FNshowreg : Print the contents of reg n to screen (signed)
3390DEFFNshowreg(n)
3400[OPT pass%
3410   STMFD   (sp)!,{r0-r2}
3420   MOV     r0,n
3430   CMP     r0,#0
3440   RSBMI   r0,r0,#0
3450   SWIMI   &amp;100+ASC("-")
3460   SUB     sp,sp,#16
3470   MOV     r1,sp
3480   MOV     r2,#16
3490   SWI     "OS_ConvertCardinal4"
3500   SWI     "OS_Write0"
3510   ADD     sp,sp,#16
3520   LDMFD   (sp)!,{r0-r2}
3530]:=0
3540:
3550REM FNshowhex : Print the contents of reg
3560DEFFNshowhex(n)
3570[OPT pass%
3580   STMFD   (sp)!,{r0-r2}
3590   MOV     r0,n
3600   SWI     &amp;100+ASC("&amp;")
3610   SUB     sp,sp,#12
3620   MOV     r1,sp
3630   MOV     r2,#12
3640   SWI     "OS_ConvertHex8"
3650   SWI     "OS_Write0"
3660   ADD     sp,sp,#12
3670   LDMFD   (sp)!,{r0-r2}
3680]:=0
3690:
3700REM FNshowstr0 : Show the string pointed to, end =0
3710DEFFNshowstr0(n)
3720[OPT pass%
3730   STMFD   (sp)!,{r0}
3740   MOV     r0,n
3750   SWI     "OS_Write0"
3760   LDMFD   (sp)!,{r0}
3770]:=0
3780:
3790REM FNshowstrctrl : Show the ctrl ended string
3800DEFFNshowstrctrl(n)
3810[OPT pass%
3820   STMFD   (sp)!,{r0,r1}
3830   MOV     r1,n
3840   LDRB    r0,[r1],#1
3850   CMP     r0,#32
3860   SWIGE   "OS_WriteC"
3870   BGE     P%-12
3880   LDMFD   (sp)!,{r0,r1}
3890]:=0
3900:
3910REM **** Code prefix macro routine ****
3920:
3930DEFFNcodename(n$)
3940[OPT pass%
3950   EQUS    n$+CHR$0:ALIGN
3960   EQUD    &amp;FF000000+((LEN(n$)+4) AND NOT 3)
3970]:=pass%
3980:
3990DEFFNencodedict(a$,c$)
4000LOCAL ch%,n%,b$
4010REPEAT
4020 ch%=FALSE:RESTORE +1
4030 REPEAT
4040  READ n%,b$
4050  IF n%&lt;&gt;-1 THEN
4060   IF INSTR(b$,"¤")&lt;&gt;0 THENb$=LEFT$(b$,INSTR(b$,"¤")-1)+c$+MID$(b$,INSTR(b$,"¤")+1)
4070   IF INSTR(b$,"£")&lt;&gt;0 THENb$=LEFT$(b$,INSTR(b$,"£")-1)+CHR$10+MID$(b$,INSTR(b$,"£")+1)
4080   IF INSTR(a$,b$)&lt;&gt;0 THEN
4090    a$=LEFT$(a$,INSTR(a$,b$)-1)+CHR$27+CHR$n%+MID$(a$,INSTR(a$,b$)+LEN(b$))
4100    ch%=TRUE
4110   ENDIF
4120  ENDIF
4130 UNTILn%=-1
4140UNTILch%=FALSE
4150=a$
4160DATA 1, "Syntax: *¤"
4170DATA 2, " the "
4180DATA 3, "director"
4190DATA 4, "filing system"
4200DATA 5, "current"
4210DATA 6, "to a variable. Other types of value can be assigned with *"
4220DATA 7, "file"
4230DATA 8, "default"
4240DATA 9, "tion"
4250DATA 10, "*Configure"
4260DATA 11, "name"
4270DATA 12, " server"
4280DATA 13, "number"
4290DATA 14, "Syntax: *¤ &lt;"
4300DATA 15, " one or more files that match the given wildcard"
4310DATA 16, " and "
4320DATA 17, "relocatable module"
4330DATA 18, "£C(onfirm)    Prompt for confirmation of each "
4340DATA 19, "sets the "
4350DATA 20, "Syntax: *¤ [&lt;disc spec.&gt;]"
4360DATA 21, ")£V(erbose)   Print information on each file "
4370DATA 23, "spriteLandscape [&lt;XScale&gt; [&lt;YScale&gt; [&lt;Margin&gt; [&lt;Threshold&gt;]]]]]"
4380DATA 24, " is used to print a hard copy of the screen on EPSON-"
4390DATA 25, ".£Options: (use ~ to force off, eg. ~"
4400DATA 26, "printe"
4410DATA 27, "Syntax: *¤ &lt;filename&gt;"
4420DATA 28, "select"
4430DATA 29, "xpression"
4440DATA 30, "Syntax: *¤ ["
4450DATA 31, "sprite"
4460DATA 32, " displays"
4470DATA 33, "free space"
4480DATA 34, " {off}"
4490DATA 35, "library"
4500DATA 36, "parameter"
4510DATA 37, "object"
4520DATA 38, " all "
4530DATA 39, "disc"
4540DATA 40, " to "
4550DATA 41, " is "
4560DATA 0, "¤"
4570DATA -1, ""
4580:
32639REM JFPatch
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
