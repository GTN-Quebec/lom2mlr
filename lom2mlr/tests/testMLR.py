"""Integration tests for :py:class:`lom2mlr.transform.Converter`"""

import unittest
import os.path
from collections import defaultdict
import traceback

from rdflib import RDF, Graph, term, Namespace

from lom2mlr import Converter
from isodate import parse_date, parse_datetime

MLR1 = Namespace('http://standards.iso.org/iso-iec/19788/-1/ed-1/en/')
MLR2 = Namespace('http://standards.iso.org/iso-iec/19788/-2/ed-1/en/')
MLR3 = Namespace('http://standards.iso.org/iso-iec/19788/-3/ed-1/en/')
MLR4 = Namespace('http://standards.iso.org/iso-iec/19788/-4/ed-1/en/')
MLR5 = Namespace('http://standards.iso.org/iso-iec/19788/-5/ed-1/en/')
MLR8 = Namespace('http://standards.iso.org/iso-iec/19788/-8/ed-1/en/')
MLR9 = Namespace('http://standards.iso.org/iso-iec/19788/-9/ed-1/en/')
OA = Namespace('http://www.w3.org/ns/oa#')

prologue = '''
@prefix mlr1: <%s> .
@prefix mlr2: <%s> .
@prefix mlr3: <%s> .
@prefix mlr4: <%s> .
@prefix mlr5: <%s> .
@prefix mlr8: <%s> .
@prefix mlr9: <%s> .
@prefix oa: <%s> .

''' % (MLR1, MLR2, MLR3, MLR4, MLR5, MLR8, MLR9, OA)


MLR2_Element_names = {
    MLR2.DES0100: 'Title',
    MLR2.DES0200: 'Creator',
    MLR2.DES0300: 'Subject',
    MLR2.DES0400: 'Description',
    MLR2.DES0500: 'Publisher',
    MLR2.DES0600: 'Contributor',
    MLR2.DES0700: 'Date',
    MLR2.DES0800: 'Type',
    MLR2.DES0900: 'Format',
    MLR2.DES1000: 'Identifier',
    MLR2.DES1100: 'Source',
    MLR2.DES1200: 'Language',
    MLR2.DES1300: 'Relation',
    MLR2.DES1400: 'Coverage',
    MLR2.DES1500: 'Rights'
}

MLR3_Element_names = {
    MLR3.DES0100: 'Date',
    MLR3.DES0200: 'Identifier',
    MLR3.DES0300: 'Language'
}

MLR4_Element_names = {
    MLR4.DES0100: 'Location',
    MLR4.DES0200: 'Size',
    MLR4.DES0300: 'Duration',
    MLR4.DES0400: 'Technical requirement',
    MLR4.DES0500: 'Technical features',
    MLR4.DES0600: 'Media format information'
}

MLR5_Element_names = {
    MLR5.DES1500: 'Has audience',
    MLR5.DES1700: 'Has contribution',
    MLR5.DES1900: 'Has curriculum',
    MLR5.DES2000: 'Has learning activity',
    MLR5.DES2400: 'Learning method',
    MLR5.DES2900: 'Prerequisite',
}

MLR8_Element_names = {
    MLR8.DES0300: 'Has Record',
    # MLR8.DES0400: 'Language',
    # MLR8.DES0500: 'Type',
    # MLR8.DES0600: 'Has Application Profile',
    # MLR8.DES0700: 'Contribution',
    # MLR8.DES0800: 'Record Repository',
    # MLR8.DES0900: 'Record Last Update',
    # MLR8.DES1000: 'Entity',
    # MLR8.DES1100: 'Entities',
    # MLR8.DES1200: 'Role',
    # MLR8.DES1300: 'Date',
    # MLR8.DES1400: 'Original Record',
    # MLR8.DES1500: 'Original Record Format',
    # MLR8.DES1600: 'Conversion software',
}

MLR9_Element_names = {
    # MLR9.DES0100: 'Identifier',
    # MLR9.DES0200: 'Name',
    # MLR9.DES0300: 'Family Name',
    # MLR9.DES0400: 'Given Name',
    # MLR9.DES0500: 'Name',
    # MLR9.DES0600: 'SkypeID',
    # MLR9.DES0700: 'vCard N',
    # MLR9.DES0800: 'vCard FN',
    # MLR9.DES0900: 'Email',
    # MLR9.DES1000: 'Work Telephone',
    # MLR9.DES1100: 'Work For',
    # MLR9.DES1200: 'vCard ORG',
    # MLR9.DES1300: 'Location',
    # MLR9.DES1400: 'Longitude',
    # MLR9.DES1500: 'Latitude',
    # MLR9.DES1600: 'Representation',
    # MLR9.DES1700: 'Description'
}

