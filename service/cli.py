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
                        help="Source file to build")
    parser.add_argument('--debug', type=str, default='',
                        help="Add debug options to the execution")

    return parser


parser = setup_parser()
options = parser.parse_args()

try:
    builder = build.Builder(options.source)
    builder.load()
    builder.prepare_builder()
    builder.prepare_pyro()
    #pyro.add_command('gos')

    if options.debug:
        for debug in options.debug.split(','):
            builder.pyro.add_debug(debug)

    builder.prepare_docker()
    rc = builder.run()

    result = builder.result
    print("Output:")
    output = ''.join(result.output).rstrip('\r\n').split('\n')
    for line in output:
        print("  {}".format(line))
    print("")

    print("Builder messages:")
    for line in result.messages:
        print("  {}".format(line))
    print("")

    if result.clipboard:
        print("Generated file:")
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
finally:
    builder.close()
