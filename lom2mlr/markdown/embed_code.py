#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""A :markdown-ext:`treeprocessors` that embeds each markdown code fragment in a div with relevant CSS classes."""

from cgi import escape
import re

import markdown
from markdown.treeprocessors import Treeprocessor
from markdown.util import etree

from lom2mlr.util import splitcode


HEADER_R = re.compile(r'^h[1-9]$', re.I)


def stringify_error_element(n):
    try:
        return escape(n.n3())
    except AttributeError:
        return escape(u'"%s"' % (n))


class EmbedCodeTreeprocessor(Treeprocessor):
    """Embeds code fragments in divs.
    """
    def __init__(self, md, buttons, hide_eg, delete_eg):
        self.buttons = buttons
        self.hide_eg = hide_eg
        self.delete_eg = delete_eg

    def run(self, root):
        elements = list(root)  # should be an iterator, but 2.6 getiterator vs 2.7 iter.
        root.clear()
        target = root
        example_num = 0
        for element in elements:
            if HEADER_R.match(element.tag):
                target = root
            elif element.tag == 'pre':
                sub = list(element)
                assert len(sub) == 1
                code_el = sub[0]
                assert code_el.tag == 'code'
                format, code, args = splitcode(code_el.text)
                divclasses = [format]
                if args == 'forbidden':
                    divclasses.append(args)
                if format.lower() == 'n3':
                    divclasses.append('mlr')
                subdiv = etree.Element('div', {'class': ' '.join(divclasses)})
                subdiv.append(element)
                element = subdiv
                if target is root:
                    example_num += 1
                    if self.buttons:
                        button = etree.Element('button', {'onclick': "$('#eg%d').toggle();" % (example_num,)})
                        button.text = 'Example'
                        root.append(button)
                    divattr = {"class": "example", 'id': 'eg%d' % (example_num,)}
                    if self.hide_eg:
                        divattr['style'] = 'display:none'
                    div = etree.Element('div', divattr)
                    if not self.delete_eg:
                        root.append(div)
                    target = div
            target.append(element)
        return root


class EmbedCodeExtension(markdown.Extension):
    def __init__(self, buttons=False, hide_eg=True, delete_eg=False):
        self.buttons = buttons
        self.hide_eg = hide_eg
        self.delete_eg = delete_eg

    def extendMarkdown(self, md, md_globals):
        """ Add EmbedCodeTreeprocessor to Markdown instance. """
        embedcode = EmbedCodeTreeprocessor(md, self.buttons, self.hide_eg, self.delete_eg)
        md.treeprocessors.add("embedcode", embedcode, "<inline")
        md.registerExtension(self)
