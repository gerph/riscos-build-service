#!/usr/bin/env python3
"""
Integration tests for the HTTP JSON and WebSocket build interfaces.
"""

import base64
import io
import json
import threading
import time
import unittest
import zipfile
from unittest import mock

from websocket import create_connection

import server
import wsserver


INVALID_SCRIPT_MESSAGE = 'ROBuild YAML: jobs.build.script.0 must be a string'


def source_archive(config):
    """
    Create a source archive containing a .robuild.yaml configuration file.
    """
    output = io.BytesIO()
    with zipfile.ZipFile(output, 'w') as archive:
        archive.writestr('.robuild.yaml', config)
    return output.getvalue()


class HTTPInterfaceTests(unittest.TestCase):

    def test_json_reports_malformed_robuild_yaml(self):
        source = source_archive('jobs:\n  build:\n    script:\n      - 42\n')
        with server.app.test_client() as client:
            response = client.post('/build/json', data={
                'source': (io.BytesIO(source), 'source.zip'),
            })

        self.assertEqual(response.status_code, 500)
        content = response.get_json()
        self.assertIn(INVALID_SCRIPT_MESSAGE, content['messages'])
        self.assertIn(INVALID_SCRIPT_MESSAGE, content['output'])
        self.assertEqual(content['rc'], 1)


class WebSocketInterfaceTests(unittest.TestCase):

    def setUp(self):
        self.server = wsserver.make_server(host='127.0.0.1', port=0)
        self.server.run_forever(threaded=True)
        self.client = create_connection('ws://127.0.0.1:{}'.format(self.server.port), timeout=5)

    def tearDown(self):
        self.client.close()
        self.server.shutdown_gracefully()
        self.server.server_close()

    def receive_until(self, action):
        messages = []
        end_time = time.time() + 5
        while time.time() < end_time:
            message = json.loads(self.client.recv())
            messages.append(message)
            if message[0] == action:
                return messages
        self.fail("Did not receive '{}' message".format(action))

    def test_malformed_robuild_yaml_is_reported_to_websocket_client(self):
        self.assertEqual(self.receive_until('welcome')[0][0], 'welcome')

        source = source_archive('jobs:\n  build:\n    script:\n      - 42\n')
        self.client.send(json.dumps(['source', base64.b64encode(source).decode('ascii')]))
        self.assertEqual(self.receive_until('response')[-1], ['response', 'Source loaded'])

        self.client.send(json.dumps(['build', None]))
        messages = self.receive_until('complete')

        self.assertIn(['response', 'Started build'], messages)
        self.assertIn(['message',
                       'Build failure: {}\nPlease report this to <gerph@gerph.org>.'.format(INVALID_SCRIPT_MESSAGE)],
                      messages)
        self.assertIn(['rc', 255], messages)
        self.assertEqual(messages[-1], ['complete', True])


class WebSocketDisconnectionTests(unittest.TestCase):
    """
    Confirm that losing the WebSocket connection whilst a build is running stops the
    Docker container it started, rather than leaving it running unattended.

    docker.DockerStreamed is replaced with a fake that blocks in 'run' (as a real build
    would whilst the container executes) until 'stop' is called, so the test does not need
    a real Docker daemon.
    """

    def setUp(self):
        self.server = wsserver.make_server(host='127.0.0.1', port=0)
        self.server.run_forever(threaded=True)
        self.client = create_connection('ws://127.0.0.1:{}'.format(self.server.port), timeout=5)

    def tearDown(self):
        self.server.shutdown_gracefully()
        self.server.server_close()

    def test_losing_the_connection_stops_the_docker_container(self):
        created = []

        class FakeDockerStreamed(object):
            def __init__(self, image, hostname=None, user=None, command=None, workdir=None,
                        data_function=None, complete_function=None):
                self.name = 'fake-container'
                self.complete_function = complete_function
                self.started = threading.Event()
                self.stopped = threading.Event()
                created.append(self)

            def bind(self, host_dir=None, guest_dir=None):
                pass

            def run(self):
                self.started.set()
                self.stopped.wait(5)
                if self.complete_function:
                    self.complete_function()
                return 137

            def stop(self):
                self.stopped.set()

        self.client.recv()  # 'welcome'

        source = source_archive('jobs:\n  build:\n    script:\n      - "echo hi"\n')
        self.client.send(json.dumps(['source', base64.b64encode(source).decode('ascii')]))
        self.client.recv()  # 'response', 'Source loaded'

        with mock.patch('docker.DockerStreamed', FakeDockerStreamed):
            self.client.send(json.dumps(['build', None]))
            self.client.recv()  # 'response', 'Started build'

            end_time = time.time() + 5
            while time.time() < end_time and not created:
                time.sleep(0.05)
            self.assertEqual(len(created), 1, "Build did not reach 'docker run'")
            fake_docker = created[0]
            self.assertTrue(fake_docker.started.wait(5), "Docker container was not started")

            # Simulate the client (eg its process being interrupted) going away mid-build.
            self.client.close()

            self.assertTrue(fake_docker.stopped.wait(5),
                            "Docker container was not stopped when the connection was lost")


if __name__ == '__main__':
    unittest.main()
