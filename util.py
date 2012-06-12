def is_sequence(arg):
    return (not hasattr(arg, "strip") and
            hasattr(arg, "__getitem__") or
            hasattr(arg, "__iter__"))

def unlist(arg):
    if is_sequence(arg) and len(arg) == 1:
        return arg[0]
    return arg

def seqlen(arg):
    if is_sequence(arg):
        return len(arg)
    return 1

def unwrap_seq(func):
    def wrapped(context, *args):
        lengths = [seqlen(a) for a in args]
        args = [unlist(a) for a in args]
        if max(lengths) == 0 and len(lengths) > 0:
            return []
        if max(lengths) > 1:
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
    if code[0:3] == ':::':
        lines = code.split("\n")
        code_type = lines[0][3:]
        code = "\n".join(lines[1:])
    else:
        code_type = None
    return code_type, code
