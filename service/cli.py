#!/usr/bin/env python
"""
CLI tool for building.
"""

import argparse
import os
import sys

import build


def setup_parser():
    parser = argparse.ArgumentParser(usage="%s [<options>]" % (os.path.basename(sys.argv[0]),))
    parser.add_argument('--source', type=str,
                        help="Show the special exit codes used")

    return parser


parser = setup_parser()
options = parser.parse_args()

#sourcefile = '../example/djf-source,13c'
#sourcefile = '../example/pt-backup.zip'
#sourcefile = '../example/demo.c'
sourcefile = '../example/phelloworld'
sourcefile = '../example/bad-pascal.p'


builder = build.Builder(options.source)
builder.load()
builder.prepare_builder()
builder.prepare_pyro()
#pyro.add_command('gos')
#pyro.add_debug('cli')
#pyro.add_debug('traceswiargs')
builder.prepare_docker()
rc = builder.run()

result = builder.result
print("Output:")
output = ''.join(result.output).rstrip('\r\n').split('\n')
for line in output:
    print("  {}".format(line))
print("")

if result.clipboard:
    print("Output:")
    for clip in result.clipboard:
        print("  Filetype:    {:03x}".format(clip.filetype))
        print("  Size:        {} bytes".format(len(clip.data)))
        print("")
else:
    print("No output created")
    print("")

if result.throwback:
    print("Throwback:")
    for tb in result.throwback:
        print("  Reason:    {}".format(tb.reason_name))
        print("  File:      {}".format(tb.filename.ro_filename))
        if tb.reason != 0:
            print("  Severity:  {}".format(tb.severity))
            print("  Line:      {}".format(tb.lineno))
            print("  Message:   {}".format(tb.message))
        print("")
