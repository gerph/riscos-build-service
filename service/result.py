#!/usr/bin/env python
"""
Storage and communication for the results of a run.
"""

import collections

import roname

Clipboard = collections.namedtuple('Clipboard', 'data,filetype')


class ThrowbackData(object):

    def __init__(self, data):
        """
        Process the JSON data into a more manageable structure
        """
        self.reason = data['reason']
        self.reason_name = data['reason_name']
        self.filename = roname.RISCOSName(ro_filename=data['filename'])
        self.url = data['url']
        self.message = data.get('message')
        self.lineno = data.get('lineno')
        self.severity = data.get('severity')

    def __repr__(self):
        return "<{}({} for {}: {})>".format(self.__class__.__name__,
                                           self.reason_name,
                                           self.filename.ro_filename,
                                           self.message or '<no message>')


class BuildResult(object):

    def __init__(self):
        self.finished = False
        self.messages = []
        self.output = []
        self.clipboard = []
        self.throwback = []
        self.rc = None

    def __repr__(self):
        return "<{}({} messages, {} output chunks, {} throwback)>".format(self.__class__.__name__,
                                                                          len(self.messages),
                                                                          len(self.output),
                                                                          len(self.throwback))

    def output_data(self, data):
        self.output.append(data)

    def output_complete(self):
        self.finished = True

    def throwback_received(self, data):
        self.throwback.append(ThrowbackData(data))

    def clipboard_received(self, data, filetype):
        self.clipboard.append(Clipboard(data, filetype))

    def message(self, message):
        self.messages.append(message)


class BuildResultLines(BuildResult):

    def __init__(self, *args, **kwargs):
        super(BuildResultLines, self).__init__(*args, **kwargs)
        self.output_full = False
        self.output = ['']

    def output_data(self, data):
        if not data:
            return
        if '\n' in data:
            parts = data.split('\n')
            for part in parts[:-1]:
                self.output_data(part)
                self.output[-1] += '\n'
                self.output_full = True
            self.output_data(parts[-1])
        else:
            if self.output_full:
                self.output.append(data)
                self.output_full = False
            else:
                self.output[-1] += data
