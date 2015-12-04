#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

from __future__ import print_function

__doc__ = """The :py:class:`SchemaFixer` do various fix on XML shema coming from ENS Lyon OAI.

TODO: propose a true hooks system
"""
__docformat__ = "restructuredtext en"

from lxml import etree
from lxml.etree import Element
from lxml import objectify

from os import listdir
from os.path import exists
from os.path import isdir
from os.path import sep as path_sep

from sys import argv

class SchemaFixer(object):
    """"""

    def __init__(self, folder):
        """Constructor"""

        if not isdir(folder):
            raise TypeError("Not a path to a directory: "+folder)

        self.folder_path = folder

    def walkDirectories(self, folder_path):
        """ Main working loop

        It follows subdirectory and executes fixes sequentially on each file.
        """
        for filename in listdir(folder_path):
            file_path = folder_path+path_sep+filename
            if isdir(file_path):
                self.walkDirectories(file_path)
            else:
                file_xml = open(file_path, mode='rw')
                tree = etree.parse(file_xml)

                if tree.getpath(tree.getroot()).startswith('/lom:'):
                    namespaces = {
                        'lom':      'http://ltsc.ieee.org/xsd/LOM',
                        'lomfr':    'http://www.lom-fr.fr/xsd/LOMFR',
                        'lomfrens': 'http://pratic.ens-lyon.fr/xsd/LOMFRENS',
                    }
                else:
                    namespaces = {}

                # Run fixes
                self.fix01FixNamespace(tree, namespaces)
                self.fix10MissingIdentifier(tree, namespaces=namespaces,
                                            **{'filename': filename})
                self.fix20FixFrenchISO639_3(tree, namespaces)

                tree.write(file_path, pretty_print=True, encoding='UTF-8')

    def fix01FixNamespace(self, tree, namespaces={}, **kwargs):
        """Remove unused namespaces

        :type xml: :lxml-class:`_ElementTree`
        :param xml: the parsed LOM record.
        :param namespaces: the needed namespaces.
        :param kwargs: additionnal parameters mandatory for this fix
        """
        root = tree.getroot()
        objectify.deannotate(root, cleanup_namespaces=True)

    def fix10MissingIdentifier(self, tree, namespaces={}, **kwargs):
        """Fix missing lom/metaMetadata/identifier

        :type xml: :lxml-class:`_ElementTree`
        :param xml: the parsed LOM record.
        :param namespaces: the needed namespaces.
        :param kwargs: additionnal parameters mandatory for this fix
        """
        filename = kwargs.get('filename')

        if namespaces:
            meta_id_xpath     = '//lom:metaMetadata/lom:identifier/lom:entry'
            meta_cat_xpath    = '//lom:metaMetadata/lom:catalog/lom:entry'
            general_id_xpath  = '//lom:general/lom:identifier/lom:entry'
            general_cat_xpath = '//lom:general/lom:identifier/lom:catalog'
        else:
            meta_id_xpath     = '//metaMetadata/identifier/entry'
            meta_cat_xpath    = '//metaMetadata/catalog/entry'
            general_id_xpath  = '//general/identifier/entry'
            general_cat_xpath = '//general/identifier/catalog'

        meta_id  = tree.xpath(meta_id_xpath, namespaces=namespaces)
        meta_cat = tree.xpath(meta_cat_xpath, namespaces=namespaces)
        if not meta_id:
            general_id  = tree.xpath(general_id_xpath, namespaces=namespaces)[0].text
            general_cat = tree.xpath(general_cat_xpath, namespaces=namespaces)[0].text
            meta_entry  = general_id.split('/')[0]+'/metadata/'+filename
            meta_cat = u"méta"+general_cat

            if namespaces:
                meta_elem = tree.xpath('//lom:metaMetadata', namespaces=namespaces)[0]
                meta_elem.insert(0, Element(u'{%s}identifier' % namespaces['lom']))
                # Use XPath to be sure the element is created in the right place
                id_elem = tree.xpath('//lom:metaMetadata/lom:identifier', namespaces=namespaces)[0]
                cat_elem = Element(u'{%s}catalog' % namespaces['lom'])
                cat_elem.text = meta_cat
                id_elem.append(cat_elem)
                entry_elem = Element(u'{%s}entry' % namespaces['lom'])
                entry_elem.text = meta_entry
                id_elem.append(entry_elem)
            else:
                meta_elem = tree.xpath('//metaMetadata')[0]
                meta_elem.insert(0, meta_elem.makeelement(u'identifier'))
                id_elem = tree.xpath('//metaMetadata/identifier')[0]
                cat_elem = Element(u'catalog')
                cat_elem.text = meta_cat
                id_elem.append(cat_elem)
                entry_elem = Element(u'entry')
                entry_elem.text = meta_entry
                id_elem.append(entry_elem)

    def fix20FixFrenchISO639_3(self, tree, namespaces={}, **kwargs):
        """Remove unused namespaces

        :type xml: :lxml-class:`_ElementTree`
        :param xml: the parsed LOM record.
        :param namespaces: the needed namespaces.
        :param kwargs: additionnal parameters mandatory for this fix
        """
        root = tree.getroot()
        nodes = root.xpath("//lom:string", namespaces=namespaces)
        for node in nodes:
            if node.get('language') == 'fre':
                node.set('language', 'fra')

def main():
    usage = "Usage: %s target_folder" % argv[0]
    if len(argv) != 2:
        raise IndexError('Only one argument, no option\n\n'+usage)

    fixer = SchemaFixer(argv[1])
    fixer.walkDirectories(fixer.folder_path)


if __name__ == '__main__':
    main()