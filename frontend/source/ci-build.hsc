<!DOCTYPE html>
<html>
<html-header title='CI Configuration' codecolouring></html-header>
<body onload='setup_colouring({mode: "text/yaml", autosize: true, linenumbers: false});'>
    <page section='CI Configuration'>

<section>
<h2>Introduction</h2>

<p>
    <service-name> can be used with Continuous Integration ('CI') systems to build
    RISC OS components automatically. The <a href=":api.html">API documentation</a>
    describes the API that is used by the service. The <a href=":robuildyaml.html">Build
    configuration</a> describes configuration files that can be used to describe the
    RISC OS build process.
</p>

<p>
    This document describes how these can be used together with CI systems.
    The CI systems that are discussed are:

    <ul>
        <li><a href='#github'>GitHub Workflows</a></li>
        <li><a href='#gitlab'>GitLab CI</a></li>
    </ul>
</p>

<p>
    These build tools can be used with the JSON API,and examples will be given for
    <a href="#curl">curl and jq</a>.
    However, the service is easier to access with the '<a href="#robuild">robuild-client</a>' tool.
    Both these methods will be described.
</p>
</section>


<section>
    <h2 id='assumptions'>Assumptions</h2>

<p>
    It is assumed that:
<ul>
    <li>The projects being built are in a git repository.</li>
    <li>The project is stored with non-RISC OS filename encoding, eg '<code>,xxx</code>'.</li>
    <li>A '<code>.robuild.yaml</code>' file has been created which can build the project.</li>
    <li>There is a passing familiarity with shell scripting on unix systems.</li>
</ul>

</p>

</section>


<section>
    <h2 id='curl'>JSON API with curl</h2>

<h3>Simple build and status</h3>
<p>
    The simplest example of submitting a file <code>my-source-file</code> to the service with curl would be a command like:
</p>
<shell>
curl --silent -F source=@my-source-file -o /tmp/output http://json.build.riscos.online/build/
</shell>

<p>
    The result is written to the file <code>/tmp/output</code>. However this assumes that the build was successful - if it is unsuccessful the result will be a 400 response with the output written to the body. The 400 code is silently ignored by the response here.
</p>

<p>
    It is, however, possible to capture the status code with a little a capture and assignment:
</p>

