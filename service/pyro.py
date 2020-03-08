#!/usr/bin/env python
"""
Interface to the Pyromaniac system.
"""


class Pyro(object):
    """
    Configuration for the Pyromaniac system.
    """

    def __init__(self):
        self.configs = {}
        self.config_files = []
        self.debugs = set([])
        self.modules = []
        self.commands = []
        self.enter_module = None
        self.internal_modules = True
        self.timeout = None

    def __repr__(self):
        params = []

        return "<{}({})>".format(self.__class__.__name__,
                                 ','.join(params))

    def add_config_file(self, config_file):
        self.config_files.append(config_file)

    def set_config(self, var, value):
        if isinstance(value, bool):
            value = 'yes' if value else 'no'
        self.configs[var] = str(value)

    def add_module(self, module):
        self.modules.append(module)

    def add_command(self, command):
        self.commands.append(command)

    def add_debug(self, flag):
        self.debugs.add(flag)

    def command(self):
        args = []
        if self.timeout:
            args.extend(['timeout', str(self.timeout)])
        args.append('pyro')

        # Configuration
        for config_file in self.config_files:
            args.extend(['--config-file', config_file])
        for config, value in sorted(self.configs.items()):
            args.extend(['--config', '{}={}'.format(config, value)])

        # Modules
        if self.internal_modules:
            args.append('--load-internal-modules')
        for module in self.modules:
            args.extend(['--load-module', module])

        # Debug
        if self.debugs:
            args.extend(['--debug', ','.join(self.debugs)])

        # Execution
        for command in self.commands:
            args.extend(['--command', command])

        if self.enter_module:
            args.extend(['--enter-module', self.enter_module])

        return args
