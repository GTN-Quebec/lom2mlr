#!/usr/env python
# -*- coding: utf-8 -*-

from collections import defaultdict
from itertools import chain
import re
from uuid import UUID

from lxml import etree
from rdflib import Graph, BNode, URIRef

from lom2mlr import Converter

LOM_TEMPLATE = u'''<?xml version="1.0"?>
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

SECTIONS = (1, 2, 3, 4, 5, 9)
LANGUAGES = ('eng', 'fra', 'rus')
PATTERN1 = "@prefix mlr%d: <http://standards.iso.org/iso-iec/19788/-%d/ed-1/en/> ."
PATTERN2 = "@prefix mlr%d_%s: <http://standards.iso.org/iso-iec/19788/-%d/ed-1/en/%s/> ."
N3_PREFIXES = "\n".join([PATTERN1 % (s, s) for s in SECTIONS]) + "\n" + \
              "\n".join(chain(*[[PATTERN2 % (s, l, s, l)
                                for s in SECTIONS] for l in LANGUAGES]))
BLANK_UUID_RE = re.compile(u'^urn:uuid:([0-5])0000000-0000-0000-0000-([0-9]{12})$')
UUID_RE = re.compile(u'^urn:uuid:[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')


def translate_triple(triple, map):
    s, p, o = triple
    return (map.get(s, s), p, map.get(o, o))


def treat_as_blank(node):
    """Whether this node has to be treated as a local reference.
    Also applies to some UUIDs, so as to match equivalent UUID-1s."""
    return isinstance(node, BNode) or BLANK_UUID_RE.match(unicode(node))


def valid_uuid_correspondance(blank_node, node):
    if isinstance(blank_node, BNode):
        return True
    assert(BLANK_UUID_RE.match(unicode(blank_node)))
    if type(blank_node) != type(node):
        return False
    if not UUID_RE.match(unicode(node)):
        return False
    uuid = UUID(str(node)[9:])
    return uuid.version == int(blank_node[9])


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
            if treat_as_blank(s):
                if s in self.blank_map:
                    s = self.blank_map[s]
                else:
                    unknown += 1
                    continue
            for s2, p2, o2 in self.dest.triples((s, p, None)):
                if not valid_uuid_correspondance(s_node, o2):
                    continue
                objects[o2] += 1
        return len(object_sig) - unknown, objects

    def identify_one_by_subjects(self, s_node):
        subject_sig = list(self.source.triples((s_node, None, None)))
        unknown = 0
        subjects = defaultdict(int)
        for s, p, o in subject_sig:
            if treat_as_blank(o):
                if o in self.blank_map:
                    o = self.blank_map[o]
                else:
                    unknown += 1
                    continue
            for s2, p2, o2 in self.dest.triples((None, p, o)):
                if not valid_uuid_correspondance(s_node, s2):
                    continue
                subjects[s2] += 1
        return len(subject_sig) - unknown, subjects

    def identify(self):
        subjects_s = set(self.source.subjects())
        subjects_s.update(set(n for n in self.source.objects()
                              if BLANK_UUID_RE.match(unicode(n))))
        blanks_s = set((n for n in subjects_s if treat_as_blank(n)))
        subjects_d = set(self.dest.subjects())
        subjects_d.update(set(n for n in self.dest.objects()
                              if UUID_RE.match(unicode(n))))
        blanks_d = set((n for n in subjects_d if treat_as_blank(n)))
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
                combined_candidates = set(objects.keys()).union(
                    set(subjects.keys()))
                if len(combined_candidates) == 0:
                    missing.add(n)
                    break
                if len(combined_candidates) == 1:
                    self.blank_map[n] = combined_candidates.pop()
                    break
                combined = [(objects[n] / (1.0 + num_ob_stmt) +
                            subjects[n] / (1.0 + num_sub_stmt), n)
                            for n in combined_candidates]
                combined.sort()
                best = combined[-1][1]
                score = combined[-1][0] - combined[-2][0]
                quality.append((score, n, best))
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
        self.reset()

    def normalizeTerm(self, graph, term):
        if isinstance(term, URIRef):
            return graph.normalizeUri(term)
        return term

    def reset(self):
        self.last_lom = None
        self.last_graph = None
        self.last_comparator = None

    def set_lom(self, lom):
        self.reset()
        self.last_lom = etree.fromstring(LOM_TEMPLATE % (lom,))

    def process_line(self, format, code, args=None):
        format = format.lower()
        if format == 'xml':
            self.set_lom(code)
            return None, []
        elif format == 'n3':
            return self.test_n3(code, args)
        assert False, 'format should be xml or n3'

    def parse_n3(self, n3):
        return Graph().parse(data=N3_PREFIXES + n3, format="n3")

    def test_n3(self, n3, args=None):
        return self.test_graph(self.parse_n3(n3), args)

    def find_missing(self, expected_graph, obtained_graph):
        errors = []
        nsm = obtained_graph.namespace_manager
        comparator_eo = GraphCorrespondence(expected_graph, obtained_graph)
        self.last_comparator = comparator_eo
        comparator_eo.identify()
        triples = expected_graph.triples((None, None, None))
        triples = comparator_eo.translate_triple_list(triples)
        for triple in triples:
            if not list(obtained_graph.triples(triple)):
                errors.append(tuple([self.normalizeTerm(nsm, x) for x in triple]))
        return errors

    def find_forbidden(self, forbidden_graph, obtained_graph):
        assert self.last_comparator
        expected_graph = self.last_comparator.source
        errors = []
        nsm = obtained_graph.namespace_manager
        comparator_fo = GraphCorrespondence(forbidden_graph, obtained_graph)
        comparator_fo.identify()
        map_oe = {o: e for (e, o) in
                  self.last_comparator.blank_map.items()}
        map_fe = {f: map_oe.get(o, None) for f, o in
                  comparator_fo.blank_map.items()}
        triples = forbidden_graph.triples((None, None, None))
        for triple in triples:
            if list(obtained_graph.triples(comparator_fo.translate_triple(triple))) \
                and not list(expected_graph.triples(translate_triple(triple, map_fe))):
                errors.append(tuple([self.normalizeTerm(nsm, x) for x in triple]))
        return errors

    def test_graph(self, graph, args=None):
        assert self.last_lom is not None
        errors = []
        if args and args.lower() == 'forbidden':
            assert(self.last_graph)
            errors = [(self.UNEXPECTED, e) for e in 
                        self.find_forbidden(graph, self.last_graph)]
        else:
            if args:
                args = eval(args)
                assert isinstance(args, dict)
                self.converter.set_options_from_dict(args)
            else:
                self.converter.set_options_from_list()
            obtained_graph = self.converter.lomxml2graph(self.last_lom)
            self.last_graph = obtained_graph
            errors = [(self.MISSING, e) for e in self.find_missing(graph, obtained_graph)]
        return self.last_graph, errors
