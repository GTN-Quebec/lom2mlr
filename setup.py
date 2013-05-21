#!/usr/bin/env python

from setuptools import setup

setup(name='lom2mlr',
      version='0.1',
      description="Utilities to convert learning resources metadata "
      "from IEEE LOM to ISO-19788 format",
      author='Marc-Antoine Parent',
      author_email='map@ntic.org',
      url='https://github.com/GTN-Quebec/lom2mlr',
      packages=['lom2mlr', 'lom2mlr.markdown', 'lom2mlr.validate'],
      package_data={'lom2mlr': ['lom2mlr.xsl',
                                'iso639.xsl',
                                'correspondances_xsl.xsl',
                                'vdex/ISO*.xsl',
                                'vdex/*.vdex',
                                'translations/translation.xml',
                                'translations/translation_*.xsl'
                                ]
                    },
      install_requires=[
          'vobject==0.8.1c',
          'lxml>=2.3',
          'python-dateutil<2.0',
          'rdflib>=4.0',
          'isodate',
          'pygments',
          'Markdown'
      ],
      tests_require=['nose'],
      entry_points={
          'console_scripts': [
              'lom2mlr = lom2mlr.transform:main',
              'lom2mlr_markdown = lom2mlr.markdown:compile'
          ]
      }
      )
