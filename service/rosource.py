#!/usr/bin/env python
"""
Extract files from a source package ready for building.

Given a file, extracts any content and determines what RISC OS buildable files are present.

* Takes the file and puts it in a temporary directory.
* If the file is a zip archive, extracts the contents
* Using the rozipinfo to extract RISC OS data from the zip.
"""

import os
import shutil
import tempfile
import zipfile

import roname
from rofiletypes import *
import rozipinfo


try:
    unicode
except NameError:
    # Python 3, make unicode the str type
    unicode = str


# Files with these extensions will be flipped to put the files into subdirectories
translate_extension = ['.c', '.s', '.h', '.c++', '.p']

# Those files that *must* be in a subdirectory to work properly
require_subdirectory = {
        FILETYPE_C: 'c',
        FILETYPE_H: 'h',
        FILETYPE_OBJASM: 's',
        FILETYPE_PASCAL: 'p',
    }

# Files in these directories have a known type
directory_filetype = {
        'c': FILETYPE_C,
        'h': FILETYPE_H,
        's': FILETYPE_OBJASM,
        'cmhg': FILETYPE_CMHG,
        'p': FILETYPE_PASCAL,
    }

# Our temporary directory (so that it's easy to clean up.
tempdir = os.path.join(os.getcwd(), 'tmp')
if not os.path.isdir(tempdir):
    os.mkdir(tempdir)


def touch(fname, times=None):
    with open(fname, 'a'):
        os.utime(fname, times)


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
        self.files = []

    def __repr__(self):
        return "<{}(file={}, filetype={}, #buildables={})>" \
                .format(self.__class__.__name__,
                        self.primary_ro_filename,
                        '&{:03x}'.format(self.primary_filetype) if self.primary_filetype else None,
                        len(self.buildables) if self.buildables is not None else '?')

    def __del__(self):
        if getattr(self, 'dir'):
            if getattr(self, 'shutil'):
                try:
                    self.shutil.rmtree(self.dir)
                except Exception:
                    pass

    def close(self):
        if self.dir and os.path.isdir(self.dir):
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

        if data.startswith(('REM>', 'REM >', '0REM', '10REM')) or \
           (data.startswith('10') and '\nPRINT' in data) or \
           ('\nPRINT' in data and '\nSYS' in data) or \
           ('\nDEF PROC' in data or '\nDEFPROC' in data):
            return FILETYPE_BASTXT

        if unix_filename:
            # The filename will give us some hints if the prefix checks don't tell us what it is
            dirname = os.path.basename(os.path.dirname(unix_filename))
            filetype = directory_filetype.get(dirname)
            if filetype:
                return filetype

            # Let's see if the extension helps?
            (base, ext) = os.path.splitext(unix_filename)
            if base and ext in translate_extension:
                filetype = directory_filetype.get(ext[1:])
                if filetype:
                    return filetype

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
                'program ' in data and ' writeln(' in data,
                data.startswith('program ')]):
            return FILETYPE_PASCAL

        if '\n' in data:
            (firstline, rest) = data.split('\n', 1)
        else:
            firstline = data

        if any([data.startswith('#!') and 'perl' in firstline,
                '\nBEGIN {' in data,]):
            return FILETYPE_PERL

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
                zi = rozipinfo.ZipInfoRISCOS(zipinfo=zi)
                # Force the use of the NFS encoded filenames
                zi.riscos_filename = zi.riscos_filename

                filename = zi.filename

                is_dir = (zi.riscos_objtype == 2)

                # There was no RISC OS extension, so see if we can translate the filename extension
                # into RISC OS format.
                (base, ext) = os.path.splitext(filename)
                if base and ext in translate_extension:
                    # Turns foo.c into c/foo
                    dirname = os.path.dirname(filename)
                    filename = os.path.join(dirname, ext[1:], base)

                # In Python 2 the filename is a unicode if the UTF-8 flag was set, and a str if not.
                # In Python 3 the filename is always a unicode.
                if isinstance(filename, unicode):
                    filename = filename.encode('utf-8')
                absfile = self.absfile(filename)
                if is_dir:
                    if absfile.endswith('/'):
                        absfile = absfile[:-1]
                    if not os.path.isdir(absfile):
                        os.makedirs(absfile)
                else:
                    parent = os.path.dirname(absfile)
                    if not os.path.isdir(parent):
                        os.makedirs(parent)
                    name = roname.RISCOSName(unix_filename=filename)
                    with zh.open(zi) as ifh:
                        with open(absfile, 'wb') as ofh:
                            data = ifh.read()
                            ofh.write(data)

                    filetype = self.guess_filetype(data=data, unix_filename=name.unix_filename)
                    #print("%r is %03x" % (name, filetype))
                    if filetype == FILETYPE_AMU or \
                       name.filetype == FILETYPE_AMU or \
                       os.path.basename(name.unix_filename).upper() == 'MAKEFILE':
                        makefile = name
                    else:
                        if filetype in BUILDABLE_FILETYPES:
                            buildables.append(name)
                        elif name.filetype in BUILDABLE_FILETYPES:
                            buildables.append(name)

                    files.append(name)
                    dt = rozipinfo.tuple_to_datetime(zi.riscos_date_time)
                    epoch_time = rozipinfo.datetime_to_epochtime(dt)
                    touch(absfile, (epoch_time, epoch_time))

        #print(makefile)
        #print(buildables)

        if makefile:
            self.primary_file = makefile
        elif len(buildables) == 1:
            self.primary_file = buildables[0]

        # Touch all the buildable files so that they have a later timestamp than
        # any of the other files - then they should be built by amu.
        for name in buildables:
            filename = os.path.join(self.dir, name.unix_filename)
            if os.path.exists(filename):
                touch(filename)

        self.buildables = buildables
        self.makefile = makefile
        self.files = files

        # FIXME: If there are multiple buildables we might be able to construct a makefile for them.

        return files
