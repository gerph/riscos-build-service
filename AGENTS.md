# RISC OS Build Service

This repository holds the software behind the RISC OS Build Service
(https://build.riscos.online/): a static front end web interface, and two
back end servers that run uploaded RISC OS source through RISC OS Pyromaniac
in Docker and return the built result.

The repository is a demonstration/reference copy: it is not deployed from
directly, and there is no requirement to keep it buildable end-to-end on
every change, but each part below has its own build and test path.

## Layout

* `frontend/` - static site sources, built with the `hsc` preprocessor.
  Served from CloudFront. See "Front end" below.
* `service/source/` - the Python build service (two entry points sharing a
  library of modules). See `service/source/AGENTS.md` for the details of
  this part; read it before changing anything under `service/source/`.
* `service/ansible/` - Ansible playbook and roles that install and configure
  the service on the EC2 host (Docker, the systemd unit, kernel mitigations).
* `crosscompile/` - Dockerfile and `*.pyro` Pyromaniac configuration files
  used to build the Docker image the service launches per-request.
* `ci/` - a git submodule providing shared CI scripts; not part of this
  repository's own history.
* `frontend/source/jfpatch-as-a-service-examples/` - a git submodule of
  example sources shown/loadable in the front end editor.

Only the files tracked by `git` (`git ls-files`) are part of the project.
The working tree may contain other, untracked files left over from manual
testing (build output, scratch scripts, downloaded examples, etc.) - ignore
these unless a task specifically concerns them.

## Front end

* Built with `make` from `frontend/source/`; output goes to `frontend/dest/`.
* Pages are `.hsc` sources processed by the `hsc` HTML preprocessor;
  `frontend/Makefile` tracks per-page dependencies in a block between the
  `DO NOT MODIFY THIS LINE` markers, regenerated with `make depend` after
  adding/removing pages.
* `frontend/source/api.hsc` is the user-facing protocol documentation for
  the JSON and WebSocket APIs. Update it whenever an externally visible
  request, response, or error behaviour of the back end changes - this is
  the single source of truth read by both the site and by API consumers.
* `frontend/source/codemirror/mode/` holds the CodeMirror syntax modes for
  the RISC OS-specific languages the editor supports (BBC BASIC, ObjAsm,
  JFPatch, etc).
* `frontend/source/diagrams/` holds the GraphViz `.dot.in` sources for the
  architecture diagrams referenced from `README.md` and the site; built via
  `make` in that directory.
* CI builds the front end with `cd frontend/source && make` (see
  `.gitlab-ci.yml`, job `build-frontend`) purely to check it still builds;
  the output is not published from CI.

## Back end (service)

The service is a host-side Python program (Python 3, dependencies in
`service/source/requirements.txt`: Flask and the `websocket-server`/
`websocket-client` packages). It exposes:

* a blocking JSON HTTP API (`server.py`, Flask), and
* a streaming WebSocket API (`wsserver.py`).

Both share the same library of modules for recognising uploaded source,
selecting a builder, invoking Docker/Pyromaniac, and streaming results back.
Full detail of the modules, their responsibilities, and how to run the tests
is in `service/source/AGENTS.md` - read that file before working in
`service/source/`.

## Docker image / cross-compile environment

`crosscompile/` builds the Docker image (`gerph/robuild-service`) that the
service launches to actually run a build. `crosscompile/Makefile` builds and,
on `master` with a clean tagged version, pushes the image
(`crosscompile/tag-and-push`). The `*.pyro` files there are Pyromaniac
configuration consumed by `pyro.py` in the service when constructing an
invocation; the 32-bit and aarch64 (64-bit) variants are configured
separately (`build-service.pyro` / `build-service-aarch64.pyro`).

## Deployment

`service/ansible/` installs and configures the service on its EC2 host:
Docker, kernel mitigation settings, and the `robuild-service` systemd unit
(templated from `service/ansible/roles/robuild-service/templates/`). See
`service/ansible/README.md` for the `ansible-playbook` invocations for the
test and production hosts. Deploying is a real, hard-to-reverse action
against shared infrastructure - do not run the playbook against the
production (`robuild-service`, non-`-test`) host without explicit
instruction to do so.

## CI

`.gitlab-ci.yml` defines three build-stage jobs: `build-docker`
(builds/installs the cross-compile environment via `ci/build.sh`, a script
from the `ci` submodule), `build-frontend` (builds the static site), and
`test-service` (runs `make tests` in `service/source/`, see
`service/source/AGENTS.md`).

## Conventions

* MIT license unless stated otherwise; do not introduce GPL-licensed
  dependencies or components (organisational policy, not specific to this
  repository).
* Use British English in comments and documentation.
* Do not commit generated build output (`frontend/dest/`, `service/source/.venv/`,
  Docker build context downloads under `crosscompile/riscos/`,
  `crosscompile/pyromaniac/`, `crosscompile/ro64/`, CI `artifacts/`/`ci-logs/`)
  - see `.gitignore`.
* Diagrams under `frontend/source/diagrams/` and the top-level `.dot`/`.png`
  files document the same architecture described in `README.md` - keep them
  in step if the request/response flow or component boundaries change.
