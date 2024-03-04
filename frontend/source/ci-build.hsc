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
    The above examples suffice for simple submissions to the service, but you may wish to do more than this.
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
RC=$(jq -r .rc /tmp/result.json)
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
FILETYPE_HEX=$(printf '%03x' "$FILETYPE")
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
    FILETYPE_HEX=$(printf '%03x' "$FILETYPE")
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
curl --silent -L -o riscos-build-online https://github.com/gerph/robuild-client/releases/download/v0.05/riscos-build-online &amp;&amp; chmod +x riscos-build-online

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
    GitHub can trigger builds when changes are pushed to branches or tags.
    The definition of what build is triggered is called a 'workflow', and the workflows can trigger
    multiple actions. The workflows are described in YAML, which is described in the
    <a href="https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions">GitHub documentation</a>.
</p>

<h3>Basic workflow</h3>
<p>
    The YAML file is held in the files '<code>.github/workflows/NAME.yml</code>'.
    There can be multiple independant workflows which will be run in parallel, differentiated by the filename '<code>NAME</code>'.
    The YAML content looks like this:
</p>

<yaml>
name: RISC OS

# Controls when the action will run. Triggers the workflow on:
#   * push or pull request on any branch.
on:
  push:
    branches: ["*"]
  pull_request:
    branches: ["*"]

jobs:
  build-riscos:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v2

      # The scripts to run
      - name: Build
        run: |
            echo Script goes here...
</yaml>

<ul>
    <li>The top level '<code>name</code>' key allows different workflows to be distinguished from one another.</li>
    <li>The '<code>on</code>' block defines which git server operations will cause the workflow to be run.
        In the example, this is on all branches and all pull requests, as this is likely to be the most
        common set of triggers that will be required.</li>
    <li>The '<code>jobs</code>' block defines multiple jobs which can be run to perform the build or test.
        In the example, only one job is present, for the build of a RISC OS component.
        Some projects may wish to include other types of builds; for example the <a href="https://github.com/gerph/robuild-client/blob/master/.github/workflows/ci.yml">robuild-client</a> workflow has three distinct builds
        present, which are serialised (build for Linux, build for RISC OS, create release).</li>
    <li>Within each of the builds, there are other properties, which can refine how the build happens.</li>
    <li>The '<code>runs-on</code>' key defines the environment on which the steps in this build of the workflow will
        be run. The robuild-client is built for ubuntu, so this is used in the example.</li>
    <li>The '<code>steps</code>' block describes the steps that will be run to make the build.</li>
    <li>The '<code>uses</code>' key allows 'actions' - canned operations - to be performed. There are many actions
        available to GitHub workflows. The example uses just one of the 'checkout' operations, which checks out
        the git source into the working directory.</li>
    <li>The '<code>runs</code>' key allows a shell script to be executed. This is used with the '<code>name</code>'
        key, which gives the step a name. The value of the '<code>runs</code>' element is a list of lines to
        run. In YAML, this list is indicated by the '<code>|</code>', and ends when the indentation of the line
        returns to that of the introducing key. Consult the <a href='http://yaml.org/spec/1.1/'>YAML documentation</a>
        for more detail (but be prepared for headaches).</li>
</ul>

<h3>Artifacts and version numbering</h3>
<p>
    This configuration can be combined with the scripting used in the earlier examples to give a build of the
    RISC OS component. To be useful as a tool for building binaries that others may use, though, it is necessary
    to archive the output into an 'artifact'. In building an distributable component, it is common to want to
    distribute the results with a version number or other differentiating feature.
</p>

<p>
    Version numbering can be performed in a number of ways, but it is common to have a '<code>VersionNum</code>'
    file which contains '<code>#define</code>' statements to declare the version number. This is the way that
    the RISC OS source manages its versions. However, if no version is handled this way, it may be more useful
    to just use the commit identifier (aka 'Git SHA'). These operations can be performed with a YAML file that
    looks like this:
</p>

<yaml>
name: RISC OS

on:
  push:
    branches: ["*"]
  pull_request:
    branches: ["*"]

jobs:
  build-riscos:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    outputs:
      version: ${{ steps.version.outputs.version }}
      leafname: ${{ steps.version.outputs.leafname }}

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v2

      # Build our RISC OS component
      - name: Build through build.riscos.online
        run: |
          ...

      - name: Give the output a versioned name
        id: version
        run: |
          if [[ -f VersionNum ]] ; then
              version=$(sed '/MajorVersion / ! d ; s/.*MajorVersion *"\(.*\)"/\1/' VersionNum)
          else
              version=$(git rev-parse --short HEAD)
          fi
          echo "This is version: $version"
          leafname="MyProgram-$version.zip"
          if [ -f /tmp/built,a91 ] ; then
              cp /tmp/built,a91 "MyProgram-$version.zip"
          else
              echo "No archive was built?"
              exit 1
          fi
          echo "::set-output name=version::$version"
          echo "::set-output name=leafname::$leafname"

      - uses: actions/upload-artifact@v2
        with:
          name: RISCOS-build
          path: ${{ steps.version.outputs.leafname }}
        # The artifact that is downloadable from the Actions is actually a zip of the artifacts
        # that we supply. So it will be a regular Zip file containing a RISC OS Zip file.
</yaml>

<ul>
    <li>The '<code>outputs</code>' block defines that there will be variables generated by an identified step.
        These variables can be used in later steps, or in different builds. We use them here to declare what
        we called the archive that we built, and the version number we determined.</li>
    <li>A new step is created which will create extract the version number from the <code>VersionNum</code> file, or
        use the commit identifier if no version file was found. Other methods might be to extract from a tag,
        or to use a different file to read the version from.
    </li>
    <li>
        The magic output '<code>::set-output ...</code>' indicates the variables that should be set and their
        values.
    </li>
    <li>
        The built output is, here, assumed to be a Zip archive. Zip archives will be created by the build service
        if the build configuration specifies an artifact path, rather than using the clipboard to copy a file.
        Filetype &amp;a91 is used for Zip archives.
    </li>
    <li>
        The final step uses the '<code>upload-artifact</code>' action to transfer the artifact from the CI
        server to GitHub.
    </li>
