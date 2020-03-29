#!/bin/bash
##
# Run the two services
#

set -eo pipefail

scriptdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$scriptdir"

logdir=logs

mkdir -p "$logdir"

sig_term() {
  echo "Requested to exit - killing subprocesses"
  kill -TERM "$pid_server" || true
  kill -TERM "$pid_wsserver" || true
  kill -TERM "$pid_sleep" || true
  echo "Exiting"
  exit
}

trap sig_term SIGTERM
trap sig_term SIGHUP
trap sig_term SIGINT


export PYTHONUNBUFFERED=1

# Using > >(...) to create a redirection to a subprocess.
# Using this rather than a pipe with | means that $! gets
# set to the pid of the first command, not the second.
./server.py > >(ts >> "$logdir/server.log") 2>&1 &
pid_server=$!
./wsserver.py > >(ts >> "$logdir/wsserver.log") 2>&1 &
pid_wsserver=$!

while true; do
    sleep 60 &
    pid_sleep=$!
    wait
done