MLR_codomain = {
    MLR5.DES1500: (MLR5.RC0002, ),  # Audience
    MLR5.DES1700: (MLR5.RC0003, ),  # Contribution
    MLR5.DES1900: (MLR5.RC0004, ),  # Curriculum
    MLR5.DES2000: (MLR5.RC0005, ),  # Learning activity
    MLR5.DES1400: (MLR1.RC0003, MLR9.RC0001, MLR9.RC0002),  # Person and subclasses
    MLR5.DES1800: (MLR1.RC0003, MLR9.RC0001, MLR9.RC0002),  # Person and subclasses
    MLR8.DES0200: (MLR1.RC0002, ),  # Describes
    MLR8.DES0300: (MLR8.RC0001, ),  # Has Record
    MLR8.DES0700: (MLR8.RC0002, ),  # Contribution
    MLR8.DES1000: (MLR1.RC0003, MLR9.RC0001, MLR9.RC0002),  # Person and subclasses
    # MLR8.DES1100: (Seq(MLR1.RC0003), ),  # Entities
    MLR9.DES1100: (MLR9.RC0002, ),  # Organization
    MLR9.DES1300: (MLR9.RC0003, ),  # Geographical location
    MLR9.DES1600: (MLR9.RC0004, ),  # Digital media
}

MLR_Subclass_attributes = {
    MLR1.RC0003: { # Person
        MLR9.DES0100: 'Identifier',
        MLR9.DES0200: 'Name',
    },
    OA.Annotation: { # Annotation
        # OA.annotatedAt: 'Annotation date',
        OA.hasBody: 'Annotation text',
        # OA.motivatedBy: 'Annotation type',
        # OA.annotatedBy: 'Has annotator',
    },
    MLR5.RC0002: { # Audience
        MLR5.DES0400: 'Audience language',
        MLR5.DES0500: 'Audience level',
        MLR5.DES0600: 'Audience role',
        MLR5.DES2500: 'Maximum age',
        MLR5.DES2600: 'Minimum age',
    },
    MLR5.RC0003: { # Contribution
        MLR5.DES1800: 'Has contributor',
        MLR5.DES0700: 'Contribution date',
        MLR5.DES0800: 'Contributor role',
    },
    MLR5.RC0004: { # Curriculum
        # MLR5.DES0900: 'Curriculum assessment',
        MLR5.DES1000: 'Curriculum level',
        # MLR5.DES1100: 'Curriculum specification',
        # MLR5.DES1200: 'Curriculum topic',
    },
    MLR5.RC0005: { # Learning activity
        # MLR5.DES1600: 'Has audience',
        # MLR5.DES2100: 'Induced activity',
        # MLR5.DES2200: 'Learning activity occurrence',
        # MLR5.DES2300: 'Learning method',
        # MLR5.DES2700: 'Pedagogical relation',
        # MLR5.DES2800: 'Pedagogical type',
        MLR5.DES3000: 'Typical learning time',
    },
    MLR8.RC0001: {  # MLR Record
        MLR8.DES0100: 'Record Identifier',
        MLR8.DES0200: 'Describes',
        MLR8.DES0400: 'Language',
        MLR8.DES0500: 'Type',
        MLR8.DES0600: 'Has Application Profile',
        MLR8.DES0700: 'Contribution',
        MLR8.DES0800: 'Record Repository',
        MLR8.DES1400: 'Original Record',
        MLR8.DES1500: 'Original Record Format',
        MLR8.DES1600: 'Conversion software',
    },
    MLR8.RC0002: {  # Contribution
        MLR8.DES1000: 'Entity',
        MLR8.DES1200: 'Role',
        MLR8.DES1300: 'Date',
    },
    MLR8.RC0003: {  # Mutable MLR Record
        MLR8.DES0900: 'Record Last Update',

    },
    MLR9.RC0001: { # Natural Person
        MLR9.DES0100: 'Identifier',
        MLR9.DES0300: 'Family Name',
        MLR9.DES0400: 'Given Name',
        MLR9.DES0500: 'Name',
        MLR9.DES0600: 'SkypeID',
        MLR9.DES0700: 'vCard N',
        MLR9.DES0800: 'vCard FN',
        MLR9.DES0900: 'Email',
        MLR9.DES1000: 'Work Telephone',
        MLR9.DES1100: 'Work For',
    },
    MLR9.RC0002: { # Organization
        MLR9.DES0100: 'Identifier',
        # MLR9.DES0200: 'Name', TODO: Is this necessary????
        MLR9.DES0900: 'Email',
        MLR9.DES1200: 'vCard ORG',
        MLR9.DES1300: 'Location',
    },
    MLR9.RC0003: { # Geographical Location
        MLR9.DES1400: 'Longitude',
        MLR9.DES1500: 'Latitude',
        # MLR9.DES1600: 'Representation',
        MLR9.DES1700: 'Description'
    },
    MLR9.RC0004: { # Digital media
    },
}


Element_names = { RDF.type:'type' }
Element_names.update(MLR2_Element_names)
Element_names.update(MLR3_Element_names)
Element_names.update(MLR4_Element_names)
Element_names.update(MLR5_Element_names)
Element_names.update(MLR8_Element_names)
Element_names.update(MLR9_Element_names)

