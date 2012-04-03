import sys
import unittest

import rdflib

from lom2mlr import Converter
from isodate import parse_date, parse_datetime

MLR1_NS = 'http://standards.iso.org/iso-iec/19788/-1/ed-1/en/'
MLR2_NS = 'http://standards.iso.org/iso-iec/19788/-2/ed-1/en/'
MLR3_NS = 'http://standards.iso.org/iso-iec/19788/-3/ed-1/en/'
MLR4_NS = 'http://standards.iso.org/iso-iec/19788/-4/ed-1/en/'
MLR5_NS = 'http://standards.iso.org/iso-iec/19788/-5/ed-1/en/'

prologue = '''
@prefix mlr1: <%s> .
@prefix mlr2: <%s> .
@prefix mlr3: <%s> .
@prefix mlr4: <%s> .
@prefix mlr5: <%s> .

''' % (MLR1_NS, MLR2_NS, MLR3_NS, MLR4_NS, MLR5_NS)

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

MLR5_Element_names = {
	MLR5_NS+'DES1300': 'Has annotation',
	MLR5_NS+'DES1500': 'Has audience',
#	MLR5_NS+'DES1700': 'Has contribution',
	MLR5_NS+'DES1900': 'Has curriculum',
	MLR5_NS+'DES2000': 'Has learning activity',
#	MLR5_NS+'DES2400': 'Learning method',
#	MLR5_NS+'DES2900': 'Prerequisite',
}

MLR_codomain = {
	MLR5_NS+'DES1300': MLR5_NS+'RC0001', # Annotation
	MLR5_NS+'DES1500': MLR5_NS+'RC0002', # Audience
	MLR5_NS+'DES1700': MLR5_NS+'RC0003', # Contribution
	MLR5_NS+'DES1700': MLR5_NS+'RC0003', # Contribution
	MLR5_NS+'DES1900': MLR5_NS+'RC0004', # Curriculum
	MLR5_NS+'DES2000': MLR5_NS+'RC0005', # Learning activity
	MLR5_NS+'DES1400': MLR1_NS+'RC0003', # Person
	MLR5_NS+'DES1800': MLR1_NS+'RC0003', # Person
}

MLR_Subclass_attributes = {
	MLR1_NS+'RC0003': { # Person

	},
	MLR5_NS+'RC0001': { # Annotation
		# MLR5_NS+'DES0100': 'Annotation date',
		MLR5_NS+'DES0200': 'Annotation text',
		# MLR5_NS+'DES0300': 'Annotation type',
		# MLR5_NS+'DES1400': 'Has annotator',
	},
	MLR5_NS+'RC0002': { # Audience
		MLR5_NS+'DES0400': 'Audience language',
		MLR5_NS+'DES0500': 'Audience level',
		MLR5_NS+'DES0600': 'Audience role',
		MLR5_NS+'DES2500': 'Maximum age',
		MLR5_NS+'DES2600': 'Minimum age',
	},
	MLR5_NS+'RC0003': { # Contribution
		# MLR5_NS+'DES1800': 'Has contributor',
		# MLR5_NS+'DES0700': 'Contribution date',
		# MLR5_NS+'DES0800': 'Contributor role',
	},
	MLR5_NS+'RC0004': { # Curriculum
		# MLR5_NS+'DES0900': 'Curriculum assessment',
		MLR5_NS+'DES1000': 'Curriculum level',
		# MLR5_NS+'DES1100': 'Curriculum specification',
		# MLR5_NS+'DES1200': 'Curriculum topic',
	},
	MLR5_NS+'RC0005': { # Learning activity
		# MLR5_NS+'DES1600': 'Has audience',
		# MLR5_NS+'DES2100': 'Induced activity',
		# MLR5_NS+'DES2200': 'Learning activity occurrence',
		# MLR5_NS+'DES2300': 'Learning method',
		# MLR5_NS+'DES2700': 'Pedagogical relation',
		# MLR5_NS+'DES2800': 'Pedagogical type',
		MLR5_NS+'DES3000': 'Typical learning time',
	}
}


Element_names = {}
Element_names.update(MLR2_Element_names)
Element_names.update(MLR3_Element_names)
Element_names.update(MLR4_Element_names)
Element_names.update(MLR5_Element_names)

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
		expected = '%s <%s> mlr3:DES0500 "fra-CA".' % (prologue, TEST_ID)
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

	def test_codomain(self):
		for predicate in MLR_codomain.keys():
			for s, p, o in self.graph.triples((None, rdflib.term.URIRef(predicate), None)):
				for s2, p2, o2 in self.graph.triples((o, rdflib.RDF.type, None)):
					assert str(o2) == MLR_codomain[predicate]

	def test_subobjects_has_only_mlr_values(self):
		for s, p, o in self.graph.triples((None, rdflib.RDF.type, None)):
			assert str(o) in MLR_Subclass_attributes
			attributes = MLR_Subclass_attributes[str(o)]
			for s2, p2, o2 in self.graph.triples((s, None, None)):
				if rdflib.RDF.type == p2:
					continue
				assert str(p2) in attributes, "unknown predicate: "+p2+" for a "+o

	def test_subobjects_has_all_mlr_values(self):
		for s, p, o in self.graph.triples((None, rdflib.RDF.type, None)):
			assert str(o) in MLR_Subclass_attributes
			attributes = MLR_Subclass_attributes[str(o)]
			predicates = set((str(p2) for s2, p2, o2 in self.graph.triples((s, None, None))))
			for p3, name in attributes.items():
				assert p3 in predicates,  "Missing predicate: "+p3+", "+name

	def test_value_types(self):
		triples = list(self.graph.triples((None, None, None)))
		for s, p, o in triples:
			if str(p) in Type_constraints:
				assert Type_constraints[str(p)](str(o))
