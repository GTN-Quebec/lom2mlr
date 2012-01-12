#!/usr/bin/env python2.7
import argparse

from lxml import etree
from vobject.base import readOne
from vobject import vcard

def is_sequence(arg):
    return (not hasattr(arg, "strip") and
            hasattr(arg, "__getitem__") or
            hasattr(arg, "__iter__"))

def vobj_to_str(vobj, root, attributes):
	for n in attributes:
		if getattr(vobj, n):
			el = etree.Element(n.lower())
			root.append(el)
			val = getattr(vobj, n)
			if is_sequence(val):
				val = u' '.join(val)
			el.text = val

# TODO: Utiliser http://viagenie.ca/publications/2009-11-12-ietf-vcarddav-vcardxml.pdf
def convert(context, card):
	if is_sequence(card):
		if len(card) > 1:
			return [convert(context, c) for c in card]
		else:
			card = card[0]
	card = readOne(card)
	root = etree.Element('vcard')
	for e in card.getChildren():
		el = etree.Element(e.name.lower())
		root.append(el)
		v = e.transformToNative().value
		if isinstance(v, vcard.Address):
			vobj_to_str(v, el, vcard.ADDRESS_ORDER)
		elif isinstance(v, vcard.Name):
			vobj_to_str(v, el, vcard.NAME_ORDER)
		else:
			el.text = v
		for k,v in e.params.items():
			if is_sequence(v):
				v = ','.join(v)
			el.attrib[k.lower()] = v
	context.context_node.append(root)
	return root

VCARDNS='http://ntic.org/vcard'

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Apply a XSLT stylesheet to a LOM file')
	parser.add_argument('-s', default='lom2mlr.xsl', help='Name of the stylesheet')
	parser.add_argument('infile')
	args = parser.parse_args()
	xsl = etree.parse(args.s)
	output = xsl.xpath('xsl:output/@method', namespaces={'xsl':'http://www.w3.org/1999/XSL/Transform'})
	xsl = etree.XSLT(xsl,
		extensions={(VCARDNS, 'convert'):convert})
	xml = etree.parse(args.infile)
	if output and output[0] == 'text':
		print unicode(xsl(xml)).encode('utf-8')
	else:
		print etree.tounicode(xsl(xml), pretty_print=True).encode('utf-8')
