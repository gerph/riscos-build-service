#!/usr/bin/env python
"""
Rudimentary makefile parser.

The parser is only really intended to be able to extract enough information
to know what the targets are, and what we might be able to build. It's probably
actually able to perform more AMU build functions if we extended it a little
bit - it's not especially clever at the moment, and largely takes the easy way
out on many things.

Things that don't work / are missing for interpretation of the files:

  * Variable priorities
  * Variable assignment types (?= / := / +=)
  * Many of the functions (only patsubst is supported)
  * .INIT/.FINAL
  * .PHONY

Things that would be needed if you were actually implementing a make utility:
  * File newness checking
  * Execution of commands
"""

import re


functions = {}
def register_function(func):
    name = func.__name__
    if name.startswith('func_'):
        name = name[5:]
    functions[name] = func
    return func


@register_function
def func_patsubst(makefile, params):
    """
    Pattern substitution, with '%' character as a wildcard.
    """
    match_str = params[0]
    replace_str = params[1]
    string = params[2]

    match_re = re.compile(re.escape(match_str).replace(r'\%', '(.*)'))

    # the string input is split into words for processing
    accumulator = []
    for word in string.split():
        match = match_re.search(word)
        if match:
            word = replace_str.replace('%', match.group(1))
        accumulator.append(word)

    return ' '.join(accumulator)


class CommandAccumulator(object):
    command_re = re.compile(r'\s+(.*)$')

    def __init__(self, commands):
        self.commands = commands or []

    def match_command(self, line):
        match = self.command_re.match(line)
        if match:
            self.add_command(match.group(1))
            return True
        return False

    def add_command(self, command):
        if not command.strip():
            # Empty commands can be ignored
            return
        self.commands.append(command)


class SuffixRule(CommandAccumulator):
    match_re = re.compile(r'^\.([a-zA-Z0-9\+_-]+).([a-zA-Z0-9\+_-]+):\s*$')

    def __init__(self, ext_from, ext_to, commands=None):
        super(SuffixRule, self).__init__(commands)
        self.ext_from = ext_from
        self.ext_to = ext_to

    def __repr__(self):
        return "<{}(from {} to {}: {} commands)>".format(self.__class__.__name__,
                                                         self.ext_from,
                                                         self.ext_to,
                                                         len(self.commands))

    def key(self):
        return (self.ext_from, self.ext_to)

    @classmethod
    def parse(cls, line):
        match = cls.match_re.match(line)
        if match:
            ext_from = match.group(1)
            ext_to = match.group(2)
            obj = cls(ext_from, ext_to)
            return obj
        return None

    def add_command(self, command):
        self.commands.append(command)


class Target(CommandAccumulator):
    match_re = re.compile(r'([^\s:\.]+[^\s:]*):(?!=)\s*(.*)$')
    depsplit_re = re.compile(r'\s+')

    def __init__(self, target, dependencies, commands=None):
        super(Target, self).__init__(commands)
        self.target = target
        self.dependencies = dependencies
        self.commands = commands or []
        self.variables = {
                '@': self.target,
                '<': self.dependencies[0] if self.dependencies else '',
                '?': ' '.join(self.dependencies),
            }

    def __repr__(self):
        return "<{}({}: {} dependencies, {} commands)>".format(self.__class__.__name__,
                                                               self.target,
                                                               len(self.dependencies),
                                                               len(self.commands))

    @classmethod
    def parse(cls, line):
        match = cls.match_re.match(line)
        if match:
            target = match.group(1)
            dependency_string = match.group(2)
            dependencies = cls.depsplit_re.split(dependency_string)
            # Remove any empty strings
            dependencies = [dep for dep in dependencies if dep]
            obj = cls(target, dependencies)
            return obj
        return None

    def merge(self, other):
        self.dependencies.extend(other.dependencies)
        self.commands.extend(other.commands)
        return self


class SpecialTarget(Target):
    match_re = re.compile(r'(\.[A-Z_]+):(?!=)\s*(.*)$')


