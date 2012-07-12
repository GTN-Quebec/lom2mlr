#!/usr/bin/env python2.7
import argparse
import sys
import os.path

from uuid import UUID, uuid1, uuid5, NAMESPACE_URL
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
def uuid_unique(context):
    'Return a unique UUID composed from the MAC address and timestamp'
    return str(uuid1())


@unwrap_seq
def uuid_string(context, s, namespace=None):
    'Return a UUID based on a string'
    if namespace is None:
        namespace = NAMESPACE_URL
    elif not isinstance(namespace, UUID):
        namespace = UUID(namespace)
    return str(uuid5(namespace, s.encode('utf-8')))


class Converter(object):
    """A converter between LOM and MLR formats.

    Can take a file or lxml object; can return rdf-xml or rdflib graphs."""

    default_options = {
        "use_mail_and_fn_uuid": "true()",
        "use_mail_uuid": "false()",
        "use_mail_url": "false()",
        "use_org_uuid": "true()",
        "use_fn_uuid": "false()",
        "use_random_uuid": "false()",
    }

    def __init__(self, stylesheet=STYLESHEET, options = None):
        stylesheet_xml = etree.parse(stylesheet)
        self.langsheets = {}
        self.set_options(options)
        #self.output = stylesheet_xml.xpath('xsl:output/@method',
        #	namespaces={'xsl':XSLT_NS})
        self.stylesheet = etree.XSLT(stylesheet_xml,
            extensions={
                (VCARDC_NS, 'convert'): convert,
                (URL_MLR_EXT, 'uuid_string'): uuid_string,
                (URL_MLR_EXT, 'uuid_unique'): uuid_unique,
                (URL_MLR_EXT, 'uuid_url'): uuid_url,
                })

    def set_options(self, options = None):
        if options is None:
            self.options = self.default_options
        else:
            self.options = { k: 'true()' if k in options else 'false()' 
                    for k in self.default_options.keys()}

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
        try:
            rdfxml = self.stylesheet(xml, **self.options)
        except:
            print self.stylesheet.error_log
            raise
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
        if xml:
            return Graph().parse(data=etree.tounicode(xml), format="xml")

    def lomxml2graph(self, xml, lang=None):
        "Takes a LOM xml object, returns a rdf graph"
        xml = self.lomxml2rdfxml(xml, lang)
        if xml:
            return Graph().parse(data=etree.tounicode(xml), format="xml")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Apply a XSLT stylesheet to a LOM file')
    parser.add_argument('-s', '--stylesheet', default=STYLESHEET, help='Name of the stylesheet')
    parser.add_argument('-l', '--language', help='Express using language')
    parser.add_argument('-f', '--format', default='rawxml',
            help="output format: one of 'rawxml', 'xml', 'n3', 'turtle', 'nt', 'pretty-xml', trix'")
    parser.add_argument('-o', '--output', help="Output file", type=argparse.FileType('w'), default=sys.stdout)
    parser.add_argument('-x', '--option', action='append',
        help="""Stylesheet options: any combination of:
        *use_mail_and_fn_uuid, use_mail_uuid, use_mail_url, *use_org_uuid, use_fn_uuid, use_random_uuid.
        See stylesheet for definition. Starred items are on if no option is specified.""")
    parser.add_argument('infile')
    args = parser.parse_args()
    converter = Converter(args.stylesheet, args.option)
    
    try:
        if (args.format == 'rawxml'):
            xml = converter.lomfile2rdfxml(args.infile, args.language)
            if xml:
                args.output.write(etree.tounicode(xml, pretty_print=True).encode('utf-8'))
        else:
            rdf = converter.lomfile2graph(args.infile, args.language)
            if rdf:
                args.output.write(rdf.serialize(format=args.format, encoding='utf-8'))
    finally:
        args.output.close()

