#!/usr/bin/env python
"""
Bare HTTP server for processing stuff.

Protocol
--------

The HTTP build service allows building of RISC OS binaries through a POST request,
with the response format selectable through the URI.

POST requests are application/x-www-form-urlencoded with the following parameters:

* 'source': the source data to build

The response depends on format selected by the URI. The following URIs are supported:

* `/build/binary`: Outputs a binary file from the build when successful, with the content
  type `application/riscos`, supplying the filetype with the name. On a failed build a
  400 response will be given with a content type of `text/plain`, and a body describing
  the build messages.

* `/build/json`: Outputs JSON encoded details of the build and output. The following
  dictionary keys are defined:
    * 'messages': A list of build management messages, explaining what the system did to
        perform the build
    * 'throwback': A list of throwback event structures. Each structure is the same format
        as the 'throwback' server action in the WebSocket protocol.
    * 'output': A list of text lines output by the build process.
    * 'data': Base64 encoded binary which was built
    * 'filetype': RISC OS file type of the built binary
    * 'rc': Return code for the build. Usually 0 for success or 1 for failure.
"""

import base64

from flask import Flask, Response, request, jsonify
app = Flask(__name__)

import build
import json_funcs


# How long we'll allow things to run
MAX_RUNTIME = 600


@app.route('/ping')
def url_ping():
    return 'OK'


@app.route('/build/<format>', methods=['POST'])
def url_build(format):
    if 'source' not in request.files:
        return "Unprocessable entity: Require 'source' to build", 422

    if format not in ('binary', 'json'):
        return "Unprocessable entity: Format may only be 'binary' or 'json'", 422

    source = request.files['source'].stream.read()

    builder = build.Builder(data=source)
    try:
        builder.load()
        builder.prepare_builder()
        builder.prepare_pyro()
        builder.pyro.timeout = MAX_RUNTIME
        #builder.pyro.add_command('gos')
        #builder.pyro.add_debug('cli')
        #builder.pyro.add_debug('traceswiargs')
        builder.prepare_docker()
        rc = builder.run()

        result = builder.result

        # At this point we're able to return the data back as JSON
        if format == 'binary':
            print("Returning binary data")
            # We can only return the binary if there wasn't an error
            success = True
            content = ''
            if result.rc != 0:
                if result.rc == 124:
                    content = 'Execution timeout reached - terminated'
                else:
                    content = 'Failed to build, return code {}\n'.format(result.rc)
                success = False
            elif len(result.clipboard) == 0:
                content = 'No content returned\n'
                success = False
            if not success:
                content += '---- Output ----\n'
                content += ''.join(result.output)
                content += '\n'
                if result.throwback:
                    content += "---- Throwback ----\n"
                    for tb in result.throwback:
                        content += "Reason:    {}\n".format(tb.reason_name)
                        content += "File:      {}\n".format(tb.filename.ro_filename)
                        if tb.reason != 0:
                            content += "Severity:  {}\n".format(tb.severity)
                            content += "Line:      {}\n".format(tb.lineno)
                            content += "Message:   {}\n".format(tb.message)
                        content += '\n'
                return Response(content, 400, mimetype='text/plain')

            # Success, so let's return the correct content
            data = result.clipboard[0].data
            filetype = result.clipboard[0].filetype
            return Response(data, 200, mimetype='application/riscos; name="build,{:03x}"'.format(filetype & 0xfff))

        elif format == 'json':
            print("Returning JSON data")
            data = None
            filetype = None
            if len(result.clipboard) != 0:
                data = result.clipboard[0].data
                filetype = result.clipboard[0].filetype
            content = {
                    'messages': result.messages,
                    'throwback': result.throwback,
                    'output': result.output,
                    'data': base64.b64encode(data) if data else None,
                    'filetype': filetype,
                    'rc': result.rc,
                }
            if not data or len(data) < 1024*10:
                encoded = json_funcs.json_iterable(content, pretty=True)
            else:
                encoded = json_funcs.json_iterable(content)
            return Response(encoded, 200, mimetype='application/json')

    except Exception as exc:
        try:
            if builder:
                builder.close()
        except Exception as exc2:
            print("Another exception in close: {}".format(exc2))
        #raise
        return "Badness: {}".format(exc), 500


if __name__ == "__main__":
    debug = True
    host = '0.0.0.0'
    port = 13255
    app.run(debug=True, host=host, port=port, threaded=True)
