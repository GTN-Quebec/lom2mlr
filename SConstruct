import os.path
from functools import partial

from lxml import etree

from lom2mlr.vdex.make_vdex import make_vdex

builders = {}


LANGS = ('eng', 'fra', 'rus')

def apply_stylesheet(sheet, params, target, source, env):
    assert len(source) == 1, source
    assert len(target) == 1, target
    source = etree.parse(source[0].get_path())
    result = sheet(source, **params)
    with open(target[0].get_path(), 'w') as f:
        f.write(etree.tounicode(result, pretty_print=True).encode('utf-8'))

trans_to_lang_sheet = etree.XSLT(etree.parse(
    os.path.join('lom2mlr', 'translations', 'make_translation_tolang.xsl')))
trans_from_lang_sheet = etree.XSLT(etree.parse(
    os.path.join('lom2mlr', 'translations', 'make_translation_fromlang.xsl')))
vdex_to_lang_sheet = etree.XSLT(etree.parse(
    os.path.join('lom2mlr', 'vdex', 'make_translation_tolang.xsl')))
vdex_from_lang_sheet = etree.XSLT(etree.parse(
    os.path.join('lom2mlr', 'vdex', 'make_translation_fromlang.xsl')))
skos_sheet =  etree.XSLT(etree.parse(
    os.path.join('lom2mlr', 'vdex', 'vdex2skos.xsl')))
correspondances_sheet =  etree.XSLT(etree.parse(
    os.path.join('lom2mlr', 'correspondances.xsl')))

trans_lang_builders = dict(
    ("Trans_" + lang,
        Builder(action = partial(apply_stylesheet, trans_to_lang_sheet, {'lang': "'%s'" % (lang, )}),
                  suffix = '_%s.xsl' % (lang,),
                  src_suffix = '.xml'))
    for lang in LANGS
)

builders.update(trans_lang_builders)

builders['Trans_mlr'] = Builder(
    action = partial(apply_stylesheet, trans_from_lang_sheet, {}),
    suffix = '_mlr.xsl',
    src_suffix = '.xml')


vdex_lang_builders = dict(
    ("Vdex_" + lang,
        Builder(action = partial(apply_stylesheet, vdex_to_lang_sheet, {'lang': "'%s'" % (lang, )}),
                  suffix = '_%s.xsl' % (lang,),
                  src_suffix = '.vdex'))
    for lang in LANGS
)

builders.update(vdex_lang_builders)
builders['Vdex_mlr'] = Builder(
    action = partial(apply_stylesheet, vdex_from_lang_sheet, {}),
    suffix = '_mlr.xsl',
    src_suffix = '.vdex')
builders['Vdex_skos'] = Builder(
    action = partial(apply_stylesheet, skos_sheet, {}),
    suffix = '.skos',
    src_suffix = '.vdex')

builders['Correspondances'] = Builder(
    action = partial(apply_stylesheet, correspondances_sheet, {}),
    suffix = '_xsl.xsl',
    src_suffix = '_type.xml')

def process_vdex(env, sources):
    """Process vdex"""
    l = []
    for source in sources:
        l.extend([getattr(env, 'Vdex_' + lang )(source) for lang in LANGS])
        l.append(env.Vdex_mlr(source))
        l.append(env.Vdex_skos(source))
    return l

def process_trans(env, source):
    """Process vdex"""
    l = [getattr(env, 'Trans_' + lang )(source) for lang in LANGS]
    l.append(env.Trans_mlr(source))
    return l

def make_vdex_scons(target, source, env):
    assert len(source) == 1, source
    make_vdex(source[0].get_path())

builders['Txt_Vdex'] = Builder(action = make_vdex_scons,
                     suffix = '.vdex',
                     src_suffix = '.txt')

env = Environment(BUILDERS=builders)
env.AddMethod(process_vdex, "Process_vdex")
env.AddMethod(process_trans, "Process_trans")
env.Process_trans('lom2mlr/translations/translation.xml')
vdex_targets = []
for vdex in Glob('lom2mlr/vdex/*.txt'):
    vdex_targets.extend(env.Txt_Vdex(vdex))
env.Process_vdex(vdex_targets)
env.Correspondances('lom2mlr/correspondances_type.xml')
