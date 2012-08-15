#!/usr/bin/env python
# -*- coding: utf-8 -*-

import markdown
from markdown.treeprocessors import Treeprocessor
from markdown.util import etree


class EmbedTreeprocessor(Treeprocessor):
    "Embed the root in html/body tags."

    def __init__(self, md, delete_eg, trans):
        self.delete_eg = delete_eg
        self.trans = trans

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
        if self.trans and not self.delete_eg:
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
    def __init__(self, delete_eg=False, trans=False):
        self.delete_eg = delete_eg
        self.trans = trans

    def extendMarkdown(self, md, md_globals):
        """ Add Embed to Markdown instance. """
        embed = EmbedTreeprocessor(md, self.delete_eg, self.trans)
        md.treeprocessors.add("embed", embed, "<inline")
        md.registerExtension(self)
