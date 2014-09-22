# -*- mode: python -*-
from sys import platform
from glob import glob
from os.path import abspath, join, basename

data_files = [
  (basename(f), abspath(f), 'DATA')
  for f in (
    'lom2mlr/lom2mlr.xsl',
    'lom2mlr/iso639.xsl',
    'lom2mlr/correspondances_xsl.xsl')
] + [
  (join('translations', basename(f)), abspath(f), 'DATA')
  for f in glob('lom2mlr/translations/translation_*.xsl') + ['lom2mlr/translations/translation.xml']
] + [
  (join('vdex', basename(f)), abspath(f), 'DATA')
  for f in glob('lom2mlr/vdex/ISO*.xsl') + glob('lom2mlr/vdex/*.vdex')
]

name = 'lom2mlr'
if platform.lower().startswith('win'):
  name += '.exe'

a = Analysis(['lom2mlr/transform.py'],
             pathex=[abspath('.')],
             hiddenimports=[],
             hookspath=None,
             runtime_hooks=None)
pyz = PYZ(a.pure)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas + data_files,
          name=name,
          debug=False,
          strip=None,
          upx=True,
          console=True )
