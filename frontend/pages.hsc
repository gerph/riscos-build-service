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

<link-to-page href=':fileformat.html' name='JFPatch File Format'>
    File format specification for JFPatch files.
</link-to-page>

<link-to-page href=':api.html' name='API documentation'>
    API documentation for communicating with <service-name>.
</link-to-page>

<link-to-page href=':robuildyaml.html' name='Build configuration'>
    File format specification for '.robuild.yaml' build configuration.
</link-to-page>

<link-to-page href=':ci-build.html' name='CI configuration'>
    How to use <service-name> with CI systems.
</link-to-page>

<link-to-page href=':history.html' name='History'>
    History of <service-name> and related systems.
</link-to-page>
</$macro>
