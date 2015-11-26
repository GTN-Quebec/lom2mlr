#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-


import argparse
import sys
import os.path
from urlparse import urlparse
from urllib import urlopen

from lxml import etree

from common.converter import XMLTransform
from vcard2xcard import convert

this_dir = os.path.dirname(unicode(__file__, sys.getfilesystemencoding( )))

STYLESHEET = os.path.join(this_dir, 'extendvcard.xsl')
""" The stylesheet used by the converter."""

VCARDC_NS = 'http://ntic.org/vcard'
"""A namespace for XSLT extensions in :py:mod:`lom2mlr.vcard2xcard`"""

class Converter(XMLTransform):
    def __init__(self):
        extensions = {(VCARDC_NS, 'convert'): convert}
        XMLTransform.__init__(self, STYLESHEET, extensions)

def main():
    """Apply a Converter to a LOM file according to command-line arguments."""
    converter = Converter()
    parser = argparse.ArgumentParser(
        description='Extend the vcard of a lom into a xcard')
    parser.add_argument('-o', '--output', help="Output file",
                        type=argparse.FileType('w'), default=sys.stdout)
    parser.add_argument("-e", "--encoding", default="UTF-8", help="Encoding to use")
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
        print(args.encoding)
        args.output.write(etree.tostring(xml, encoding=args.encoding, pretty_print=True))
    args.output.close()

if __name__ == '__main__':
    main()
