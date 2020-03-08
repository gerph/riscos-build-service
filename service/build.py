#!/usr/bin/env python
"""
Invoke a RISC OS build on a given file.
"""

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

        self.result.rc = rc
        self.result.message("Return code: {}".format(rc))

    def close(self):
        if self.pyro:
            self.pyro.stop_server()
        # FIXME: Stop any docker that might be running by killing it?
