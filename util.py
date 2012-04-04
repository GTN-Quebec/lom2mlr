def is_sequence(arg):
    return (not hasattr(arg, "strip") and
            hasattr(arg, "__getitem__") or
            hasattr(arg, "__iter__"))

def unwrap_seq(func):
	def wrapped(context, l):
		if is_sequence(l):
			if len(l):
				if len(l) > 1:
					return [func(context, c) for c in l]
				else:
					return func(context, l[0])
			else:
				return []
		else:
			return func(context, l)
	return wrapped