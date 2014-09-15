#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""A :markdown-ext:`treeprocessors` that treats LOM fragments followed by MLR fragments as doctests."""

from __future__ import print_function

from cgi import escape
import re
import traceback

import markdown
from markdown.treeprocessors import Treeprocessor
from markdown.util import etree

from lom2mlr.validate.graph_comparison import GraphTester
from lom2mlr.util import splitcode


HEADER_R = re.compile(r'^h[1-9]$', re.I)


def stringify_error_element(n):
    try:
        return escape(n.n3())
    except AttributeError:
        return escape(u'"%s"' % (n))


class TestTreeprocessor(Treeprocessor):
    """Treats a series of code fragments in a markdown document as a doctest.

    Moreover, the results of the doctest are embedded in the resulting document.
    XML fragments are assumed to be LOM fragments,
    and are transformed into MLR by a Converter.
    N3 fragments are assumed to be MLR fragments.
    Each triple in a N3 fragment is required to be found
    in the MLR generated from the previous LOM fragment.
    Some N3 fragments are forbidden: triples from such fragments found
    in the MLR generated from the previous LOM fragment
    AND not in the previous (required) N3 fragment constitute an error.
    The comparison uses the GraphTester.
    """
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
                print(" " * int(element.tag[1]) + element.text)
            elif element.tag == 'pre':
                sub = list(element)
                assert len(sub) == 1
                code_el = sub[0]
                assert code_el.tag == 'code'
                format, code, args = splitcode(code_el.text)
                code_el.text = ":::%s\n%s" % (format, code)  # remove args
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
                        print('*', e)
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
                                print('*', p.text)
                                diverrors.append(p)
                            element = diverrors
                    except Exception as e:
                        target.append(element)
                        p2 = etree.Element('pre', {"class": "error"})
                        tr = etree.Element('code')
                        p2.append(tr)
                        tr.text = ":::Python Traceback\n" + traceback.format_exc()
                        element = p2
                        print('*', e)
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
