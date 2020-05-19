#!/usr/bin/env python
"""
Decide how to build sources on RISC OS.

Uses the RISCOSSource information to decide how the source should be built within RISC OS.

* Each builder will determine whether it can build using the RISCOSSource supplied.
* ROBuild YAML will be parsed through the ROBuildYAML parser.
* Makefiles will be parsed by the makefile module.
"""

import os

from rofiletypes import *

import makefile
import robuildyaml


builder_classes = []
def register_builder(cls):
    builder_classes.append(cls)
    return cls


class ROBuilderBase(object):
    tool_name = None
    tool_command = None

    def __init__(self, source, options=None):
        self.source = source
        self.options = options or {}

    def __repr__(self):
        return "<{}({})>".format(self.__class__.__name__, self.source)

    def recognise(self):
        return False

    def commands(self):
        raise NotImplementedError("{}.commands is not implemented".format(self.__class__.__name__))

    @property
    def ro_filename(self):
        return self.source.primary_file.ro_filename

    @property
    def ro_leafname(self):
        return self.source.primary_file.ro_leafname

    @property
    def ro_dirname(self):
        return self.source.primary_file.ro_dirname


@register_builder
class ROBuilderYAML(ROBuilderBase):
    tool_name = 'ROBuild YAML'
    config_ro_filename = ['/robuild/yaml',
                          '/robuild/yml',
                          '/robuild']

    def commands(self):
        # We can only have one file with this name
        roname = [roname for roname in self.source.files if roname.ro_filename in self.config_ro_filename][0]
        config_filename = os.path.join(self.source.dir, roname.unix_filename)

        roby = robuildyaml.ROBuildYAML(config_filename)

        # Now build the commands!
        job = roby.jobs[0]

        commands = []
        for key, value in sorted(job.env.items()):
            commands.append('Set {} {}'.format(key, str(value)))

        if job.working_directory:
            commands.append('Dir {}'.format(job.working_directory))

        for cmd in job.script:
            commands.append(cmd)

        return commands

    def recognise(self):
        return [roname for roname in self.source.files if roname.ro_filename in self.config_ro_filename]


class ROBuilderSingleFile(ROBuilderBase):
    tool_filetype = None

    def recognise(self):
        if len(self.source.buildables) != 1:
            return False
        if self.source.primary_file.filetype == self.tool_filetype:
            return True
        return False


@register_builder
class ROBuilderJFPatch(ROBuilderSingleFile):
    tool_name = 'JFPatch'
    tool_command = '/jfpatch'
    tool_filetype = FILETYPE_JFPATCH
    default_options = {
            'throwback': True,
            'show_warnings': True,
        }

    def commands(self):
        args = ['{}'.format(self.tool_command)]

        if self.options.get('throwback', True):
            args.append('-throwback')
        if self.options.get('show_warnings', True):
            args.append('-warnings')
        args.append('-clipboard')

        args.extend(['-in', self.ro_filename])

        return [' '.join(args)]


@register_builder
class ROBuilderBASIC(ROBuilderSingleFile):
    tool_name = 'BASIC'
    tool_command = 'BASIC'
    tool_filetype = FILETYPE_BASIC

    def commands(self):
        args = ['{}'.format(self.tool_command)]

        args.append('-quit')
        args.append(self.ro_filename)

        return [' '.join(args)]


@register_builder
class ROBuilderBASTXT(ROBuilderBASIC):
    tool_name = 'BASIC Text'
    tool_command = 'BASIC'
    tool_filetype = FILETYPE_BASTXT


@register_builder
class ROBuilderPerl(ROBuilderSingleFile):
    tool_name = 'Perl'
    tool_command = 'Perl'
    tool_filetype = FILETYPE_PERL

    def commands(self):
        args = ['{}'.format(self.tool_command)]

        args.append(self.ro_filename)

        return [' '.join(args)]


@register_builder
class ROBuilderC(ROBuilderSingleFile):
    tool_name = 'Norcroft C'
    tool_command = 'CC'
    tool_filetype = FILETYPE_C

    def commands(self):
        args = ['{}'.format(self.tool_command)]

        args.append('-throwback')
        args.append('-apcs 3/32')
        args.append('-DBUILD32=1')
        args.append('-l C:o.stubsG')
        args.append('-IC:')
        args.append(self.ro_filename)

        return ['cdir o',
                ' '.join(args),
                'If "<Sys$ReturnCode>" <> 0 Then Error Compilation failed',
                'Clipboard_FromFile {}'.format(self.ro_leafname)]


@register_builder
class ROBuilderPascal(ROBuilderSingleFile):
    tool_name = 'P2C + Norcroft C'
    tool_command = 'P2CC'
    tool_filetype = FILETYPE_PASCAL

    def commands(self):
        args = ['{}'.format(self.tool_command)]

        args.append('-throwback')
        args.append('-apcs 3/32')
        args.append('-DBUILD32=1')
        args.append('-IC:')
        #args.append('-l C:o.stubsG')
        args.append(self.ro_filename)

        return ['cdir o',
                ' '.join(args),
                'If "<Sys$ReturnCode>" <> 0 Then Error Compilation failed',
                'Clipboard_FromFile !RunImage']


@register_builder
class ROBuilderMakefile(ROBuilderBase):
    tool_name = 'AMU'
    tool_command = 'AMU'

    def commands(self):
        args = ['{}'.format(self.tool_command)]

        args.append('-f')
        args.append(self.ro_leafname)
        args.append('BUILD32=1')

        cmds = ['dir {}'.format(self.ro_dirname)]

        needed_directories = set([])
        try:
            # Process the makefile to try to guess what we need
            mf_filename = os.path.join(self.source.dir, self.source.makefile.unix_filename)
            mf = makefile.read_makefile(mf_filename)

            for target, command in mf.target_commands():
                if '/' not in target and '.' in target:
                    target_dir, _name = target.rsplit('.', 1)
                    needed_directories |= set([target_dir])

        except Exception as exc:
            print("Failed to read Makefile: {}".format(exc))

            # Simple processing, looking at what buildables we have
            need_odirectory = False
            for f in self.source.buildables:
                if f.filetype in AOF_GENERATING:
                    need_odirectory = True

            if need_odirectory:
                needed_directories |= set(['o'])

        cmds.extend('cdir {}'.format(name) for name in needed_directories)

        cmds.append(' '.join(args))
        return cmds

    def recognise(self):
        return bool(self.source.makefile)


class ROBuilderError(Exception):
    pass


def ROBuilder(source, options=None):
    """
    Select a ROBuilder class based on the supplied source.
    """

    #print("Finding ROBuilder for %r" % (source,))
    for cls in builder_classes:
        #print("Checking ROBuilder %r" % (cls,))
        obj = cls(source, options)
        if obj.recognise():
            return obj

    raise ROBuilderError("Unrecognised source content: {!r}".format(source))
