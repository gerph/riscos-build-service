#!/usr/bin/env python
"""
RISC OS/Unix filename convention conversions.
"""

import re
import string

from rofiletypes import FILETYPE_DEFAULT


native_filetype_re = re.compile(',([0-9a-f]{3})$')


class RISCOSName(object):
    """
    An class to hold either the Unix or the RISCOS filename.
    """
    trans_table = string.maketrans('./', '/.')

    def __init__(self, unix_filename=None, ro_filename=None, filetype=None):
        self._unix_filename = None
        self._ro_filename = None
        self._filetype = None

        if unix_filename:
            self.unix_filename = unix_filename
        if ro_filename:
            self.ro_filename = ro_filename
        if filetype:
            self.filetype = filetype

    def __bool__(self):
        return self._unix_filename is None and self._ro_filename is None

    def __hash__(self):
        return hash((self._unix_filename, self._ro_filename, self._filetype))

    def __eq__(self, other):
        if isinstance(other, RISCOSName):
            return self.unix_filename == other.unix_filename
        return NotImplemented

    def __repr__(self):
        if self._unix_filename:
            return "<{}(unix_filename={!r})>".format(self.__class__.__name__,
                                                     self._unix_filename)
        if self._ro_filename:
            return "<{}(ro_filename={!r}, filetype={})>".format(self.__class__.__name__,
                                                                self._ro_filename,
                                                                '&{:03x}'.format(self._filetype) if self._filetype else None)
        if self._filetype:
            return "<{}(filetype=&{:03x})>".format(self.__class__.__name__,
                                                   self._unix_filename)

        return "<{}()>".format(self.__class__.__name__)

    @property
    def ro_filename(self):
        if self._ro_filename:
            return self._ro_filename
        if not self._unix_filename:
            return None

        name = self._unix_filename
        match = native_filetype_re.search(name)
        if match:
            name = name[:-4]
        return name.translate(self.trans_table)

    @ro_filename.setter
    def ro_filename(self, value):
        self._unix_filename = None
        self._ro_filename = value

    @property
    def unix_filename(self):
        if self._unix_filename:
            return self._unix_filename
        if not self._ro_filename:
            return None

        suffix = ''
        if self.filetype is not None:
            suffix = ',%03x' % (self.filetype & 0xFFF,)

        name = self._ro_filename.translate(self.trans_table)
        return name + suffix

    @unix_filename.setter
    def unix_filename(self, value):
        self._unix_filename = value
        self._ro_filename = None

    @property
    def filetype(self):
        if self._filetype is not None:
            return self._filetype

        if self._ro_filename:
            # The RISC OS name is set, so we don't have a filetype
            return FILETYPE_DEFAULT
        if not self._unix_filename:
            return FILETYPE_DEFAULT

        # We must have a unix filename, so see if we can extract an extension.
        name = self._unix_filename
        match = native_filetype_re.search(name)
        if match:
            filetype = int(name[-3:], 16)
            return filetype

        return FILETYPE_DEFAULT

    @filetype.setter
    def filetype(self, value):
        # Assert that the RISC OS name is the canonical one, so that the unix name is generated
        self.ro_filename = self.ro_filename
        self._filetype = value

    @property
    def ro_dirname(self):
        """
        The directory for the RISC OS file.
        """
        # FIXME: Handle ^. sequences?
        if '.' in self.ro_filename:
            (dirname, leafname) = self.ro_filename.rsplit('.', 1)
        elif ':' in self.ro_filename:
            (dirname, leafname) = self.ro_filename.rsplit(':', 1)
            dirname += ':'
        elif self.ro_filename in ('$', '@', '%', '\\'):
            # These should not happen with the extracted zip files
            dirname = self.ro_filename
        else:
            dirname = '@'
        return dirname

    @property
    def ro_leafname(self):
        """
        The directory for the RISC OS file.
        """
        # FIXME: Handle ^. sequences?
        if '.' in self.ro_filename:
            (dirname, leafname) = self.ro_filename.rsplit('.', 1)
        elif ':' in self.ro_filename:
            (dirname, leafname) = self.ro_filename.rsplit(':', 1)
        elif self.ro_filename in ('$', '@', '%', '\\'):
            # These should not happen with the extracted zip files
            leafname = self.ro_filename
        else:
            leafname = '@'
        return leafname
