import sys
import unittest

import rdflib

from lom2mlr import Converter

MLR2_NS = 'http://standards.iso.org/iso-iec/19788/-2/ed-1/en/'

prologue = '''
@prefix mlr2: <http://standards.iso.org/iso-iec/19788/-2/ed-1/en/> .

'''

Element_names = {
	MLR2_NS+'DES0100': 'Title',
	MLR2_NS+'DES0200': 'Creator',
	MLR2_NS+'DES0300': 'Subject',
	MLR2_NS+'DES0400': 'Description',
	MLR2_NS+'DES0500': 'Publisher',
	MLR2_NS+'DES0600': 'Contributor',
	MLR2_NS+'DES0700': 'Date',
	MLR2_NS+'DES0800': 'Type',
	MLR2_NS+'DES0900': 'Format',
	MLR2_NS+'DES1000': 'Identifier',
	MLR2_NS+'DES1100': 'Source',
	MLR2_NS+'DES1200': 'Language',
	MLR2_NS+'DES1300': 'Relation',
	MLR2_NS+'DES1400': 'Coverage',
	MLR2_NS+'DES1500': 'Rights'
}

Expected_values = {
	'DES0100': 'Title',
	'DES0200': 'Creator',
	'DES0300': 'Subject',
	'DES0400': 'Description',
	'DES0500': 'Publisher',
	'DES0600': 'Contributor',
	'DES0700': 'Date',
	'DES0800': 'Type',
	'DES0900': 'Format',
	'DES1000': 'Identifier',
	'DES1100': 'Source',
	'DES1200': 'Language',
	'DES1300': 'Relation',
	'DES1400': 'Coverage',
	'DES1500': 'Rights'
}

TEST_ID = "oai:test.licef.ca:123123"

class testMlr2(unittest.TestCase):
	@classmethod
	def setupClass(self):
		self.converter = Converter()
		self.graph = self.converter.lomfile2graph('tests/data/Valid.xml')

	def triple_from_n3(self, n3):
		g = rdflib.ConjunctiveGraph().parse(data=n3, format="n3")
		return g.triples((None,None,None)).next()

	def test_not_empty(self):
		assert(len(self.graph)>0)

	def test_has_lang(self):
		expected = '%s <%s> mlr2:DES1200 "fr-CA".' % (prologue, TEST_ID)
		assert(len(list(self.graph.triples(self.triple_from_n3(expected)))))

	def test_has_all_mlr2_values(self):
		triples = list(self.graph.triples((rdflib.term.URIRef(TEST_ID), None, None)))
		#sys.stderr.write(`triples`)
		predicates = set(str(p) for (s,p,o) in triples)
		for (p,n) in Element_names.items():
			assert p in predicates, "Missing predicate: "+p+", "+n

	def test_has_only_mlr2_values(self):
		triples = list(self.graph.triples((rdflib.term.URIRef(TEST_ID), None, None)))
		predicates = set(str(p) for (s,p,o) in triples)
		for p in predicates:
			assert p in Element_names, "Unknown predicate: "+p

