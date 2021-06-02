<*** This macros document just holds the pages for the system so it can be used
     in the main page and on links in the menu bar ***>

<$macro link-to-page /CLOSE href:uri name:string>
<li class='page-link'><a href=(href)><(name)></a>
  <span class='page-link-description'><$content></span>
</li>
</$macro>



<$macro links-to-pages>
<link-to-page href=':index.html' name='Home'>
    <service-name> build page.
</link-to-page>

<link-to-page href=':about.html' name='About'>
    General information about <service-name>.
</link-to-page>

<$if COND=(service = 'jfpaas')>
<link-to-page href=':fileformat.html' name='Docs: JFPatch File Format'>
    File format specification for JFPatch files.
</link-to-page>
</$if>

<link-to-page href=':api.html' name='Docs: Service API'>
    API documentation for communicating with <service-name>.
</link-to-page>

<link-to-page href=':robuildyaml.html' name='Docs: .robuild.yaml format'>
    File format specification for '.robuild.yaml' build configuration.
</link-to-page>

<link-to-page href=':ci-build.html' name='Docs: Automation with git'>
    How to use <service-name> with automation systems like Github, GitLab, Jenkins, etc.
</link-to-page>

<$if COND=(service = 'bro')>
<link-to-page href=':fileformat.html' name='Docs: JFPatch format'>
    File format specification for JFPatch files.
</link-to-page>
</$if>

<link-to-page href=':statistics.html' name='Statistics'>
    Some statistics on Pyromaniac and related projects.
</link-to-page>

<link-to-page href=':history.html' name='History'>
    History of <service-name> and related systems.
</link-to-page>
</$macro>
