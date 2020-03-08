#!/usr/bin/env python
"""
Interface to a command within Docker.
"""

import os
import subprocess
import streamedinput
import time


try:
    # Python 2 has Queue with a capital
    import Queue as queue
except ImportError:
    # Python 3 does not have a capital
    import queue        # pylint: disable=import-error


class DockerError(Exception):
    pass


class Docker(object):
    """
    Manage the invocation of our pyro within Docker.
    """
    tool_command = 'docker'

    def __init__(self, image, hostname=None, user=None, command=None, workdir=None):
        self.volumes = []
        self.user = user
        self.image = image
        self.name = None
        self.hostname = hostname
        self.command = command
        self.workdir = workdir
        self.interactive = False

    def bind(self, host_dir=None, guest_dir=None):
        if not host_dir:
            host_dir = os.getcwd()
        if not guest_dir:
            guest_dir = host_dir
        self.volumes.append((host_dir, guest_dir))

    def get_command(self):
        args = [self.tool_command]
        args.append('run')

        # Interactive, with a terminal
        if self.interactive:
            args.append('-it')

        # Delete after use
        args.append('--rm')

        if self.name:
            args.extend(['--name', self.name])
        if self.hostname:
            args.extend(['--hostname', self.hostname])
        if self.user:
            args.extend(['--user', self.user])
        if self.workdir:
            args.extend(['--workdir', self.workdir])

        for host_dir, guest_dir in self.volumes:
            args.extend(['-v', '{}:{}'.format(host_dir, guest_dir)])

        if self.image:
            args.append(self.image)
        else:
            raise DockerError("No image supplied")

        command = self.command
        if isinstance(command, (list, tuple)):
            args.extend(command)
        else:
            args.append(command)

        return args

    def run(self):
        command = self.get_command()
        #print("Running command: %s" % (command,))
        rc = subprocess.call(command)
        return rc


class StreamEOF(object):
    pass


class DockerStreamed(Docker):

    def __init__(self, *args, **kwargs):
        self.stream_queue = kwargs.pop('stream_queue', queue.Queue())
        self.data_function = kwargs.pop('data_function', self.got_output)
        self.complete_function = kwargs.pop('complete_function', self.got_complete)
        super(DockerStreamed, self).__init__(*args, **kwargs)
        self.stream = None

    def run(self):
        args = self.get_command()
        self.stream = streamedinput.ThreadedStreamedInput(args, shell=False, keep_stderr=True,
                                                          data_function=self.data_function,
                                                          complete_function=self.complete_function)
        self.stream.start()
        while self.stream.is_running():
            # Wait between checks for it completing
            time.sleep(0.5)
        return self.stream.returncode

    def got_output(self, data):
        self.stream_queue.put(data)

    def got_complete(self):
        self.stream_queue.put(StreamEOF)
