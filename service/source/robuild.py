#!/usr/bin/env python
"""
Decide how to build sources on RISC OS.

Uses the RISCOSSource information to decide how the source should be built within RISC OS.

* Each builder will determine whether it can build using the RISCOSSource supplied.
* ROBuild YAML will be parsed through the ROBuildYAML parser.
* Makefiles will be parsed by the makefile module.
"""

import io
import os
import traceback
import zipfile

from rofiletypes import *

import makefile
import robuildyaml
from roname import RISCOSName
import rozipinfo


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
        """
        Recogniser for this builder type.

        @return:    True if the self.source is recognised (use self.source.primary_file for single files)
                    False if this builder cannot handle the content.
        """
        return False

    def messages(self):
        """
        Messages to report from the builder processes on recognition of the type.

        @return:    list of strings to report
        """
        return []

    def configs(self):
        """
        Additional Pyromaniac configurations to add if recognised.

        @return:    list of tuples of (config, value)
        """
        return []

    def commands(self):
        """
        Commands to execute if recognised.

        @return:    list of RISC OS commands
        """
        raise NotImplementedError("{}.commands is not implemented".format(self.__class__.__name__))

    def collect_artifact(self):
        """
        Collect any artifacts from the output.

        @return:    tuple of (data, filetype), or (None, None) if no data present
        """
        return (None, None)

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
    config_ro_filename = [
            '/robuild/yaml',
            '/robuild/yml',
            '/robuild',
        ]
    roby = None

    def commands(self):
        # We can only have one file with this name
        roname = [roname for roname in self.source.files if roname.ro_filename in self.config_ro_filename][0]
        config_filename = os.path.join(self.source.dir, roname.unix_filename)

        roby = robuildyaml.ROBuildYAML(config_filename)

        self.roby = roby

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

    def collect_artifact(self):
        artifacts = self.roby.jobs[0].artifacts
        if not artifacts:
            return (None, None)

        ro_filename = artifacts[0].path
        roname = RISCOSName(ro_filename)
        # FIXME: We only support zipping the contents of a directory at present
        ofh = io.BytesIO()
        artifact_dir = os.path.join(self.source.dir, roname.unix_filename)

        with zipfile.ZipFile(ofh, 'w', compression=zipfile.ZIP_DEFLATED) as zh:
            for path, dirname, filenames in os.walk(artifact_dir):
                p = os.path.relpath(path, artifact_dir) + '/'
                if p.startswith('./'):
                    p = p[2:]

                for d in dirname:
                    fn = '{}{}/'.format(p, d)
                    dfn = os.path.join(path, d)
                    zi = rozipinfo.ZipInfoRISCOS.from_file(filename=dfn, arcname=fn)
                    zi.nfs_encoding = False
                    zh.writestr(zi, b'')
                    #print("Add dir: %s%s/" % (p, d))

                for f in filenames:
                    fn = '{}{}'.format(p, f)
                    dfn = os.path.join(path, f)
                    zi = rozipinfo.ZipInfoRISCOS.from_file(filename=dfn, arcname=fn)
                    zi.nfs_encoding = False
                    with open(dfn) as fh:
                        zh.writestr(zi, fh.read(), compress_type=zipfile.ZIP_DEFLATED)
                    #print("Add file: %s%s" % (p, f))

        return (ofh.getvalue(), FILETYPE_ZIP)


class ROBuilderSingleFile(ROBuilderBase):
    tool_filetype = None
    tool_filetypes = ()

    def recognise(self):
        if len(self.source.buildables) != 1:
            return False
        if self.tool_filetype and \
           self.source.primary_file.filetype == self.tool_filetype:
            return True
        if self.tool_filetypes and \
           self.source.primary_file.filetype in self.tool_filetypes:
            return True
        return False


