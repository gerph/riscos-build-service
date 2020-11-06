#!/usr/bin/python

import os

translate_extension = ['.c', '.s', '.h', '.c++', '.p']

def test(filename):
    was = filename
    (base, ext) = os.path.splitext(os.path.basename(filename))
    if base and ext in translate_extension:
        # Turns foo.c into c/foo
        dirname = os.path.dirname(filename)
        filename = os.path.join(dirname, ext[1:], base)
    print("Name: %s => %s" % (was, filename))
    return filename

test("this/that")
test("this/that.c")
test("this/that.cx")
test("this/that.c++")
