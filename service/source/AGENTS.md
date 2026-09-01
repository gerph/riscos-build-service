# RISC OS Build Service

This directory contains the Python service which accepts uploaded RISC OS
source material, selects a builder, and runs it through Pyromaniac in Docker.
It is a host-side service: use Python 3 and the dependencies in
`requirements.txt`.

## Interfaces

* `server.py` provides the blocking Flask HTTP API. `POST /build/json` returns
  build details as JSON, while `POST /build/binary` returns a built RISC OS
  file or a plain-text error.
* `wsserver.py` provides the streaming WebSocket API. Clients send JSON
  two-item lists: `source`, `build`, `options`, and `option`. Server messages
  include `welcome`, `response`, `error`, `message`, `output`, `throwback`,
  `clipboard`, `rc`, and `complete`.
* User-facing protocol documentation is maintained in
  `/riscos-source/frontend/source/api.hsc`. Update it when an externally
  visible request, response, or error behaviour changes.

## Build lifecycle and cleanup

`build.Builder` (`build.py`) drives a build: `prepare_docker()` starts a
`docker.DockerStreamed` container (`docker.py`) bound to the extracted
source, and `run()` blocks until it exits. `Builder.close()` must always be
able to stop a build that is still in progress - it calls `self.docker.stop()`,
which asks the Docker daemon directly (`docker kill <name>`) to kill the
container by the name every `Docker` instance is given at construction. Do
not rely solely on signalling the local `docker run` client process:
terminating or killing that local process does not guarantee the container
itself stops, particularly if the client process is killed forcefully before
it has forwarded the signal on.

`wsserver.py` must call `harness.close()` (which reaches `Builder.close()`)
when a client's connection is lost mid-build (`server.set_fn_client_left`),
not only when a build finishes normally or a `connected`/`received` message
handler raises. This used to be a dangling `# FIXME`, wired up nowhere, so a
client disconnecting (eg the browser closing, or `wsclient.py`/the build
command being interrupted) left its Docker container running with nothing
left to receive its output. If you touch the connect/disconnect wiring or
`Builder.close()`/`Docker.stop()`, keep `test_docker.py`'s
`DockerStreamedStopTests` and `test_interfaces.py`'s
`WebSocketDisconnectionTests` passing - they exist specifically to catch a
regression of this.

## ROBuild YAML

`robuildyaml.py` parses `.robuild.yaml` files supplied in source archives.
Validation errors must raise `ROBuildYAMLError` with the precise configuration
path, such as `jobs.build.script.0`, so that both interfaces can report a
useful user error. Do not silently coerce malformed configuration values.

## Testing

Run `make tests` from this directory. It creates or updates `.venv` from
`requirements.txt`, then runs the parser (`test_robuildyaml`), Docker
container lifecycle (`test_docker`), and interface (`test_interfaces`) tests.
The interface tests exercise malformed `.robuild.yaml` input, and a real
local WebSocket server (including simulated client disconnection) through a
faked `docker.DockerStreamed`; they intentionally do not require Docker or
an emulator. This is also run in CI (`.gitlab-ci.yml`, job `test-service`).

Avoid including generated `.venv`, `tmp`, or build-output files in commits.
