#!/usr/bin/env python2.7
import argparse
import sys
import os.path

from uuid import uuid5, NAMESPACE_URL
from lxml import etree
from rdflib import Graph

from util import unwrap_seq
from vcard2xcard import convert

VCARDC_NS = 'http://ntic.org/vcard'
XSLT_NS = 'http://www.w3.org/1999/XSL/Transform'
STYLESHEET = 'lom2mlr.xsl'

URL_MLR = 'http://standards.iso.org/iso-iec/19788/'
URL_GTN = 'http://gtn-quebec.org/ns/'
URL_MLR_EXT = URL_MLR + 'ext/'
NAMESPACE_MLR = uuid5(NAMESPACE_URL, URL_MLR)

@unwrap_seq
def uuid_url(context, url):
	return 'urn:uuid:'+str(uuid5(NAMESPACE_MLR, url))

@unwrap_seq
def uuid_email(context, email):
	return uuid_url(context, 'mailto:'+email)

class Converter(object):
	"""A converter between LOM and MLR formats. 

	Can take a file or lxml object; can return rdf-xml or rdflib graphs."""

	def __init__(self, stylesheet=STYLESHEET):
		stylesheet_xml = etree.parse(stylesheet)
		self.langsheets = {}
		#self.output = stylesheet_xml.xpath('xsl:output/@method', 
		#	namespaces={'xsl':XSLT_NS})
		self.stylesheet = etree.XSLT(stylesheet_xml,
			extensions={
				(VCARDC_NS, 'convert'):convert,
				(URL_MLR_EXT, 'uuid_email'):uuid_email,
				(URL_MLR_EXT, 'uuid_url'):uuid_url})

	def get_lang_sheet(self, lang):
		if lang in self.langsheets:
			return self.langsheets[lang]
		langsheet = None
		try:
			langsheet = etree.XSLT(etree.parse(os.path.join('translations','translation_%s.xsl'%(lang,))))
		except: pass
		self.langsheets[lang] = langsheet
		return langsheet

	def lomxml2rdfxml(self, xml, lang=None):
		"Transform a lom xml object to a rdf-xml object"
		rdfxml = self.stylesheet(xml)
		langsheet = self.get_lang_sheet(lang)
		if langsheet:
			rdfxml = langsheet(rdfxml)
		return rdfxml

	def lomfile2rdfxml(self, fname, lang=None):
		"Takes a path to a lom file, returns a rdf-xml object"
		xml = etree.parse(fname)
		return self.lomxml2rdfxml(xml, lang)

	def lomfile2graph(self, fname, lang=None):
		"Takes a path to a lom file, returns a rdf graph"
		xml = self.lomfile2rdfxml(fname, lang)
		return Graph().parse(data=etree.tounicode(xml), format="xml")

	def lomxml2graph(self, xml, lang=None):
		"Takes a LOM xml object, returns a rdf graph"
		xml = self.lomxml2rdfxml(xml, lang)
		return Graph().parse(data=etree.tounicode(xml), format="xml")


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Apply a XSLT stylesheet to a LOM file')
	parser.add_argument('-s', default=STYLESHEET, help='Name of the stylesheet')
	parser.add_argument('-l', help='Express using language')
	parser.add_argument('-f', default='rawxml', help="output format: one of 'xml', 'n3', 'turtle', 'nt', 'pretty-xml', trix'")
	parser.add_argument('infile')
	args = parser.parse_args()
	converter = Converter(args.s)
	if (args.f == 'rawxml'):
		xml = converter.lomfile2rdfxml(args.infile, args.l)
		print etree.tounicode(xml, pretty_print=True).encode('utf-8')
	else:
		rdf = converter.lomfile2graph(args.infile, args.l)
		print rdf.serialize(format=args.f, encoding='utf-8')

