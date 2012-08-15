#!/usr/bin/env python2.7

import argparse
import sys
import os.path

from uuid import UUID, uuid1, uuid5, NAMESPACE_URL, RFC_4122
from lxml import etree
from rdflib import Graph

from util import unwrap_seq
from vcard2xcard import convert

VCARDC_NS = 'http://ntic.org/vcard'
XSLT_NS = 'http://www.w3.org/1999/XSL/Transform'

this_dir, this_filename = os.path.split(__file__)
STYLESHEET = os.path.join(this_dir, 'lom2mlr.xsl')

URL_MLR = 'http://standards.iso.org/iso-iec/19788/'
URL_GTN = 'http://gtn-quebec.org/ns/vcarduuid/'
URL_MLR_EXT = URL_MLR + 'ext/'
NAMESPACE_MLR = uuid5(NAMESPACE_URL, URL_GTN)


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
        namespace = NAMESPACE_MLR
    elif not isinstance(namespace, UUID):
        namespace = UUID(namespace)
    return str(uuid5(namespace, s.encode('utf-8')))


@unwrap_seq
def is_uuid1(context, uuid):
    'Return a UUID based on a string'
    if not uuid.startswith('urn:uuid:'):
        return false
    u = UUID(uuid[9:])
    assert u.variant == RFC_4122
    return u.version == 1


def _to_xsl_option(val):
    if val is True:
        return "true()"
    elif val is False:
        return "false()"
    else:
        return "'%s'" % (val, )


class Converter(object):
    """A converter between LOM and MLR formats.

    Can take a file or lxml object; can return raw rdf-xml or rdflib graphs."""

    def __init__(self, stylesheet=STYLESHEET):
        stylesheet_xml = etree.parse(stylesheet)
        self._read_options(stylesheet_xml)
        self.langsheets = {}
        self.options = {}
        self.stylesheet = etree.XSLT(stylesheet_xml,
            extensions={
                (VCARDC_NS, 'convert'): convert,
                (URL_MLR_EXT, 'uuid_string'): uuid_string,
                (URL_MLR_EXT, 'uuid_unique'): uuid_unique,
                (URL_MLR_EXT, 'uuid_url'): uuid_url,
                (URL_MLR_EXT, 'is_uuid1'): is_uuid1,
            })

    def _read_options(self, stylesheet):
        """Extract the stylesheet options
        These will be presented to the user in the help.
        """
        comment = None
        options = {}
        option_defaults = {}
        for c in stylesheet.getroot().getchildren():
            if isinstance(c, etree._Comment):
                comment = c.text.strip()
            elif isinstance(c, etree._Element) and \
                    c.tag == '{http://www.w3.org/1999/XSL/Transform}param':
                option_name = c.attrib['name']
                options[option_name] = comment or ''
                option_defaults[option_name] = c.attrib['select'] or ''
        self.sheet_options = options
        self.option_defaults = option_defaults

    def set_options_from_dict(self, options=None):
        """Set options for the stylesheet from a python dict"""
        options = options or {}
        self.options = {str(k): _to_xsl_option(v)
                        for k, v in options.items()
                        if str(k) in self.sheet_options}

    def _get_lang_sheet(self, lang):
        "Obtain the cached language translation stylesheet."
        if lang in self.langsheets:
            return self.langsheets[lang]
        langsheet = None
        try:
            langsheet = etree.XSLT(etree.parse(os.path.join(
                'translations', 'translation_%s.xsl' % (lang,))))
        except:
            pass
        self.langsheets[lang] = langsheet
        return langsheet

    def lomxml2rdfxml(self, xml, lang=None):
        "Transform a lom xml object to a rdf-xml object"
        try:
            rdfxml = self.stylesheet(xml, **self.options)
        except:
            print self.stylesheet.error_log
            raise
        langsheet = self._get_lang_sheet(lang)
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

    def populate_argparser(self, parser=None):
        """Add options from the stylesheet to the argparser"""
        if parser is None:
            parser = argparse.ArgumentParser()
        for name, desc in self.sheet_options.items():
            default = self.option_defaults[name]
            if default == 'true()':
                parser.add_argument('--no-' + name, action='store_false',
                                    dest=name, help=desc, default=True)
            elif default == 'false()':
                parser.add_argument('--' + name, action='store_true',
                                    help=desc, default=False)
            elif default[0] == "'" and default[-1] == "'":
                parser.add_argument('--' + name, help=desc,
                                    default=default[1:-1])
        return parser


def main():
    """Apply a Converter to a LOM file according to command-line arguments."""
    converter = Converter(STYLESHEET)
    parser = argparse.ArgumentParser(
        description='Apply a XSLT stylesheet to a LOM file')
    parser.add_argument('-l', '--language', help='Express using language')
    parser.add_argument('-f', '--format', default='rawxml',
                        help="output format: one of 'rawxml', 'xml', 'n3',"
                             " 'turtle', 'nt', 'pretty-xml', trix'")
    parser.add_argument('-o', '--output', help="Output file",
                        type=argparse.FileType('w'), default=sys.stdout)
    converter.populate_argparser(parser)
    parser.add_argument('infile')
    args = parser.parse_args()
    converter.set_options_from_dict(vars(args))

    try:
        if (args.format == 'rawxml'):
            xml = converter.lomfile2rdfxml(args.infile, args.language)
            if xml:
                args.output.write(
                    etree.tounicode(xml, pretty_print=True).encode('utf-8'))
        else:
            rdf = converter.lomfile2graph(args.infile, args.language)
            if rdf:
                args.output.write(
                    rdf.serialize(format=args.format, encoding='utf-8'))
    finally:
        args.output.close()

if __name__ == '__main__':
    main()
