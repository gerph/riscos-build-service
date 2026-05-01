#!/usr/bin/env python
"""
Run a command, non-blocking, and call a function as data arrives.

The intention of the class is to abstract away any of the ugliness involved in running a command
and accumulating data without blocking.

Example usage
=============

  1. Run command, and read the timestamps and lines (using built-in buffer)::
     si = StreamedInput(['ping', '-c', '4', 'foo.bar'])
     si.start()
     for chunk in si:
        print "Time: %s, Output: %s" % (chunk[0], chunk[1])

  2. Run command, processing chunks as they arrive (using custom handler)::
     def data_handler(data):
        print "Got line %s" % (data,)
     si = StreamedInput(['ping', '-c', '4', 'foo.bar'], data_function=data_handler)
     si.start()

  3. Run a command in the background and pick up its output later::
     si = ThreadedStreamedInput(['syslog'])
     si.start()
     # ... do something long running ...
     for chunk in si:
        print "Time: %s, Output: %s" % (chunk[0], chunk[1])
     # Note, if there is an exception, the syslog command will run to completion before the
     # program will exit.

  4. Safely run command in the background, and pick up its output::
     with ThreadedStreamedInput(['tail', '-f', 'logfile']) as si:
        # ... do stuff ...

     # Now process the chunks that have been received, and their timestamps
     for chunk in si:
        print "Time: %s, Output: %s" % (chunk[0], chunk[1])
"""

import errno
import os
import select
import shlex
import subprocess
import time
import threading

try:
    import fcntl
except ImportError:
    # No fcntl module; might be running on non-POSIX system
    fcntl = None

try:
    # Python 2 has Queue with a capital
    import Queue as queue
except ImportError:
    # Python 3 does not have a capital
    import queue        # pylint: disable=import-error

# Ensure that we can check basestring and unicode on Python 2 and 3.
try:
    basestring
except NameError:
    basestring = str    # pylint: disable=redefined-builtin


class StreamedInputError(Exception):
    pass


class StreamedInputCannotStartError(StreamedInputError):
    pass


class StreamedInputNotSimpleError(StreamedInputError):
    pass


class StreamedInputNotStartedError(StreamedInputError):
    pass


