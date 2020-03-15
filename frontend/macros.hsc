<$macro page_title section:string/REQUIRED>
<div class='page-head'>
<img src='icons/patched.png' alt='[Patched Cog]' />
<h1 class='title'>JFPatch<small><i> as a Service</i></small></h1>
<span class='section'><(section)><img src='icons/menu.png' alt='[menu]'/></span>
</div>
</$macro>


<**** Documentation styles ****>
<$macro param-list /CLOSE label:string="Parameter">
<table class='param-list'>
    <tr class='heading'>
        <th><(label)></th>
        <th>Meaning</th>
    </tr>
<$content>
</table>
</$macro>

<$macro param /CLOSE name:string/REQUIRED>
<tr class='row'>
    <th><(name)></th>
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
