#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""A :markdown-ext:`treeprocessors` that adds translated versions of N3 MLR fragments."""

import re
import os.path
from collections import defaultdict

#Hack pour importer sw sans le mettre dans pygments
from . import sw
import pygments.plugin
pygments.plugin.find_plugin_lexers = lambda: [sw.Notation3Lexer]

import markdown
from markdown.treeprocessors import Treeprocessor
from markdown.util import etree


# TODO: Extract this from correspondances_type.xml
vocabularies_for_DES = {
    "mlr2:DES0800": "ISO_IEC_19788-3-2011-VA.2",
    "mlr5:DES0800": "ISO_IEC_19788-5-2012-VA.1",
    "mlr5:DES0600": "ISO_IEC_19788-5-2012-VA.2",
    "mlr5:DES2100": "ISO_IEC_19788-5-2012-VA.3",
    "mlr5:DES2400": "ISO_IEC_19788-5-2012-VA.4",
    "mlr5:DES0300": "ISO_IEC_19788-5-2012-VA.5",
    "mlr9:DES1900": "ISO_IEC_19788-9-2014-VA.2.1",
}

VDEX_PREFIX = '{http://www.imsglobal.org/xsd/imsvdex_v1p0}'

this_dir, this_filename = os.path.split(__file__)
head_dir = os.path.split(this_dir)[0]
TRANSLATION_FILE = os.path.join(head_dir, 'translations', 'translation.xml')
VDEX_DIR = os.path.join(head_dir, 'vdex')


class TranslateMlrTreeprocessor(Treeprocessor):
    "Translate mlr strings in N3 code fragments marked as MLR."

    mlr_r = re.compile(r'\b(mlr[0-9]:(?:DES|RC)[0-9]+)( "(T[0-9]+)")?')

    def __init__(self, md):
        name_trans = re.compile(u"[ '\u2019]")
        tree = etree.parse(TRANSLATION_FILE)
        translations = defaultdict(dict)
        for idtag in tree.getiterator('id'):
            for termtag in idtag.getiterator('term'):
                lang = termtag.get('lang')
                translations[lang]["%s:%s" % (idtag.get('ns'), idtag.get('id'))] = \
                    u"%s:%s" % (idtag.get('ns'), name_trans.sub("_", termtag.text))
#                   u"%s_%s:%s" % (idtag.get('ns'), lang, name_trans.sub("_", termtag.text))
        self.translations = translations
        vocs = {}

        for voc in vocabularies_for_DES.itervalues():
            vocs[voc] = defaultdict(dict)
            tree = etree.parse(os.path.join(VDEX_DIR, '%s.vdex' % (voc)))
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
        for div in root.getiterator("div"):
            if div.get("class") != 'example':
                continue
            div_els = div.getchildren()
            div.clear()
            for el in div_els:
                div.append(el)
                classes = set(el.get("class", "").split())
                if 'mlr' in classes:
                    classes.remove('mlr')
                    pre = [e for e in el.getchildren() if e.tag == 'pre']
                    assert len(pre) == 1
                    pre = pre[0]
                    code = [e for e in pre.getchildren() if e.tag == 'code']
                    assert len(code) == 1
                    code = code[0]
                    t = code.text
                    if isinstance(t, str):
                        t = t.decode('utf-8')
                    for lang in self.translations.iterkeys():
                        cl = classes.copy()
                        cl.add('lang_' + lang)
                        new_div = etree.Element('div', {'class': ' '.join(cl)})
                        div.append(new_div)
                        new_pre = etree.Element('pre')
                        new_div.append(new_pre)
                        new_code = etree.Element('code')
                        new_pre.append(new_code)
                        new_code.text = self.mlr_r.sub(lambda m: self._trans(lang, m), t)
        return root


class TranslateMlrExtension(markdown.Extension):
    def extendMarkdown(self, md, md_globals):
        """ Add Embed to Markdown instance. """
        translateMlr = TranslateMlrTreeprocessor(md)
        md.treeprocessors.add("translateMlr", translateMlr, "<inline")
        md.registerExtension(self)
