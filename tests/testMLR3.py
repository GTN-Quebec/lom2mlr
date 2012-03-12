import unittest

import rdflib

from lom2mlr import Converter

MLR2_NS = u'http://standards.iso.org/iso-iec/19788/-2/ed-1/en/'

prologue = u'''
@prefix mlr2: <http://standards.iso.org/iso-iec/19788/-2/ed-1/en/> .

'''

class testMlr3(unittest.TestCase):
	@classmethod
	def setupClass(self):
		self.converter = Converter()
		self.graph = self.converter.file2rdf('tests/data/Valid.xml')
	def triple_from_n3(self, n3):
		g = rdflib.ConjunctiveGraph().parse(data=n3, format="n3")
		return g.triples((None,None,None)).next()
	def test_not_empty(self):
		assert(len(self.graph)>0)
	def test_has_lang(self):
		expected = prologue+u'<oai:test.licef.ca:123123> mlr2:DES1200 "fr-CA".'
		assert(len(list(self.graph.triples(self.triple_from_n3(expected)))))
