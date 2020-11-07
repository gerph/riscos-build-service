<!DOCTYPE html>
<html>
<html-header title='Build Configuration' codecolouring></html-header>
<body onload='setup_colouring({mode: "text/yaml", autosize: true, linenumbers: false});'>
    <page section='Build Configuration'>

<section>
<h2>Introduction</h2>

<p>
    <service-name> is a cloud based general RISC OS build system.
    It can also be supplied a Zip archive, as described on the home page, which contains
    the JFPatch source and patch files, and it will build these. This is only one of
    the modes in which it can function. If the Zip archive contains a configuration file,
    the <service-name> system will interpret this as build instructions and return
    the results.
</p>
</section>


<section>
    <h2>Build configuration</h2>

<p>
    The build configuration is held in a file with the RISC OS filename '<code>/robuild/yaml</code>', '<code>/robuild/yml</code>' or '<code>/robuild</code>'. The YAML format has been allocated the filetype &amp;F74, although the file does not have to have this filetype assigned to it.
</p>

<p>
    The file may be stored in the Zip archive using either RISC OS zip conventions (using the <code>AC</code>/<code>ARC0</code> extra field, as used by most RISC OS tools), or the standard unix conventions, with or without NFS encoding of the filename (ie, the file in the Zip can be called '<code>.robuild.yml</code>', or '<code>.robuild.yml,f74</code>' or any of the other variations.
</p>

<p>
    The file is used to define how the build should be performed. The file must contain a dictionary with the following elements:

    <ul>
        <li><code>source</code>: Defines where the source should be obtained from. Not currently implemented.</li>

        <li><code>jobs</code>: Defines a dictionary of the build jobs which the file declares. Only one job may be defined at present, which it is recommended be called '<code>build</code>'.</li>
    </ul>
</p>

<p>
    The <code>jobs</code> dictionary may contain the following keys:

    <ul>
        <li><code>env</code>: Declares a dictionary of system variables which should be set before the build.</li>

        <li><code>script</code>: Declares a list of the RISC OS commands to run. Failure of any command will fail the build.
<$if COND=(service = 'bro')>
More information about the environment can be found in information <a href=":about.html">about the service</a>.
</$if>
        </li>

        <li><code>artifacts</code>: Declares a list of artifacts that should be returned. Only one item can exist at present</li>
    </ul>
</p>

<p>
    The <code>artifacts</code> list items are a dictionary describing how they artifacts are to be
    handled:

    <ul>
        <li><code>path</code>: Declares the path which will be archived.</li>
    </ul>
</p>

<p>
    The YAML file content is restricted to simple expressions. Flow content (eg JSON strings), block strings, anchors and aliases, directives and types are not supported.
</p>

</section>


<section>
    <h2>Example</h2>

<p>
    An example file, used in the LineEditor build.
</p>

<p>
<yaml>
%YAML 1.0
---

# Example .robuild.yml file

# Source is optional (NYI), and should be a URL to source the content from.
#source: http://some-url/archive.zip

# Defines a list of jobs which will be performed.
# Only 1 job will currently be executed.
jobs:
  build:
    # Env defines system variables which will be used within the environment.
    # Multiple variables may be assigned.
    env:
      "Sys$Environment": ROBuild

    # Directory to change to before running script
    #dir: src

    # Commands which should be executed to perform the build.
    # The build will terminate if any command returns a non-0 return code or an error.
    script:
      - !!Release

    # Outputs from the build are defined in artifacts
    # These are a list of artifacts to report directories or files.
    # Only a single item is currently supported.
    artifacts:
      # Each element of the artifacts should have a path key, which gives the file or
      # directory to return.
      - path: Release
</yaml>
</p>


</section>

    </page>
</body>
</html>
