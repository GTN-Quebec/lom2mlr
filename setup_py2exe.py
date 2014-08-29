#!/usr/bin/env python

from distutils.core import setup
import py2exe
from glob import glob

data_files=['lom2mlr/lom2mlr.xsl',
                  'lom2mlr/iso639.xsl',
                  'lom2mlr/correspondances_xsl.xsl',
                  'lom2mlr/translations/translation.xml']
data_files.extend(glob('lom2mlr/vdex/ISO*.xsl'))
data_files.extend(glob('lom2mlr/vdex/*.vdex'))
data_files.extend(glob('lom2mlr/vdex/translation_*.xsl'))

requirements = open('requirements.txt').readlines()

setup(name='lom2mlr',
      version='0.1',
      description="Utilities to convert learning resources metadata "
      "from IEEE LOM to ISO-19788 format",
      author='Marc-Antoine Parent',
      author_email='map@ntic.org',
      url='https://github.com/GTN-Quebec/lom2mlr',
      data_files=data_files,
      options={'py2exe':{
		#'includes':['pyparsing', 'lxml', 'rdflib', 'python-dateutil', 'vobject', 'six', 'gzip', 'lxml._elementpath'],
		'packages':['lom2mlr', 'lom2mlr.validate', 'lom2mlr.markdown'],
		'bundle_files': 1
	}},
      tests_require=['nose'],
	console=['lom2mlr/transform.py'])