class StreamedInput(object):
    # Default values to ensure nothing is ever missed, even when deleting.
    command = None
    data_function = None
    data_buffer = None
    complete_function = None
    shell = False
    buffer_size = 0
    stop_timeout = 0
    stop_issued = False
    keep_stderr = False
    stdoutfd = 0
    proc = None

    def __init__(self, command, data_function=None, complete_function=None, keep_stderr=False,
                 shell=False, buffer_size=1024 * 32, stop_timeout=10):
        """
        Create an object which can run a subprocess and deliver its data to a function as it arrives.

        Without a data_function being specified, we will use an internal routine to record the time
        that data was received and the data chunk. This data can be read using the 'read' method,
        or by iterating over the object.

        @param self:                This new object
        @param command:             subprocess.Popen style command (either a list or a string)
        @param data_function:       Function to call with the received data (default: Accumulate data into
                                    StreamedInput.data_buffer queue for reading with 'read' or iteration)
        @param complete_function:   Function to call when the subprocess completes (default: None)
        @param keep_stderr:         If the stderr is merged into the output.
        @param shell:               Whether a shell should be used (default: False)
        @param buffer_size:         Internal read buffer size
        @param stop_timeout:        Grace timeout for the subprocess to exit when told to terminate,
                                    after which the subprocess will have a 'KILL' issued.
        """
        if not isinstance(command, (basestring, list)):
            raise ValueError("StreamedInput command must be a list or string, not %s" % (command.__class__.__name__,))

        self.command = command
        self.shell = shell
        self.proc = None
        self.buffer_size = buffer_size
        self.stdoutfd = None
        self.data_buffer = queue.Queue()
        self.stop_timeout = stop_timeout
        self.stop_issued = False
        self.keep_stderr = keep_stderr

        # Function to call with data as it is received
        self.data_function = data_function or self._simple_buffer_function
        self.complete_function = complete_function

    def __repr__(self):
        """
        Return a representation of the parameters and state of the object.

        @return: description of the object
        """
        datafunc = getattr(self.data_function, '__name__', '<no-function>')

        extra = ''
        if self._is_simple_buffer():
            datafunc = '<simple-buffer>'
            extra = ', data_chunks=%s' % (len(self),)

        stopped = 'n/a'
        if self.proc is not None:
            if self.proc.poll() is not None:
                stopped = 'stopped'
            elif self.stop_issued:
                stopped = 'requested'
            else:
                stopped = 'running'

        return "%s(command=%r, shell=%r, buffer_size=%s; " \
               "started=%s, stopped=%s, data_function=%s%s)" % \
               (self.__class__.__name__,
                self.command, self.shell, self.buffer_size,
                self.proc is not None, stopped, datafunc, extra)

    def _set_nonblocking(self):
        """
        Internal: Set the handle as non-blocking.
        """
        fd = self.stdoutfd
        if fcntl:
            flags = fcntl.fcntl(fd, fcntl.F_GETFL)
            fcntl.fcntl(fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)  # pylint: disable=no-member
        else:
            print("Warning: Cannot mark subprocess output as non-blocking")

    def _is_simple_buffer(self):
        """
        Internal: Check whether we are using simple buffering, of a custom function.
        """
        return self.data_function == self._simple_buffer_function

    def start(self):
        """
        Start running the command.

        Blocks until the command has completed its execution and terminated.
        """

        if self.proc is not None:
            raise StreamedInputCannotStartError("Cannot start StreamedInput which has already been started")

        try:
            stderr = subprocess.STDOUT if self.keep_stderr else open(os.devnull, 'w')
            command = self.command
            if os.name == 'nt':
                if isinstance(command, basestring):
                    command = shlex.split(command)

            self.proc = subprocess.Popen(command, shell=self.shell,
                                         stdin=subprocess.PIPE,
                                         stdout=subprocess.PIPE, stderr=stderr,
                                         bufsize=0)
            self.stdoutfd = self.proc.stdout.fileno()
            self._set_nonblocking()

            inputfds = [self.proc.stdout]
            outputfds = []
            exceptfds = [self.proc.stdout]

            while self.proc.poll() is None:
                readable, _, exceptional = select.select(inputfds, outputfds, exceptfds)
                if readable:
                    self._receive_from_subprocess()
                if exceptional:
                    break

        finally:
            # Whatever else happens, we're going to try to clear up by reading any pending
            # data, and then terminating the process.
            if self.proc:
                # We have a proc (we might not if the initial subprocess failed)

                # Read any data that's still pending
                self._receive_from_subprocess()
                if self.proc.poll() is None:
                    # Subprocess still running, so we should try to terminate it
                    # If the terminate was issued outside of our control, the flag will
                    # have been set already.
                    if not self.stop_issued:
                        self._terminate()
                        self.stop_issued = True

                    start = time.time()
                    while self.proc.poll() is None and time.time() < start + self.stop_timeout:
                        self._receive_from_subprocess()
                        time.sleep(0.1)

                    if self.proc.poll() is None:
                        # It still isn't dead. Kill it.
                        self._kill()

                # Call the completion function
                if self.complete_function:
                    self.complete_function()

    def send(self, string):
        """
        Send a string to the stdin of the subprocess.
        """
        if self.proc is None:
            raise StreamedInputNotStartedError("StreamedInput object cannot be sent data before starting")
        self.proc.stdin.write(string)

    @property
    def returncode(self):
        if not self.proc:
            return None
        return self.proc.returncode

    def _terminate(self):
        """
        Internal call to issue a TERM signal to the subprocess.
        """
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()

    def _kill(self):
        """
        Internal call to issue a KILL signal to the subprocess.
        """
        if self.proc and self.proc.poll() is None:
            self.proc.kill()

    def stop(self):
        """
        Terminate the process, if it is currently running.
        """
        if self.proc and self.proc.poll() is None and not self.stop_issued:
            self._terminate()
            self.stop_issued = True

    def _receive_from_subprocess(self):
        """
        Internal: Receive data from the process and dispatch it to the data function.
        """
        while True:
            try:
                data = self.proc.stdout.read(self.buffer_size)
            except IOError as ex:
                if ex.errno == errno.EWOULDBLOCK:  # Resource unavailable (no data present)
                    break
                raise
            if not data:
                break
            if isinstance(data, bytes):
                data = data.decode('utf-8', 'replace')
            self.data_function(data)

    def _simple_buffer_function(self, data):
        """
        Internal routine which buffers data into 'self.data_buffer'.

        Data can be read with 'object.read()', or by iterating over the object.
        Available data can be checked with 'len(object)'
        """
        self.data_buffer.put((time.time(), data))

    def __len__(self):
        """
        Number of chunks pending, when used in the simple data buffering mode.
        """
        if not self._is_simple_buffer():
            raise StreamedInputNotSimpleError("Cannot read length of StreamedInput when not in 'simple' mode")
        if self.proc is None:
            # Not started yet, so return length of 0.
            return 0
        return self.data_buffer.qsize()

    def __iter__(self):
        """
        Allow iteration of the data chunks which are currently available to us, in simple buffering mode.

        Iteration over the buffer is a repeated call to the 'read' function, so the return of None does
        not necessarily mean that the data is complete. Although it will be if used in the single threaded
        class.
        """
        if not self._is_simple_buffer():
            raise StreamedInputNotSimpleError("Cannot iterate over StreamedInput when not in 'simple' mode")
        if self.proc is None:
            raise StreamedInputNotStartedError("StreamedInput object cannot be enumerated before starting")

        while len(self):
            item = self.read()
            if not item:
                break
            yield item

    def eof(self):
        """
        Check whether we have reached the end of the stream of data.

        The end of the stream is when the process has exited, and there is no further data to be read.
        In the simple buffering mode, this means that we have exhaused the chunks and the process has
        terminated.
        In the custom function mode, this means that the process has exited (as the custom function will
        have been delivered all the data as it arrived).
        """
        if self.proc is None:
            raise StreamedInputNotStartedError("StreamedInput object cannot check EOF before starting")

        if self.proc.poll() is None:
            # Still running, so cannot be eof.
            return False

        if not self._is_simple_buffer():
            # Not simple buffering, so the fact that we've exited is enough
            return True

        # Simple buffering, so we reach EOF when all the data has been read
        return len(self) == 0

    def read(self):
        """
        Read data from the simple buffer.

        Whilst there is buffered data, we will return its content.
        When we run out of data, we return None. This does not mean that we have finished, only that
        there is no data in the buffer.

        @return: tuple (time received, content), or None if no data further data has been received.
        """
        if not self._is_simple_buffer():
            raise StreamedInputNotSimpleError("Cannot read data from StreamedInput when not in 'simple' mode")
        if self.proc is None:
            raise StreamedInputNotStartedError("StreamedInput object cannot be read before starting")

        try:
            return self.data_buffer.get_nowait()
        except queue.Empty:
            return None

    def is_running(self):
        """
        Check whether the process is running or not.

        The lack of a running process does not mean that there is no further data, as this may be in the buffer,
        or currently being delivered, in the threaded version.

        @return: True if running, False if the process has exited.
        """
        if self.proc and self.proc.poll() is None:
            return True
        return False

    def __enter__(self):
        """
        Context handler which starts this subprocess running.
        """
        self.start()
        return self

    def __exit__(self, exc_type, exc, tb):
        """
        Leaving the context handler will stop the subprocess running.
        """
        self.stop()


