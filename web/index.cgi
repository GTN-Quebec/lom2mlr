#!/usr/bin/python
# coding=utf-8

import cgi
import os
import os.path
import sys
from urlparse import parse_qs
from lom2mlr.transform import Converter
from lxml import etree

# import cgitb
# cgitb.enable()

rdf_types = {
    'application/rdf+xml': None,
    # 'application/rdf+xml': 'xml',
    # 'application/rdf+xml': 'pretty-xml',
    'text/plain': 'nt',
    'text/n3': 'n3',
    'text/rdf+n3': 'n3',
    'text/turtle': 'turtle',
    'text/x-turtle': 'turtle',
    'text/x-nquads': 'nquads',
    'application/trix': 'trix',
    'application/x-trig': 'trig',
    'application/ld+json': 'json-ld',
    #'application/rdf+json': 'rdfjson',
    #'application/xhtml+xml': 'rdfa',
}

type_by_serializer = dict([(v, k) for k, v in rdf_types.items()])
type_by_serializer['pretty-xml'] = 'application/rdf+xml'


def parse_accept():
    accept = os.environ['HTTP_ACCEPT']
    for t in accept.split(','):
        t = t.split(';')[0]
        if t in rdf_types:
            return (accept, rdf_types[t])
    return ('application/rdf+xml', None)


if __name__ == '__main__':
    method = os.environ['REQUEST_METHOD'].upper()
    form = cgi.FieldStorage()
    converter = Converter()
    boolean_options = set()
    for k, v in converter.option_defaults.items():
        if v in ('true()', 'false()'):
            boolean_options.add(k)
    if method == 'GET':
        print 'Content-type:', 'text/html'
        print
        qs = dict([(k, form.getfirst(k)) for k in form.keys()])
        print "<html><head><title>LOM to MLR Converter</title></head><body>"
        print "<h1>LOM to MLR converter</h1>"
        print """<p>This project aims to convert Learning Object Metadata, 
        <a href="http://ltsc.ieee.org/wg12/files/LOM_1484_12_1_v1_Final_Draft.pdf">IEEE 1484.12.1-2002</a>
        into Metadata for Learning Resources,
        <a href="http://www.iso.org/iso/iso_catalogue/catalogue_tc/catalogue_detail.htm?csnumber=50772">ISO/IEC 19788-1:2011</a>.</p>
        <p>The source is available on <a href="https://github.com/gtn-Quebec/lom2mlr">Github</a>,
        and the heuristics used are described <a href="rationale.html">here</a>.</p>"""
        print "<form method='POST' enctype='multipart/form-data' action='index.cgi'>"
        for option, desc in converter.sheet_options.iteritems():
            default = converter.option_defaults[option]
            if default in ('true()', 'false()'):
                if qs.get(option, '').lower() in ('true', 'false'):
                    qs[option] = 'checked'
                value = qs.get(option, default)
                print '<p><input name="%s" type="checkbox" %s /><label>%s</label>' % (
                    option, ("checked='checked'" if default=="true()" else ''), option)
            else:
                value = qs.get(option, default).strip("'")
                print "<p><label>%s</label>: <input name='%s' type='text' value='%s'></input>" % (
                    option, option, value)
            print "<br/>%s</p>" % (desc, )
        print "<p><label>Language</label>: <select name='language'>"
        print "<option value='' selected='selected'>None</option>"
        print "<option value='eng'>English</option>"
        print "<option value='fra'>Français</option>"
        print "<option value='rus'>Русский</option>"
        print "</select></p>"
        print "<p><label>Format</label>: <select name='format'>"
        print "<option value='' selected='selected'>Raw XML</option>"
        print "<option value='pretty-xml'>RDF-XML (prettified)</option>"
        print "<option value='turtle'>Turtle</option>"
        print "<option value='n3'>N3</option>"
        #print "<option value='json-ld'>JSON-LD</option>"
        print "<option value='nt'>N-Triples</option>"
        #print "<option value='nquads'>N-Quads</option>"
        #print "<option value='trix'>Trix</option>"
        print "<option value='trig'>Trig</option>"
        print "</select></p>"
        print "<input name='lomfile' type='file' accept='application/xml'/>"
        print "<input type='submit' />"
        print "</form></body></html>"
    elif method == 'POST':
        mimetype, rdfserializer = parse_accept()
        if form.headers['content-type'].startswith('multipart/form-data'):
            qs = dict([(k, form.getfirst(k)) for k in form.keys()
                       if k not in ('lomfile', 'converte_id')])
            lomdata = form['lomfile'].file
        else:
            # RESTful
            lomdata = form.file
            #lomdata = form.value
            qs = parse_qs(form.qs_on_post)
            qs = dict([(k, v[0]) for k, v in qs.items()])
        for option in boolean_options:
            qs[option] = 'true()' if option in qs else 'false()'
        lang = qs.get('language', None)
        if qs.get('format', None) in type_by_serializer:
            rdfserializer = qs.get('format')
            mimetype = type_by_serializer.get(rdfserializer, mimetype)
        print 'Content-type:', mimetype
        print
        # for option in qs:
        #     if option not in boolean_options:
        #         qs[option] = "'%s'" % qs[option]
        converter.set_options_from_dict(qs)
        if rdfserializer:
            rdf = converter.lomfile2graph(lomdata, lang=lang)
            if rdf:
                print rdf.serialize(format=rdfserializer, encoding='utf-8')
        else:
            xml = converter.lomfile2rdfxml(lomdata, lang=lang)
            if xml:
                print etree.tounicode(
                    xml, pretty_print=True).encode('utf-8')
