# -*- coding: utf-8 -*-
#
# Sphinx documentation build configuration file

import re
import sphinx

extensions = ['sphinx.ext.autodoc', 'sphinx.ext.doctest', 'sphinx.ext.todo',
              'sphinx.ext.autosummary', 'sphinx.ext.extlinks',
              'sphinx.ext.intersphinx']

master_doc = 'index'
#templates_path = ['_templates']
exclude_patterns = ['_build']

autodoc_default_flags = ['members', 'undoc-members',
                         'show-inheritance', 'synopsis']

project = 'lom2mlr'
copyright = u'2012, GTN-Qu\u00e9bec'
#version = lom2mlr.__released__
version = "0.1"
release = version
show_authors = True

html_theme = 'sphinxdoc'
modindex_common_prefix = ['lom2mlr.']
html_static_path = ['_static']
html_sidebars = {}  # 'index': ['indexsidebar.html', 'searchbox.html']}
# html_additional_pages = {'index': 'index.rst'}
html_use_opensearch = 'https://github.com/GTN-Quebec/lom2mlr'

htmlhelp_basename = 'lom2mlr'

epub_theme = 'epub'
epub_basename = 'lom2mlr'
epub_author = 'Marc-Antoine Parent'
epub_publisher = 'https://gtn-quebec.org/'
epub_scheme = 'url'
epub_identifier = epub_publisher
epub_pre_files = [('index.html', 'Welcome')]
epub_exclude_files = ['_static/opensearch.xml', '_static/doctools.js',
                      '_static/jquery.js', '_static/searchtools.js',
                      '_static/underscore.js', '_static/basic.css',
                      'search.html']

latex_documents = [('contents', 'lom2mlr.tex', 'Lom2MLR Documentation',
                    'Marc-Antoine Parent', 'manual', 1)]
#latex_logo = '_static/lom2mlr.png'
latex_elements = {
    'fontpkg': '\\usepackage{palatino}',
}
latex_show_urls = 'footnote'

autodoc_member_order = 'groupwise'
todo_include_todos = True

extlinks = {
    'rdflib_api': ('https://rdflib.readthedocs.org/en/latest/_static/api/'
                   'index.html#%s', ''),
    'markdown-ext': ('http://packages.python.org/Markdown/extensions/api.html#%s', ''),
    'etree': ('http://effbot.org/zone/element.htm#%s', ''),
    'lxml-func': ('http://lxml.de/api/lxml.etree-module.html#%s', 'lxml.etree.'),
    'lxml-class': ('http://lxml.de/api/lxml.etree.%s-class.html', 'lxml.etree.'),
    'vobject-func': ('http://vobject.skyhouseconsulting.com/epydoc/public/vobject.vobject-module.html#%s', 'vobject.vobject.'),
    'vobject-class': ('http://vobject.skyhouseconsulting.com/epydoc/public/vobject.vobject.%s-class.html', 'vobject.vobject.'),
    'vcard-func': ('http://vobject.skyhouseconsulting.com/epydoc/public/vobject.vcard-module.html#%s', 'vobject.vcard.'),
    'vcard-class': ('http://vobject.skyhouseconsulting.com/epydoc/public/vobject.vcard.%s-class.html', 'vobject.vcard.'),
    }

man_pages = [
    ('contents', 'lom2mlr-all', 'lom2mlr transformation engine',
     'Marc-Antoine Parent', 1),
]

texinfo_documents = [
    ('contents', 'lom2mlr', 'lom2mlr Documentation', 'Marc-Antoine Parent',
     'lom2mlr', 'The lom2mlr transformation engine.', 'Documentation tools',
     1),
]

intersphinx_mapping = {
    'python': ('http://docs.python.org/2.7/', None),
    'rdflib': ('http://rdflib.readthedocs.org/en/latest/', None)}


# -- Extension interface ------------------------------------------------------

from sphinx import addnodes


event_sig_re = re.compile(r'([a-zA-Z-]+)\s*\((.*)\)')


def parse_event(env, sig, signode):
    m = event_sig_re.match(sig)
    if not m:
        signode += addnodes.desc_name(sig, sig)
        return sig
    name, args = m.groups()
    signode += addnodes.desc_name(name, name)
    plist = addnodes.desc_parameterlist()
    for arg in args.split(','):
        arg = arg.strip()
        plist += addnodes.desc_parameter(arg, arg)
    signode += plist
    return name


def setup(app):
    from sphinx.ext.autodoc import cut_lines
    from sphinx.util.docfields import GroupedField
    #app.connect('autodoc-process-docstring', cut_lines(4, what=['module']))
    app.add_object_type('confval', 'confval',
                        objname='configuration value',
                        indextemplate='pair: %s; configuration value')
    fdesc = GroupedField('parameter', label='Parameters',
                         names=['param'], can_collapse=True)
    app.add_object_type('event', 'event', 'pair: %s; event', parse_event,
                        doc_field_types=[fdesc])