@register_builder
class ROBuilderUtility(ROBuilderSingleFile):
    tool_name = 'Utility'
    tool_command = 'Run'
    tool_filetypes = (FILETYPE_UTILITY32, FILETYPE_UTILITY64)
    default_options = {}

    def messages(self):
        if self.source.primary_file.filetype == FILETYPE_UTILITY64:
            return ["Requires RISC OS AArch64"]
        return []

    def configs(self):
        if self.source.primary_file.filetype == FILETYPE_UTILITY64:
            return [
                    ('emulation.implementation', 'aarch64'),
                ]
        return []

    def commands(self):
        args = [self.tool_command, self.ro_filename]
        return [' '.join(args)]


@register_builder
class ROBuilderAbsolute(ROBuilderSingleFile):
    tool_name = 'Absolute'
    tool_command = 'Run'
    tool_filetypes = (FILETYPE_ABSOLUTE32, FILETYPE_ABSOLUTE64)
    default_options = {}

    def messages(self):
        if self.source.primary_file.filetype == FILETYPE_ABSOLUTE64:
            return ["Requires RISC OS AArch64"]
        return []

    def configs(self):
        if self.source.primary_file.filetype == FILETYPE_ABSOLUTE64:
            return [
                    ('emulation.implementation', 'aarch64'),
                ]
        return []

    def commands(self):
        args = [self.tool_command, self.ro_filename]
        return [' '.join(args)]


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

        # Always build in 32bit mode
        args.extend(['-apcs', '3/32'])
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
    mf = None

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

            self.mf = mf

        except Exception as exc:
            traceback.print_exc()
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

    def collect_artifact(self):
        if not self.mf:
            return (None, None)

        linkables = self.mf.linkables()
        if not linkables:
            return (None, None)

        if self.ro_dirname != '@':
            linkables = ["{}.{}".format(self.ro_dirname, linkable) for linkable in linkables]

        #print("Linkables: %r" % (linkables,))

        # We just archive the files that exist in as linkables in the target - ie anything
        # we guessed is a target. But only if it exists.
        ofh = io.BytesIO()
        artifact_dir = self.source.dir

        dirscreated = set([])
        nfiles = 0

        with zipfile.ZipFile(ofh, 'w', compression=zipfile.ZIP_DEFLATED) as zh:
            for ro_filename in linkables:
                roname = RISCOSName(ro_filename)
                local_filename = os.path.join(self.source.dir, roname.unix_filename)

            for path, dirname, filenames in os.walk(artifact_dir):
                p = os.path.relpath(path, artifact_dir) + '/'
                if p.startswith('./'):
                    p = p[2:]

                for f in filenames:
                    fn = '{}{}'.format(p, f)
                    roname = RISCOSName(unix_filename=fn)
                    #print("File: %s / %s / %s" % (fn, roname, roname.ro_filename))

                    if roname.ro_filename in linkables:
                        # We wanted this file archiving.
                        #print("Want to archive %s / %s" % (fn, roname))

                        # We want to archive this file, BUT to do so we need to ensure that all
                        # the directories above it exist.
                        dir_parts = roname.ro_filename.split('.')
                        for nparts in range(1, len(dir_parts)):
                            rodirname = '.'.join(dir_parts[:nparts])
                            if rodirname not in dirscreated:
                                rodir = RISCOSName(ro_filename=rodirname)
                                # FIXME: Bit of a hack here to remove the ,ffd that gets appended
                                unixdirname = rodir.unix_filename[:-4]
                                unixdir = os.path.join(self.source.dir, unixdirname)
                                zi = rozipinfo.ZipInfoRISCOS.from_file(filename=unixdir, arcname=unixdirname)
                                zi.nfs_encoding = False
                                zh.writestr(zi, b'')
                                #print("Add dir: %s" % (unixdirname,))
                                dirscreated.add(rodirname)

                        dfn = os.path.join(path, f)
                        zi = rozipinfo.ZipInfoRISCOS.from_file(filename=dfn, arcname=fn)
                        zi.nfs_encoding = False
                        with open(dfn) as fh:
                            zh.writestr(zi, fh.read(), compress_type=zipfile.ZIP_DEFLATED)
                        #print("Add file: %s%s" % (p, f))
                        nfiles += 1

        if not nfiles:
            return (None, None)
        return (ofh.getvalue(), FILETYPE_ZIP)


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
