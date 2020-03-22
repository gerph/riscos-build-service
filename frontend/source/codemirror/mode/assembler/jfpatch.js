/* Simple mode definition for ARM code in JFPatch.
 * Based on the example Javascript Simple Mode.
 */

(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("../../lib/codemirror"), require("../../addon/mode/simple"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["../../lib/codemirror", "../../addon/mode/simple"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function(CodeMirror) {
"use strict";

var conditions = ['EQ', 'NE',
                  'VS', 'VC',
                  'HI', 'LS',
                  'PL', 'MI',
                  'CS', 'CC',
                  'HS', 'LO',
                  'GE', 'GT',
                  'LE', 'LT',
                  'AL', /*'NV',*/
                  ''];

// FIXME: Add 'modern' arithmetic instructions
var inst_arithmetic = ['ADD', 'ADC',
                       'SUB', 'SBC',
                       'RSB', 'RSC',
                       'MUL', 'MLA',
                       'EOR', 'ORR',
                       'AND', 'BIC',
                       'MOV', 'MVN'];

var inst_compare = ['CMN', 'CMP', 'TEQ', 'TST'];
// Can be followed by S (redundant) or P (obsolete).

var inst_system = ['MSR', 'MRS'];

// FIXME: Add 'modern' extensions to loads
var inst_memory = ['LDR', 'STR'];
var inst_memorysize = ['B', 'H', ''];
// Can be followed by T

var inst_set = ['EQU', 'DC'];
var inst_setsize = ['D', 'B', 'W', 'S'];

var inst_branch = ['BL', 'BX', 'B'];
// Special case BLT/BLS as otherwise we get BL coloured and a T or S in the normal colour.
inst_branch = ['BLT', 'BLS'].concat(inst_branch)

var inst_multiple = ['LDM', 'STM'];
var inst_multiplestepping = ['IB', 'IA',
                             'DB', 'DA',
                             'FD', 'FA',
                             'ED', 'EA'];

var inst_addressof = ['ADR'];
var inst_swi = ['SWI'];

var inst_atomic_swap = ['SWP']
var inst_atomic_memory = ['LDREX', 'STREX'];
var inst_atomic_memorysize = ['B', 'H', 'D', ''];

var inst_directive = ['ALIGN'];



// res_* => regular expressions as strings
// re_ => regular expressions as RegExp object
var res_conditions = '(?:' + conditions.join('|') + ')';
var res_inst_arithmetic = '(?:' + inst_arithmetic.join('|') + ')' +
                          res_conditions +
                          'S?';
var res_inst_compare = '(?:' + inst_compare.join('|') + ')' +
                       res_conditions +
                       '[SP]?';
var res_inst_system = '(?:' + inst_system.join('|') + ')' +
                       res_conditions;
var res_inst_branch = '(?:' + inst_branch.join('|') + ')' +
                      res_conditions;
var res_inst_memory = '(?:' + inst_memory.join('|') + ')' +
                      res_conditions +
                      '(?:' + inst_memorysize.join('|') + ')' +
                      'T?';

var res_inst_multiple = '(?:' + inst_multiple.join('|') + ')' +
                        res_conditions +
                        '(?:' + inst_multiplestepping.join('|') + ')';
var res_inst_addressof = '(?:' + inst_addressof.join('|') + ')' +
                         res_conditions +
                         'L?';
var res_inst_set = '(?:' + inst_set.join('|') + ')' +
                   '(?:' + inst_setsize.join('|') + ')';
var res_inst_swi = '(?:' + inst_swi.join('|') + ')' +
                   res_conditions;
var res_inst_atomic_swap = '(?:' + inst_atomic_swap.join('|') + ')' +
                           res_conditions;
var res_inst_atomic_memory = '(?:' + inst_atomic_memory.join('|') + ')' +
                             '(?:' + inst_atomic_memorysize.join('|') + ')';
var res_inst_directive = '(?:' + inst_directive.join('|') + ')';



// JFPatch specific
var inst_jfpatch_memoryworkspace = ['LDRW', 'STRW', 'LDRBW', 'STRBW', 'ADRW'];
var inst_jfpatch_extended = ['XSWI', 'LMOV', 'LADR', 'LADD', 'XBL', 'REMP', 'REM', 'SWAP', 'NOP'];
var inst_jfpatch_nocondition = ['RES', 'XLDMFD', 'DIV', 'EQUZA', 'EQUZ'];
var res_inst_jfpatch_memoryworkspace = '(?:' + inst_jfpatch_memoryworkspace.join('|') + ')' +
                                       res_conditions
                                       'T?';
var res_inst_jfpatch_extended = '(?:' + inst_jfpatch_extended.join('|') + ')' +
                                res_conditions;
var res_inst_jfpatch_nocondition = '(?:' + inst_jfpatch_nocondition.join('|') + ')';

// Put all these instructions together
var res_inst_jfpatch_list_all = [res_inst_jfpatch_memoryworkspace,
                                 res_inst_jfpatch_extended,
                                 res_inst_jfpatch_nocondition];
// Build a regex of the different instruction forms
var res_inst_jfpatch_all = '(?:' + res_inst_jfpatch_list_all.map( (res) => {
    return "(?:" + res + ")";
}).join('|') + ')(?=\\s|$)';


// Regular instructions
var res_inst_list_all = [res_inst_arithmetic,
                         res_inst_compare,
                         res_inst_system,
                         res_inst_branch,
                         res_inst_atomic_swap,
                         res_inst_atomic_memory,
                         res_inst_memory,
                         res_inst_multiple,
                         res_inst_swi,
                         res_inst_addressof,
                         res_inst_set,
                         res_inst_directive];
// Build a regex of the different instruction forms
var res_inst_all = '(?:' + res_inst_list_all.map( (res) => {
    return "(?:" + res + ")";
}).join('|') + ')(?=\\s|$)';

var registers_plain = ['r10', 'r11', 'r12', 'r13', 'r14', 'r15',
                       'r0', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7', 'r8', 'r9'];
registers_plain = registers_plain.concat(registers_plain.map( (reg) => {
    return reg.toUpperCase();
}));
var registers_apcs = ['a1', 'a2', 'a3', 'a4', 'v1', 'v2', 'v3', 'v4', 'v5',
                      'v6', 'sb',
                      'v7', 'sl',
                      'v8', 'fp',
                            'ip',
                            'sp',
                            'lr',
                            'pc'];
registers_apcs = registers_apcs.concat(registers_apcs.map( (reg) => {
    return reg.toUpperCase();
}));
var registers_aliases = ['stack', 'link'];

var registers_all = registers_plain.concat(registers_apcs).concat(registers_aliases);

// All the registers together
var res_registers_all = '(?:' + registers_all.join('|') + ')';


// Shifts
var register_shifts = ['LSL', 'LSR', 'ASL', 'ASR', 'ROL', 'ROR', 'RRX'];
var res_register_shifts = '(?:' + register_shifts.join('|') + ')';


// JFPatch resources
var jfpatch_events = [
    'BUFFER_OUTPUTEMPTY',
    'BUFFER_INPUTFULL',
    'BUFFER_ENTERING',
    'ADCENDED',
    'VSYNC',
    'INTERVAL',
    'ESCAPE',
    'SERIAL_ERROR',
    'ECONET_USERRPC',
    'USER',
    'TRANSITION_MOUSE',
    'TRANSITION_KEY',
    'SOUND_STARTBAR',
    'PCEMULATOR',
    'ECONET_RECEIVE',
    'ECONET_TRANSMIT',
    'ECONET_OSRPC',
    'MIDI',
    'INTERNET_EVENT',
    'INTERNET',
    'DEVICE_OVERRUN',
    'DCI2_FRAME',
    'DCI2_TRANSMITTED',
    'BMU_EVENT',
];
var jfpatch_vectors = [
    'USERV',
    'ERRORV',
    'IRQV',
    'WRCHV',
    'READCV',
    'CLIV',
    'BYTEV',
    'WORDV',
    'FILEV',
    'ARGSV',
    'BGETV',
    'BPUTV',
    'GBPBV',
    'FINDV',
    'READLINEV',
    'FSCONTROLV',
    'EVENTV',
    'KEYV',
    'INSV',
    'REMV',
    'CNPV',
    'UKVDU23V',
    'UKSWIV',
    'UKPLOTV',
    'MOUSEV',
    'VDUXV',
    'TICKERV',
    'UPCALLV',
    'CHANGEENVIRONMENTV',
    'SPRITEV',
    'DRAWV',
    'ECONETV',
    'COLOURV',
    'PALETTEV',
    'SERIALV',
    'FONTV',
    'POINTERV',
    'TIMESHAREV',
];
var jfpatch_services = [
    'UKCOMMAND',
    'ERROR',
    'UKBYTE',
    'UKWORD',
    'HELP',
    'RELEASEFIQ',
    'CLAIMFIQ',
    'MEMORY',
    'STARTUPFS',
    'POSTRESET',
    'RESET',
    'UKCONFIG',
    'UKSTATUS',
    'NEWAPPLICATION',
    'FSREDECLARE',
    'PRINT',
    'LOOKUPFILETYPE',
    'INTERNATIONAL',
    'KEYHANDLER',
    'PRERESET',
    'POSTMODECHANGE',
    'CLAIMFIQBG',
    'REALLOCATEPORTS',
    'STARTWIMP',
    'STARTEDWIMP',
    'STARTFILER',
    'STARTEDFILER',
    'PREMODECHANGE',
    'MEMORYMOVED',
    'FILERDYING',
    'MODEEXTENSION',
    'MODETRANSLATION',
    'MOUSETRAP',
    'WIMPCLOSEDOWN',
    'SOUND',
    'NETFS',
    'ECONETDYING',
    'WIMPREPORTERROR',
    'RESOURCEFSSTARTED',
    'RESOURCEFSDYING',
    'CALIBRATIONCHANGED',
    'WIMPSAVEDESKTOP',
    'WIMPPALETTE',
    'MESSAGEFILECLOSED',
    'NETFSDYING',
    'RESOURCEFSSTARTING',
    'TERRITORYMANAGERLOADED',
    'PDRIVERSTARTING',
    'PDUMPERSTARTING',
    'PDUMPERDYING',
    'CLOSEFILE',
    'IDENTIFYDISC',
    'ENUMERATEFORMATS',
    'IDENTIFYFORMAT',
    'DISPLAYFORMATHELP',
    'VALIDATEADDRESS',
    'FONTSCHANGED',
    'BUFFERSTARTING',
    'DEVICEFSSTARTING',
    'DEVICEFSDYING',
    'SWITCHINGOUTPUTTOSPRITE',
    'POSTINIT',
    'TERRITORYSTARTED',
    'MONITORLEADTRANSLATION',
    'PDRIVERGETMESSAGE',
    'DEVICEDEAD',
    'SCREENBLANKED',
    'SCREENRESTORED',
    'DESKTOPWELCOME',
    'DISCDISMOUNTED',
    'SHUTDOWN',
    'PDRIVERCHANGED',
    'SHUTDOWNCOMPLETE',
    'DEVICEFSCLOSEREQUEST',
    'INVALIDATECACHE',
    'PROTOCOLDYING',
    'FINDNETWORKDRIVER',
    'WIMPSPRITESMOVED',
    'WIMPREGISTERFILTERS',
    'FILTERMANAGERINSTALLED',
    'FILTERMANAGERDYING',
    'MODECHANGING',
    'PORTABLE',
    'NETWORKDRIVERSTATUS',
    'SYNTAXERROR',
    'ENUMERATEMODES',
    'PAGESUNSAFE',
    'DYNAMICAREACREATE',
    'DYNAMICAREAREMOVE',
    'DYNAMICAREARENUMBER',
    'COLOURPICKERLOADED',
    'ENUMERATENETWORKDRIVERS',
    'DCIDRIVERSTATUS',
    'DCIFRAMETYPEFREE',
    'DCIPROTOCOLSTATUS',
    'URI',
    'INTERNETSTATUS',
    'ADFSPODULE',
    'ADFSPODULEIDE',
    'ADFSPODULEIDEDYING',
    'WIMPERRORSTARTING',
    'WIMPERRORBUTTONPRESSED',
    'WIMPERRORENDING',
    'DRAWFILEOBJECTRENDER',
    'DRAWFILEDECLAREFONTS',
    'AMPLAYER',
];
var jfpatch_filters = [
    'NULL',
    'REDRAW',
    'OPENWINDOW',
    'CLOSEWINDOW',
    'POINTERLEAVING',
    'POINTERENTERING',
    'MOUSECLICK',
    'USERDRAGBOX',
    'DRAGDROPPED',
    'KEYPRESSED',
    'KEYPRESS',
    'MENUSELECTION',
    'MENU',
    'SCROLLREQUEST',
    'SCROLL',
    'LOSECARET',
    'GAINCARET',
    'POLLWORD',
    'USERMSGREC',
    'USERMESSAGERECORDED',
    'MESSAGEREC',
    'USERMSGACK',
    'USERMESSAGEACKNOWLEDGED',
    'MESSAGEACK',
    'USERMSG',
    'USERMESSAGE',
    'MESSAGE',
];
var jfpatch_imagefs_flags = [
    'TELLFSWHENFLUSHING',
    'TELLWHENFLUSHING',
];
var jfpatch_fs_flags = [
    "SPECIALFIELDS",
    "INTERACTIVESTREAMS", "INTERACTIVE",
    "NULLFILENAMES",
    "ALWAYSOPENFILES",
    "TELLFSWHENFLUSHING", "TELLWHENFLUSHING",
    "SUPPORTSFILE9",
    "SUPPORTSFUNC20",
    "SUPPORTSFUNC18",
    "SUPPORTSIMAGEFS",
    "USEURDLIB",
    "NODIRECTORIES", "NODIRS",
    "NEVERLOAD", "USEOPENGETCLOSE",
    "NEVERSAVE", "USEOPENPUTCLOSE",
    "USEFUNC9",
    "READONLY",
    "SUPPORTSFILE34",
    "SUPPORTSCAT",
    "SUPPORTSEX",
];
var res_jfpatch_imagefs_flags = '(?:\\s+-?(?:' + jfpatch_imagefs_flags.join('|') + '))+';
var res_jfpatch_fs_flags = '(?:\\s+-?(?:' + jfpatch_fs_flags.join('|') + '))+';
var res_jfpatch_events = '(?:' + jfpatch_events.join('|') + ')';
var res_jfpatch_vectors = '(?:' + jfpatch_vectors.join('|') + ')';
var res_jfpatch_services = '(?:' + jfpatch_services.join('|') + ')';
var res_jfpatch_filters = '(?:' + jfpatch_filters.join('|') + ')';

// Taken from https://github.com/pygments/pygments/blob/master/pygments/lexers/basic.py
// which I originally submitted.
var basic_keywords = ['OTHERWISE', 'AND', 'DIV', 'EOR', 'MOD', 'OR', 'ERROR',
                      'LINE', 'OFF', 'STEP', 'SPC', 'TAB', 'ELSE', 'THEN',
                      'OPENIN', 'PTR', 'PAGE', 'TIME', 'LOMEM', 'HIMEM', 'ABS',
                      'ACS', 'ADVAL', 'ASC', 'ASN', 'ATN', 'BGET', 'COS', 'COUNT',
                      'DEG', 'ERL', 'ERR', 'EVAL', 'EXP', 'EXT', 'FALSE', 'FN',
                      'GET', 'INKEY', 'INSTR', 'INT', 'LEN', 'LN', 'LOG', 'NOT',
                      'OPENUP', 'OPENOUT', 'PI', 'POINT', 'POS', 'RAD', 'RND',
                      'SGN', 'SIN', 'SQR', 'TAN', 'TO', 'TRUE', 'USR', 'VAL',
                      'VPOS', 'CHR$', 'GET$', 'INKEY$', 'LEFT$', 'MID$',
                      'RIGHT$', 'STR$', 'STRING$', 'EOF', 'PTR', 'PAGE', 'TIME',
                      'LOMEM', 'HIMEM', 'SOUND', 'BPUT', 'CALL', 'CHAIN', 'CLEAR',
                      'CLOSE', 'CLG', 'CLS', 'DATA', 'DEF', 'DIM', 'DRAW', 'END',
                      'ENDPROC', 'ENVELOPE', 'FOR', 'GOSUB', 'GOTO', 'GCOL', 'IF',
                      'INPUT', 'LET', 'LOCAL', 'MODE', 'MOVE', 'NEXT', 'ON',
                      'VDU', 'PLOT', 'PRINT', 'PROC', 'READ', 'REM', 'REPEAT',
                      'REPORT', 'RESTORE', 'RETURN', 'RUN', 'STOP', 'COLOUR',
                      'TRACE', 'UNTIL', 'WIDTH', 'OSCLI',

                      'WHEN', 'OF', 'ENDCASE', 'ENDIF', 'ENDWHILE', 'CASE',
                      'CIRCLE', 'FILL', 'ORIGIN', 'POINT', 'RECTANGLE', 'SWAP',
                      'WHILE', 'WAIT', 'MOUSE', 'QUIT', 'SYS', 'INSTALL',
                      'LIBRARY', 'TINT', 'ELLIPSE', 'BEATS', 'TEMPO', 'VOICES',
                      'VOICE', 'STEREO', 'OVERLAY', 'APPEND', 'AUTO', 'CRUNCH',
                      'DELETE', 'EDIT', 'HELP', 'LIST', 'LOAD', 'LVAR', 'NEW',
                      'OLD', 'RENUMBER', 'SAVE', 'TEXTLOAD', 'TEXTSAVE',
                      'TWIN', 'TWINO', 'INSTALL', 'SUM', 'BEAT']
basic_keywords.sort(function(a, b){
  // ASC  -> a.length - b.length
  // DESC -> b.length - a.length
  return b.length - a.length;
});
var res_basic_keywords = '(?:' + basic_keywords.join('|') + ')';


// Styles:
//      def         - JFPatch directives
//      variable    - JFPatch parameters, in JFPatch blocks
//                    labels and label references
//      comment     - single line and multi line comments
//      meta        - JFPatch symbol directives (%, @)
//      keyword     - Label introducer
//                    ARM mnemonics
//                    ARM shifts
//      atom        - ARM register
//      number      - number (including '&hex' and '%binary')
//      operator    - operator symbols (including {}, !, (), +, -, % /, *)
//      qualifier   - import/export | characters
//                    workspace marker for 0-initialisation '*'-prefixed size

CodeMirror.defineSimpleMode("jfpatch", {
  // The start state contains the rules that are intially used
  start: [
    // Header for the file
    {regex: /(App|In|Out|Ver)(\s+)(.*)/i, sol: true, token: ['def', 'none', 'variable']},
    {regex: /(Max)(\s+)([0-9]+K?)/i, sol: true, token: ['def', 'none', 'variable']},
    {regex: /(Type)(\s+)(Module|Utility|Util|Absolute|Code|Memory|AOF|AOF Debug|AOFModule|AOFModule Debug)/i, sol: true, token: ['def', 'none', 'variable']},
    {regex: /(PC)(\s+)([0-9]+|&[a-f0-9]+)/i, token: ['def', 'none', 'number']},
    {regex: /Pre/i, sol: true, token: 'def', next: 'pre'},
    {regex: /Define Module/i, sol: true, token: 'def', next: 'define_module'},
    {regex: /Define Workspace/i, sol: true, token: 'def', next: 'define_workspace'},
    {regex: /Define Macros/i, sol: true, token: 'def', next: 'define_macros'},
    {regex: /(?=;|\.|>|#|@)/, sol: true, next: 'jfpatch'},
    {regex: /{/, sol: true, token: "comment", push: "multiline_comment"},

    // If we get any instructions directly, we move into the jfpatch code
    // Largely this is so that the documentation styling works; it's not actually valid in
    // JFPatch itself.
    {regex: new RegExp("(?=\\s+" + res_inst_jfpatch_all + ")"), token: 'none', next: 'jfpatch'},
    {regex: new RegExp("(?=\\s+" + res_inst_all + ")"), token: 'none', next: 'jfpatch'},

    {regex: /(.*)/, token: 'error'},
  ],
  pre: [
    // Before we assemble anything
    {regex: /End Pre/i, token: 'def', next: 'start'},

    // Directives
    {regex: /\s*#\s*(?=[A-Za-z])/, sol: true, token: 'def', push: 'directive'},

    // AOF exported constant
    {regex: /(\s*)(\|)([`a-zA-Z][a-zA-Z0-9_]*)(\|)(\s*)(=)/, sol: true,
     token: ['none', 'qualifier', 'variable', 'qualifier', 'none', 'operator'], posh: 'basic_line_continuation'},

    // Basic lines
    {regex: /[\s:]*/, token: 'none', push: 'basic_line'},
  ],

  post: [
    // BASIC statements which are run after the compilation
    {regex: /(\s*#\s*(?:Wimp)?Run)(\s*)(<CODE>)/i, sol: true, token: ['def', 'none', 'builtin']},
    {regex: /(\s*#\s*(?:Wimp)?Run)(\s*)(<THISDIR>)(\..*)/i, sol: true, token: ['def', 'none', 'builtin', 'string']},
    {regex: /(\s*#\s*(?:Wimp)?Run)(\s*)(.*)/i, sol: true, token: ['def', 'none', 'string']},
    {regex: /(\s*#\s*Examine)(\s*)(.*)/i, sol: true, token: ['def', 'none', 'string']},
    {regex: /(\s*#\s*Captrue)(\s*)/i, sol: true, token: ['def', 'none'], push: 'boolean'},
    {regex: /\s*#\s*End/i, sol: true, token: 'def', next: 'end'},

    // Basic lines
    {regex: /[\s:]*/, token: 'none', push: 'basic_line'},
  ],

  end: [
    // Regular BASIC code to tack on to the end of the file (eg functions)

    // Basic lines
    {regex: /[\s:]*/, token: 'none', push: 'basic_line'},
  ],

  // BASIC lines, which are just keyword coloured; there's no structure checking performed here.
  basic_line: [
    {regex: /(REM)(.*)/, token: ["comment", 'comment'], pop: true},
    {regex: new RegExp(res_basic_keywords), token: 'keyword', next: 'basic_line_continuation'},

    // * command
    {regex: /(\*)(.*)/, token: ["keyword", "string"], pop: true},

    // Variable assignment
    {regex: /[`@A-Za-z][`a-zA-Z0-9_]*[%$]?/, token: "variable", next: 'basic_line_continuation'},
    // Function return, or a memory poke.
    {regex: /[=?!\|]+/, token: "operator", next: 'basic_line_continuation'},

    {regex: /(.*)/, token: 'error', pop: true},
  ],
  basic_line_continuation: [
    {sol: true, pop: true},
    {regex: /(REM)(.*)/, token: ["comment", 'comment'], pop: true},
    {regex: new RegExp(res_basic_keywords), token: 'keyword'},
    {regex: /\&[a-f\d]+|[-+]?(?:\.\d+|\d+\.?\d*)(?:e[-+]?\d+)?|%[01]+/i,
     token: "number"},
    {regex: /".*?"/, token: "string"},
    {regex: /[-+\/*=<>!^]+/, token: "operator"},
    {regex: /[`@A-Za-z][`a-zA-Z0-9_]*[%$]?/, token: "variable"},
  ],

  define_workspace: [
    {regex: /End Workspace/i, token: 'def', next: 'start'},
    {regex: /(\s+)(Name)(\s+)(.*)/i, token: ['none', 'def', 'none', 'variable']},
    {regex: /(\s+)(Default)(\s+)(.*)/i, token: ['none', 'def', 'none', 'atom']},

    // offset format
    {regex: /(\s+)([0-9]+|&[a-f0-9]+)(\s+)([`a-zA-Z][a-zA-Z0-9_]*)(.*)/i, token: ['none', 'number', 'none', 'variable', 'comment']},
    // relative format
    {regex: /(\s+)([`a-zA-Z][a-zA-Z0-9_]*)(\s+)([!%\$\^])([0-9]*)(.*)/i, token: ['none', 'variable', 'none', 'operator', 'number', 'comment']},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_macros: [
    {regex: /\s*End Macros/i, token: 'def', next: 'start'},

    {regex: /(\s*)(Command)(\s+)([A-Za-z][A-Za-z0-9_]*)/i, token: ['none', 'def', 'none', 'keyword']},
    {regex: /(\s*)(Conds)(\s+)(INVERT|ALL|NEVER)/i, token: ['none', 'def', 'none', 'keyword']},
    {regex: /(\s*)(Conds)(\s+)([A-Za-z]{2}(?:\s+[A-Za-z]{2})*)/i, token: ['none', 'def', 'none', 'qualifier']},
    // The mask isn't validated and coloured here
    {regex: /(\s*)(Mask)(\s+)(.*)/i, token: ['none', 'def', 'none', 'string']},
    {regex: /(\s*)(Temps)(\s+)([0-9]+)/i, token: ['none', 'def', 'none', 'number']},
    {regex: /(\s*)(Code)/i, token: ['none', 'def'], push: 'define_macros_code'},

    {regex: /{/, sol: true, token: "comment", push: "multiline_comment"},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_macros_code: [
    {regex: /\s*End Code/i, token: 'def', pop: true},

    {push: 'jfpatch_line'},
  ],

  define_module: [
    {regex: /\s*End Module/i, token: 'def', next: 'start'},

    {regex: /(\s*)(Name|Version|Author|Help|Extra|MessageFile)(\s+)(.*)/, token: ['none', 'def', 'none', 'string']},
    {regex: /(\s*)(Init|Final|Start|Service|SWIHandler)(\s+)([`a-zA-Z][a-zA-Z0-9_]+)/, token: ['none', 'def', 'none', 'variable']},
    {regex: /(\s*)(Workspace)(\s+)(\*?)([0-9]+|&[a-fA-F0-9]+)/i, token: ['none', 'def', 'none', 'qualifier', 'number']},
    {regex: /(\s*)(Workspace)(\s+)(\*?)([`a-zA-Z][a-zA-Z0-9_]+)/i, token: ['none', 'def', 'none', 'qualifier', 'variable']},
    {regex: /(\s*)(Commands)/, token: ['none', 'def'], push: 'define_module_commands'},
    {regex: /(\s*)((?:Pre|Post|Copy|Rect|PostRect|PostIcon)Filter)/, token: ['none', 'def'], push: 'define_module_filters'},
    {regex: /(\s*)(SWIs)/, token: ['none', 'def'], push: 'define_module_swis'},
    {regex: /(\s*)(Events)/, token: ['none', 'def'], push: 'define_module_events'},
    {regex: /(\s*)(Vectors)/, token: ['none', 'def'], push: 'define_module_vectors'},
    {regex: /(\s*)(Services)/, token: ['none', 'def'], push: 'define_module_services'},
    {regex: /(\s*)(WimpSWIs)/, token: ['none', 'def'], push: 'define_module_wimpswis'},
    {regex: /(\s*)(Resources)/, token: ['none', 'def'], push: 'define_module_resources'},
    {regex: /(\s*)(ImageFS)/, token: ['none', 'def'], push: 'define_module_imagefs'},
    {regex: /(\s*)(FS)/, token: ['none', 'def'], push: 'define_module_fs'},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_module_commands: [
    {regex: /\s*End commands/i, token: 'def', pop: true},
    {regex: /(\s*)(Name|Type)(\s+)(.+)/i, token: ['none', 'def', 'none', 'string']},
    {regex: /(\s*)(Code)(\s+)(.+)/i, token: ['none', 'def', 'none', 'variable']},
    {regex: /(\s*)(Min|Max|Flags)(\s+)([0-9]+|&[a-fA-F0-9]+)/i, token: ['none', 'def', 'none', 'number']},
    {regex: /(\s+)(Help|Syntax)(\s+)/i, token: ['none', 'def', 'none'], push: 'maybe_long_string'},
    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  // The string or '...' followed by multiple string lines
  maybe_long_string: [
    {regex: /\.\.\./, token: 'qualifier', next: 'long_string'},
    {regex: /.*/, token: 'string', pop: true},
  ],

  long_string: [
    {regex: /(\s{6}\s*)(.*)/, token: 'string'},
    {pop: true},
  ],

  define_module_swis: [
    {regex: /\s*End SWIs/i, token: 'def', pop: true},

    {regex: /(\s*)(Prefix)(\s+)([A-WYZa-wyz][A-Za-z0-9]*)/, token: ['none', 'def', 'none', 'string']},
    {regex: /(\s*)(Base)(\s+)([0-9]+|&[a-fA-F0-9]+|%[01]+)/i, token: ['none', 'def', 'none', 'number']},
    {regex: /(\s*)(Base)(\s+)([`a-zA-Z][a-zA-Z0-9_]*)/i, token: ['none', 'def', 'none', 'variable']},

    {regex: /(\s+)([0-9]+|&[a-f0-9]+)(\s+)([A-Za-z][A-Za-z_0-9]*)(\s+)([`a-zA-Z][a-zA-Z0-9_]*)/i, token: ['none', 'number', 'none', 'string', 'none', 'variable']},

    {regex: /{/, sol: true, token: "comment", push: "multiline_comment"},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_module_events: [
    {regex: /\s*End Events/i, token: 'def', pop: true},

    {regex: /(\s+)([0-9]+|&[a-f0-9]+)(\s+)([`a-zA-Z][a-zA-Z0-9_]*)(.*)/i, token: ['none', 'number', 'none', 'variable']},
    {regex: new RegExp('(\\s+)(' + res_jfpatch_events + ')(\\s+)([`a-zA-Z][a-zA-Z0-9_]*)', 'i'), token: ['none', 'string', 'none', 'variable']},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_module_vectors: [
    {regex: /\s*End Vectors/i, token: 'def', pop: true},

    {regex: /(\s+)([0-9]+|&[a-f0-9]+)(\s+)([`a-zA-Z][a-zA-Z0-9_]*)(.*)/i, token: ['none', 'number', 'none', 'variable']},
    {regex: new RegExp('(\\s+)(' + res_jfpatch_vectors + ')(\\s+)([`a-zA-Z][a-zA-Z0-9_]*)', 'i'), token: ['none', 'string', 'none', 'variable']},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_module_services: [
    {regex: /\s*End Services/i, token: 'def', pop: true},

    {regex: /(\s+)([0-9]+|&[a-f0-9]+)(\s+)([`a-zA-Z][a-zA-Z0-9_]*)(.*)/i, token: ['none', 'number', 'none', 'variable']},
    {regex: new RegExp('(\\s+)(' + res_jfpatch_services + ')(\\s+)([`a-zA-Z][a-zA-Z0-9_]*)', 'i'), token: ['none', 'string', 'none', 'variable']},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_module_wimpswis: [
    {regex: /\s*End WimpSWIs/i, token: 'def', pop: true},

    {regex: /(\s*)(SWI)(\s+)(Wimp_[A-Za-z][A-Za-z0-9]*)/, token: ['none', 'def', 'none', 'string']},
    {regex: /(\s*)(Pre|Post)(\s+)(\^?)([`a-zA-Z][a-zA-Z0-9_]*)/i, token: ['none', 'def', 'none', 'qualifier', 'variable']},

    {regex: /(\s+)([0-9]+|&[a-f0-9]+)(\s+)([A-Za-z][A-Za-z_0-9]*)(\s+)([`a-zA-Z][a-zA-Z0-9_]*)/i, token: ['none', 'number', 'none', 'string', 'none', 'variable']},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_module_resources: [
    {regex: /\s*End Resources/i, token: 'def', pop: true},

    {regex: /(\s+)([^\s]+)(\s+)([^\s]+)/i, token: ['none', 'string', 'none', 'string']},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_module_imagefs: [
    {regex: /\s*End (?:Image)?FS/i, token: 'def', pop: true},

    {regex: new RegExp('(\\s+)(Flags)(\\s+)(' + res_jfpatch_imagefs_flags + ')', 'i'), token: ['none', 'def', 'none', 'string']},
    {regex: /(\s*)(Type|Filetype)(\s+)(&?[a-fA-F0-9]{3})/i, token: ['none', 'def', 'none', 'number']},
    {regex: /(\s*)(Type|Filetype)(\s+)([A-Za-z_\-0-9]{1,8})/i, token: ['none', 'def', 'none', 'string']},

    {regex: /(\s*)(Open|Close|GetBytes|Get|PutBytes|Put|Args|File|Func)(\s+)([`a-zA-Z][a-zA-Z0-9_]+)/i, token: ['none', 'def', 'none', 'variable']},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_module_fs: [
    {regex: /\s*End FS/i, token: 'def', pop: true},

    {regex: new RegExp('(\\s+)(Flags)(\\s+)(' + res_jfpatch_fs_flags + ')', 'i'), token: ['none', 'def', 'none', 'string']},
    {regex: /(\s*)(Files)(\s+)(INFINITE|-|&?[a-fA-F0-9]{1,2}|[0-9]{1,3})/i, token: ['none', 'def', 'none', 'number']},
    {regex: /(\s*)(Number)(\s+)(&?[a-fA-F0-9]{1,2}|[0-9]{1,3})/i, token: ['none', 'def', 'none', 'number']},
    {regex: /(\s*)(Name|Startup)(\s+)(.*)/i, token: ['none', 'def', 'none', 'string']},

    {regex: /(\s*)(Open|Close|GetBytes|Get|PutBytes|Put|Args|File|Func|GBPB)(\s+)([`a-zA-Z][a-zA-Z0-9_]+)/i, token: ['none', 'def', 'none', 'variable']},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  define_module_filters: [
    {regex: /\s*End (?:Pre|Post|Copy|Rect|PostRect|PostIcon|)filter/i, token: 'def', pop: true},
    {regex: /(\s*)(Name|Task)(\s+)(.+)/i, token: ['none', 'def', 'none', 'string']},
    {regex: /(\s*)(Code)(\s+)(.+)/i, token: ['none', 'def', 'none', 'variable']},
    {regex: /(\s*)(Mask)(\s+)([0-9]+|&[a-fA-F0-9]+|%[01]+)/i, token: ['none', 'def', 'none', 'number']},
    {regex: new RegExp('(\\s+)(Accept)(\\s+)(' + res_jfpatch_filters + ')', 'i'), token: ['none', 'def', 'none', 'string']},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],



  // Actual JFPatch code blocks - defined in terms of jfpatch_lines, which we just push into for
  // each line. The jfpatch_line state is reused for the contents of the Define Macros blocks.
  jfpatch: [
    {push: 'jfpatch_line'},
  ],

  jfpatch_line: [
    // Directives
    {regex: /\s*#\s*(?=[A-Za-z])/, sol: true, token: 'def', next: 'directive'},

    // Special symbols
    {regex: /%\s*/, sol: true, token: 'meta', next: 'basic_line'},
    {regex: /(@)(\s+)(&[a-fA-F0-9]+|[0-9]+|[a-zA-Z][a-zA-Z0-9]*$)/, sol: true, token: ['meta', 'none', 'keyword']},
    {regex: /{/, sol: true, token: "comment", next: "multiline_comment"},
    {regex: /;.*/, sol: true, token: "comment", pop: true},

    // Labels
    {regex: /([>\.\$])([`a-zA-Z][a-zA-Z0-9_]*)/, sol: true, token: ['keyword', 'variable'], pop: true},
    {regex: /([>\.\$])(\|)([`a-zA-Z][a-zA-Z0-9_]*)(\|)(\s+ENTRY)?/i, sol: true, token: ['keyword', 'qualifier', 'variable', 'qualifier', 'qualifier'], pop: true},
    {regex: /([>\.\$])(\|)([`a-zA-Z][a-zA-Z0-9_]*)(->)([`a-zA-Z][a-zA-Z0-9_]*)(\|)(\s+ENTRY)?/, sol: true, token: ['keyword', 'qualifier', 'variable', 'operator', 'variable', 'qualifier', 'qualifier'], pop: true},
    {regex: / +$/, sol: true, token: 'none', pop: true},

    // Assembler line.
    {regex: / +(?!;)/, sol: true, token: 'none', next: 'arm'},

    // Anything else isn't recognised and comes out as an error
    {regex: /(.*)/, token: 'error', pop: true},
  ],

  directive: [
    {sol: true, pop: true},

    {regex: /Post/i, token: 'def', next: 'post'},
    {regex: /End/i, token: 'def', next: 'end'},

    {regex: /(REM\s+|#CODEPREFIX\s+)/i, token: 'def', push: 'boolean'},
    {regex: /(LOAD)(\s+)([^ ,]+)(,\s*)(-?&[a-fA-F0-9]+|-?[0-9]+$)/i, token: ['def', 'none', 'string', 'operator', 'number'], pop: true},
    {regex: /(MAPWS)(\s+)([^ ,]+)(?:(,\s*)(r[0-9]+))?/i, token: ['def', 'none', 'variable', 'operator', 'atom'], pop: true},
    {regex: /(AREA)(\s+)("[^ ]+")((?:\s*(?:CODE|READONLY|32BIT|STACKCHECK))*)/i, token: ['def', 'none', 'variable', 'qualifier'], pop: true},

    // This Library directive doesn't check the format
    {regex: /(LIBRARY)(\s+)(.*)/i, token: ['def', 'none', 'string'], pop: true},
    {regex: /HERE LIBRARIES/i, token: 'def', pop: true},

    {regex: /(CHECK (?:STRING|WORD))(\s+)(&[a-fA-F0-9]+|[0-9]+$)(\s+)(.*)/i, token: ['def', 'none', 'number', 'none', 'string'], pop: true},
    {regex: /(CHECK LEN)(\s+)(&[a-fA-F0-9]+|[0-9]+$)/i, token: ['def', 'none', 'number'], pop: true},

    {regex: /COND\s+(?:INTERNAL|EXTERNAL)/i, token: 'def', pop: true},
    {regex: /(COND\s+SET)(\s+)([`a-zA-Z][a-zA-Z0-9_]*)(\s+)/i, token: ['def', 'none', 'variable', 'none'], push: 'boolean', pop: true},
    {regex: /(COND\s+OF)(\s+)([`a-zA-Z][a-zA-Z0-9_]*)/i, token: ['def', 'none', 'variable'], pop: true},
    {regex: /COND\s+(?:ELSE|ENDIF|END)/i, token: 'def', pop: true},
    {regex: /(COND\s+)([`a-zA-Z][a-zA-Z0-9_]*)(\s+)(.*)/i, token: ['def', 'none', 'variable', 'none', 'string'], pop: true},

    {regex: /.*/, token: 'error'},
  ],

  arm: [
    {sol: true, pop: true},

    {regex: new RegExp(res_inst_jfpatch_all), token: 'keyword', next: 'arm_params'},
    {regex: new RegExp(res_inst_all), token: 'keyword', next: 'arm_params'},

    {regex: /;.*/, token: "comment", pop: true},

    {regex: /.*/, token: 'error', pop: true},
  ],
  arm_params: [
    {sol: true, pop: true},

    {regex: new RegExp(res_registers_all), token: 'atom'},
    {regex: new RegExp(res_register_shifts), token: 'keyword'},

    {regex: /\&[a-f\d]+|[-+]?(?:\.\d+|\d+\.?\d*)(?:e[-+]?\d+)?|%[01]+/i,
     token: "number"},

    // The regex matches the token, the token property contains the type
    {regex: /".*?"/, token: "string"},

    {regex: /;.*/, token: "comment", pop: true},
    {regex: /[-+\/*=<>!^]+/, token: "operator"},
    {regex: /`?[A-Za-z$][a-zA-Z0-9_]*/, token: "variable"},
    {regex: /(\|)([`_a-zA-Z][a-zA-Z0-9_]*)(\|)/, token: ['qualifier', 'variable', 'qualifier']},
  ],

  // The multi-line comment state.
  multiline_comment: [
    {regex: /.*?}/, token: "comment", pop: true},
    {regex: /.*/, token: "comment"}
  ],

  // A boolean value
  boolean: [
    {regex: /ON|TRUE|ENABLED|OFF|FALSE|DISABLED/i, token: 'number', pop: true},
    {regex: /(=)(.*)/, token: ('qualifier', 'string'), pop: true},

    // Not recognised, so show as an error
    {regex: /.*/, token: 'error'},
  ],

  // The meta property contains global information about the mode. It
  // can contain properties like lineComment, which are supported by
  // all modes, and also directives like dontIndentStates, which are
  // specific to simple modes.
  meta: {
    dontIndentStates: ["comment"],
    lineComment: "; "
  }
});

  CodeMirror.defineMIME("text/x-jfpatch", "jfpatch");
});