<shell>
STATUS_CODE=$(curl --silent -F source=@my-source-file -o /tmp/output --write-out "%{http_code}" http://json.build.riscos.online/build/binary)
# $STATUS_CODE now holds the status from the curl operation (200 for success)
# /tmp/output contains the output from the build
</shell>

<p>
    One caveat for submitting single files which you should be aware of is that the <code>-F</code> switch
    to specify the file to submit does not support passing filenames with commas in.
    This means that if you are submitting a filename encoded with the RISC OS filetype format you will need
    to copy the file before hand.
</p>

<h3>Extracting more information</h3>

<p>
    The above example suffice for simple submissions to the service, but you may wish to do more than this.
    The JSON interface allows you to extract more information about the response from the service.
</p>

<shell>
curl --silent -F source=@my-source-file -o /tmp/result.json http://json.build.riscos.online/build/json
# /tmp/result.json contains the output in JSON.
</shell>

<p>
    The '<code>jq</code>' tool can be used to extract information from the output JSON file. For example to extract the messages you might use:
</p>

<shell>
jq -r '.messages[]' /tmp/result.json &gt; /tmp/messages.txt
jq -r 'reduce .output[] as $i ("";. + $i)' /tmp/result.json &gt; /tmp/output.txt
RC=$(jq -r .rc /tmp/robuild/result.json)
# /tmp/messages.txt now contains the messages from the service.
# /tmp/output now contains the output from the build.
# $RC contains the return code (0 if all was well)
</shell>

<p>
    The resulting data, if any, is returned in the '<code>data</code>' key, and the RISC OS filetype in the 'filetype' as an integer.
    The returned data is Base64 encoded, so will need to be decoded before it can be used.
</p>

<shell>
FILETYPE=$(jq -r .filetype /tmp/result.json)
FILETYPE_HEX=$(printf '%3x' "$FILETYPE")
if [ "$RC" = 0 ] ; then
    jq -r .data /tmp/result.json | base64 --decode - &gt; "/tmp/built,$FILETYPE_HEX"
fi
# $FILETYPE is the integer filetype
# $FILETYPE_HEX is the 3-digit hex value of the filetype
# /tmp/built,XXX contains the built data.
</shell>

<p>
    Of course, it is common to want to stop when the build fails. This is simplest if we just check the return code for non-0, and exit the build process at that point.
</p>

<shell>
if [ "$RC" = 0 ] ; then
    jq -r .data /tmp/result.json | base64 --decode - &gt; "/tmp/built,$FILETYPE_HEX"
else
    echo "Failed to build."
    exit "$RC"
fi
</shell>

<h3>Handling multiple files</h3>

<p>
    Whilst it's nice to be able to work with a single file, that's commonly not how projects are structured. Commonly there are multiple files that make up the project, and that's where the zip
    archives and '<code>.robuild.yaml</code>' build configuration becomes useful. If you have a repository
    containing files, together with a '<code>.robuild.yaml</code>' file, these can be transferred to the
    server as a Zip archive.
</p>

<shell>
# Archive the source, and the build configuration
zip -9r /tmp/source-archive.zip * .robuild.yaml
# Send the source archive to the API server, and get back a JSON response
curl -q -F 'source=@/tmp/source-archive.zip' -o /tmp/result.json http://json.build.riscos.online/build/json
</shell>

<h3>Bringing it all together</h3>

<p>
    To script this in a generic way, I put together the fragments in a way that makes it easy to reuse in
    different cases. This could be in your own scripts or in a build system like Jenkins. The basic submission and data collection script I have used is:
</p>


<shell>
# Any failing command is a total failure.
set -o pipefail

# Place the files in a separate directory
TMPBUILD=/tmp/robuild
rm -rf "${TMPBUILD}"
mkdir -p "${TMPBUILD}"

# Zip up the source to send to the server
zip -9r "${TMPBUILD}/source-archive.zip" *
# Add whichever build configuration format they used
if [ -f ".robuild.yml" ] ; then zip -9r "${TMPBUILD}/source-archive.zip" .robuild.yml ; fi
if [ -f ".robuild.yaml" ] ; then zip -9r "${TMPBUILD}/source-archive.zip" .robuild.yaml ; fi

# Send the archive file to JFPatch as a service
curl --silent -F "source=@${TMPBUILD}/source-archive.zip" -o "${TMPBUILD}/result.json" http://json.build.riscos.online/build/json

# Extract any system messages and output
jq -r '.messages[]' "${TMPBUILD}/result.json" &gt; "${TMPBUILD}/messages.txt"
jq -r 'reduce .output[] as $i ("";. + $i)' "${TMPBUILD}/result.json" &gt; "${TMPBUILD}/output.txt"

# Extract return code and filetype
RC=$(jq -r .rc "${TMPBUILD}"/result.json | tee "${TMPBUILD}/rc")
FILETYPE=$(jq -r .filetype "${TMPBUILD}/result.json")
FILETYPE_HEX=xxx
if [ "$FILETYPE" != 'null' ] ; then
    FILETYPE_HEX=$(printf '%3x' "$FILETYPE")
fi

# Marker files for the state
if [ "$RC" != "0" ] ; then touch "${TMPBUILD}/failed" ; else touch "${TMPBUILD}/ok" ; fi

# Extract the built binary if we had any
if [ "$RC" = "0" -a "$FILETYPE_HEX" != 'xxx' ] ; then
    jq -r .data "${TMPBUILD}/result.json" | base64 --decode - &gt; "${TMPBUILD}/built,${FILETYPE_HEX}"
    ln -s "${TMPBUILD}/built,${FILETYPE_HEX}" "${TMPBUILD}/built"
fi

# Outputs:
#   ${TMPBUILD}/result.json     - JSON output from the service.
#   ${TMPBUILD}/{ok,failed}     - status of the build (whether RC was 0).
#   ${TMPBUILD}/built           - the output result from the build (symlink)
#   ${TMPBUILD}/built,${FILETYPE_HEX}   - the output result from the build.
#   ${TMPBUILD}/rc              - the value of the return code (decimal string)
#   ${TMPBUILD}/messages.txt    - system messages
#   ${TMPBUILD}/output.txt      - output from the build
#   $RC                         - return code from build
#   $FILETYPE_HEX               - hex filetype of the build
</shell>

<p>
    This produces a set of files, in a temporary directory, and a couple of environment variables
    which can be used to decide what to do with the build.
</p>

<p>
    To decide what to do you might print out the output messages, and report the failures if any:
</p>

<shell>
echo "System messages:"
sed 's/^/  /' &lt; "${TMPBUILD}/messages.txt"
echo
echo "Build output:"
sed 's/^/  /' &lt; "${TMPBUILD}/output.txt"
echo
if [ ! -f "${TMPBUILD}/ok" ] ; then
    echo "FAILED! Aborting"
    exit 1
fi
</shell>

</section>


<section>
    <h2 id='robuild'>'robuild-client' tool</h2>

<p>
    The '<code>robuild-client</code>' tool is intended to make it easier to drive the build service through the
    websockets interface by removing the need for manually manipulating the JSON files and extracting content,
    and to give a more interactive environment to see the output as it happens. The tool works on Linux, macOS
    and RISC OS. It should be trivial to port to Windows, but this has not been attempted as yet.
</p>

<p>
    Unlike the manual method above, we must first obtain the build client tool, before we can submit the files
    to the service. Whilst the tool could be installed in your environment, when used from CI, it's commonly
    easier to just download it as needed.
</p>

<shell>
# Any failing command is a total failure.
set -o pipefail

# Fetch the build client
curl --silent -L -o riscos-build-online https://github.com/gerph/robuild-client/releases/download/v0.05/riscos-build-online && chmod +x riscos-build-online

# Send the archive file to build service
./riscos-build-online -i my-source-file -t 60 -o /tmp/built

# The tool will return a non-0 return code if the build failed
# The output is stored in /tmp/built,XXX.
</shell>

<p>
    The result will be written to the file '<code>/tmp/build,XXX</code>'. The job has been given a timeout of
    60 seconds. This can be useful if you're concerned that it might get into an infinite loop. There is a timeout
    on the service, but this is system controlled, so it is better to specify a timeout to what you feel is
    appropriate.
    The system output and the build output will be written to the terminal, which means that it is not ncessary
    to do any more parsing of files.
</p>

<p>
    Although this requires a download of the tool on each invocation, it's simpler and more maintainable in a
    CI environment than the shell code which did similar operations. Consult the '<a href='https://github.com/gerph/robuild-client'>robuild-client</a>' repository for more details on the tool.
</p>

</section>


<section>
    <h2 id='github'>GitHub Workflows</h2>

<p>
FIXME
</p>
</section>


<section>
    <h2 id='gitlab'>GitLab CI</h2>

<p>
FIXME
</p>
</section>


    </page>
</body>
</html>