class ImplicitTarget(object):
    """
    A rule created from a suffix rule for a specific case.
    """
    def __init__(self, target, dependency, suffix_rule, target_rule):
        self.target_rule = target_rule
        self.suffix_rule = suffix_rule
        self.target = target
        self.dependency = dependency

        stem = '?stem?'
        if target.endswith('.' + suffix_rule.ext_to):
            stem = target[:-(len(suffix_rule.ext_to) + 1)]
        elif target.startswith(suffix_rule.ext_to):
            stem = target[len(suffix_rule.ext_to) + 1:]

        # Variables for this target
        self.variables = {
                '@': self.target,
                '%': '<$$% not supported>',
                '<': self.dependency,

                # $? is meant to be just those that are newer; not supported here
                '?': ' '.join(self.dependencies),
                '^': '<$$^ not supported>',
                '+': '<$$+ not supported>',
                '|': '<$$| not supported>',
                '*': stem,
            }

    def __repr__(self):
        return "<{}({}: using rule {}, {} dependencies)>" \
               .format(self.__class__.__name__,
                       self.target,
                       self.suffix_rule,
                       0 if not self.target_rule else len(self.target_rule.dependencies))

    @property
    def dependencies(self):
        return self.target_rule.dependencies + [self.dependency]

    @property
    def commands(self):
        return self.suffix_rule.commands


class Variable(object):
    match_re = re.compile(r'^\s*([A-Za-z_][A-Za-z_0-9]*)\s*(:=|\?=|\+=|=)\s*(.*)$')

    def __init__(self, variable, value):
        self.variable = variable
        self.value = value

    def __repr__(self):
        return "<{}({}: {})>".format(self.__class__.__name__,
                                     self.variable,
                                     self.value)

    @classmethod
    def parse(cls, line):
        match = cls.match_re.match(line)
        if match:
            name = match.group(1)
            assignment = match.group(2)
            value = match.group(3)
            # FIXME: I'm ignoring the assignment type
            obj = cls(name, value)
            return obj
        return None


