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


from lxml import etree, _elementpath
from rdflib import Graph

from common import converter, utils

VCARDC_NS = 'http://ntic.org/vcard'
"""A namespace for XSLT extensions in :py:mod:`lom2mlr.vcard2xcard`"""

this_dir = os.path.dirname(unicode(__file__, sys.getfilesystemencoding( )))

STYLESHEET = os.path.join(this_dir, 'lom2mlr.xsl')
""" The stylesheet used by the converter."""

URL_MLR = 'http://standards.iso.org/iso-iec/19788/'
""" The URL for the MLR standards, as a namespace."""

URL_MLR_EXT = URL_MLR + 'ext/'
"""A namespace for XSLT utility extensions"""


class Converter(converter.XMLTransform):
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

        extensions={
            (URL_MLR_EXT, 'uuid_string'): utils.uuid_string,
            (URL_MLR_EXT, 'uuid_unique'): utils.uuid_unique,
            (URL_MLR_EXT, 'uuid_url'): utils.uuid_url,
            (URL_MLR_EXT, 'is_uuid1'): utils.is_uuid1,
            (URL_MLR_EXT, 'is_absolute_iri'): utils.is_absolute_iri,
            (URL_MLR_EXT, 'vcard_uuid'): utils.vcard_uuid,
            (URL_MLR_EXT, 'person_uuid'): utils.uuid_string,
        }

        converter.XMLTransform.__init__(self, stylesheet, extensions)

        self.langsheets = {}
        ""

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
        rdfxml = self.convertxml(xml)
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
