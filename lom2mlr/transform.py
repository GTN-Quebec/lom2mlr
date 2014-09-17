#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

from __future__ import print_function

__doc__ = """The :py:class:`Converter` transforms LOM records into MLR records."""
__docformat__ = "restructuredtext en"

import argparse
import sys
import os.path
import re
from urlparse import urlparse
from urllib import urlopen

from uuid import UUID, uuid1, uuid5, NAMESPACE_URL, RFC_4122
from lxml import etree, _elementpath
from rdflib import Graph
import rfc3987

from lom2mlr.util import unwrap_seq, module_path
from lom2mlr.vcard2xcard import convert

VCARDC_NS = 'http://ntic.org/vcard'
"""A namespace for XSLT extensions in :py:mod:`lom2mlr.vcard2xcard`"""

XSLT_NS = 'http://www.w3.org/1999/XSL/Transform'

this_dir = module_path()

STYLESHEET = os.path.join(this_dir, 'lom2mlr.xsl')
""" The stylesheet used by the converter."""

URL_MLR = 'http://standards.iso.org/iso-iec/19788/'
""" The URL for the MLR standards, as a namespace."""

URL_MLR_EXT = URL_MLR + 'ext/'
"""A namespace for XSLT utility extensions"""

URL_GTN = 'http://gtn-quebec.org/ns/vcarduuid/'
""" A namespace URL for GTN-Québec.  Used to build UUIDs for vCards."""

NAMESPACE_MLR = uuid5(NAMESPACE_URL, URL_GTN)
"""The UUID5 built from the URL_GTN, used as a namespace for GTN-Québec extensions"""


absolute_iri_ref_re = re.compile(u"%s(#%s)?" % (
    rfc3987.bmp_upatterns_no_names['absolute_IRI'],
    rfc3987.bmp_upatterns_no_names['ifragment']))


@unwrap_seq
def uuid_url(context, url, namespace=None):
    """A XSLT extension that returns a UUID based on a URL"""
    if namespace is None:
        namespace = NAMESPACE_URL
    elif not isinstance(namespace, UUID):
        namespace = UUID(namespace)
    return str(uuid5(namespace, url))


@unwrap_seq
def uuid_unique(context):
    """A XSLT extension that returns a unique UUID composed from the MAC address and timestamp"""
    return str(uuid1())


@unwrap_seq
def uuid_string(context, s, namespace=None):
    """A XSLT extension that returns a UUID based on a string"""
    if namespace is None:
        namespace = NAMESPACE_MLR
    elif not isinstance(namespace, UUID):
        namespace = UUID(namespace)
    return str(uuid5(namespace, s.encode('utf-8')))


@unwrap_seq
def is_uuid1(context, uuid):
    """A XSLT extension that returns a UUID based on a string"""
    if not uuid.startswith('urn:uuid:'):
        return False
    u = UUID(uuid[9:])
    assert u.variant == RFC_4122
    return u.version == 1


@unwrap_seq
def is_absolute_iri(context, string):
    return absolute_iri_ref_re.match(string) is not None


def _to_xsl_option(val):
    if val is True:
        return "true()"
    elif val is False:
        return "false()"
    else:
        return "'%s'" % (val, )


