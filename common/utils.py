#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

from uuid import UUID, uuid1, uuid5, NAMESPACE_URL, RFC_4122
import rfc3987
import re
from functools import wraps

URL_GTN = 'http://gtn-quebec.org/ns/vcarduuid/'
""" A namespace URL for GTN-Québec.  Used to build UUIDs for vCards."""

NAMESPACE_MLR = uuid5(NAMESPACE_URL, URL_GTN)
"""The UUID5 built from the URL_GTN, used as a namespace for GTN-Québec extensions"""

"""The namespace for xCard """
VCARD_NS = 'urn:ietf:params:xml:ns:vcard-4.0'

NAMESPACE_VCARD = uuid5(NAMESPACE_URL, VCARD_NS)


absolute_iri_ref_re = re.compile(u"%s(#%s)?" % (
    rfc3987.bmp_upatterns_no_names['absolute_IRI'],
    rfc3987.bmp_upatterns_no_names['ifragment']))


def is_sequence(arg):
    """Test for sequence objects"""
    return (not hasattr(arg, "strip") and
            hasattr(arg, "__getitem__") or
            hasattr(arg, "__iter__"))


def unlist(arg):
    """Transform single-element collections into their content."""
    if is_sequence(arg) and len(arg) == 1:
        return arg[0]
    return arg


def seqlen(arg):
    """Return length of sequences, or atoms as singletons"""
    if is_sequence(arg):
        return len(arg)
    return 1


def unwrap_seq(func):
    """Wrap a XLT extension function so it will be mapped to multiple fragments"""
    @wraps(func)
    def wrapped(context, *args):
        lengths = [seqlen(a) for a in args]
        args = [unlist(a) for a in args]
        if len(lengths) > 0 and max(lengths) == 0:
            return []
        if len(lengths) > 0 and max(lengths) > 1:
            pos1 = [p for (p, l) in enumerate(lengths) if l > 1][0]
            result = []
            for v in args[pos1]:
                subargs = args[:]
                subargs[pos1] = v
                result.append(func(context, *subargs))
            return result
        else:
            return func(context, *args)
    return wrapped


def splitcode(code):
    """Split markdown code block markers into contents, code_type and arguments"""
    if code[0:3] == ':::':
        lines = code.split("\n")
        code_type = lines[0][3:]
        code = "\n".join(lines[1:])
    else:
        code_type = None
    args = None
    if ' ' in code_type:
        code_type, args = code_type.split(' ', 1)
    return code_type, code, args

def module_path():
    import sys
    import os.path
    if getattr(sys, "frozen", False):
        d = getattr(sys, "_MEIPASS", None)
        if d:
            # pyinstaller
            return d
        else:
            # py2exe
            return os.path.dirname(unicode(sys.executable, sys.getfilesystemencoding( )))

    return os.path.dirname(unicode(__file__, sys.getfilesystemencoding( )))


vcard_uuid = lambda c, s : uuid_string(c, s, NAMESPACE_VCARD)

@unwrap_seq
def uuid_url(context, url, namespace=None):
    """A XSLT extension that returns a UUID based on a URL"""
    if namespace is None:
        namespace = NAMESPACE_URL
    elif not isinstance(namespace, UUID):
        namespace = UUID(namespace)
    return str(uuid5(namespace, url))


@unwrap_seq
def uuid_unique(context):
    """A XSLT extension that returns a unique UUID composed from the MAC address and timestamp"""
    return str(uuid1())


@unwrap_seq
def uuid_string(context, s, namespace=None):
    """A XSLT extension that returns a UUID based on a string"""
    if namespace is None:
        namespace = NAMESPACE_MLR
    elif not isinstance(namespace, UUID):
        namespace = UUID(namespace)
    return str(uuid5(namespace, s.encode('utf-8')))


@unwrap_seq
def is_uuid1(context, uuid):
    """A XSLT extension that returns a UUID based on a string"""
    if not uuid.startswith('urn:uuid:'):
        return False
    u = UUID(uuid[9:])
    assert u.variant == RFC_4122
    return u.version == 1


@unwrap_seq
def is_absolute_iri(context, string):
    return absolute_iri_ref_re.match(string) is not None
