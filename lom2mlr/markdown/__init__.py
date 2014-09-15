#!/usr/bin/env python
"""Markdown extensions used to create the :file:`rationale.html` file"""

import os.path
import argparse

# Import sw without altering the pygments install
from . import sw
import pygments.plugin
pygments.plugin.find_plugin_lexers = lambda: [sw.Notation3Lexer]

import markdown
from markdown.extensions.codehilite import CodeHiliteExtension
from markdown.extensions.tables import TableExtension

from .embed import EmbedExtension


def compile():
    """Process a markdown file according to command-line arguments"""
    parser = argparse.ArgumentParser(
        description='Create the documentation file')
    parser.add_argument('-l', help='Give language translations',
                        default=False, action='store_true')
    parser.add_argument('-c', help='Check validity',
                        default=False, action='store_true')
    parser.add_argument('-b', help='Add buttons for each example',
                        default=False, action='store_true')
    parser.add_argument('--hide', help='Hide examples by default',
                        default=False, action='store_true')
    parser.add_argument('--delete', help='Delete examples',
                        default=False, action='store_true')
    parser.add_argument('--output', help='Output file name', default=None)
    parser.add_argument('infile')
    args = parser.parse_args()
    extensions = [TableExtension(),
                  CodeHiliteExtension({}),
                  EmbedExtension(args.delete, args.l)
                  ]
    if args.l:
        from .translate import TranslateMlrExtension
        extensions.insert(0, TranslateMlrExtension())
        if not args.c:
            from .embed_code import EmbedCodeExtension
            extensions.insert(0, EmbedCodeExtension(args.b, args.hide, args.delete))
    if args.c:
        from .test_mlr import TestExtension
        extensions.insert(0, TestExtension(args.b, args.hide, args.delete))
    output = args.output or (
        os.path.basename(args.infile).rsplit('.', 1)[0] + '.html')
    markdown.markdownFromFile(
        input=args.infile,
        output=output,
        encoding='utf-8',
        extensions=extensions)