class Makefile(object):
    rule_split_re = re.compile(r'([^\s:]+\s*:);\s*(.*)')
    default_suffixes = SpecialTarget('.SUFFIXES', '.c .o .h .s')

    def __init__(self, content):
        self.content = content
        self.lines = []
        accumulator = []
        for line in content.splitlines():
            if line.endswith('\\'):
                accumulator.append(line[:-1])
                continue
            else:
                accumulator.append(line)
                self.lines.append(''.join(accumulator))
                accumulator = []
        if accumulator:
            self.lines.append(''.join(accumulator))

        self.targets = {}
        self.variables = {}
        self.first_target = None
        self.suffixrules = {}
        self.specialtargets = {}
        self.implicit_targets = {}
        self.current_target = None

    def __repr__(self):
        return "<{}({} targets, {} suffix rules, {} variables)>".format(self.__class__.__name__,
                                                                        len(self.targets),
                                                                        len(self.suffixrules),
                                                                        len(self.variables))

    def parse(self):
        self.current_target = None
        for line in self.lines:
            match = self.rule_split_re.match(line)
            if match:
                target_name = match.group(1)
                commands = match.group(2)
                self.parse_line(target_name)
                self.parse_line(' ' + commands)
                continue

            self.parse_line(line)

    def parse_line(self, line):
        expansion = self.expand(line)
        new_target = Target.parse(expansion)
        if new_target:
            if new_target.target in self.targets:
                # It's already present, so we will need to merge them
                new_target = self.targets[new_target.target].merge(new_target)
            else:
                self.targets[new_target.target] = new_target
            if not self.first_target:
                self.first_target = new_target
            self.current_target = new_target
            return

        new_target = SuffixRule.parse(line)
        if new_target:
            if new_target.key() in self.suffixrules:
                raise ValueError("Cannot repeat suffix rules (from {} to {})".format(new_target.ext_from, new_target.ext_to))
            self.suffixrules[new_target.key()] = new_target
            self.current_target = new_target
            return

        new_target = SpecialTarget.parse(line)
        if new_target:
            if new_target.target in self.specialtargets:
                raise ValueError("Cannot repeat special targets (target {})".format(new_target.target))
            self.specialtargets[new_target.target] = new_target
            self.current_target = new_target
            return

        if self.current_target and self.current_target.match_command(line):
            return

        new_variable = Variable.parse(line)
        # FIXME: Appending variables not supported
        if new_variable:
            self.variables[new_variable.variable.lower()] = new_variable

    def read_variable(self, variable):
        """
        Return the value of a variable, performing expansions if necessary
        """
        # FIXME: All expansions are recursive right now
        value = self.variables.get(variable.lower(), None)
        if not value:
            # No value set, so we return an empty string
            return ''
        value = self.expand(value.value)
        return value

    def expand(self, string, variables=None):
        """
        Expand a string within the Makefile.
        """
        # Fast exit if we don't have any substitutions to perform
        if '$' not in string:
            return string

        try:
            if variables:
                for var, value in variables.items():
                    self.variables[var] = Variable(var, value)

            accumulator = []
            while string:
                if '$' in string:
                    literal, rest = string.split('$', 1)
                    accumulator.append(literal)
                    (expansion, string) = self.expand_variable(rest)
                    accumulator.append(expansion)
                else:
                    accumulator.append(string)
                    break

        finally:
            if variables:
                for var, value in variables.items():
                    del self.variables[var]

        return ''.join(accumulator)

    def expand_special(self, special):
        var = self.variables.get(special, None)
        if var:
            return var.value
        return '$' + special

    def expand_variable(self, string):
        """
        Variable expansion, between the ${} or $() characters, or a special expansion, eg $@

        @param string:  The string to expand, starting from the character after the $.

        @return: tuple of (the expansion of the string, the rest after the expansion)
        """
        if len(string) == 0:
            # The dollar was at the end of the line; just return it bare
            return ('$', '')
        if string[0] == '$':
            # Escaped dollar, so return it as the expansion
            return ('$', string[1:])
        if string[0] not in ('{', '('):
            # It's a special character, so expand
            return (self.expand_special(string[0]), string[1:])

        terminator = '}' if string[0] == '{' else ')'
        string = string[1:]

        spec = []
        while True:
            dollar_index = string.find('$')
            terminator_index = string.find(terminator)

            if ((dollar_index != -1 and terminator_index == -1) # Only a dollar
                or (dollar_index != -1 and dollar_index < terminator_index)): # dollar before terminator
                spec.append(string[:dollar_index])
                string = string[dollar_index + 1:]
                (expansion, string) = self.expand_variable(string)

            elif dollar_index == -1 and terminator_index == -1:
                # No dollar or terminator.
                raise ValueError("Expected to see terminator {}, but reached end of string at {!r}".format(terminator,
                                                                                                           string))

            else:
                # Terminator came before the dollar, so we've found the end of the string.
                spec.append(string[:terminator_index])
                string = string[terminator_index + 1:]
                break

        # Now process the spec
        #print("SPEC: %r" % (spec,))

        spec = ''.join(spec)

        if ':' not in spec and ' ' not in spec:
            # Simple variable specification, so expand it.
            variable = spec
            value = self.read_variable(variable)

            return (value, string)

        if ':' in spec:
            # pattern substitution:
            #   ${var:tail=replace}
            # is the same as:
            #   ${patsubst %tail,%replace,${var})
            variable, pattern = spec.split(':', 1)
            tail, replace = pattern.split('=', 1)
            if '%' in tail:
                spec = 'patsubst {},{},{}'.format(tail, replace, self.read_variable(variable))
            else:
                spec = 'patsubst %{},%{},{}'.format(tail, replace, self.read_variable(variable))

        # We now know that this is a function call.
        func_name, rest = spec.split(' ', 1)
        # All parameters are always specified with commas between them
        params = rest.split(',')

        func = functions.get(func_name, None)
        if not func:
            raise ValueError("Function '{}' is not implemented".format(func_name))
        value = func(self, params)

        return (value, string)

    def match_suffix(self, filename, ext):
        """
        Match a suffix (like '.c' or 'c') to a filename (like 'main.c', 'c.main', or 'tool.c.main')
        """
        if ext[0] != '.':
            ext = '.' + ext

        if filename.endswith(ext):
            # This is a Unix-style name
            return True

        # Strip the dot from the start
        ext = ext[1:]

        parts = filename.split('.')
        #print("match_suffix: Check %s against %s" % (ext, parts))
        if len(parts) == 1:
            return False

        return parts[-2].lower() == ext.lower()

    def find_rule(self, target_name):
        """
        Find a rule for a given target.

        We generate a new rule if there is a suffix rule that would apply.
        """

        # If we've already created a rule, let's use it
        if target_name in self.implicit_targets:
            return self.implicit_targets[target_name]

        # Check if we have an explicit target
        target = self.targets.get(target_name)
        if target:
            # The target is only useful if we have commands associated with it
            if target.commands:
                return target

        dot_suffixes = self.specialtargets.get('.SUFFIXES', self.default_suffixes).dependencies
        dot_suffixes = list(suffix.replace('.', '') for suffix in dot_suffixes)

        #print("find_rule for %s" % (target_name,))

        # We don't have an explicit target for this file which can build it.
        # We will try to find a suffix rule that might support this.
        candidates = []
        for key, rule in self.suffixrules.items():
            (ext_from, ext_to) = key

            #print("FindRule: %s -> %s   dot_suffixes = %s" % (ext_from, ext_to, dot_suffixes))

            if ext_from not in dot_suffixes or \
               ext_to not in dot_suffixes:
                # This isn't a rule that is a candidate for suffix matching, so skip it
                continue

            #print("Matches .SUFFIXES")

            if self.match_suffix(target_name, ext_to):
                # This target is a candidate for suffix rules, so let's check the dependencies (if there are
                # any present)

                #print("Matches target %s\n" % (target_name,))

                for dependency in target.dependencies:
                    if self.match_suffix(dependency, ext_from):
                        candidates.append((dependency, rule))

        if len(candidates) > 1:
            raise ValueError("Multiple suffix rule matches for {}: {}"
                             .format(target_name,
                                     ','.join(str(rule) for rule in candidates)))

        if not candidates:
            # There are no candidates for suffix rules, BUT there might have been a target which
            # was just dependencies, so we can return that.
            return target

        # Create an implicit rule for this candidate
        (dependency, rule) = candidates[0]
        new_target = ImplicitTarget(target_name, dependency, rule, target)
        self.implicit_targets[target_name] = new_target
        return new_target

    def target_commands(self, goal=None):
        """
        Return all the commands that would be run by each of the required goals.

        @return: A list of tuples of the form (target, command)
        """
        commands = []
        if not goal:
            if not self.first_target:
                return commands
            goal = self.first_target.target

        rule = self.find_rule(goal)
        if not rule:
            return commands

        dependencies = rule.dependencies
        for dependency in dependencies:
            dependency_commands = self.target_commands(goal=dependency)
            commands.extend(dependency_commands)

        for command in rule.commands:
            expansion = self.expand(command, rule.variables)
            expansion = expansion.lstrip('*')
            expansion = expansion.lstrip(' ')
            commands.append((goal, expansion))

        return commands

    def linkables(self, goal=None, link_tools=('link', 'drlink')):
        """
        Return all the linkable targets.

        @return: A set of the linkable target names
        """
        commands = self.target_commands(goal=goal)

        linkables = set([])
        for target, command in commands:
            if ' ' in command:
                cmd, _ = command.split(' ', 1)
            else:
                cmd = command
            if cmd.lower() in link_tools:
                linkables |= set([target])

        return linkables


