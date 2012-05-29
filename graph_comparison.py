#!/usr/env python
# -*- coding: utf-8 -*-

from collections import defaultdict
from itertools import chain

from lxml import etree
from rdflib import Graph, BNode, URIRef

from lom2mlr import Converter

LOM_TEMPLATE=u'''<?xml version="1.0"?>
<lom xmlns="http://ltsc.ieee.org/xsd/LOM">%s</lom>
'''

N3_PREFIXES = u'''
@prefix mlr1: <http://standards.iso.org/iso-iec/19788/-1/ed-1/en/> .
@prefix mlr2: <http://standards.iso.org/iso-iec/19788/-2/ed-1/en/> .
@prefix mlr3: <http://standards.iso.org/iso-iec/19788/-3/ed-1/en/> .
@prefix mlr4: <http://standards.iso.org/iso-iec/19788/-4/ed-1/en/> .
@prefix mlr5: <http://standards.iso.org/iso-iec/19788/-5/ed-1/en/> .
@prefix mlr9: <http://standards.iso.org/iso-iec/19788/-9/ed-1/en/> .
'''

SECTIONS = (1,2,3,4,5,9)
LANGUAGES = ('en','fr','ru')
PATTERN1 = "@prefix mlr%d: <http://standards.iso.org/iso-iec/19788/-%d/ed-1/en/> ."
PATTERN2 = "@prefix mlr%d_%s: <http://standards.iso.org/iso-iec/19788/-%d/ed-1/en/%s/> ."
N3_PREFIXES = "\n".join([PATTERN1 % (s, s) for s in SECTIONS])+"\n"+\
              "\n".join(chain(*[[PATTERN2 % (s, l, s, l) for s in SECTIONS] for l in LANGUAGES]))


def translate_triple(triple, map):
    s, p, o = triple
    return (map.get(s, s), p, map.get(o, o))


class GraphCorrespondence(object):
    "Finds which nodes in dest correspond to blank nodes in source."
    def __init__(self, source, dest):
        self.source = source
        self.dest = dest
        self.blank_map = {}
        self.identify()

    def translate_triple_list(self, triples):
        sig_t = set()
        for s, p, o in triples:
            sig_t.add((self.blank_map.get(s, s), p, self.blank_map.get(o, o)))
        return sig_t

    def translate_triple(self, triple):
        return translate_triple(triple, self.blank_map)

    def identify_one_by_objects(self, s_node):
        object_sig = list(self.source.triples((None, None, s_node)))
        unknown = 0
        objects = defaultdict(int)
        for s, p, o in object_sig:
            if isinstance(s, BNode):
                if s in self.blank_map:
                    s = self.blank_map[s]
                else:
                    unknown += 1
                    continue
            else:
                for s2, p2, o2 in self.dest.triples((s, p, None)):
                    objects[o2] += 1
        return len(object_sig) - unknown, objects

    def identify_one_by_subjects(self, s_node):
        subject_sig = list(self.source.triples((s_node, None, None)))
        unknown = 0
        subjects = defaultdict(int)
        for s, p, o in subject_sig:
            if isinstance(o, BNode):
                if o in self.blank_map:
                    o = self.blank_map[o]
                else:
                    unknown += 1
                    continue
            else:
                for s2, p2, o2 in self.dest.triples((None, p, o)):
                    subjects[s2] += 1
        return len(subject_sig) - unknown, subjects

    def identify(self):
        subjects_s = set(self.source.subjects())
        blanks_s = set((n for n in subjects_s if isinstance(n, BNode)))
        subjects_d = set(self.dest.subjects())
        blanks_d = set((n for n in subjects_d if isinstance(n, BNode)))
        loose_d = subjects_d - blanks_d - subjects_s
        # first candidates identified by objects
        for n in blanks_s:
            unknown, objects = self.identify_one_by_objects(n)
            if len(objects) == 1:
                self.blank_map[n] = objects.keys()[0]
        missing = set()
        while len(self.blank_map) + len(missing) < len(blanks_s):
            remainder = blanks_s - set(self.blank_map.keys()) - missing
            quality = []
            for n in remainder:
                # Recalculate every time. Optimize later.
                num_ob_stmt, objects = self.identify_one_by_objects(n)
                num_sub_stmt, subjects = self.identify_one_by_subjects(n)
                combined_candidates = set(objects.keys()).union(set(subjects.keys()))
                if len(combined_candidates) == 0:
                    missing.add(n)
                    break
                if len(combined_candidates) == 1:
                    self.blank_map[n] = combined_candidates.pop()
                    break
                combined = [(objects[n] / (1.0 + num_ob_stmt) + subjects[n] / (1.0 + num_sub_stmt), n)
                            for n in combined_candidates]
                combined.sort()
                best = combined[-1][1]
                score = combined[-1][0] - combined[-2][0]
                quality.append(score, n, best)
            else:  # no breaks
                quality.sort()
                #TODO: What if best quality is too low?
                score, orig_node, dest_node = quality[-1]
                self.blank_map[orig_node] = dest_node


class GraphTester(object):

    MISSING = 1
    UNEXPECTED = 2

    def __init__(self):
        self.converter = Converter()

    def normalizeTerm(self, graph, term):
        if isinstance(term, URIRef):
            return graph.normalizeUri(term)
        return term

    def test_graphs(self, obtained_graph, expected_graph, forbidden_graph=None):
        "Identify triples in expected not in obtained, or in forbidden and obtained (unless also in expected.)"
        errors = []
        nsm = obtained_graph.namespace_manager
        comparator_eo = GraphCorrespondence(expected_graph, obtained_graph)
        comparator_eo.identify()
        triples = expected_graph.triples((None, None, None))
        triples = comparator_eo.translate_triple_list(triples)
        for triple in triples:
            if not list(obtained_graph.triples(triple)):
                errors.append((self.MISSING, tuple([self.normalizeTerm(nsm, x) for x in triple])))
        if forbidden_graph:
            comparator_fo = GraphCorrespondence(forbidden_graph, obtained_graph)
            comparator_fo.identify()
            map_oe = {o: e for (e, o) in comparator_eo.blank_map.items()}
            map_fe = {f: map_oe.get(o, None) for f, o in comparator_fo.blank_map.items()}
            triples = forbidden_graph.triples((None, None, None))
            for triple in triples:
                if list(obtained_graph.triples(comparator_fo.translate_triple(triple))) \
                    and not list(expected_graph.triples(translate_triple(triple, map_fe))):
                    errors.append((self.UNEXPECTED, tuple([self.normalizeTerm(nsm, x) for x in triple])))
        return errors

    def convert_lom(self, lom):
        return self.converter.lomxml2graph(etree.fromstring(LOM_TEMPLATE % (lom,)))

    def convert_n3(self, n3):
        return Graph().parse(data=N3_PREFIXES + n3, format="n3")

    def convert(self, format, code):
        if format.lower() == 'xml':
            return self.convert_lom(code)
        elif format.lower() == 'n3':
            return self.convert_n3(code)
        else:
            raise Exception("invalid code format parameter: " + format)

    def test_lom(self, lom, expected_n3, forbidden_n3=None):
        "Transform a LOM string into a graph; returns discrepancies with (N3) expected and forbidden."
        obtained_graph = self.convert_lom(lom)
        expected_graph = self.convert_n3(expected_n3)
        forbidden_graph = None
        if forbidden_n3:
            forbidden_graph = self.convert_n3(forbidden_n3)
        errors = self.test_graphs(obtained_graph, expected_graph, forbidden_graph)
        return obtained_graph, errors
