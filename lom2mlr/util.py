
"Utility functions, mostly used by XSLT extensions."

from functools import wraps


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
