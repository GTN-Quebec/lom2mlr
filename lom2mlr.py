#!/usr/bin/env python2.7
import argparse

from lxml import etree

from vcard2xcard import convert

from rdflib import ConjunctiveGraph

VCARDC_NS = 'http://ntic.org/vcard'
XSLT_NS = 'http://www.w3.org/1999/XSL/Transform'
STYLESHEET = 'lom2mlr.xsl'

class Converter(object):
	def __init__(self, stylesheet=STYLESHEET):
		stylesheet_xml = etree.parse(stylesheet)
		self.output = stylesheet_xml.xpath('xsl:output/@method', 
			namespaces={'xsl':XSLT_NS})
		self.stylesheet = etree.XSLT(stylesheet_xml,
			extensions={(VCARDC_NS, 'convert'):convert})
	def lomxml2rdfxml(self, xml):
		return self.stylesheet(xml)
	def lomfile2rdfxml(self, fname):
		xml = etree.parse(fname)
		return self.lomxml2rdfxml(xml)
	def lomfile2graph(self, fname):
		xml = self.lomfile2rdfxml(fname)
		return ConjunctiveGraph().parse(data=etree.tounicode(xml), format="xml")
	def lomxml2graph(self, xml):
		xml = self.lomxml2graph(self, xml)
		return ConjunctiveGraph().parse(data=etree.tounicode(xml), format="xml")


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Apply a XSLT stylesheet to a LOM file')
	parser.add_argument('-s', default='lom2mlr.xsl', help='Name of the stylesheet')
	parser.add_argument('infile')
	args = parser.parse_args()
	converter = Converter(args.s)
	xml = converter.lomfile2rdfxml(args.infile)
	output = converter.output
	if output and output[0] == 'text':
		print unicode(xml.encode('utf-8'))
	else:
		print etree.tounicode(xml, pretty_print=True).encode('utf-8')
