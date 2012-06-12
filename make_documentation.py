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

from graph_comparison import GraphTester
from util import splitcode


HEADER_R = re.compile(r'^h[1-9]$', re.I)


class TestTreeprocessor(Treeprocessor):
    def __init__(self, md, buttons, hide_eg, delete_eg):
        self.graph_tester = GraphTester()
        self.buttons = buttons
        self.hide_eg = hide_eg
        self.delete_eg = delete_eg

    def remove_namespace(self, n3):
        lines = n3.split("\n")
        lines = [l for l in lines if l and l[0] != '@']
        return "\n".join(lines)

    def make_response(self, graphs):
        assert len(graphs) in range(2, 4), "%d sections of code" % (len(graphs),)
        errors = self.graph_tester.test_graphs(*graphs)
        if errors:
            div = etree.Element('div', {"class": "error"})
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
                print '*', p.text
                div.append(p)
            return div

    def run(self, root):
        elements = list(root)  # should be an iterator, but 2.6 getiterator vs 2.7 iter.
        root.clear()
        target = root
        graphs = []
        error = False
        example_num = 0
        for element in elements:
            if HEADER_R.match(element.tag):
                if graphs and not error:
                    response = self.make_response(graphs)
                    if response:
                        target.append(response)
                target = root
                graphs = []
                error = False
                print " " * int(element.tag[1]) + element.text
            elif element.tag == 'pre':
                sub = list(element)
                assert len(sub) == 1 and sub[0].tag == 'code'
                format, code = splitcode(sub[0].text)
                if format.lower() in ('n3', 'xml'):
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
                    try:
                        graph = self.graph_tester.convert(format, code)
                        graphs.append(graph)
                    except Exception as e:
                        p2 = etree.Element('pre', {"class": "error"})
                        tr = etree.Element('code')
                        p2.append(tr)
                        tr.text = ":::Python Traceback\n" + traceback.format_exc()
                        target.append(p2)
                        print '*', e
                        error = True
            target.append(element)
        if graphs and not error:
            response = self.make_response(graphs)
            if response:
                target.append(response)
        return root


class TestExtension(markdown.Extension):
    def __init__(self, buttons=False, hide_eg=True, delete_eg=False):
        self.buttons = buttons
        self.hide_eg = hide_eg
        self.delete_eg = delete_eg

    def extendMarkdown(self, md, md_globals):
        """ Add TestTreeprocessor to Markdown instance. """
        tester = TestTreeprocessor(md, self.buttons, self.hide_eg, self.delete_eg)
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
                    translations["%s:%s" % (idtag.get('ns'), idtag.get('id'))] = \
                        u"%s_%s:%s" % (idtag.get('ns'), lang, name_trans.sub("_", termtag.text))
                    break
        self.translations = translations

    def run(self, root):
        mlr_r = re.compile(r'\b(mlr[0-9]:(?:DES|RC)[0-9]+)')

        def trans(match):
            c = match.group(0)
            return self.translations.get(c, c)
        for code in root.iter("code"):
            t = code.text
            if isinstance(t, str):
                t = t.decode('utf-8')
            code.text = mlr_r.sub(trans, t)
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

    def __init__(self, md, delete_eg):
        self.delete_eg = delete_eg

    def run(self, root):
        html = etree.Element('html')
        body = etree.Element('body')
        head = etree.Element('head')
        link = etree.Element('link', {'href': "default.css", 'rel': "stylesheet", 'type': "text/css"})
        head.append(link)
        if not self.delete_eg:
            jquery = etree.Element('script', {'src': 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js'})
            head.append(jquery)
        html.append(head)
        html.append(body)
        if not self.delete_eg:
            buttons = etree.Element('p')
            button = etree.Element('button', {'onclick': "$('.example').show();"})
            button.text = 'Show'
            buttons.append(button)
            button.tail = ' or '
            button = etree.Element('button', {'onclick': "$('.example').hide();"})
            button.text = 'Hide'
            button.tail = ' all examples'
            buttons.append(button)
            body.append(buttons)
        elements = list(root)  # should be an iterator, but 2.6 getiterator vs 2.7 iter.
        for n in elements:
            root.remove(n)
            body.append(n)
        root.clear()
        root.append(html)
        return root


class EmbedExtension(markdown.Extension):
    def __init__(self, delete_eg=False):
        self.delete_eg = delete_eg

    def extendMarkdown(self, md, md_globals):
        """ Add Embed to Markdown instance. """
        embed = EmbedTreeprocessor(md, self.delete_eg)
        md.treeprocessors.add("embed", embed, "<inline")
        md.registerExtension(self)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Create the documentation file')
    parser.add_argument('-l', help='Express using language')
    parser.add_argument('-b', help='Add buttons for each example', default=False, action='store_true')
    parser.add_argument('--hide', help='Hide examples by default', default=False, action='store_true')
    parser.add_argument('--delete', help='Delete examples', default=False, action='store_true')
    parser.add_argument('--output', help='Output file name')
    args = parser.parse_args()
    extensions = [TestExtension(args.b, args.hide, args.delete), CodeHiliteExtension({}), EmbedExtension(args.delete)]
    target_name = args.output
    if not target_name:
        if args.l:
            target_name = 'documentation_%s.html' % (args.l,)
        else:
            target_name = 'documentation.html'
    if args.l:
        extensions.insert(1, TranslateMlrExtension(args.l))
        target_name = 'documentation_%s.html' % (args.l,)
    markdown.markdownFromFile(
        input='documentation.md',
        output=target_name,
        encoding='utf-8',
        extensions=extensions)
