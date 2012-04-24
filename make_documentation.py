#!/usr/bin/env python
# -*- coding: utf-8 -*-

from cgi import escape
import re
import traceback
import argparse

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

    def make_response(self, graphs):
        assert len(graphs) in range(2, 4)
        errors = self.graph_tester.test_graphs(*graphs)
        if errors:
            div = etree.Element('div',{"class":"error"})
            p = etree.Element('p')
            p.text = "Erreur. Obtenu: "
            div.append(p)
            pre = etree.Element('pre')
            div.append(pre)
            graph_e = etree.Element('code')
            pre.append(graph_e)
            result = graphs[0].serialize(format='n3', encoding='utf-8')
            graph_e.text = ':::N3\n' + self.remove_namespace(result).decode('utf-8')
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
        graphs = []
        offset = 0
        error = False
        for pos, element in enumerate(elements):
            if HEADER_R.match(element.tag):
                if graphs and not error:
                    response = self.make_response(graphs)
                    if response:
                        target.insert(pos+offset, response)
                        offset += 1
                    graphs = []
                error = False
            if element.tag == 'pre':
                sub = list(element)
                assert len(sub) == 1 and sub[0].tag == 'code'
                format, code = splitcode(sub[0].text)
                try:
                    graph = self.graph_tester.convert(format, code)
                    graphs.append(graph)
                except Exception as e:
                    p2 = etree.Element('pre')
                    tr = etree.Element('code')
                    p2.append(tr)
                    tr.text = ":::Python Traceback\n"+traceback.format_exc()
                    offset += 1
                    target.insert(pos+offset, p2)
                    error = True
        if graphs:
            response = self.make_response(graphs)
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

class TranslateMlrTreeprocessor(Treeprocessor):
    "Translate mlr strings"
    def __init__(self, md, lang):
        self.lang = lang
        name_trans = re.compile(u"[ '\u2019]")
        tree = etree.parse('translations/translation.xml')
        translations = {}
        for idtag in tree.getiterator('id'):
            for termtag in idtag.getiterator('term'):
                if termtag.get('lang') == lang:
                    translations["%s:%s" % (idtag.get('ns'),idtag.get('id'))] = \
                        "%s_%s:%s" % (idtag.get('ns'),lang, name_trans.sub("_", termtag.text))
                    break
        self.translations = translations

    def run(self, root):
        mlr_r = re.compile(r'\b(mlr[0-9]:(?:DES|RC)[0-9]+)')
        def trans(match):
            c = match.group(0)
            return self.translations.get(c, c)
        for code in root.iter("code"):
            code.text = mlr_r.sub(trans, code.text)
        return root

class TranslateMlrExtension(markdown.Extension):
    def __init__(self, lang):
        self.lang = lang

    def extendMarkdown(self, md, md_globals):
        """ Add Embed to Markdown instance. """
        translateMlr = TranslateMlrTreeprocessor(md, self.lang)
        md.treeprocessors.add("translateMlr", translateMlr, "<inline")
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
    parser = argparse.ArgumentParser(description='Create the documentation file')
    parser.add_argument('-l', help='Express using language')
    args = parser.parse_args()
    extensions = [TestExtension(), CodeHiliteExtension({}), EmbedExtension()]
    target_name = 'documentation.html'
    if (args.l):
        extensions.insert(1, TranslateMlrExtension(args.l))
        target_name = 'documentation_%s.html' % (args.l,)
    markdown.markdownFromFile(
        input='documentation.md',
        output=target_name,
        encoding='utf-8',
        extensions=extensions)
