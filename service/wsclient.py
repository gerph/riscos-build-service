#!/usr/bin/env python

import argparse
import base64
import json
import os
import sys

from websocket import create_connection


def setup_parser():
    parser = argparse.ArgumentParser(usage="%s [<options>]" % (os.path.basename(sys.argv[0]),))
    parser.add_argument('--source', type=str,
                        help="Source file to build")
    parser.add_argument('--server', type=str, default='localhost:13254',
                        help="Use the streaming interface")

    return parser


parser = setup_parser()
options = parser.parse_args()

ws = create_connection("ws://{}/".format(options.server))

STATE_AWAITWELCOME = 0
STATE_SENDGO = 1
STATE_RUNNING = 2
STATE_COMPLETE = 3


filename = options.source
with open(filename) as fh:
    source_data = fh.read()

def send(action, data):
    ws.send(json.dumps([action, data]))


state = STATE_AWAITWELCOME
while state != STATE_COMPLETE:
    result = ws.recv()
    action, data = json.loads(result)
    print("{}: {!r}".format(action, data))

    if action == 'error':
        # Cannot continue if we got an error
        break

    if state == STATE_AWAITWELCOME:
        # Now we send the source we're wanting built
        send('source', base64.b64encode(source_data))
        state = STATE_SENDGO

    elif state == STATE_SENDGO:
        send('go', None)
        state = STATE_RUNNING

    elif state == STATE_RUNNING:
        if action == 'complete':
            break

ws.close()
