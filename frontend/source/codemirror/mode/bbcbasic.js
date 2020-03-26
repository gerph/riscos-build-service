/* Simple mode definition for BBC Basic.
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

CodeMirror.defineSimpleMode("bbcbasic", {
  // The start state contains the rules that are intially used
  start: [
    {next: 'bbcbasic_prefix'},
  ],

  bbcbasic_prefix: [
    {regex: /(\s*)([0-9]+)/, sol: true, token: ['none', 'qualifier', 'none'], push: 'basic_line'},

    // Basic lines
    {regex: /[\s:]*/, token: 'none', push: 'basic_line'},
  ],

  // BASIC lines, which are just keyword coloured; there's no structure checking performed here.
  basic_line: [
    {regex: /\s+/, token: 'none', pop: true},
    {regex: /(REM)(.*)/, token: ['comment', 'comment'], pop: true},
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

  // The meta property contains global information about the mode. It
  // can contain properties like lineComment, which are supported by
  // all modes, and also directives like dontIndentStates, which are
  // specific to simple modes.
  meta: {
    dontIndentStates: ["comment"],
    lineComment: "; "
  }
});

  CodeMirror.defineMIME("text/x-basic-bbcbasic", "bbcbasic");
});
