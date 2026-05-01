#!/usr/bin/env python
"""
Pyromaniac class, with the ability to start a server to handle the clipboard and throwback.
"""

import email.message
import http.server
import json
import socket
import threading
import time
import urllib.parse

import roname
import pyro
from rofiletypes import *


def parse_content_type(value):
    """
    Parse a Content-Type header into its media type and parameters.
    """
    message = email.message.Message()
    message['content-type'] = value
    content_type = message.get_content_type()
    params = dict(message.get_params(header='content-type')[1:])
    return content_type, params


class PyroHTTPRequestHandler(http.server.BaseHTTPRequestHandler):

    def do_POST(self):

        path = self.path
        request_headers = self.headers
        content_type = request_headers.get_all('content-type')
        content_type = content_type[0].lower() if content_type else None
        content_length = request_headers.get_all('content-length')
        length = int(content_length[0]) if content_length else 0
        body = self.rfile.read(length)

        self.log_message("Received %s" % (path,))
        self.log_message("Content type %s" % (content_type,))

        content_type_params = {}
        if content_type:
            content_type, content_type_params = parse_content_type(content_type)
        filename = None
        filetype = None
        if content_type == 'application/riscos':
            # A RISC OS file received!
            filename = content_type_params.get('name', None)
            if filename:
                filename = roname.RISCOSName(unix_filename=filename)
                filetype = filename.filetype
        elif content_type == 'application/json':
            body = json.loads(body)
            filename = None
            filetype = FILETYPE_THROWBACK
            #import pprint
            #pprint.pprint(body)

        try:
            self.server.data_received(path, body, filename, filetype)
            self.send_response(200)
            self.end_headers()

        except Exception as exc:
            self.send_response(500, 'Internal error: {}'.format(exc))
            self.end_headers()

    def log_message(self, *args, **kwargs):
        return self.server.log_message(*args, **kwargs)


class PyroServer(pyro.Pyro):

    def __init__(self, hostname=None, port=8080, scheme='http', path='/{service}', url=None):
        super(PyroServer, self).__init__()
        self._post_scheme = None
        self._post_hostname = None
        self._post_port = None
        self._post_path = None
        self._post_url = None

        self.set_config('clipboardholder.implementation', 'posturl')
        self.set_config('throwback.implementation', 'posturl')
        self.set_config('throwback.url_scheme', 'riscos')

        if url:
            self.post_url = url
        else:
            self.post_scheme = scheme
            if hostname:
                self.post_hostname = hostname
            else:
                fqdn = socket.getfqdn()
                try:
                    fqdn = socket.gethostbyname(fqdn)
                except Exception:
                    # IF we couldn't convert to a hostname, don't bother.
                    pass
                self.post_hostname = fqdn
            self.post_port = port
            self.post_path = path

    def _update_url(self):
        url = self.post_url.replace('{service}', 'clipboard')
        self.set_config('clipboardholder.post_url', url)

        url = self.post_url.replace('{service}', 'throwback')
        self.set_config('throwback.url', url)

    @property
    def post_hostname(self):
        return self._post_hostname

    @post_hostname.setter
    def post_hostname(self, value):
        self._post_hostname = value
        self._post_url = None
        self._update_url()

    @property
    def post_port(self):
        return self._post_port

    @post_port.setter
    def post_port(self, value):
        self._post_port = value
        self._post_url = None
        self._update_url()

    @property
    def post_path(self):
        return self._post_path

    @post_path.setter
    def post_path(self, value):
        self._post_path = value
        self._post_url = None
        self._update_url()

    @property
    def post_scheme(self):
        return self._post_scheme

    @post_scheme.setter
    def post_scheme(self, value):
        self._post_scheme = value
        self._post_url = None
        self._update_url()

    @property
    def post_url(self):
        if self._post_url:
            return self._post_url
        else:
            return '{}://{}:{}{}'.format(self._post_scheme, self._post_hostname, self._post_port, self._post_path)

    @post_url.setter
    def post_url(self, value):
        self._post_url = value

        parsed = urllib.parse.urlparse(value)
        self._post_hostname = parsed.hostname
        self._post_port = parsed.port or 80
        self._post_scheme = parsed.scheme or 'http'
        self._post_path = parsed.path
        self._update_url()


class PyroNativeServer(PyroServer):

    def __init__(self, hostname=None, port=0, scheme='http', path='/{service}', url=None,
                 throwback_function=None,
                 clipboard_function=None):
        super(PyroNativeServer, self).__init__(hostname=hostname, port=port, scheme=scheme, path=path, url=url)
        self.server = None
        self.server_thread = None
        self.server_running = False
        self.throwback_function = throwback_function
        self.clipboard_function = clipboard_function

    def data_received(self, path, data, filename, filetype):
        if path == '/throwback':
            if filetype == FILETYPE_THROWBACK:
                if self.throwback_function:
                    self.throwback_function(data)
                return
        elif path == '/clipboard':
            if self.clipboard_function:
                self.clipboard_function(data, filetype)

        else:
            raise ValueError('No handler for path {}'.format(path))

    def log_message(self, format, *args):
        """
        Log message from the HTTP server.
        """
        pass

    def start_server(self):
        if not self.server:
            self.server = http.server.HTTPServer(('', self.post_port), PyroHTTPRequestHandler)
            self.server.data_received = self.data_received
            self.server.log_message = self.log_message
            if not self.post_port:
                # They requested an ephemeral port, so find out what that port is.
                self.post_port = self.server.server_address[1]
            #print("Listening at {}".format(self.server.server_address))
            self.server.timeout = 1
            # We want the server to run on another thread
            def start(pyro=self, server=self.server):
                try:
                    #print("Starting the server on port {}".format(self.post_port))
                    while pyro.server_running:
                        server.handle_request()
                except Exception as exc:
                    #print("Failed: {}".format(exc))
                    raise
                finally:
                    # We have terminated, so clear the server handle
                    try:
                        server.server_close()
                    except Exception:
                        pass
                    #print("PyroNativeServer exiting")
                    pyro.server = None

            thread = threading.Thread(target=start)
            # Make the thread a daemon so that we don't actually /have/ to join it.
            thread.daemon = True
            self.server_running = True
            thread.start()

    def stop_server(self):
        if self.server:
            self.server_running = False
            # Wait for a moment or two for the server to shut down
            end_timeout = time.time() + 5
            while time.time() < end_timeout and self.server:
                time.sleep(0.5)
            if self.server:
                print("Server did not shut down.")
                # FIXME: Decide how to handle this - if the thread didn't exit when asked to, something's bad.
                self.server = None
                self.server_thread = None
            else:
                self.server_thread = None
