#!/usr/bin/env python
"""
Invoke a RISC OS build on a given file.
"""

import threading
import time

try:
    # Python 2 has Queue with a capital
    import Queue as queue
except ImportError:
    # Python 3 does not have a capital
    import queue        # pylint: disable=import-error

import docker
from rosource import RISCOSSource
import pyroserver
import robuild
import result


class Builder(object):
    docker_image = 'gerph/jfpatch'
    docker_workdir = '/home/riscos'
    docker_mountdir = '{}/fs/work'.format(docker_workdir)
    pyro_configfile = 'jfpatch.pyro'
    pyro_config = [
            ('trace.watch_lowvectors', False),
        ]

    def __init__(self, sourcefile=None, data=None):
        self.sourcefile = sourcefile
        self.data = data
        self.result = result.BuildResultLines()
        self.rosource = None
        self.robuilder = None
        self.pyro = None
        self.docker = None

    def load(self, sourcefile=None, data=None):
        if sourcefile:
            self.sourcefile = sourcefile
        if data:
            self.data = data
        if self.sourcefile:
            with open(self.sourcefile, 'rb') as fh:
                self.data = fh.read()
        self.rosource = RISCOSSource(self.data)
        self.rosource.extract()

    def setup_pyro(self):
        """
        Injection point for setting up pyro before the main execution.
        """
        self.pyro.add_config_file(self.pyro_configfile)
        for config, value in self.pyro_config:
            self.pyro.set_config(config, value)

    def prepare_builder(self):
        self.robuilder = robuild.ROBuilder(self.rosource)
        self.result.message("Build tool selected: {}".format(self.robuilder.tool_name))

    def prepare_pyro(self):
        self.pyro = pyroserver.PyroNativeServer(throwback_function=self.result.throwback_received,
                                                clipboard_function=self.result.clipboard_received)
        self.setup_pyro()
        for command in self.robuilder.commands():
            self.pyro.add_command(command)

    def prepare_docker(self):
        self.pyro.start_server()
        self.docker = docker.DockerStreamed(self.docker_image,
                                            hostname='robuild', command=self.pyro.command(),
                                            workdir=self.docker_workdir,
                                            data_function=self.result.output_data,
                                            complete_function=self.result.output_complete)
        self.docker.bind(self.rosource.dir, self.docker_mountdir)

    def run(self):
        rc = self.docker.run()
        try:
            self.pyro.stop_server()
        except Exception as exc:
            print("Failed to stop server? - {}".format(exc))
            # And fall through

        self.result.set_rc(rc)
        self.result.message("Return code: {}".format(rc))

    def close(self):
        if self.rosource:
            self.rosource.close()
        if self.pyro:
            self.pyro.stop_server()
        # FIXME: Stop any docker that might be running by killing it?


class BuilderStream(Builder):
    """
    A version of the Builder which collects data from the running jobs and streams the results.
    """

    # How often we send heartbeat message when there's no other data
    heartbeat_period = 1

    def __init__(self, *args, **kwargs):
        callback_function = kwargs.pop('callback_function')
        super(BuilderStream, self).__init__(*args, **kwargs)
        self.stream = queue.Queue()
        self.result = result.BuildResultQueue(queue=self.stream)
        self.callback_function = callback_function
        self.thread = None

    def run(self):
        """
        Run the job, getting with the results fed into the callback function.
        """
        threadrun = super(BuilderStream, self).run
        self.thread = threading.Thread(target=threadrun)
        self.thread.start()

        # We keep the accumulator
        output_accumulator = []
        while self.thread.is_alive() or not self.stream.empty():
            try:
                message = self.stream.get(True, self.heartbeat_period)
            except queue.Empty:
                message = ('heartbeat',)
            code = message[0]
            data = message[1:]
            if code == 'output':
                if '\n' in data[0]:
                    (before_newline, after_newline) = data[0].rsplit('\n', 1)
                    output_accumulator.extend([before_newline, '\n'])
                    self.callback_function(code=code, data=(''.join(output_accumulator),))
                    if after_newline:
                        output_accumulator = [after_newline]
                    else:
                        output_accumulator = []
                else:
                    output_accumulator.append(data[0])
                continue
            else:
                if output_accumulator:
                    self.callback_function(code=code, data=(''.join(output_accumulator),))
                    output_accumulator = []
            if code == 'heartbeat':
                continue
            self.callback_function(code=code, data=data)

        # If there was anything left, send it on.
        if output_accumulator:
            self.callback_function(code=code, data=(''.join(output_accumulator),))
