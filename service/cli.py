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
    parser.add_argument('--stream', action='store_true',
                        help="Use the streaming interface")

    return parser


def show_throwback(tb, indent=''):
    print("{}Reason:    {}".format(indent, tb.reason_name))
    print("{}File:      {}".format(indent, tb.filename.ro_filename))
    if tb.reason != 0:
        print("{}Severity:  {}".format(indent, tb.severity_name))
        print("{}Line:      {}".format(indent, tb.lineno))
        print("{}Message:   {}".format(indent, tb.message.rstrip()))


def show_clipboard(clipboard, indent=''):
    print("{}Filetype:    {:03x}".format(indent, clip.filetype))
    print("{}Size:        {} bytes".format(indent, len(clip.data)))


def stream_callback(code, data):
    print("%s: %r" % (code, data))


parser = setup_parser()
options = parser.parse_args()

builder = None
try:
    if options.stream:
        builder = build.BuilderStream(options.source, callback_function=stream_callback)
    else:
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

    if not options.stream:
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
                show_clipboard(clip, indent='  ')
                print("")
        else:
            print("No output created")
            print("")

        if result.throwback:
            print("Throwback:")
            for tb in result.throwback:
                show_throwback(tb, indent='  ')
                print("")
finally:
    if builder:
        builder.close()
