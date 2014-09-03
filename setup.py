#!/usr/bin/env python

from setuptools import setup
from glob import glob
try:
  import py2exe
except:
  pass

core_data_files = [
  'lom2mlr/lom2mlr.xsl',
  'lom2mlr/iso639.xsl',
  'lom2mlr/correspondances_xsl.xsl']
translations_files = glob('lom2mlr/translations/translation_*.xsl')
translations_files.append('lom2mlr/translations/translation.xml')
vdex_files = glob('lom2mlr/vdex/ISO*.xsl')
vdex_files.extend(glob('lom2mlr/vdex/*.vdex'))

data_files=[('', core_data_files),
            ('translations', translations_files),
            ('vdex', vdex_files)]

requirements = open('requirements.txt').readlines()

setup(name='lom2mlr',
      version='0.1',
      description="Utilities to convert learning resources metadata "
      "from IEEE LOM to ISO-19788 format",
      author='Marc-Antoine Parent',
      author_email='map@ntic.org',
      url='https://github.com/GTN-Quebec/lom2mlr',
      packages=['lom2mlr', 'lom2mlr.markdown', 'lom2mlr.validate'],
      package_data={
        'lom2mlr': core_data_files + translations_files + vdex_files},
      data_files=data_files,
      install_requires=requirements,
      tests_require=['nose'],
      entry_points={
          'console_scripts': [
              'lom2mlr = lom2mlr.transform:main',
              'lom2mlr_markdown = lom2mlr.markdown:compile'
          ]
      },
      console=['lom2mlr/transform.py'],
      options={'py2exe':{
        #'includes':['pyparsing', 'lxml', 'rdflib', 'python-dateutil', 'vobject', 'six', 'gzip', 'lxml._elementpath'],
        'packages':['lom2mlr', 'lom2mlr.validate', 'lom2mlr.markdown'],
        'bundle_files': 1
      }}
      )