class ThreadedStreamedInput(StreamedInput):
    """
    A threaded implementation of the StreamedInput.

    Instead of blocking and only being able to read the data at the end of the command's execution,
    this implementation will spawn a thread and execute concurrently with the main thread.

    This allows us to read data from the Queue (which is threadsafe) to find out what has been output,
    whilst we were doing other things.

    When using the ThreadedStreamedInput, it is important that the executed process be terminatable.
    If a 'sudo' command is used, the subprocess will not be able to be terminated, because we cannot
    signal a process not owned by us.
    """

    def __init__(self, *args, **kwargs):
        """
        Initialisation is the same as the StreamedInput() class.
        """

        super(ThreadedStreamedInput, self).__init__(*args, **kwargs)
        self.thread = None
        self.thread_exception = None

    def start(self):
        """
        Start the running command.

        Will return once the thread (and subprocess) has started - no blocking till completion here.
        """

        if self.thread is not None:
            raise StreamedInputCannotStartError("Cannot start StreamedInput which has already been started")

        startfunc = super(ThreadedStreamedInput, self).start

        def threadrun():
            try:
                startfunc()
            except Exception as ex:  # pylint: disable=broad-except
                self.thread_exception = ex
                if self.proc and self.proc.poll() is None:
                    self._terminate()

        self.thread = threading.Thread(target=threadrun)
        self.thread.start()

        # Now we wait for either the thread to terminate, proc to be set, or a timeout
        timeout = time.time() + 15
        while time.time() < timeout and self.proc is None and self.thread.is_alive():
            time.sleep(0.1)

        if self.thread_exception:
            raise self.thread_exception  # pylint: disable=raising-bad-type
