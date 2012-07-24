#!/usr/bin/env python
# -*- coding: utf-8 -*-

from cgi import escape
import re
import traceback
import argparse
from collections import defaultdict

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


def stringify_error_element(n):
    try:
        return escape(n.n3())
    except AttributeError:
        return escape(u'"%s"' % (n))

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
            pass

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
                assert len(sub) == 1
                code_el = sub[0]
                assert code_el.tag == 'code'
                format, code, args = splitcode(code_el.text)
                code_el.text = ":::%s\n%s" % (format, code)  # remove args
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
                if format.lower() == 'xml':
                    try:
                        self.graph_tester.set_lom(code)
                    except Exception as e:
                        target.append(element)
                        p2 = etree.Element('pre', {"class": "error"})
                        tr = etree.Element('code')
                        p2.append(tr)
                        tr.text = ":::Python Traceback\n" + traceback.format_exc()
                        element = p2
                        print '*', e
                        error = True
                elif format.lower() == 'n3':
                    try:
                        graph, errors = self.graph_tester.test_n3(code, args)
                        if errors:
                            target.append(element)
                            diverrors = etree.Element('div', {"class": "error"})
                            p = etree.Element('p')
                            p.text = "Erreur. Obtenu: "
                            diverrors.append(p)
                            pre = etree.Element('pre')
                            diverrors.append(pre)
                            graph_e = etree.Element('code')
                            pre.append(graph_e)
                            result = graph.serialize(format='n3', encoding='utf-8')
                            graph_e.text = ':::N3\n' + self.remove_namespace(result).decode('utf-8')
                            for err_type, error in errors:
                                p = etree.Element('p')
                                error = tuple(map(stringify_error_element, error))
                                if err_type == GraphTester.MISSING:
                                    p.text = u"Il manque &lt; %s %s %s &gt;." % error
                                elif  err_type == GraphTester.UNEXPECTED:
                                    p.text = u"&lt; %s %s %s &lt; est présent et ne devrait pas l'être." % error
                                print '*', p.text
                                diverrors.append(p)
                            element = diverrors
                    except Exception as e:
                        target.append(element)
                        p2 = etree.Element('pre', {"class": "error"})
                        tr = etree.Element('code')
                        p2.append(tr)
                        tr.text = ":::Python Traceback\n" + traceback.format_exc()
                        element = p2
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


# Should I extract this from correspondances_type.xml?
vocabularies_for_DES = {
    "mlr3:DES0700": "ISO_IEC_19788-3-2011-VA.2",
    "mlr5:DES0800": "ISO_IEC_19788-5-2012-VA.1",
    "mlr5:DES0600": "ISO_IEC_19788-5-2012-VA.2",
    "mlr5:DES2100": "ISO_IEC_19788-5-2012-VA.3",
    "mlr5:DES2400": "ISO_IEC_19788-5-2012-VA.4",
    "mlr5:DES0300": "ISO_IEC_19788-5-2012-VA.5",
    "mlr8:DES1200": "ISO_IEC_19788-8-2012-VA.2.2"
}

VDEX_PREFIX = '{http://www.imsglobal.org/xsd/imsvdex_v1p0}'


class TranslateMlrTreeprocessor(Treeprocessor):
    "Translate mlr strings"

    mlr_r = re.compile(r'\b(mlr[0-9]:(?:DES|RC)[0-9]+)( "(T[0-9]+)")?')

    def __init__(self, md):
        name_trans = re.compile(u"[ '\u2019]")
        tree = etree.parse('translations/translation.xml')
        translations = defaultdict(dict)
        for idtag in tree.getiterator('id'):
            for termtag in idtag.getiterator('term'):
                lang = termtag.get('lang')
                translations[lang]["%s:%s" % (idtag.get('ns'), idtag.get('id'))] = \
                    u"%s_%s:%s" % (idtag.get('ns'), lang, name_trans.sub("_", termtag.text))
        self.translations = translations
        vocs = {}

        for voc in vocabularies_for_DES.values():
            vocs[voc] = defaultdict(dict)
            tree = etree.parse('vdex/%s.vdex' % (voc))
            for term in tree.findall(VDEX_PREFIX + 'term'):
                id = str(term.find(VDEX_PREFIX + 'termIdentifier').text)
                captions = term.find(VDEX_PREFIX + 'caption')
                for cap in captions.findall(VDEX_PREFIX + 'langstring'):
                    vocs[voc][str(cap.get('language'))][id] = cap.text
        self.vocabularies = vocs

    def _trans(self, lang, match):
        c = match.group(1)
        t = match.group(3)
        if t:
            trans = self.vocabularies[vocabularies_for_DES[c]][lang].get(str(t))
            if trans:
                t = ' "%s"@%s' % (trans, lang)
            else:
                t = ' "%s"' % (t, )
        else:
            t = ''
        return self.translations[lang].get(c, c) + t

    def run(self, root):
        for div in root.iter("div"):
            if div.get("class") != 'example':
                continue
            div_els = div.getchildren()
            div.clear()
            count = 0
            for el in div_els:
                if el.tag == 'pre':
                    if count == 0:
                        css_class = "lom"
                    else:
                        css_class = "n3 mlr"
                    new_div = etree.Element('div', {'class': css_class})
                    div.append(new_div)
                    new_div.append(el)
                    if count > 0:
                        code = [e for e in el.getchildren() if e.tag == 'code']
                        if not code:
                            print "missing code"
                            continue
                        code = code[0]
                        t = code.text
                        if isinstance(t, str):
                            t = t.decode('utf-8')
                        for lang in self.translations.keys():
                            new_div = etree.Element('div', {'class': 'n3 lang_' + lang})
                            div.append(new_div)
                            new_pre = etree.Element('pre')
                            new_div.append(new_pre)
                            new_code = etree.Element('code')
                            new_pre.append(new_code)
                            new_code.text = self.mlr_r.sub(lambda m: self._trans(lang, m), t)
                    count += 1
                else:
                    div.append(el)
        return root


class TranslateMlrExtension(markdown.Extension):
    def extendMarkdown(self, md, md_globals):
        """ Add Embed to Markdown instance. """
        translateMlr = TranslateMlrTreeprocessor(md)
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
        langs = set(('fra', 'eng', 'rus'))
        if not self.delete_eg:
            div = etree.Element('div', {'class': 'controls'})
            form = etree.Element('form')
            div.append(form)
            button = etree.Element('input', {'type': 'radio', 'checked': 'checked', 'name': 'lang', 'onclick': "$('.n3').hide();$('.mlr').show();"})
            button.tail = 'MLR '
            form.append(button)
            for lang in langs:
                button = etree.Element('input', {'type': 'radio', 'name': 'lang', 'onclick': "$('.n3').hide();$('.lang_" + lang + "').show();"})
                button.tail = lang + " "
                form.append(button)
            body.append(div)
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
    parser.add_argument('-l', help='Give language translations', default=False, action='store_true')
    parser.add_argument('-b', help='Add buttons for each example', default=False, action='store_true')
    parser.add_argument('--hide', help='Hide examples by default', default=False, action='store_true')
    parser.add_argument('--delete', help='Delete examples', default=False, action='store_true')
    parser.add_argument('--output', help='Output file name', default="documentation.html")
    args = parser.parse_args()
    extensions = [TestExtension(args.b, args.hide, args.delete), CodeHiliteExtension({}), EmbedExtension(args.delete)]
    target_name = args.output
    if args.l:
        extensions.insert(1, TranslateMlrExtension())
    markdown.markdownFromFile(
        input='documentation.md',
        output=args.output,
        encoding='utf-8',
        extensions=extensions)