</ul>

<h3>Releases</h3>
<p>
    Artifacts stored by GitHub are only available for a short period. In order to be retained so that they
    can be used for distribution, it is necessary to create a 'Release' in GitHub. This can be achieved at
    the end of the build process. Commonly, releases are only created when a block of work has been completed
    and the author is happy with the results. This can be achieved by using git 'tags' to indicate that a
    release is required. Using any tag prefixed by a 'v' is a common way to achieve this.
</p>

<yaml>
name: RISC OS

# Controls when the action will run. Triggers the workflow on:
#   * push or pull request on any branch.
#   * tag creation for tags beginning with a 'v'
on:
  push:
    branches: ["*"]
  pull_request:
    branches: ["*"]
  create:
    tags:
      - v*

jobs:
  build-riscos:
    ... (as above examples) ...

  # The release only triggers when the thing that was pushed was a tag starting with 'v'
  release:
    needs: build-riscos
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')

    steps:
      - name: Download built binary
        uses: actions/download-artifact@v1
        with:
          name: RISCOS-build

      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ needs.build-riscos.outputs.version }}
          draft: true
          prerelease: false

      - name: Upload Release Asset
        id: upload-release-asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          # This pulls from the CREATE RELEASE step above, referencing it's ID to get its outputs object, which include a `upload_url`.
          # See this blog post for more info: https://jasonet.co/posts/new-features-of-github-actions/#passing-data-to-future-steps 
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: RISCOS-build/${{ needs.build-riscos.outputs.leafname }}
          asset_name: ${{ needs.build-riscos.outputs.leafname }}
          asset_content_type: application/zip
</yaml>

<ul>
    <li>The '<code>on</code>' block has been extended to trigger on the creation of tags that start with a '<code>v</code>'.</li>
    <li>The '<code>build-riscos</code>' block has been elided.</li>

    <li>A new job has been created which follows on from the earlier job, due to the '<code>needs</code>' element.</li>
    <li>The 'release' job, is conditional with the '<code>if</code>' key which restricts it to only run when the tag
        has been pushed which starts with a '<code>v</code>'.</li>

    <li>The binary we created as an artifact is downloaded with the '<code>download-artifact</code>' action.</li>
    <li>The '<code>create-release</code>' action is used to create a new release into which we can put the artifact.
        There is a name, based on the version number we determined earlier, generated for the release. In theory
        this could be based on the tag name, but then the version number in the built component might not match
        that of the release. The release is created as a 'draft' so that it must be approved before being public.
    </li>

    <li>
        The '<code>upload-release-asset</code>' action is then used to put the content that was downloaded into
        the release. This must use a magic token (because we don't want any old user uploading a release to your
        project). The name of the file that will be uploaded, its content type, and where it can be found are
        given with the '<code>asset_</code>' prefixed keys.
    </li>
</ul>

<p>
    Once released, it is necessary for the author to confirm the release (because it was a 'draft'). This allows
    the author a chance to test that what was built is actually suitable for distribution. Releases do not expire
    by default and will remain available to the public.
</p>

<p>
    The <a href="https://github.com/gerph/cobey/blob/master/.github/workflows/ci.yml">CObey</a> component gives an
    example of how you might build components and releases automatically. It is not required to follow the pattern
    given here - there are other ways to achieve this automation which you can use as you wish.
</p>

</section>


<section>
    <h2 id='gitlab'>GitLab CI</h2>

<p>
    GitLab CI is able to build on commits in much the same way as the GitHub actions. It is a very powerful
    system, but doesn't have the same 'action' infrastructure as the GitHub. Consequently, a simpler example
    is supplied here which shows how to use CI with GitLab. There is fuller documentation on the
    <a href="https://docs.gitlab.com/ee/ci/yaml/">GitLab documentation site</a>.
</p>

<h3>Basic structure</h3>
<p>
    As with the <service-name> build configuration, and GitHub workflow, the configuration for GitLab CI is
    YAML. GitLab CI organises the builds into stages, which may contain multiple builds. The builds will happen
    in parallel, unless a dependency is introduced. Each build may contain multiple scripted steps, which are
    run in the shell on the target system.
</p>

<p>
    The basic structure of the GitLab CI file is thus:
</p>


<yaml>
riscos:
    stage: build
    script:
      - |
        ...

    artifacts:
        when: always
        paths:
            - MyProgram-*.zip

    tags:
      - linux

stages:
    - build
</yaml>

<ul>
    <li>The '<code>stages</code>' block declares which named stages will be built, and the order in which
        they will be built. If any of the builds within the stages fails, the stage will fail, and the
        job will be terminated.</li>

    <li>
        The '<code>riscos</code>' block is a named build. It contains a '<code>stage</code>' key which
        declares the stage this build will be executed within.
    </li>

    <li>
        The '<code>script</code>' block is a list of shell commands to run. The failure of any of these
        commands will terminate the build with a failure. As with the GitHub shell commands, these are
        usually indicated by a '<code>|</code>' block which introduces lines of commands.
    </li>

    <li>
        The '<code>artifacts</code>' block declares which files should be archived as artifacts.
    </li>

    <li>
        The '<code>tags</code>' block indicates which environments (which 'runner' in GitLab terms)
        the code should run on. This will depend on your installation as to which builder is
        appropriate.
    </li>
</ul>

</section>

    </page>
</body>
</html>
