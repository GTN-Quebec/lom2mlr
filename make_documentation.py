#!/usr/bin/env python
# -*- coding: utf-8 -*-

from cgi import escape
import re

#Hack pour importer sw sans le mettre dans pygments
import sw
import pygments.plugin
pygments.plugin.find_plugin_lexers = lambda: [sw.Notation3Lexer]

import markdown
from markdown.treeprocessors import Treeprocessor
from markdown.util import etree
from markdown.extensions.codehilite import CodeHiliteExtension

from lom2mlr import Converter
from graph_comparison import GraphTester
from util import splitcode


HEADER_R = re.compile(r'^h[0-9]$', re.I)

class TestTreeprocessor(Treeprocessor):
    def __init__(self, md):
        self.graph_tester = GraphTester()

    def remove_namespace(self, n3):
        lines = n3.split("\n")
        lines = [l for l in lines if l and l[0] != '@']
        return "\n".join(lines)

    def make_response(self, code):
        assert len(code) in range(2, 4)
        if len(code) == 2:
            code.append(('N3',''))
        assert [t.lower() for t, c in code] == ['xml','n3','n3']
        code = [c for t, c in code]
        obtained_graph, errors = self.graph_tester.test_lom(*code)
        if errors:
            div = etree.Element('div',{"class":"error"})
            p = etree.Element('p')
            p.text = "Erreur. Obtenu: "
            div.append(p)
            pre = etree.Element('pre')
            div.append(pre)
            code = etree.Element('code')
            pre.append(code)
            result = obtained_graph.serialize(format='n3', encoding='utf-8')
            code.text = ':::N3\n' + self.remove_namespace(result).decode('utf-8')
            for err_type, error in errors:
                p = etree.Element('p')
                errors = [escape(x) for x in error]
                if err_type == GraphTester.MISSING:
                    p.text = u"Il manque < %s %s %s >." % error
                elif  err_type == GraphTester.UNEXPECTED:
                    p.text = u"< %s %s %s > est présent et ne devrait pas l'être." % error
                div.append(p)
            return div

    def run(self, root):
        elements = list(root) # should be an iterator, but 2.6 getiterator vs 2.7 iter.
        target = root
        code = []
        offset = 0
        for pos, element in enumerate(elements):
            if HEADER_R.match(element.tag):
                if code:
                    response = self.make_response(code)
                    if response:
                        target.insert(pos+offset, response)
                        offset += 1
                    code = []
            if element.tag == 'pre':
                sub = list(element)
                assert len(sub) == 1 and sub[0].tag == 'code'
                code.append(splitcode(sub[0].text))
        if code:
            response = self.make_response(code)
            if response:
                target.append(response)
        return root

class TestExtension(markdown.Extension):
    def __init__(self):
        pass

    def extendMarkdown(self, md, md_globals):
        """ Add TestTreeprocessor to Markdown instance. """
        tester = TestTreeprocessor(md)
        md.treeprocessors.add("tester", tester, "<inline")
        md.registerExtension(self)

class EmbedTreeprocessor(Treeprocessor):
    "Embed the root in html/body tags."
    def run(self, root):
        html = etree.Element('html')
        body = etree.Element('body')
        head = etree.Element('head')
        link = etree.Element('link',{'href':"default.css", 'rel':"stylesheet", 'type':"text/css"})
        head.append(link)
        html.append(head)
        html.append(body)
        elements = list(root) # should be an iterator, but 2.6 getiterator vs 2.7 iter.
        for n in elements:
            root.remove(n)
            body.append(n)
        root.clear()
        root.append(html)
        return root

class EmbedExtension(markdown.Extension):
    def __init__(self):
        pass

    def extendMarkdown(self, md, md_globals):
        """ Add Embed to Markdown instance. """
        embed = EmbedTreeprocessor(md)
        md.treeprocessors.add("embed", embed, "<inline")
        md.registerExtension(self)

if __name__ == '__main__':
    markdown.markdownFromFile(
        input='conversion.md',
        output='conversion.html',
        encoding='utf-8',
        extensions=[TestExtension(), CodeHiliteExtension({}), EmbedExtension()])
