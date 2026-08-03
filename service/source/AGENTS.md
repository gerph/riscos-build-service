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

## ROBuild YAML

`robuildyaml.py` parses `.robuild.yaml` files supplied in source archives.
Validation errors must raise `ROBuildYAMLError` with the precise configuration
path, such as `jobs.build.script.0`, so that both interfaces can report a
useful user error. Do not silently coerce malformed configuration values.

## Testing

Run `make tests` from this directory. It creates or updates `.venv` from
`requirements.txt`, then runs the parser and interface tests. The interface
tests exercise malformed `.robuild.yaml` input through Flask and a real local
WebSocket server; they intentionally do not require Docker or an emulator.

Avoid including generated `.venv`, `tmp`, or build-output files in commits.