class Converter(object):
    """A converter between LOM and MLR formats.

    Through various methods, the Converter object can receive a file
    or lxml object and return raw rdf-xml or rdflib graphs.
    """

    def __init__(self, stylesheet=None):
        """
        :param stylesheet: The path to the :file:`lom2mlr.xslt` stylesheet
        """
        if stylesheet is None:
            stylesheet = STYLESHEET
        stylesheet_xml = etree.parse(stylesheet)
        self.sheet_options = {}
        """
        The name and comments for each option in the stylesheet.

        :type: {str:str}
        """
        self.option_defaults = {}
        """The default value for each option, as found in the stylesheet.

        :type: {str:str}
        """
        self._read_options(stylesheet_xml)
        self.langsheets = {}
        ""
        self.options = {}
        """The options that will be passed to the XSLT stylesheet.
        The values are suitable to be passed as XSL params."""
        self.stylesheet = etree.XSLT(
            stylesheet_xml,
            extensions={
                (VCARDC_NS, 'convert'): convert,
                (URL_MLR_EXT, 'uuid_string'): uuid_string,
                (URL_MLR_EXT, 'uuid_unique'): uuid_unique,
                (URL_MLR_EXT, 'uuid_url'): uuid_url,
                (URL_MLR_EXT, 'is_uuid1'): is_uuid1,
                (URL_MLR_EXT, 'is_absolute_iri'): is_absolute_iri,
            })
        """ :lxml-class:`XSLT` object
            The Converter's stylesheet """

    def _read_options(self, stylesheet):
        """Extract the stylesheet options

        These will be presented to the user in the help.

        :type stylesheet: :lxml-class:`_ElementTree`
        :param stylesheet: The Converter's stylesheet (as a documentTree,
            before xslt)
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
        """Set options for the stylesheet

        :type options: {str:object}
        :param options: The options that will be passed to the stylesheet.
            Strings will be quoted, booleans will be replaced by formula
            according to :py:func:`_to_xsl_option`
        """
        options = options or {}
        self.options = dict(
            (str(k), _to_xsl_option(v))
            for k, v in options.iteritems()
            if str(k) in self.sheet_options)

    def _get_lang_sheet(self, lang):
        """Obtain the cached language translation stylesheet.

        :param lang: a ISO-696-3 language identifier.
        :returns: a :lxml-class:`XSLT` stylesheet.
        """
        if not lang:
            return None
        if lang in self.langsheets:
            return self.langsheets[lang]
        langsheet = None
        filename = os.path.join(
            this_dir, 'translations', 'translation_%s.xsl' % (lang,))
        assert os.path.exists(filename), filename
        langsheet = etree.XSLT(etree.parse(filename))
        self.langsheets[lang] = langsheet
        return langsheet

    def lomxml2rdfxml(self, xml, lang=None):
        """Transform a lom xml object to a rdf-xml object

        :type xml: :lxml-class:`_ElementTree`
        :param xml: the parsed LOM record.
        :param lang: a ISO-696-3 language identifier.
        :returns: a MLR record in RDF-XML format
            (as a :lxml-class:`_ElementTree`)
        """
        try:
            rdfxml = self.stylesheet(xml, **self.options)
        except:
            print(self.stylesheet.error_log)
            raise
        langsheet = self._get_lang_sheet(lang)
        if langsheet:
            rdfxml = langsheet(rdfxml)
        return rdfxml

    def lomfile2rdfxml(self, afile, lang=None):
        """Takes a path to a lom file, returns a rdf-xml object

        :param afile: a file-like object
        :param lang: a ISO-696-3 language identifier.
        :returns: a MLR record in RDF-XML format
            (as a :lxml-class:`_ElementTree`)
        """
        xml = etree.parse(afile)
        return self.lomxml2rdfxml(xml, lang)

    def lomfile2graph(self, afile, lang=None):
        """Takes a path to a lom file, returns a rdf graph

        :param afile: a file-like object
        :param lang: a ISO-696-3 language identifier.
        :returns: a MLR record in RDF-XML format
            (as a :py:class:`rdflib Graph<rdflib:rdflib.graph.Graph>`)
        """
        xml = self.lomfile2rdfxml(afile, lang)
        if xml:
            return Graph().parse(data=etree.tounicode(xml), format="xml")

    def lomxml2graph(self, xml, lang=None):
        """Takes a LOM xml object, returns a rdf graph

        :type xml: :lxml-class:`_ElementTree`
        :param xml: the parsed LOM record.
        :param lang: a ISO-696-3 language identifier.
        :returns: a MLR record in RDF-XML format
            (as a :py:class:`rdflib Graph<rdflib:rdflib.graph.Graph>`)
        """
        xml = self.lomxml2rdfxml(xml, lang)
        if xml:
            return Graph().parse(data=etree.tounicode(xml), format="xml")

    def populate_argparser(self, parser=None):
        """Add options from the stylesheet to the argparser

        :type parser: :py:class:`argparse.ArgumentParser`
        """
        if parser is None:
            parser = argparse.ArgumentParser()
        for name, desc in self.sheet_options.iteritems():
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
    parser.add_argument('infiles', nargs='+', help="input files or urls")
    converter.populate_argparser(parser)
    args = parser.parse_args()
    converter.set_options_from_dict(vars(args))
    for infile in args.infiles:
        if (urlparse(infile).scheme):
            infile = urlopen(infile)
        else:
            infile = open(infile)
        try:
            if (args.format == 'rawxml'):
                xml = converter.lomfile2rdfxml(infile, args.language)
                if xml:
                    args.output.write(etree.tounicode(
                        xml, pretty_print=True).encode('utf-8'))
            else:
                rdf = converter.lomfile2graph(infile, args.language)
                if rdf:
                    args.output.write(
                        rdf.serialize(format=args.format, encoding='utf-8'))
        except:
            pass
    args.output.close()

if __name__ == '__main__':
    main()
