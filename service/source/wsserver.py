#!/usr/bin/env python
"""
WebSocket builder.
"""

import base64
import json
import os
import threading

from websocket_server import WebsocketServer

import robuild
import build
import json_funcs
import simpleyaml


VERSION = '1.06'
NAME = 'RISC OS Build system'


# Maximum timeout we'll allow things to run for (in seconds)
MAX_RUNTIME = 30 * 60

# The default timeout (in seconds)
DEFAULT_RUNTIME = 10 * 60


class Config(object):
    def __init__(self):
        self.version = VERSION
        self.name = NAME
        self.max_runtime = MAX_RUNTIME
        self.default_runtime = DEFAULT_RUNTIME
        if os.path.isfile('override_ws.yaml'):
            # The override file allows us to reconfigure this at deployment time.
            with open('override_ws.yaml', 'r') as fh:
                override = simpleyaml.load(fh)
                if 'version' in override:
                    self.version = override['version']
                if 'name' in override:
                    self.name = override['name']
                if 'max_runtime' in override:
                    self.max_runtime = override['max_runtime']
                if 'default_runtime' in override:
                    self.default_runtime = override['default_runtime']


class OptionError(Exception):
    pass


class HarnessStream(object):

    def __init__(self):
        self.config = Config()
        self.builder = None
        self.source_data = None
        self.debug = None
        self.thread = None
        self.server_running = False
        self.timeout = self.config.default_runtime
        self.ansitext = True
        self.arch = None

    def set_source(self, source_data):
        self.source_data = source_data

    def set_debug(self, debug):
        self.debug = debug

    def get_options(self):
        return {
                'timeout': self.timeout,
                'ansitext': self.ansitext,
                'arch': self.arch,
            }

    def set_option(self, option, value):
        # For safety, the 'debug' option isn't externally configurable - it may expose
        # more about the system than necessary.
        if option == 'timeout':
            if not isinstance(value, (int, float)) or \
               value > self.config.max_runtime or \
               value <= 0:
                raise OptionError("Option 'timeout' must be a positive number, less than {}".format(self.config.max_runtime))
            print("Configured 'timeout' to {}".format(value))
            self.timeout = value
            return

        if option == 'ansitext':
            value = bool(value)
            print("Configured 'ansitext' to {}".format(value))
            self.ansitext = value
            return

        if option == 'arch':
            if value not in ('aarch32', 'aarch64'):
                raise OptionError("Option 'arch' must be either 'aarch32' or 'aarch64'")
            print("Configured 'arch' to {}".format(value))
            self.arch = value
            return

        raise OptionError("Option '{}' is not known".format(option))

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
            self.builder.timeout = self.timeout
            if self.ansitext:
                self.builder.pyro_config.append(('vdu.implementation', 'ansitext'))
            else:
                self.builder.pyro_config.append(('vdu.implementation', 'plain'))
            if self.arch:
                self.builder.pyro_config.append(('emulation.implementation', self.arch))

            self.builder.prepare_pyro()
            if self.debug:
                for debug in self.debug.split(','):
                    self.builder.pyro.add_debug(debug)

            self.builder.prepare_docker()
            rc = self.builder.run()
            print("Stream finished with rc: {}".format(rc))

        except robuild.ROBuilderError as exc:
            self.stream_callback('message', 'Source file format not recognised')
            self.stream_callback('rc', 255)
            self.stream_callback('complete', True)

        except Exception as exc:
            self.stream_callback('message', 'Build failure: ' + str(exc))
            self.stream_callback('rc', 255)
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
        self.send_message('welcome', '{} version {}'.format(self.config.name, self.config.version))

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
    # For every action that is received, a 'response', or an 'error' must be sent back.
    try:
        action, data = json.loads(message)
        print("  Action: {}".format(action))

        if action == 'source':
            # format: ['source', <base64-data>]
            if harness.server_running:
                error("Cannot set source. Build is already running")
                return

            data = base64.b64decode(data)
            print("  Setting data: {} bytes".format(len(data)))
            #print("  Data: {!r}".format(data))
            harness.set_source(data)
            response('Source loaded')

        elif action == 'build':
            # format: ['build', <any>]
            if harness.server_running:
                error("Cannot start build. Build is already running")
                return
            harness.start()
            response('Started build')

        elif action == 'options':
            # format: ['options', <any>]
            if harness.server_running:
                error("Cannot examine options; build is running")
                return

            try:
                options = harness.get_options()
                response("Options returned", options)
            except OptionError as exc:
                error("Options failed: {}".format(str(exc)))

        elif action == 'option':
            # format: ['option', [<variable>, <value>]]
            if not isinstance(data, list) or len(data) != 2:
                error("Option must be passed a list of two items, a variable and a value")
            else:
                try:
                    (option, value) = data
                    harness.set_option(option, value)
                    response("Option '{}' set".format(option))

                except OptionError as exc:
                    error("Option set failed: {}".format(str(exc)))

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
