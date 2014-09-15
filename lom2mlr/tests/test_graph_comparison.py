"""Unit tests for algorithms in :py:mod:`lom2mlr.validate.graph_comparison`"""

from __future__ import print_function

import unittest

from lom2mlr.validate.graph_comparison import (
    GraphTester, N3_PREFIXES, GraphCorrespondence)
from rdflib import Graph, BNode, Namespace, RDF, Literal

MLR1_NS = "http://standards.iso.org/iso-iec/19788/-1/ed-1/en/"
MLR1 = Namespace(MLR1_NS)


class testGraphComparison(unittest.TestCase):
    @classmethod
    def setupClass(self):
        self.graphtester = GraphTester()

    def parse(self, source):
        return Graph().parse(data=N3_PREFIXES + source, format="n3")

    def test_find_missing(self):
        errors = self.graphtester.find_missing(
            self.parse('''
            <http://example.com> a mlr1:RC0002 ;
            mlr2:DES0100 "Titre" ;
            mlr2:DES0200 "Auteur" .
            '''), self.parse('''
            <http://example.com> a mlr1:RC0002.
            '''))
        assert len(errors) == 2

    def test_find_missing_on_blank(self):
        errors = self.graphtester.find_missing(
            self.parse('''
            <http://example.com> a mlr1:RC0002 ;
            mlr5:DES1300 [
                a mlr5:RC0001;
                mlr5:DES0200 "Commentaire" ] .
            '''), self.parse('''
            <http://example.com> a mlr1:RC0002 ;
            mlr5:DES1300 [
                a mlr5:RC0001 ] .
            '''))
        assert len(errors) == 1
        error = errors[0]
        print(error)
        assert error[2] == Literal(u"Commentaire")

    def test_find_missing_on_uuid(self):
        errors = self.graphtester.find_missing(
            self.parse('''
<urn:uuid:10000000-0000-0000-0000-000000000001> a mlr1:RC0002.
<urn:uuid:10000000-0000-0000-0000-000000000001> mlr5:DES1700 <urn:uuid:10000000-0000-0000-0000-000000000002>.
            '''), self.parse('''
<urn:uuid:75411ac2-d077-11e1-b25b-c8bcc8f0abdf> a mlr1:RC0002.
<urn:uuid:75411ac2-d077-11e1-b25b-c8bcc8f0abdf> mlr5:DES1700 <urn:uuid:75411ac2-d077-11e1-b25b-c8bcc8f0abcd> .
            '''))
        assert len(errors) == 0, errors

    def test_find_unexpected(self):
        obtained = self.parse('''
            <http://example.com> a mlr1:RC0002 ;
            mlr2:DES0100 "Titre" . ''')
        expected = self.parse('<http://example.com> a mlr1:RC0002 .')
        forbidden = self.parse('''
             <http://example.com> a mlr1:RC0002 ;
            mlr2:DES0100 "Titre" . ''')

        errors = self.graphtester.find_missing(expected, obtained)
        assert not errors
        errors = self.graphtester.find_forbidden(forbidden, obtained)
        assert len(errors) == 1
        error = errors[0]
        assert error[2] == Literal(u"Titre")

    def test_identify_blanks(self):
        g1 = Graph()
        g1.bind("mlr1", MLR1_NS)
        s1 = BNode()
        g1.add((s1, RDF.type, MLR1["RC0002"]))
        g2 = Graph()
        g2.bind("mlr1", MLR1_NS)
        s2 = BNode()
        g2.add((s2, RDF.type, MLR1["RC0002"]))
        c = GraphCorrespondence(g1, g2)
        c.identify()
        map = c.blank_map
        assert map == {s1: s2}
