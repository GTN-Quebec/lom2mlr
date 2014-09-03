#!/usr/bin/python

import sys
import re
from os.path import basename, splitext

TRE = re.compile('^T[0-9]+$')


def make_vdex(fname):
    vocname = splitext(basename(fname))[0]
    target = splitext(fname)[0] + '.vdex'
    lines = open(fname).readlines()
    langs = lines.pop(0).split()
    hasdef = True
    if langs[0] == 'nodef':
        hasdef = False
        langs.pop(0)
    with open(target, 'w') as f:
        f.write("""<?xml version="1.0" encoding="utf-8"?>
<vdex:vdex xmlns:vdex="http://www.imsglobal.org/xsd/imsvdex_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xsi:schemaLocation="http://www.imsglobal.org/xsd/imsvdex_v1p0 http://www.imsglobal.org/xsd/imsvdex_v1p0.xsd" xs:version="0.2">
<vdex:vocabIdentifier isRegistered="false">%s</vdex:vocabIdentifier>\n""" % (vocname))
        while lines:
            caps = {}
            defs = {}
            id = lines.pop(0).strip()
            if not TRE.match(id):
                sys.stderr.write("error, not TXXX:" + id)
                break
            for lang in langs:
                l = lines.pop(0).strip()
                if TRE.match(l):
                    sys.stderr.write("error, TXXX %s while expecting cap of %s" % (l, lang))
                    break
                caps[lang] = l
                if hasdef:
                    l = lines.pop(0).strip()
                    if TRE.match(l):
                        sys.stderr.write("error, TXXX %s while expecting def of %s" % (l, lang))
                        break
                    defs[lang] = l
            f.write("""  <vdex:term>
    <vdex:termIdentifier>%s</vdex:termIdentifier>
    <vdex:caption>\n""" % (id,))
            for lang in langs:
                if caps[lang]:
                    f.write("        <vdex:langstring language=\"%s\">%s</vdex:langstring>\n" % (lang, caps[lang]))
            f.write("    </vdex:caption>\n")
            if [x for x in defs.itervalues() if x]:
                f.write("    <vdex:description>\n")
                for lang in langs:
                    if defs[lang]:
                        f.write("        <vdex:langstring language=\"%s\">%s</vdex:langstring>\n" % (lang, defs[lang]))
                f.write("    </vdex:description>\n")
            f.write("  </vdex:term>\n")
        f.write("</vdex:vdex>\n")

if __name__ == '__main__':
    make_vdex(sys.argv[1])
