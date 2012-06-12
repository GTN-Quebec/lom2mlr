#!/usr/bin/env python2.7
import argparse
import sys
import os.path

from uuid import UUID, uuid3, uuid4, uuid5, NAMESPACE_URL
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
def uuid_url(context, url, namespace=None):
    'Return a UUID based on a URL'
    if namespace is None:
        namespace = NAMESPACE_URL
    elif not isinstance(namespace, UUID):
        namespace = UUID(namespace)
    return str(uuid5(namespace, url))


@unwrap_seq
def uuid_random(context):
    'Return a random UUID'
    return str(uuid4())


@unwrap_seq
def uuid_string(context, s, namespace=None):
    'Return a UUID based on a string'
    if namespace is None:
        namespace = NAMESPACE_MLR
    elif not isinstance(namespace, UUID):
        namespace = UUID(namespace)
    s = s.encode('ascii','backslashreplace')
    return str(uuid3(namespace, s))


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
                (VCARDC_NS, 'convert'): convert,
                (URL_MLR_EXT, 'uuid_string'): uuid_string,
                (URL_MLR_EXT, 'uuid_random'): uuid_random,
                (URL_MLR_EXT, 'uuid_url'): uuid_url,
                })

    def get_lang_sheet(self, lang, random=False):
        if lang in self.langsheets:
            return self.langsheets[lang]
        langsheet = None
        try:
            langsheet = etree.XSLT(etree.parse(os.path.join('translations','translation_%s.xsl'%(lang,))))
        except: pass
        self.langsheets[lang] = langsheet
        return langsheet

    def lomxml2rdfxml(self, xml, lang=None, random=False):
        "Transform a lom xml object to a rdf-xml object"
        arguments = {}
        if random:
            arguments['use_random_uuid'] = 'true()'
        try:
            rdfxml = self.stylesheet(xml, **arguments)
        except:
            print self.stylesheet.error_log
            raise
        langsheet = self.get_lang_sheet(lang)
        if langsheet:
            rdfxml = langsheet(rdfxml)
        return rdfxml

    def lomfile2rdfxml(self, fname, lang=None, random=False):
        "Takes a path to a lom file, returns a rdf-xml object"
        xml = etree.parse(fname)
        return self.lomxml2rdfxml(xml, lang, random)

    def lomfile2graph(self, fname, lang=None, random=False):
        "Takes a path to a lom file, returns a rdf graph"
        xml = self.lomfile2rdfxml(fname, lang, random)
        if xml:
            return Graph().parse(data=etree.tounicode(xml), format="xml")

    def lomxml2graph(self, xml, lang=None, random=False):
        "Takes a LOM xml object, returns a rdf graph"
        xml = self.lomxml2rdfxml(xml, lang, random)
        if xml:
            return Graph().parse(data=etree.tounicode(xml), format="xml")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Apply a XSLT stylesheet to a LOM file')
    parser.add_argument('-s', default=STYLESHEET, help='Name of the stylesheet')
    parser.add_argument('-l', help='Express using language')
    parser.add_argument('-f', default='rawxml',
            help="output format: one of 'rawxml', 'xml', 'n3', 'turtle', 'nt', 'pretty-xml', trix'")
    parser.add_argument('-r', help="Add random identifiers to blank nodes", action='store_true')
    parser.add_argument('infile')
    args = parser.parse_args()
    converter = Converter(args.s)
    if (args.f == 'rawxml'):
        xml = converter.lomfile2rdfxml(args.infile, args.l, args.r)
        if xml:
            print etree.tounicode(xml, pretty_print=True).encode('utf-8')
    else:
        rdf = converter.lomfile2graph(args.infile, args.l, args.r)
        if rdf:
            print rdf.serialize(format=args.f, encoding='utf-8')

