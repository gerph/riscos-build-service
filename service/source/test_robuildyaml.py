#!/usr/bin/env python

import os
import tempfile
import unittest

import robuildyaml


class ROBuildYAMLTests(unittest.TestCase):

    def parse(self, content):
        fd, filename = tempfile.mkstemp()
        try:
            with os.fdopen(fd, 'w') as fh:
                fh.write(content)
            return robuildyaml.ROBuildYAML(filename)
        finally:
            os.unlink(filename)

    def assert_invalid(self, content, message):
        with self.assertRaises(robuildyaml.ROBuildYAMLError) as context:
            self.parse(content)
        self.assertEqual(str(context.exception), message)

    def test_script_commands_must_be_strings(self):
        self.assert_invalid(
            'jobs:\n  build:\n    script:\n      - 42\n',
            'ROBuild YAML: jobs.build.script.0 must be a string')

    def test_job_must_be_a_dictionary(self):
        self.assert_invalid(
            'jobs:\n  build: command\n',
            'ROBuild YAML: jobs.build must be a dictionary')

    def test_artifact_path_must_be_a_string(self):
        self.assert_invalid(
            'jobs:\n  build:\n    script:\n      - Build\n    artifacts:\n      - path: 42\n',
            'ROBuild YAML: jobs.build.artifacts.0.path must contain a string')

    def test_valid_script_is_preserved(self):
        config = self.parse('jobs:\n  build:\n    script:\n      - Build\n')
        self.assertEqual(config.jobs[0].script, ['Build'])


if __name__ == '__main__':
    unittest.main()
