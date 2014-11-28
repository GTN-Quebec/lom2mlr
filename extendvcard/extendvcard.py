#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-


import argparse
import sys
import os.path
from urlparse import urlparse
from urllib import urlopen

from lxml import etree
from lom2mlr.util import unwrap_seq, module_path

from lom2mlr.vcard2xcard import convert

VCARDC_NS = 'http://ntic.org/vcard'
"""A namespace for XSLT extensions in :py:mod:`lom2mlr.vcard2xcard`"""

this_dir = os.path.dirname(unicode(__file__, sys.getfilesystemencoding( )))

STYLESHEET = os.path.join(this_dir, 'extendvcard.xsl')
""" The stylesheet used by the converter."""


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


        self.stylesheet = etree.XSLT(
            stylesheet_xml,
            extensions={
                (VCARDC_NS, 'convert'): convert,
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

    def convertfile(self, afile):
        """Takes a path to a lom file, returns a rdf-xml object

        :param afile: a file-like object
        :returns: a MLR record in RDF-XML format
            (as a :lxml-class:`_ElementTree`)
        """
        xml = etree.parse(afile)
        return self.convertxml(xml)

    def convertxml(self, xml):
        """Transform a lom xml object to a rdf-xml object

        :type xml: :lxml-class:`_ElementTree`
        :param xml: the parsed LOM record.
        :returns: a MLR record in RDF-XML format
            (as a :lxml-class:`_ElementTree`)
        """
        try:
            new_xml = self.stylesheet(xml, **self.options)
        except:
            print(self.stylesheet.error_log)
            raise
        return new_xml

def main():
    """Apply a Converter to a LOM file according to command-line arguments."""
    converter = Converter(STYLESHEET)
    parser = argparse.ArgumentParser(
        description='Extend the vcard of a lom into a xcard')
    parser.add_argument('-o', '--output', help="Output file",
                        type=argparse.FileType('w'), default=sys.stdout)
    parser.add_argument('infile', help="input file or url")
    converter.populate_argparser(parser)
    args = parser.parse_args()
    converter.set_options_from_dict(vars(args))
    
    if (urlparse(args.infile).scheme):
        opener = urlopen
    else:
        opener = open

    with opener(args.infile) as infile:
        xml = converter.convertfile(infile)
    if xml:
        args.output.write(etree.tounicode(
            xml, pretty_print=True).encode('utf-8'))
    args.output.close()

if __name__ == '__main__':
    main()
