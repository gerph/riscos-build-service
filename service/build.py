#!/usr/bin/env python
"""
Invoke a RISC OS build on a given file.
"""

import docker
from rosource import RISCOSSource
import pyroserver
import robuild


pyro = pyroserver.PyroNativeServer()
pyro.add_config_file('jfpatch.pyro')

sourcefile = '../example/djf-source,13c'
#sourcefile = '../example/pt-backup.zip'
#sourcefile = '../example/demo.c'
#sourcefile = '../example/phelloworld'
with open(sourcefile, 'rb') as fh:
    data = fh.read()
s = RISCOSSource(data)
s.extract()

builder = robuild.Builder(s)
print("Build tool selected: {}".format(builder.tool_name))
#pyro.add_command('gos')

for command in builder.commands():
    pyro.add_command(command)
pyro.add_debug('cli')
#pyro.add_debug('traceswiargs')

pyro.start_server()
d = docker.DockerStreamed('gerph/jfpatch', hostname='jfpatch', command=pyro.command(), workdir='/home/riscos')
d.bind(s.dir, '/home/riscos/fs/work/')
