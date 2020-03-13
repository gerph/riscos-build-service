#!/usr/bin/env python
"""
WebSocket builder.
"""

import base64
import json
import threading

from websocket_server import WebsocketServer

import robuild
import build
import json_funcs

VERSION = '1.04'
NAME = 'Linking over Internet with RISCOS Pyromaniac Agent'


class HarnessStream(object):

    def __init__(self):
        self.builder = None
        self.source_data = None
        self.debug = None
        self.thread = None
        self.server_running = False

    def set_source(self, source_data):
        self.source_data = source_data

    def set_debug(self, debug):
        self.debug = debug

    def start(self):
        if not self.source_data:
            raise ValueError("No source data has been supplied")

        self.thread = threading.Thread(target=self.start_thread)

        # Make the thread a daemon so that we don't actually /have/ to join it.
        self.thread.daemon = True
        self.server_running = True
        self.thread.start()

    def start_thread(self):
        try:
            self.builder = build.BuilderStream(data=self.source_data, callback_function=self.stream_callback)
            self.builder.load()
            self.builder.prepare_builder()
            self.builder.prepare_pyro()

            if self.debug:
                for debug in self.debug.split(','):
                    self.builder.pyro.add_debug(debug)

            self.builder.prepare_docker()
            rc = self.builder.run()
            print("Stream finished with rc: {}".format(rc))

        except robuild.ROBuilderError as exc:
            self.stream_callback('message', 'Source file format not recognised')
            self.stream_callback('rc', -1)
            self.stream_callback('complete', True)

        except Exception as exc:
            self.stream_callback('message', 'Build failure: ' + str(exc))
            self.stream_callback('rc', -1)
            self.stream_callback('complete', True)

        finally:
            self.server_running = False
            if self.builder:
                self.builder.close()
                self.builder = None

    def stream_callback(self, code, data):
        print("{}: {}".format(code, data))

    @property
    def complete(self):
        return not self.thread.is_alive()

    def close(self):
        if self.builder:
            try:
                self.builder.close()
            except Exception:
                # Just ignore - it could be closed whilst we're processing
                pass


class HarnessStreamWS(HarnessStream):

    def __init__(self, *args, **kwargs):
        self.server = kwargs.pop('server')
        self.client = kwargs.pop('client')
        super(HarnessStreamWS, self).__init__(*args, **kwargs)
        self.send_message('welcome', '{} version {}'.format(NAME, VERSION))

    def send_message(self, code, data):
        message = ''.join(json_funcs.json_iterable([code, data]))
        self.server.send_message(self.client, message)

    def start_thread(self):
        super(HarnessStreamWS, self).start_thread()
        self.send_message('complete', True)

    def stream_callback(self, code, data):
        self.send_message(code, data)


def connected(client, server):
    """
    New connection on web socket.
    """
    client['harness'] = HarnessStreamWS(client=client, server=server)


def received(client, server, message):
    """
    Message received on a websocket"
    """
    harness = client.get('harness')
    if not harness:
        server.send_message(client, json.dumps(["error", "No client"]))
        return

    def error(msg):
        print("Sending Error: {}".format(msg))
        harness.send_message('error', msg)

    def response(msg, data=None):
        print("Sending Response: {}".format(msg))
        if data is not None:
            harness.send_message('response', (msg, data))
        else:
            harness.send_message('response', msg)

    print("Received message")
    try:
        action, data = json.loads(message)
        print("  Action: {}".format(action))

        if action == 'source':
            if harness.server_running:
                error("Cannot set source. Build is already running")
                return

            data = base64.b64decode(data)
            print("  Setting data: {} bytes".format(len(data)))
            #print("  Data: {!r}".format(data))
            harness.set_source(data)
            response('Source loaded')

        elif action == 'build':
            if harness.server_running:
                error("Cannot start build. Build is already running")
                return
            harness.start()
            response('Started build')

        else:
            error("Unrecognised action '{}'".format(action))

    except Exception as exc:
        print("Exception: {}".format(exc))
        error("Failed request: {}".format(exc))


server = WebsocketServer(13254, host='0.0.0.0')
server.set_fn_new_client(connected)
# FIXME: set_fn_client_left(disconnected)
server.set_fn_message_received(received)
server.run_forever()
