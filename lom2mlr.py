#!/usr/bin/env python2.7
import argparse

from lxml import etree

from vcard2xcard import convert

VCARDCNS='http://ntic.org/vcard'

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Apply a XSLT stylesheet to a LOM file')
	parser.add_argument('-s', default='lom2mlr.xsl', help='Name of the stylesheet')
	parser.add_argument('infile')
	args = parser.parse_args()
	xsl = etree.parse(args.s)
	output = xsl.xpath('xsl:output/@method', namespaces={'xsl':'http://www.w3.org/1999/XSL/Transform'})
	xsl = etree.XSLT(xsl,
		extensions={(VCARDCNS, 'convert'):convert})
	xml = etree.parse(args.infile)
	if output and output[0] == 'text':
		print unicode(xsl(xml)).encode('utf-8')
	else:
		print etree.tounicode(xsl(xml), pretty_print=True).encode('utf-8')
