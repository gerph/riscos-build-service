#!/usr/bin/env python
"""
Invoke a RISC OS build on a given file.

Given a source file (or data), build it.

* Loads the file with RISCOSSource.
* Extracts the content into a temporary directory.
* Uses the ROBuilder to determine what should be run.
* Sets up a PyroServer for the RISC OS commands and the HTTP server environment.
* Uses the PyroServer tool command line to pass to the Docker environment.
* Uses the docker module to start the job.
* Returns the results through callbacks and the results object.
"""

import threading

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
    docker_image = 'gerph/robuild-service'
    docker_workdir = '/home/riscos'
    docker_mountdir = '{}/fs/work'.format(docker_workdir)
    pyro_configfile = None

    def __init__(self, sourcefile=None, data=None, timeout=(60 * 10)):
        self.sourcefile = sourcefile
        self.data = data
        self.result = result.BuildResultLines()
        self.rosource = None
        self.robuilder = None
        self.pyro = None
        self.docker = None
        self.timeout = timeout
        self.pyro_config = [
                ('trace.watch_lowvectors', False),
            ]

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
        if self.pyro_configfile:
            self.pyro.add_config_file(self.pyro_configfile)
        for config, value in self.pyro_config:
            self.pyro.set_config(config, value)

        # prevent things from running away?
        self.pyro.timeout = self.timeout

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

        if rc == 0:
            # All was well; see if there's any artifact to pick up
            (artifact_data, artifact_filetype) = self.robuilder.collect_artifact()
            if artifact_data:
                #print("Got artifact: %03x" % (artifact_filetype,))
                self.result.clipboard_received(artifact_data, artifact_filetype)

        self.result.set_rc(rc)
        self.result.message("Return code: {}".format(rc))
        return rc

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
            if len(message) > 1:
                data = message[1]
            else:
                data = None
            if code == 'output':
                if '\n' in data:
                    (before_newline, after_newline) = data.rsplit('\n', 1)
                    output_accumulator.extend([before_newline, '\n'])
                    self.callback_function(code='output', data=''.join(output_accumulator))
                    if after_newline:
                        output_accumulator = [after_newline]
                    else:
                        output_accumulator = []
                else:
                    output_accumulator.append(data)
                continue
            else:
                # Not an output, but something else has happened, so flush the accumulator
                if output_accumulator:
                    self.callback_function(code='output', data=''.join(output_accumulator))
                    output_accumulator = []
            if code == 'heartbeat':
                continue
            if code == 'finished':
                # This is a message from the internal system that the execution has completed.
                # It doesn't mean much to the end user, so we'll just drop it.
                continue
            self.callback_function(code=code, data=data)

        # If there was anything left, send it on.
        if output_accumulator:
            self.callback_function(code=code, data=(''.join(output_accumulator),))

        return self.result.rc
