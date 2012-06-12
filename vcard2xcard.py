#!/usr/bin/env python2.7
import re

#TODO: Get rid of vobject...
from vobject.base import readOne
from vobject import vcard

from util import is_sequence, unwrap_seq

VCARD_NS='urn:ietf:params:xml:ns:vcard-4.0'
VCARD_NSB='{%s}' % (VCARD_NS, )
NSMAP={None:VCARD_NS}


def regexp_checker(pattern):
	r = re.compile(pattern)
	return lambda s: r.match(s) is not None

def regexp_checker_ex(pattern, exceptionp):
	rp = re.compile(pattern)
	rep = re.compile(exceptionp)
	return lambda s: rep.match(s) is None and rp.match(s) is not None

def regexp_checker_exs(pattern, exceptions):
	rp = re.compile(pattern)
	rep = [re.compile(ex) for ex in exceptions]
	def check(s):
		for ex in rep:
			if ex.match(s):
				return False
		return bool(rp.match(s))
	return check

type_checkers = {
	'uri':regexp_checker(r'''^([a-zA-Z0-9+.-]+):(//([a-zA-Z0-9-._~!$&'()*+,;=:]*)@)?([a-zA-Z0-9-._~!$&'()*+,;=]+)(:(\\d*))?(/?[a-zA-Z0-9-._~!$&'()*+,;=:/]+)?(\\?[a-zA-Z0-9-._~!$&'()*+,;=:/?@]+)?(#[a-zA-Z0-9-._~!$&'()*+,;=:/?@]+)?$(:(\\d*))?(/?[a-zA-Z0-9-._~!$&'()*+,;=:/]+)?(\?[a-zA-Z0-9-._~!$&'()*+,;=:/?@]+)?(\#[a-zA-Z0-9-._~!$&'()*+,;=:/?@]+)?$'''),
	'date-time': regexp_checker_ex(r'(\d{8}|--\d{4}|---\d\d)T\d\d(\d\d(\d\d)?)?', r'(Z|[+\-]\d\d(\d\d)?)?'),
	'date': regexp_checker(r'\d{8}|\d{4}-\d\d|--\d\d(\d\d)?|---\d\d'),
	'time': regexp_checker_ex(r'(\d\d(\d\d(\d\d)?)?|-\d\d(\d\d?)|--\d\d)', r'(Z|[+\-]\d\d(\d\d)?)?'),
	'timestamp': regexp_checker(r'\d{8}T\d{6}(Z|[+\-]\d\d(\d\d)?)?'),
	'utc-offset': regexp_checker(r'[+\-]\d\d(\d\d)?'),
	'language-tag': regexp_checker_exs(r'([a-z]{2,3}((-[a-z]{3}){0,3})?|[a-z]{4,8})', 
                          (r'(-[a-z]{4})?(-([a-z]{2}|\d{3}))?',
                          r'(-([0-9a-z]{5,8}|\d[0-9a-z]{3}))*',
                          r'(-[0-9a-wyz](-[0-9a-z]{2,8})+)*',
                          r'(-x(-[0-9a-z]{1,8})+)?|x(-[0-9a-z]{1,8})+|',
                          r'[a-z]{1,3}(-[0-9a-z]{2,8}){1,2}')),
    'text': lambda s: True
}

xcard_param_types = {
	'language': 'language-tag',
	'altid': 'text',
	'mediatype': 'text-list',
	'sort-as': 'text-list',
	'geo': 'uri',
	'tz' : ('uri', 'text'),
	'type': 'text-list'
}

xcard_prop_types = {
	'source':'uri',
	'fn':'text',
	'nickname':'text-list',
	'photo':'uri',
	'bday': ('date-time', 'date', 'time', 'text'),
	'anniversary': ('date-time', 'date', 'time', 'text'),
	'gender': 'sex',
	'tel': ('uri', 'text'),
	'email': 'text',
	'impp': 'uri',
	'lang': 'language-tag',
	'tz': ('utc-offset', 'uri', 'text'),
	'geo': 'uri',
	'title': 'text',
	'role': 'text',
	'logo': 'uri',
	'org': 'text-list',
	'member': 'uri',
	'related': ('uri', 'text'),
	'categories': 'text-list',
	'note': 'text',
	'prodid': 'text',
	'rev': 'timestamp',
	'sound': 'uri',
	'uid': 'uri',
	'clientpidmap': 'uri',
	'url': 'uri',
	'key': 'uri',
	'fburl': 'uri',
	'caladruri': 'uri',
	'caluri': 'uri',
}

exclude_tags = ['version']


def vobj_to_str(vobj, root, attributes):
	for n in attributes:
		val = getattr(vobj, n, None)
		if val:
			# vobject disagrees with rfc6531
			if n == 'family': n = 'surname'
			el = root.makeelement(VCARD_NSB+n.lower(), nsmap=NSMAP)
			root.append(el)
			if is_sequence(val):
				val = u' '.join(val)
			el.text = val

def append_typed_el(root, typename, val):
	el = root.makeelement(VCARD_NSB+typename, nsmap=NSMAP)
	root.append(el)
	el.text = val


def vobj_to_typed(val, root, typelist):
	tag = root.tag
	tag = tag[1+tag.rindex('}'):]
	if tag in typelist:
		types = typelist[tag]
		if isinstance(types, tuple):
			if is_sequence(val):
				val = u' '.join(val)
			for t in types:
				if type_checkers[t](val):
					append_typed_el(root, t, val)
					break
			else:
				append_typed_el(root, 'unknown', val)
		elif types == 'text-list':
			if not is_sequence(val):
				val=[val]
			for v in val:
				append_typed_el(root, 'text', v)
		else:
			append_typed_el(root, types, val)
	else:
		if is_sequence(val):
			val = u' '.join(val)
		append_typed_el(root, 'unknown', val)

def vobj_to_typed_param(val, root):
	vobj_to_typed(val, root, xcard_param_types)

def vobj_to_typed_properties(val, root):
	vobj_to_typed(val, root, xcard_prop_types)


# TODO: Utiliser http://tools.ietf.org/html/rfc6351
@unwrap_seq
def convert(context, card):
	card = readOne(card)
	root = context.context_node.makeelement(VCARD_NSB+'vcard', nsmap=NSMAP)
	for e in card.getChildren():
		tag = e.name.lower()
		if tag in exclude_tags:
			continue
		el = root.makeelement(VCARD_NSB+tag, nsmap=NSMAP)
		root.append(el)
		if e.group:
			el.attrib['group'] = e.group
		if e.params:
			params = el.makeelement(VCARD_NSB+'parameters', nsmap=NSMAP)
			el.append(params)
			for k, v in e.params.items():
				param = params.makeelement(VCARD_NSB+k.lower(), nsmap=NSMAP)
				params.append(param)
				vobj_to_typed_param(v, param)
		v = e.transformToNative().value
		if isinstance(v, vcard.Address):
			vobj_to_str(v, el, vcard.ADDRESS_ORDER)
		elif isinstance(v, vcard.Name):
			vobj_to_str(v, el, vcard.NAME_ORDER)
		else:
			vobj_to_typed_properties(v, el)
	return root
