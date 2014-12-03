#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-


import argparse
import sys
import os.path
from urlparse import urlparse
from urllib import urlopen

from lxml import etree
from lom2mlr.util import unwrap_seq, module_path

def _to_xsl_option(val):
    if val is True:
        return "true()"
    elif val is False:
        return "false()"
    else:
        return "'%s'" % (val, )

class XMLTransform(object):
    """A converter between LOM and MLR formats.

    Through various methods, the Converter object can receive a file
    or lxml object and return raw rdf-xml or rdflib graphs.
    """

    def __init__(self, stylesheet, extensions={}):
        """
        :param stylesheet: The path to the :file:`lom2mlr.xslt` stylesheet
        """
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
        self.options = {}

        self.stylesheet = etree.XSLT(
            stylesheet_xml,
            extensions=extensions)
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

    def populate_argparser(self, parser):
        """Add options from the stylesheet to the argparser

        :type parser: :py:class:`argparse.ArgumentParser`
        """
        if self.sheet_options:
            group = parser.add_argument_group("xslt options", "The options defined in the xslt")
            for name, desc in self.sheet_options.iteritems():
                default = self.option_defaults[name]
                if default == 'true()':
                    group.add_argument('--no-' + name, action='store_false',
                                        dest=name, help=desc, default=True)
                elif default == 'false()':
                    group.add_argument('--' + name, action='store_true',
                                        help=desc, default=False)
                elif default[0] == "'" and default[-1] == "'":
                    group.add_argument('--' + name, help=desc,
                                        default=default[1:-1])

    def convertfilename(self, filename):
        if (urlparse(filename).scheme):
            print "url"
            opener = urlopen
        else:
            print "opn"
            opener = open
        
        with opener(filename) as infile:
            return self.convertfile(infile)

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
    parser = argparse.ArgumentParser(description="Transform a xml using a stylesheest")
    parser.add_argument("-s", "--stylesheet", help="The stylesheet to use")
    parser.add_argument("-o", "--output", type=argparse.FileType('w'), default=sys.stdout, help="The output file")
    parser.add_argument("-e", "--encoding", default="utf-8", help="Encoding to use")
    parser.add_argument("infile", help="input file or url")

    def on_error(message):
        pass

    _error = parser.error
    parser.error = on_error
    
    args, _ = parser.parse_known_args()

    parser.error = _error

    if args.stylesheet is None:
        print "A stylesheet is needed"
        parser.print_help()
        exit()

    converter = XMLTransform(args.stylesheet)
    
    converter.populate_argparser(parser)

    if args.infile is None:
        print "A infile is needed"
        parser.print_help()
        exit()

    args = parser.parse_args()
    converter.set_options_from_dict(vars(args))

    xml = converter.convertfilename(args.infile)

    args.output.write(etree.tounicode(xml, pretty_print=True).encode(args.encoding))


if __name__ == '__main__':
    main()
