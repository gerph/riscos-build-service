#!/usr/bin/env python3
"""
Unit tests for stopping a Docker container that was started for a build.
"""

import unittest
from unittest import mock

import docker


class DockerNamingTests(unittest.TestCase):

    def test_container_is_given_a_name_by_default(self):
        d = docker.Docker(image='some/image')
        self.assertTrue(d.name)
        self.assertIn('--name', d.get_command())
        self.assertIn(d.name, d.get_command())

    def test_each_container_gets_a_distinct_name(self):
        first = docker.Docker(image='some/image')
        second = docker.Docker(image='some/image')
        self.assertNotEqual(first.name, second.name)


class DockerStopTests(unittest.TestCase):

    def test_stop_kills_the_container_by_name(self):
        d = docker.Docker(image='some/image')
        with mock.patch('docker.subprocess.call') as call:
            d.stop()
        call.assert_called_once()
        (args,), _kwargs = call.call_args
        self.assertEqual(args, [docker.Docker.tool_command, 'kill', d.name])

    def test_stop_does_nothing_without_a_name(self):
        d = docker.Docker(image='some/image')
        d.name = None
        with mock.patch('docker.subprocess.call') as call:
            d.stop()
        call.assert_not_called()


class DockerStreamedStopTests(unittest.TestCase):

    def test_stop_kills_the_container_and_the_local_reader(self):
        d = docker.DockerStreamed(image='some/image')
        d.stream = mock.Mock()
        with mock.patch('docker.subprocess.call') as call:
            d.stop()
        call.assert_called_once()
        d.stream.stop.assert_called_once()

    def test_stop_is_safe_before_run_has_started(self):
        # 'run' has not been called, so there is no self.stream yet - this is the case
        # when a build is cancelled before the docker command has even been launched.
        d = docker.DockerStreamed(image='some/image')
        with mock.patch('docker.subprocess.call') as call:
            d.stop()  # must not raise
        call.assert_called_once()


if __name__ == '__main__':
    unittest.main()
