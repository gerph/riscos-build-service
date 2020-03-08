#!/usr/bin/env python
"""
RISC OS/Unix filename convention conversions.
"""

import os
import shutil
import struct
import tempfile
import zipfile

import roname
from rofiletypes import *


translate_extension = ['.c', '.s', '.h', '.c++', '.p']
require_subdirectory = {
        FILETYPE_C: 'c',
        FILETYPE_H: 'h',
        FILETYPE_OBJASM: 's',
        FILETYPE_PASCAL: 'p',
    }


# Our temporary directory (so that it's easy to clean up.
tempdir = os.path.join(os.getcwd(), 'tmp')
if not os.path.isdir(tempdir):
    os.mkdir(tempdir)


class RISCOSSource(object):
    dir = None

    def __init__(self, source):
        self.source = source
        self.dir = tempfile.mkdtemp(prefix='robuild', dir=tempdir)
        self.source_file = os.path.join(self.dir, '_source_')
        with open(self.source_file, 'wb') as fh:
            fh.write(self.source)
        self.primary_file = roname.RISCOSName()
        self.content = None
        self.shutil = shutil

        # Discovered items
        self.buildables = None
        self.makefile = None

    def __repr__(self):
        return "<{}(file={}, filetype={}, #buildables={})>" \
                .format(self.__class__.__name__,
                        self.primary_ro_filename,
                        '&{:03x}'.format(self.primary_filetype) if self.primary_filetype else None,
                        len(self.buildables) if self.buildables is not None else '?')

    def __del__(self):
        if getattr(self, 'dir'):
            if getattr(self, 'shutil'):
                self.shutil.rmtree(self.dir)

    def make_filename(self, path, filetype=None):
        name = path
        if filetype:
            name = 'path,%03x' % (filetype & 0xFFF,)
        return os.path.join(self.dir, name)

    def absfile(self, filename):
        return os.path.join(self.dir, filename)

    @property
    def primary_absfile(self):
        if not self.primary_file:
            return None

        return self.absfile(self.primary_file.unix_filename)

    @property
    def primary_ro_filename(self):
        if not self.primary_file:
            return None

        return self.primary_file.ro_filename

    @property
    def primary_unix_filename(self):
        if not self.primary_file:
            return None

        return self.primary_file.unix_filename

    @property
    def primary_filetype(self):
        return self.primary_file.filetype

    def guess_filetype(self, filename=None, data=None, unix_filename=None):
        """
        Identify the filetype of a given file.
        """
        if filename:
            with open(filename, 'rb') as fh:
                data = fh.read()
        if not unix_filename:
            unix_filename = filename

        if data.startswith(b'\x0d\x00') and data.endswith(b'\x0d\xff'):
            return FILETYPE_BASIC

        if data.startswith(b'\xc5\xc6\xcb\xc3'):
            return FILETYPE_AOF

        if data[0:3].upper() == 'IN ':
            return FILETYPE_JFPATCH

        if unix_filename:
            # The filename will give us some hints if the prefix checks don't tell us what it is
            dirname = os.path.basename(os.path.dirname(unix_filename))
            if dirname == 'c':
                return FILETYPE_C
            if dirname == 'h':
                return FILETYPE_H
            if dirname == 's':
                return FILETYPE_OBJASM
            if dirname == 'cmhg':
                return FILETYPE_CMHG
            if dirname == 'p':
                return FILETYPE_PASCAL

        if any(['void *' in data,
                'int main' in data,
                '#include <' in data]):
            return FILETYPE_C

        if any([' AREA ' in data,
                ' MOV ' in data,
                ' BL ' in data]):
            return FILETYPE_OBJASM

        if any(['$(CFLAGS)' in data,
                '${CFLAGS}' in data,
                '\n.INIT:' in data,
                '\n.PHONY:' in data,
                '\n.c.o: ' in data,
                '\n# Dynamic dependencies' in data]):
            return FILETYPE_AMU

        if any(['\ntitle-string:' in data]):
            return FILETYPE_CMHG

        if any(['\nbegin' in data and '\nend.' in data,
                'program ' in data and ' writeln(' in data]):
            return FILETYPE_PASCAL

        # FIXME: Recognise perl?
        # FIXME: Recognise Obey?

        return FILETYPE_DATA

    def extract(self):
        """
        Extract the files into the directory and return a list of the names.
        """
        if self.content:
            return self.content

        if zipfile.is_zipfile(self.source_file):
            self.content = self.extract_zipfile()
            return self.content

        # Work out what kind of source file it is.
        filetype = self.guess_filetype(data=self.source)
        #print("Guessing filetype gave : &%03x" % (filetype,))
        self.primary_file = roname.RISCOSName(ro_filename='source', filetype=filetype)
        if require_subdirectory.get(filetype):
            subdir = require_subdirectory.get(filetype)
            cdir = os.path.join(self.dir, subdir)
            os.mkdir(cdir)
            self.primary_file.ro_filename = '{}.source'.format(subdir)
        #print("primary_file: %s" % (self.primary_file,))
        #print("primary_file abs: %s" % (self.primary_absfile,))
        shutil.copyfile(self.source_file, self.primary_absfile)

        self.content = [self.primary_file]
        self.buildables = []
        if filetype in BUILDABLE_FILETYPES:
            self.buildables.append(self.primary_file)
        return self.content

    def extract_zipfile(self):
        """
        Extract a zip, with the RISC OS types if appropriate.
        """
        makefile = None
        buildables = []

        files = []
        with zipfile.ZipFile(self.source_file, 'r') as zh:
            infolist = zh.infolist()
            #zh.printdir()
            for zi in infolist:
                filename = zi.filename

                # FIXME: Might be wrong - appnote says that it only applies to MSDOS
                is_dir = (zi.external_attr & 1) or filename.endswith('/')
                #print("%s : ext %x int %x" % (filename, zi.external_attr, zi.internal_attr))

                # Filename is always in unix format, but may be missing the filetype if a RISC OS
                # extension is present.
                ro_extension = False
                if zi.extra and not is_dir:
                    # I'm lazy and will only process a single extra field.
                    if zi.extra.startswith('AC'):
                        acorn_block = zi.extra[4:]
                        if acorn_block[:4] == 'ARC0':
                            # It's a Spark block
                            ro_extension = True
                            word = struct.unpack('<I', acorn_block[4:8])
                            if word & 0xFFF00000 == 0xFFF00000:
                                filetype = (word>>8) & 0xFFF
                                filename += ',%03x' % (filetype,)

                if not ro_extension:
                    # There was no RISC OS extension, so see if we can translate the filename extension
                    # into RISC OS format.
                    (base, ext) = os.path.splitext(filename)
                    if base and ext in translate_extension:
                        # Turns foo.c into c/foo
                        dirname = os.path.dirname(filename)
                        filename = os.path.join(dirname, ext[1:], base)

                absfile = self.absfile(filename)
                if is_dir:
                    if absfile.endswith('/'):
                        absfile = absfile[:-1]
                    if not os.path.isdir(absfile):
                        os.makedirs(absfile)
                else:
                    name = roname.RISCOSName(unix_filename=filename)
                    with zh.open(zi.filename) as ifh:
                        with open(absfile, 'wb') as ofh:
                            data = ifh.read()
                            ofh.write(data)

                    filetype = self.guess_filetype(data=data, unix_filename=name.unix_filename)
                    #print("%r is %03x" % (name, filetype))
                    if filetype == FILETYPE_AMU or name.filetype == FILETYPE_AMU or os.path.basename(name.unix_filename).upper() == 'MAKEFILE':
                        makefile = name
                    else:
                        if filetype in BUILDABLE_FILETYPES:
                            buildables.append((name, filetype))
                        elif name.filetype in BUILDABLE_FILETYPES:
                            buildables.append((name, filetype))

                    files.append(name)

        #print(makefile)
        #print(buildables)

        if makefile:
            self.primary_file = makefile
        elif len(buildables) == 1:
            self.primary_file = buildables[0]

        self.buildables = buildables
        self.makefile = makefile

        # FIXME: If there are multiple buildables we might be able to construct a makefile for them.

        return files