Known_Missing = set([
    MLR2.DES0700,  # replaced by MLR3:DES0100
    MLR2.DES1000,  # replaced by MLR3:DES0200
    MLR2.DES1200,  # replaced by MLR3:DES0300
    MLR4.DES0500,
    MLR4.DES0600,
    MLR4.DES0700,
    MLR5.DES2400,
    MLR5.DES2900,
    MLR5.DES0700,  # occasionally missing
    MLR8.DES0800,
    MLR8.DES1400,
    MLR8.DES1600,
    MLR9.DES0600,  # occasionally missing
    MLR9.DES1400,  # occasionally missing
    MLR9.DES1500,  # occasionally missing
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
    MLR3.DES0100: valid_8601_date,
}


TEST_ID = "oai:aquops.qc.ca:videos:8"
this_dir, this_filename = os.path.split(__file__)
EXAMPLE = os.path.join(this_dir, 'data', 'Valid.xml')


class testMlr(unittest.TestCase):
    @classmethod
    def setupClass(self):
        self.converter = Converter()
        self.graph = self.converter.lomfile2graph(EXAMPLE)

    def triple_from_n3(self, n3):
        g = Graph().parse(data=n3, format="n3")
        return g.triples((None,None,None)).next()

    def test_not_empty(self):
        assert(len(self.graph)>0)

    def test_has_lang(self):
        expected = '%s <%s> mlr3:DES0300 "fra-CA".' % (prologue, TEST_ID)
        assert(len(list(self.graph.triples(self.triple_from_n3(expected)))))

    def test_has_all_mlr_values(self):
        triples = list(self.graph.triples((term.URIRef(TEST_ID), None, None)))
        #sys.stderr.write(`triples`)
        predicates = set(p for (s, p, o) in triples)
        missing_predicates = []
        for (p, n) in Element_names.items():
            if p in Known_Missing:
                continue
            if p not in predicates:
                missing_predicates.append((p, n))
        assert not missing_predicates, missing_predicates

    def test_has_only_mlr_values(self):
        triples = list(self.graph.triples((term.URIRef(TEST_ID), None, None)))
        predicates = set(p for (s, p, o) in triples)
        extra_predicates = []
        for p in predicates:
            if p == term.URIRef('http://www.inria.fr/acacia/corese#graph'):
                continue
            if not p in Element_names:
                extra_predicates.append(p)
        assert not extra_predicates, extra_predicates

    def test_codomain(self):
        wrong_codomain_type = []
        for predicate in MLR_codomain.keys():
            for s, p, o in self.graph.triples((None, term.URIRef(predicate), None)):
                for s2, p2, o2 in self.graph.triples((o, RDF.type, None)):
                    if o2 not in MLR_codomain[predicate]:
                        wrong_codomain_type.append((predicate, o2))
        assert not wrong_codomain_type, wrong_codomain_type

    def test_subobjects_has_only_mlr_values(self):
        extra_predicates = []
        for s, p, o in self.graph.triples((None, RDF.type, None)):
            if o == MLR1.RC0002:
                continue
            assert o in MLR_Subclass_attributes, "Missing type:" + o
            attributes = MLR_Subclass_attributes[o]
            for s2, p2, o2 in self.graph.triples((s, None, None)):
                if RDF.type == p2:
                    continue
                if not p2 in attributes:
                    extra_predicates.append((o, p2))
        assert not extra_predicates, extra_predicates

    def test_subobjects_has_all_mlr_values(self):
        missing_types = []
        missing_predicates = []
        res_by_type = defaultdict(set)
        pred_by_type = defaultdict(set)
        for s, p, o in self.graph.triples((None, RDF.type, None)):
            res_by_type[o].add(s)
        for type_uri, ressources in res_by_type.items():
            for r in ressources:
                for s, p, o in self.graph.triples((r, None, None)):
                    pred_by_type[type_uri].add(p)
        for type_uri, predicates in pred_by_type.items():
            if type_uri == MLR1.RC0002:
                continue
            if type_uri not in MLR_Subclass_attributes:
                missing_types.append(o)
                continue
            attributes = MLR_Subclass_attributes[type_uri]
            for p, name in attributes.items():
                if p in Known_Missing:
                    continue
                if not p in predicates:
                    missing_predicates.append((p, name, o))
        assert not missing_types, missing_types
        assert not missing_predicates, missing_predicates

    def test_value_types(self):
        triples = list(self.graph.triples((None, None, None)))
        for s, p, o in triples:
            if p in Type_constraints:
                assert Type_constraints[p](str(o))

    def test_lom_files(self):
        ex_dir = os.path.join(this_dir, 'data')
        examples = os.listdir(ex_dir)
        all_clear = True
        for example in examples:
            print example
            graph = self.converter.lomfile2graph(os.path.join(ex_dir, example))
