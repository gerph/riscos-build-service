<$define service:string>
<*** Use 'jfpaas' or 'bro' ***>
<$let service="bro">

<$if COND=(service = 'jfpaas')>
<$macro service-name>JFPatch-as-a-Service</$macro>
<$else>
<$macro service-name>RISC OS Build service</$macro>
</$if>

<$include file="../pages.hsc">

<$define Hsc.Format.Filesize:string/c="%kK">

<$macro html-header /CLOSE title:string/REQUIRED codecolouring:bool=''>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title><service-name>: <(title)></title>
  <$if COND=(service = 'jfpaas')>
   <link rel="shortcut icon" href="/favicon.ico" />
  <$else>
   <link rel="shortcut icon" href="/favicon-buildsite.ico" />
  </$if>
  <$if COND=(codecolouring)>
    <script src="codemirror/lib/codemirror.js" type='text/javascript'></script>
    <script src="codemirror/addon/mode/simple.js" type='text/javascript'></script>
    <$if COND=(set SUPPORT_JFPATCH)>
    <script src="codemirror/mode/jfpatch.js" type='text/javascript'></script>
    <$stripws type="prev"></$if>
    <$if COND=(set SUPPORT_YAML)>
    <script src="codemirror/mode/yaml.js" type='text/javascript'></script>
    <$stripws type="prev"></$if>
    <$if COND=(set SUPPORT_C)>
    <script src="codemirror/mode/clike.js" type='text/javascript'></script>
    <$stripws type="prev"></$if>
    <$if COND=(set SUPPORT_OBJASM)>
    <script src="codemirror/mode/objasm.js" type='text/javascript'></script>
    <$stripws type="prev"></$if>
    <$if COND=(set SUPPORT_PASCAL)>
    <script src="codemirror/mode/pascal.js" type='text/javascript'></script>
    <$stripws type="prev"></$if>
    <$if COND=(set SUPPORT_PERL)>
    <script src="codemirror/mode/perl.js" type='text/javascript'></script>
    <$stripws type="prev"></$if>
    <$if COND=(set SUPPORT_BASTXT)>
    <script src="codemirror/mode/bbcbasic.js" type='text/javascript'></script>
    <$stripws type="prev"></$if>
    <$if COND=(set SUPPORT_PYTHON)>
    <script src="codemirror/mode/python.js" type='text/javascript'></script>
    <$stripws type="prev"></$if>
    <$if COND=(set SUPPORT_SHELL)>
    <script src="codemirror/mode/shell.js" type='text/javascript'></script>
    <$stripws type="prev"></$if>
    <link rel="stylesheet" href="codemirror/lib/codemirror.css"/>
    <link rel="stylesheet" href="codemirror/theme/elegant.css"/>
    <link rel="stylesheet" href="codemirror/theme/liquibyte.css"/>
    <script src="colouring.js" type='text/javascript'></script>
  </$if>
  <link rel="stylesheet" type="text/css" href="/site.css" />
  <$content>
</head>
</$macro>

<$macro page /CLOSE section:string/REQUIRED>
<header class='page-head'>
<script type='text/javascript'><!--
/* 0 => off, 1 => on, 2 => toggle */
function change_header_menu(enable) {
    var menu = document.getElementById("header-menu");
    if (enable == 2)
        enable = (menu.style.display != 'block')
    menu.style.display = enable ? 'block' : 'none';
}
function toggle_header_menu() {
    change_header_menu(2)
}

window.addEventListener('click', function(e){
    if (!document.getElementById('header-menu').contains(e.target) &&
        !document.getElementById('header-menu-button').contains(e.target)) {
        change_header_menu(0);
    }
})
--></script>
  <$if COND=(service = 'jfpaas')>
<a href=':index.html'><img class='site-logo' src=':icons/patched.png' alt='[Patched Cog]' /></a>
<h1 class='title'>JFPatch <small><i>as a Service</i></small></h1>
  <$else>
<a href=':index.html'><img class='site-logo' src=':icons/buildsite.png' alt='[Build Logo]' /></a>
<h1 class='title' title="aka JFPatch-as-a-Service"><service-name></h1>
  </$if>
<nav class='header-menu'>
    <a href="#/" onclick="toggle_header_menu()" id='header-menu-button'><img src='/icons/menu.png' alt='[menu]'/></a>
    <ul class='header-menu-block' id='header-menu' style='display: none;'>
        <links-to-pages>
    </ul>
</nav>
<div class='section'><(section)></div>
</header>
<main>
<$content>
</main>
<footer class='page-foot'>
    <span class='disclaimer'>
        <service-name> is not intended for use in safety critical applications.<br/>
        No warranty is given for fitness for any particular purpose.<br/>
        Do not feed after midnight.
    </span>
</footer>
</$macro>


<**** Documentation styles ****>
<$macro param-list /CLOSE label:string="Parameter" hasrequired:bool=''>
<table class='param-list'>
    <tr class='heading'>
        <th><(label)><$if COND=(hasrequired)><br/><small>(&dagger;&nbsp;&rArr;&nbsp;required)</small></$if></th>
        <th>Meaning</th>
    </tr>
<$content>
</table>
</$macro>

<$macro param /CLOSE name:string/REQUIRED required:bool=''>
<tr class='row'>
    <th><code><(name)></code><$if COND=(required)>&nbsp;&dagger;</$if></th>
    <td><$content></td>
</tr>
</$macro>


<$macro endpoint-list /CLOSE>
<table class='endpoint-list'>
    <tr class='heading'>
        <th>URL</th>
        <th>Endpoint</th>
    </tr>
<$content>
</table>
</$macro>

<$macro endpoint /CLOSE url:string/REQUIRED method:string/REQUIRED>
<tr class='row'>
    <th><(url)></th>
    <td>Method: <span class='method-name'><(method)></span><br/>
        <$content></td>
</tr>
</$macro>


<$macro media-type /CLOSE>
<span class='media-type'><$content></span>
</$macro>



<***** File format specific macros ****>

<$macro jfpatch /CLOSE>
<div class='jfpatch'>
    <textarea class='source-code jfpatch' readonly><$content><$stripws type=both></textarea>
</div>
</$macro>

<$macro yaml /CLOSE>
<div class='yaml'>
    <textarea class='source-code yaml' readonly><$content><$stripws type=both></textarea>
</div>
</$macro>

<$macro asm /CLOSE>
<span class='asm'><$content></span>
</$macro>

<$macro python /CLOSE>
<div class='python'>
    <textarea class='source-code python' readonly><$content><$stripws type=both></textarea>
</div>
</$macro>

<$macro shell /CLOSE>
<div class='shell'>
    <textarea class='source-code shell' readonly><$content><$stripws type=both></textarea>
</div>
</$macro>


<***** Common formatting macros ****>

<$macro filelink filename:string/REQUIRED label:string/REQUIRED>
<span class='filelink'><a href=(filename)><(label)></a>
(<(GetFileSize(filename))>)</span>
</$macro>
