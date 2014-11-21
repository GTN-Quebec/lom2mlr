#!/usr/bin/env python

import xml.etree.ElementTree as ET
import argparse

def parse_all_file(filenames):
    return [ET.parse(filename) for filename in filenames]

def merge_root(main, other):
    for ogroup in other:
        for mgroup in main:
            # correpondances.xsl use only attributes 'dest' and 'always'
            # Other attributes are useless (for now ?)
            # We only check with used attributes for equality of groups
            if ogroup.get('dest') == mgroup.get('dest') and ogroup.get('always') == mgroup.get('always'):
            #if ogroup.attrib == mgroup.attrib:
                merge_group(mgroup, ogroup)
                break
        else:
            main.append(ogroup)

def merge_group(main, other):
    for term in other:
        main.append(term)

def parse_args():
    parser = argparse.ArgumentParser(description='Merge several correspondances_type_*.xml into on correspondances_type.xml')
    parser.add_argument('-o', '--outfile', help="The file to write in.")
    parser.add_argument('--outencoding', help="The encoding to use to write outfile.", default="ISO-8859-1")
    parser.add_argument('infiles', nargs="+",
                        help="The list of file to process")
    return parser.parse_args()

if __name__ == "__main__" :
    args = parse_args()

    trees = parse_all_file(args.infiles)

    # use first tree as main_tree
    main_tree = trees[0]
    main_root = main_tree.getroot()
    trees = trees[1:]

    for tree in trees:
        merge_root(main_root, tree.getroot())

    main_tree.write(args.outfile, encoding=args.outencoding)

