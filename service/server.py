#!/usr/bin/env python

from flask import Flask
app = Flask(__name__)


@app.route('/')
def hello_world():
    import time
    time.sleep(20)
    return 'Hello, World!'


@app.route('/hw')
def hello_world2():
    return 'Hello, World!'


if __name__ == "__main__":
    app.run(debug=True)
