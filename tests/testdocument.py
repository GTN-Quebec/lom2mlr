import re
import unittest
import sys

import markdown

from graph_comparison import GraphTester
from util import splitcode

HEADER_R = re.compile(r'^h[0-9]$', re.I)

graphtester = GraphTester()

def t_function(code, title):
    assert len(code) in range(2, 4)
    if len(code) == 2:
        code.append(('N3',''))
    assert [t.lower() for t, c in code] == ['xml','n3','n3']
    code = [c for t, c in code]
    obtained_graph, errors = graphtester.test_lom(*code)
    assert not errors, title+' '+`errors`

def test_document():
    m = markdown.Markdown()
    data = open('conversion.md').read().decode('utf-8')
    root = m.parser.parseDocument(data).getroot()
    elements = list(root) # should be an iterator, but 2.6 getiterator vs 2.7 iter. 
    code = []
    offset = 0
    for element in elements:
        if HEADER_R.match(element.tag):
            if code:
                t_function.description = title
                yield t_function, code, title
                code = []
            title = element.text
        if element.tag == 'pre':
            sub = list(element)
            assert len(sub) == 1 and sub[0].tag == 'code'
            code.append(splitcode(sub[0].text))
    if code:
        t_function.description = title
        yield t_function, code, title
