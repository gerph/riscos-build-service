#!/usr/bin/env python
"""
Interface to a command within Docker.
"""

import os
import subprocess
import time
import uuid

import streamedinput


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
        # Always give the container a name we can address directly, so that it can be
        # killed even if our local 'docker run' client process is no longer around to
        # forward a signal to it.
        self.name = 'robuild-{}'.format(uuid.uuid4().hex)
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

    def stop(self):
        """
        Ask the Docker daemon to kill the running container, by name.

        Terminating our local 'docker run' process is not enough to guarantee that the
        container itself stops: if that local process is killed (or dies before it has
        forwarded a signal to the container), the container - and the Pyromaniac build
        running inside it - is left running with nothing left to receive its output.
        Killing the named container directly through the daemon does not depend on the
        local process still being alive or attached.

        It is safe to call this whether or not a container is currently running; if there
        is nothing to kill, 'docker kill' merely fails and we ignore the result.
        """
        if self.name:
            with open(os.devnull, 'wb') as devnull:
                subprocess.call([self.tool_command, 'kill', self.name], stdout=devnull, stderr=devnull)


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
        #print("Running command: %s" % (' '.join('"{}"'.format(arg) for arg in args),))
        self.stream = streamedinput.ThreadedStreamedInput(args, shell=False, keep_stderr=True,
                                                          data_function=self.data_function,
                                                          complete_function=self.complete_function)
        self.stream.start()
        while self.stream.is_running():
            # Wait between checks for it completing
            time.sleep(0.5)
        return self.stream.returncode

    def stop(self):
        # Kill the container itself first - this is what actually matters - then ask our
        # local reader of its output to stop waiting on it as well.
        super(DockerStreamed, self).stop()
        if self.stream:
            self.stream.stop()

    def got_output(self, data):
        self.stream_queue.put(data)

    def got_complete(self):
        self.stream_queue.put(StreamEOF)
