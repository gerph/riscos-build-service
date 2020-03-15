<$macro page_title section:string/REQUIRED>
<div class='page-head'>
<script type='text/javascript'><!--
function toggle_header_menu() {
    var menu = document.getElementById("header-menu");
    menu.style.display = menu.style.display == 'block' ? 'none' : 'block';
}
--></script>
<a href=':index.html'><img class='site-logo' src='icons/patched.png' alt='[Patched Cog]' /></a>
<h1 class='title'>JFPatch <small><i>as a Service</i></small></h1>
<nav class='header-menu'>
    <a href="#" onclick="toggle_header_menu()"><img src='icons/menu.png' alt='[menu]'/></a>
    <ul class='header-menu-block' id='header-menu' style='display: none;'>
        <li><a href=':index.html'>Home</a></li>
        <li><a href=':fileformat.html'>File Format</a></li>
        <li><a href=':api.html'>API documentation</a></li>
        <li><a href=':about.html'>About</a></li>
    </ul>
</nav>
<div class='section'><(section)></div>
</div>
</$macro>

<$macro page_footer>
<div class='page-foot'>
    <span class='disclaimer'>
        JFPatch as a service is not intended for use in safety critical applications.<br/>
        No warranty is given for fitness for any particular purpose.<br/>
        Do not feed after midnight.</span>
</div>
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
    <th><(name)><$if COND=(required)>&nbsp;&dagger;</$if></th>
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
<pre class='jfpatch'><$content></pre>
</$macro>

<$macro asm /CLOSE>
<code class='asm'><$content></code>
</$macro>
