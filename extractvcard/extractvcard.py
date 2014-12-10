#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-


import argparse
import sys
import os.path
from urlparse import urlparse
from urllib import urlopen
from rdflib import Graph

from lxml import etree

from common.converter import XMLTransform
from common import utils

this_dir = os.path.dirname(unicode(__file__, sys.getfilesystemencoding( )))

STYLESHEET_EXTRACT = os.path.join(this_dir, 'vcard2mlr.xsl')
STYLESHEET_DUP = os.path.join(this_dir, 'removedup.xsl')

URL_MLR = 'http://standards.iso.org/iso-iec/19788/'
""" The URL for the MLR standards, as a namespace."""

URL_MLR_EXT = URL_MLR + 'ext/'
"""A namespace for XSLT utility extensions"""

""" The stylesheet used by the converter."""


def main():
    extensions = {(URL_MLR_EXT, 'vcard_uuid'): utils.vcard_uuid}
    converterExtract = XMLTransform(STYLESHEET_EXTRACT, extensions)
    converterDup = XMLTransform(STYLESHEET_DUP)
    parser = argparse.ArgumentParser(
        description='Extend the vcard of a lom into a xcard')
    parser.add_argument('-f', '--format', default='rawxml',
                        help="output format: one of 'rawxml', 'xml', 'n3',"
                             " 'turtle', 'nt', 'pretty-xml', trix'")
    parser.add_argument('-o', '--output', help="Output file",
                        type=argparse.FileType('w'), default=sys.stdout)
    parser.add_argument('infile', help="input file or url", nargs="?")
    converterExtract.populate_argparser(parser)
    #converterDup.populate_argparser(parser)
    args = parser.parse_args()
    converterExtract.set_options_from_dict(vars(args))
    #converterDup.set_options_from_dict(vars(args))
    
    if (urlparse(args.infile).scheme):
        opener = urlopen
    else:
        opener = open

    with opener(args.infile) as infile:
        xml = converterExtract.convertfile(infile)
    if xml:
        xml = converterDup.convertxml(xml)
    if xml:
        if args.format == "rawxml":
            args.output.write(etree.tounicode(xml, pretty_print=True).encode('utf-8'))
        else:
            rdf = Graph().parse(data=etree.tounicode(xml), format="xml")
            if rdf:
                args.output.write(rdf.serialize(format=args.format, encoding='utf-8'))
    args.output.close()

if __name__ == '__main__':
    main()
