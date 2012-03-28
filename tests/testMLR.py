import sys
import unittest

import rdflib

from lom2mlr import Converter
from isodate import parse_date, parse_datetime

MLR2_NS = 'http://standards.iso.org/iso-iec/19788/-2/ed-1/en/'
MLR3_NS = 'http://standards.iso.org/iso-iec/19788/-3/ed-1/en/'
MLR4_NS = 'http://standards.iso.org/iso-iec/19788/-4/ed-1/en/'

prologue = '''
@prefix mlr2: <%s> .
@prefix mlr3: <%s> .
@prefix mlr4: <%s> .

''' % (MLR2_NS, MLR3_NS, MLR4_NS)

MLR2_Element_names = {
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

MLR3_Element_names = {
	MLR3_NS+'DES0100': 'Date',
	MLR3_NS+'DES0200': 'Description',
	MLR3_NS+'DES0300': 'Format',
	MLR3_NS+'DES0400': 'Identifier',
	MLR3_NS+'DES0500': 'Language',
	MLR3_NS+'DES0600': 'Source',
	MLR3_NS+'DES0700': 'Type'
}

MLR4_Element_names = {
	MLR4_NS+'DES0100': 'Location',
	MLR4_NS+'DES0200': 'Size',
	MLR4_NS+'DES0300': 'Duration',
	MLR4_NS+'DES0400': 'Technical requirement',
	MLR4_NS+'DES0500': 'Technical features',
	MLR4_NS+'DES0600': 'Media format information',
	MLR4_NS+'DES0700': 'Technical delivery context'
}

Element_names = {}
Element_names.update(MLR2_Element_names)
Element_names.update(MLR3_Element_names)
Element_names.update(MLR4_Element_names)

Known_Missing = set([
	MLR2_NS+'DES0700', # replaced by MLR3:DES0100
	MLR2_NS+'DES0400', # replaced by MLR3:DES0200
	MLR2_NS+'DES0900', # replaced by MLR3:DES0300
	MLR2_NS+'DES1000', # replaced by MLR3:DES0400
	MLR2_NS+'DES1200', # replaced by MLR3:DES0500
	MLR2_NS+'DES1100', # replaced by MLR3:DES0600
	MLR2_NS+'DES0800', # replaced by MLR3:DES0700
	MLR4_NS+'DES0500',
	MLR4_NS+'DES0600',
	MLR4_NS+'DES0700',
	])

Expected_values = {
}

def valid_8601_date(s):
	try:
		if 'T' in s:
			parse_datetime(s)
		else:
			parse_date(s)
		return True
	except ValueError:
		return False

Type_constraints = {
	MLR3_NS+'DES0100': valid_8601_date,
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
		expected = '%s <%s> mlr3:DES0500 "fr-CA".' % (prologue, TEST_ID)
		assert(len(list(self.graph.triples(self.triple_from_n3(expected)))))

	def test_has_all_mlr_values(self):
		triples = list(self.graph.triples((rdflib.term.URIRef(TEST_ID), None, None)))
		#sys.stderr.write(`triples`)
		predicates = set(str(p) for (s,p,o) in triples)
		for (p,n) in Element_names.items():
			if p in Known_Missing: continue
			assert p in predicates, "Missing predicate: "+p+", "+n

	def test_has_only_mlr_values(self):
		triples = list(self.graph.triples((rdflib.term.URIRef(TEST_ID), None, None)))
		predicates = set(str(p) for (s,p,o) in triples)
		for p in predicates:
			assert p in Element_names, "Unknown predicate: "+p

	def test_value_types(self):
		triples = list(self.graph.triples((None, None, None)))
		for s, p, o in triples:
			if str(p) in Type_constraints:
				assert Type_constraints[str(p)](str(o))
