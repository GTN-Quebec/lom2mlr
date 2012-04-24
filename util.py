def is_sequence(arg):
    return (not hasattr(arg, "strip") and
            hasattr(arg, "__getitem__") or
            hasattr(arg, "__iter__"))

def unwrap_seq(func):
    def wrapped(context, *l):
        if len(l) == 1 and is_sequence(l[0]):
            l = l[0]
            if len(l):
                if len(l) > 1:
                    return [func(context, c) for c in l]
                else:
                    return func(context, l[0])
            else:
                return []
        else:
            return func(context, *l)
    return wrapped

def splitcode(code):
    if code[0:3] == ':::':
        lines = code.split("\n")
        code_type = lines[0][3:]
        code = "\n".join(lines[1:])
    else:
        code_type = None
    return code_type, code
