import unittest

from graph_comparison import GraphTester, LOM_TEMPLATE, N3_PREFIXES, GraphCorrespondence
from rdflib import Graph, Literal, BNode, Namespace, RDF

MLR1_NS = "http://standards.iso.org/iso-iec/19788/-1/ed-1/en/"
MLR1 = Namespace(MLR1_NS )


class testGraphComparison(unittest.TestCase):
    @classmethod
    def setupClass(self):
        self.graphtester = GraphTester()

    def parse(self, source):
        return Graph().parse(data=N3_PREFIXES+source, format="n3")

    def test_find_missing(self):
        errors = self.graphtester.test_graphs(self.parse('''
            <http://example.com> a mlr1:RC0002.
            '''),self.parse('''
            <http://example.com> a mlr1:RC0002 ;
            mlr2:DES0100 "Titre" ;
            mlr2:DES0200 "Auteur" .
            '''))
        assert len(errors)==2

    def test_find_missing_on_blank(self):
        errors = self.graphtester.test_graphs(self.parse('''
            <http://example.com> a mlr1:RC0002 ;
            mlr5:DES1300 [
                a mlr5:RC0001 ] .
            '''),self.parse('''
            <http://example.com> a mlr1:RC0002 ;
            mlr5:DES1300 [
                a mlr5:RC0001;
                mlr5:DES0200 "Commentaire" ] .
            '''))
        assert len(errors)==1
        error = errors[0]
        assert error[0] == GraphTester.MISSING
        assert error[1][2] == u"Commentaire"

    def test_find_unexpected(self):
        errors = self.graphtester.test_graphs(self.parse('''
            <http://example.com> a mlr1:RC0002 ;
            mlr2:DES0100 "Titre" .
            '''),self.parse('''
            <http://example.com> a mlr1:RC0002 .
            '''),self.parse('''
            <http://example.com> a mlr1:RC0002 ;
            mlr2:DES0100 "Titre" .
            '''))
        assert len(errors)==1
        error = errors[0]
        assert error[0] == GraphTester.UNEXPECTED
        assert error[1][2] == u"Titre"

    def test_identify_blanks(self):
        g1 = Graph()
        g1.bind("mlr1",MLR1_NS )
        s1 = BNode()
        g1.add((s1, RDF.type, MLR1["RC0002"]))
        g2 = Graph()
        g2.bind("mlr1",MLR1_NS )
        s2 = BNode()
        g2.add((s2, RDF.type, MLR1["RC0002"]))
        c = GraphCorrespondence(g1, g2)
        c.identify()
        map = c.blank_map
        assert map == {s1:s2}
