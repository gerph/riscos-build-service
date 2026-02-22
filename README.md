# RISC OS Build Service software

## Summary

This repository holds the software that drives the [RISC OS Build Service](https://build.riscos.online/).

It provides a front end web interface, and two back end servers - a JSON and WebSockets service.

The web interface is a static site that is served by CloudFront. The web interface runs
on an EC2 instance, managed by a load balancer. In theory we can have multiple service
systems available and it will scale up, but the cost means that I generally don't do
this. Alerts will cause the machine to be automatically rebooted if it becomes
unresponsive, and I get emails to let me know if things are unhappy.

The service is built around Docker images which are fired up as necessary when a request
is made to the service. This isolates the environment and ensures that the system can
be torn down cleanly.

The repository is provided to demonstrate how the RISC OS Pyromaniac build service has
been constructed.

### Structure

![How It Works!](https://build.riscos.online/images/howitworks.svg)

## Website

The static site is built by the code in the `frontend` directory. This uses the
`hsc` processing tool to generate the webpages that we use. All my sites have a
similar layout, and common functions that can be shared. The site includes all the
Javascript that drives the system, including a static copy of CodeMirror, and the
extensions that I use for the RISC OS file formats (see
`frontend/source/codemirror/mode` for these).

Diagrams are built with graphviz, (see the `frontend/source/diagrams` directory).
Icons are built from The Noun Project icons (see the `frontend/source/icons` directory).

## Service software

The service software is in two parts, which share libraries. The `service/source`
directory holds the sources. The two entry points - `wsserver.py` provides the WebSockets
server, whilst the `server.py` file provides the JSON interface through Flask.
Additionally, the `cli.py` file allows the environment to be tested without running
the full server. Whilst `curl` can be used to communicate with the JSON service, the
`wsclient.py` command allows the WebSockets service to be tested.

![External interfaces](https://build.riscos.online/images/interfaces.svg)

Various files give different interfaces to the system, which are built on top of one
another:

* `build.py` - is the main entry point for building things, which is given a file and
  some configuration information.
* `docker.py` - manages the invocation of Docker and streaming the output to the
  handlers which feed this back to the user in different ways.
* `json_funcs.py` - provides some serialisation for Python objects through dunder
  extensions.
* `makefile.py` - manages the processing of a RISC OS style Makefile, so that we can
  handle the different targets.
* `pyro.py` - converts from structured parameters to a RISC OS Pyromaniac command
  invocation.
* `pyroserver.py` - provides a simple, dynamicly instantiated Throwback and Clipboard
  server, to receive information from the Docker container's invocation of RISC OS
  Pyromaniac. The information is then passed to registered callback functions.
* `result.py` - collects all the information from the server, to pass to the caller.
  These classes are overloaded in the WebSockets implementation to give live progress.
* `robuild.py` - recognises the content that has been supplied and decides how to
  extract it (if it is a Zip for example) and how it should be invoked. Registered
  classes within this file process the file content and construct an invocation of
  the RISC OS Pyromaniac system.
* `robuildyaml.py` - processes the `.robuild.yaml` files to construct a configuration
  for the system.
* `rofiletypes.py` - contains a few definitions of the RISC OS filetypes.
* `roname.py` - converts from RISC OS filenames to POSIX filenames (and vice-versa).
* `rosource.py` - performs a lot of the actual recognition of the file content for `robuild.py`
* `rozipinfo.py` - Extracts (or builds) RISC OS Zip archives.
* `simpleyaml.py` - Pure Python implementation of the basic YAML file format reader.
* `streamedinput.py` - manages input from threaded subprocesses and dispatches to
  registered functions as it is received.

![Builder components](https://build.riscos.online/images/builder.svg)

The `service/ansible` directory deals with deployment on the EC2 instance.

## Docker image creation

The Docker image creation is in the `crosscompile` directory, based on the docker
images created for RISC OS Pyromaniac. The configuration for each of the service
invocations lives here in `*.pyro` files.
