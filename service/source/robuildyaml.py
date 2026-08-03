#!/usr/bin/env python
"""
Process the .robuild.yaml file to work out what to build.

The `.robuild.yaml` file is used within sources supplied to the RISC OS Build service
to define how the build should be performed.

The file itself may be called `.robuild.yml`, `.robuild.yaml` or `.robuild` (in RISC OS,
those files will use `/` instead of `.`).

The file is structured as YAML, and contains a dictionary with the following elements:

    * `source`: Defines where the source should be obtained from. Not currently implemented.
    * `jobs`: Defines a dictionary of the build jobs which the file declares. Only one job
      may be defined at present.

The `jobs` dictionary may contain the following keys:

    * `env`: Declares a dictionary of system variables which should be set before the build.
    * `script`: Declares a list of the RISC OS commands to run. Failure of any command will
      fail the build.
    * `artifacts`: Declares a list of artifacts that should be returned. Only one item can
      exist at present.

The `artifacts` list items are a dictionary describing how they artifacts are to be
handled:

    * `path`: Declares the path which will be archived.
"""

import simpleyaml


try:
    STRING_TYPES = (basestring,)
except NameError:
    STRING_TYPES = (str,)


class ROBuildYAMLError(Exception):
    pass


class ROBYArtifact(object):
    """
    Artifacts within the job in robuild.yaml.
    """
    path = None

    def __init__(self, artifact_yaml, path):
        self.artifact_yaml = artifact_yaml

        if not isinstance(artifact_yaml, dict):
            raise ROBuildYAMLError("ROBuild YAML: {} must be a dictionary".format(path))

        self.path = artifact_yaml.get('path', None)
        if not isinstance(self.path, STRING_TYPES) or not self.path:
            raise ROBuildYAMLError("ROBuild YAML: {}.path must contain a string".format(path))


class ROBYJob(object):
    """
    Job definition within rouild.yaml.
    """
    env = {}
    working_directory = None
    script = []
    artifacts = []

    def __init__(self, name, job_yaml):
        """
        Convert the job YAML content into an object.
        """
        self.name = name
        self.job_yaml = job_yaml
        self.path = 'jobs.{}'.format(name)

        if not isinstance(job_yaml, dict):
            raise ROBuildYAMLError("ROBuild YAML: {} must be a dictionary".format(self.path))

        # Environment variables
        env = job_yaml.get('env', {})
        if not isinstance(env, dict):
            raise ROBuildYAMLError("ROBuild YAML: {}.env must be a dictionary".format(self.path))
        self.env = env

        # Working directory
        self.working_directory = job_yaml.get('dir', None)
        if self.working_directory is not None and not isinstance(self.working_directory, STRING_TYPES):
            raise ROBuildYAMLError("ROBuild YAML: {}.dir must be a string".format(self.path))

        # Script to build
        script = job_yaml.get('script', None)
        if not isinstance(script, list) or not script:
            raise ROBuildYAMLError("ROBuild YAML: {}.script must be a non-empty list of commands to run".format(self.path))

        for index, command in enumerate(script):
            if not isinstance(command, STRING_TYPES):
                raise ROBuildYAMLError("ROBuild YAML: {}.script.{} must be a string".format(self.path, index))

        self.script = script

        # Artifacts to collect
        artifacts = job_yaml.get('artifacts', None)
        if artifacts is not None:
            if not isinstance(artifacts, list):
                raise ROBuildYAMLError("ROBuild YAML: {}.artifacts must be a list".format(self.path))
            if len(artifacts) != 1:
                raise ROBuildYAMLError("ROBuild YAML: {}.artifacts must contain a single path".format(self.path))

        self.artifacts = []
        if artifacts is not None:
            for index, artifact_yaml in enumerate(artifacts):
                self.artifacts.append(ROBYArtifact(artifact_yaml,
                                                   '{}.artifacts.{}'.format(self.path, index)))


class ROBuildYAML(object):
    config_yaml = None
    jobs = None

    def __init__(self, config_filename):
        self.config_filename = config_filename
        self.config_yaml = None
        self.parse()

    def parse(self):
        with open(self.config_filename, 'r') as fh:
            config_yaml = simpleyaml.load(fh)

        if not isinstance(config_yaml, dict):
            raise ROBuildYAMLError("ROBuild YAML: root element must be a dictionary")

        jobs = config_yaml.get('jobs', None)
        if not isinstance(jobs, dict) or not jobs:
            raise ROBuildYAMLError("ROBuild YAML: Must have a 'jobs' dictionary")
        if len(jobs) != 1:
            raise ROBuildYAMLError("ROBuild YAML: jobs dictionary must have only one key")

        self.jobs = []
        for name, job in jobs.items():
            self.jobs.append(ROBYJob(name, job))