def read_makefile(mf_filename):
    with open(mf_filename) as fh:
        data = fh.read()

    makefile = Makefile(data)
    makefile.parse()
    return makefile


def show_tree(makefile, goal=None, built={}, indent=0):
    if not goal:
        if not makefile.first_target:
            raise ValueError("No default target known in makefile")

        goal = makefile.first_target.target

    rule = makefile.find_rule(goal)
    if not rule:
        return
    #print("{}- {}   ({})".format(" " * indent, goal, rule))
    print("{}- {}".format(" " * indent, goal))
    if goal in built:
        # Already built, so we can skip its dependencies and commands
        return

    dependencies = rule.dependencies
    for dependency in dependencies:
        show_tree(makefile, goal=dependency, built=built, indent=indent+2)

    # Dependencies are now dealt with, so we need to execute commands
    for command in rule.commands:
        expansion = makefile.expand(command, rule.variables)
        print("{}  *{}".format(" " * indent, expansion))
    built[goal] = True


if __name__ == '__main__':
    import argparse
    import os
    import sys

    parser = argparse.ArgumentParser(usage="%s [<options>]" % (os.path.basename(sys.argv[0]),))
    parser.add_argument('--makefile', type=str, required=True,
                        help="Makefile to process")

    options = parser.parse_args()

    mf = read_makefile(options.makefile)
    show_tree(mf)
