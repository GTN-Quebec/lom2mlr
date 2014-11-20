#!/usr/bin/env python2.7

"""Utility module to transform a VCard (see :RFC:`2425` and :RFC:`2426`) into a XCard (see :RFC:`6351`)"""

import re
from base64 import b64encode


# TODO: Get rid of vobject and do it directly by parsing?
from vobject.base import readOne as readOne_original
from vobject import vcard

from lom2mlr.util import is_sequence, unwrap_seq

"""The namespace for xCard """
VCARD_NS = 'urn:ietf:params:xml:ns:vcard-4.0'

"""The namespace for xCard, in brackets, for :etree:`ElementTree namespace syntax <xml-namespaces>` """
VCARD_NSB = '{%s}' % (VCARD_NS, )

"""The namespace map used in building xCard objects"""
NSMAP = {None: VCARD_NS}


def readOne(card):
    card_lines = card.split('\n')
    card_lines = [l.lstrip() for l in card_lines]
    while len(card_lines[0]) == 0:
        del card_lines[0]
    use_cr = card_lines[0][-1] == '\r'
    first_line = card_lines[0].rstrip('\r')
    if first_line != first_line.rstrip():
        card_lines[0] = first_line.rstrip() + ('\r' if use_cr else '')
    card = '\n'.join(card_lines)
    return readOne_original(card)


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
    'binary': regexp_checker(r'.*[\x00-\x08\x0e-\x1f]'),
    'uri': regexp_checker(r'''^([a-zA-Z0-9+.-]+):(//([a-zA-Z0-9-._~!$&'()*+,;=:]*)@)?([a-zA-Z0-9-._~!$&'()*+,;=]+)(:(\\d*))?(/?[a-zA-Z0-9-._~!$&'()*+,;=:/]+)?(\\?[a-zA-Z0-9-._~!$&'()*+,;=:/?@]+)?(#[a-zA-Z0-9-._~!$&'()*+,;=:/?@]+)?$(:(\\d*))?(/?[a-zA-Z0-9-._~!$&'()*+,;=:/]+)?(\?[a-zA-Z0-9-._~!$&'()*+,;=:/?@]+)?(\#[a-zA-Z0-9-._~!$&'()*+,;=:/?@]+)?$'''),
    'date-time': regexp_checker_ex(r'(\d{8}|--\d{4}|---\d\d)T\d\d(\d\d(\d\d)?)?',
                                   r'(Z|[+\-]\d\d(\d\d)?)?'),
    'date': regexp_checker(r'\d{8}|\d{4}-\d\d|--\d\d(\d\d)?|---\d\d'),
    'time': regexp_checker_ex(r'(\d\d(\d\d(\d\d)?)?|-\d\d(\d\d?)|--\d\d)',
                              r'(Z|[+\-]\d\d(\d\d)?)?'),
    'timestamp': regexp_checker(r'\d{8}T\d{6}(Z|[+\-]\d\d(\d\d)?)?'),
    'utc-offset': regexp_checker(r'[+\-]\d\d(\d\d)?'),
    'language-tag': regexp_checker_exs(
        r'([a-z]{2,3}((-[a-z]{3}){0,3})?|[a-z]{4,8})',
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
    'tz': ('uri', 'text'),
    'type': 'text-list'
}

xcard_prop_types = {
    'source': 'uri',
    'fn': 'text',
    'nickname': 'text-list',
    'photo': ('uri', 'binary'),
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
    'logo': ('uri', 'binary'),
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
    'key': ('uri', 'binary'),
    'fburl': 'uri',
    'caladruri': 'uri',
    'caluri': 'uri',
}

exclude_tags = ['version']


def vobj_to_str(vobj, root, attributes):
    """Fill a XCard element's properties and text from the vobject's properties

    :type vobj: :vobject-class:`VBase`
    :param vobj: the vcard content element
    :type root: :lxml-class:`_Element`
    :param root: the xCard element to be filled
    :type attributes: [str]
    :param attributes: the list of attributes to be filled
    """
    for n in attributes:
        val = getattr(vobj, n, None)
        if val:
            # vobject disagrees with rfc6531
            if n == 'family':
                n = 'surname'
            el = root.makeelement(VCARD_NSB + n.lower(), nsmap=NSMAP)
            root.append(el)
            if is_sequence(val):
                val = u' '.join(val)
            el.text = val


def append_typed_el(root, typename, val):
    el = root.makeelement(VCARD_NSB + typename, nsmap=NSMAP)
    root.append(el)
    if typename == 'binary':
        val = "data:;base64," + b64encode(val)
    el.text = val


def vobj_to_typed(val, root, typelist):
    tag = root.tag
    tag = tag[1 + tag.rindex('}'):]
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
                val = [val]
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
    """Convert vCards into xCards, and append them to the context's node.

    :type card: str
    :param card: vCard text (may contain more than one vcard.)
    :type context: :lxml-class:`_XSLTContext`
    :param context: the xslt context that will allow creation of etree elements
    :returns: the context's node (a :lxml-class:`_Element`) on which xCards were added.
    """
    try:
        card = readOne(card)
        root = context.context_node.makeelement(VCARD_NSB + 'vcard', nsmap=NSMAP)
        for e in card.getChildren():
            tag = e.name.lower()
            if tag in exclude_tags:
                continue
            el = root.makeelement(VCARD_NSB + tag, nsmap=NSMAP)
            root.append(el)
            if e.group:
                el.attrib['group'] = e.group
            if e.params:
                params = el.makeelement(VCARD_NSB + 'parameters', nsmap=NSMAP)
                el.append(params)
                for k, v in e.params.iteritems():
                    param = params.makeelement(VCARD_NSB + k.lower(), nsmap=NSMAP)
                    params.append(param)
                    vobj_to_typed_param(v, param)
            v = e.transformToNative().value
            if isinstance(v, vcard.Address):
                vobj_to_str(v, el, vcard.ADDRESS_ORDER)
            elif isinstance(v, vcard.Name):
                vobj_to_str(v, el, vcard.NAME_ORDER)
            else:
                vobj_to_typed_properties(v, el)
    except Exception as e:
        print("oups", e.message)
        raise
    return root
