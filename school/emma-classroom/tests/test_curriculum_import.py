import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import unittest
P=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('adapter',P/'tools/import_study_universe.py');adapter=importlib.util.module_from_spec(spec);spec.loader.exec_module(adapter)
class ImportTests(unittest.TestCase):
    def setUp(self):
        self.bundle=json.loads((P/'curriculum.json').read_text());self.sha=json.loads((P/'curriculum-receipt.json').read_text())['sourceCommit']
    def sign(self,b):
        b['contentSha256']=hashlib.sha256(adapter.compact({k:v for k,v in b.items() if k!='contentSha256'}).encode()).hexdigest()
    def test_exact_generated_outputs(self):
        bank,receipt=adapter.convert(self.bundle,self.sha)
        self.assertEqual(bank,(P/'server/QuestionBank.lua').read_text());self.assertEqual(receipt,json.loads((P/'curriculum-receipt.json').read_text()))
        self.assertGreaterEqual(receipt['imported'],134);self.assertGreater(receipt['tiers']['current'],0)
    def test_repeated_conversion_is_identical(self):
        self.assertEqual(adapter.convert(self.bundle,self.sha),adapter.convert(copy.deepcopy(self.bundle),self.sha))
    def test_wrong_source_and_checksum(self):
        with self.assertRaises(ValueError):adapter.convert(self.bundle,'main')
        self.bundle['questions'][0]['answer']='Tampered'
        with self.assertRaises(ValueError):adapter.convert(self.bundle,self.sha)
    def test_resigned_malformed_key_duplicate_ids_and_private_provenance(self):
        mutations=[lambda b:b['questions'][0].update(answer='Absent'),lambda b:b['questions'][1].update(id=b['questions'][0]['id']),lambda b:b['questions'][0]['provenance'].update(privateHistory='secret')]
        for mutate in mutations:
            b=copy.deepcopy(self.bundle);mutate(b);self.sign(b)
            with self.assertRaises(ValueError):adapter.convert(b,self.sha)
    def test_dangling_or_reordered_reference_fails(self):
        for refs in [['missing'],list(reversed(self.bundle['mixedReview']))]:
            b=copy.deepcopy(self.bundle);b['mixedReview']=refs;self.sign(b)
            with self.assertRaises(ValueError):adapter.convert(b,self.sha)
    def test_unavailable_test_cannot_claim_support(self):
        b=copy.deepcopy(self.bundle);b['selectableTestPrep'].append({'id':'fixture-missing','date':'2099-01-01','label':'Unknown scope','source':'regression','questionIds':[],'supported':True,'disclaimer':'Original practice'});self.sign(b)
        with self.assertRaises(ValueError):adapter.convert(b,self.sha)
    def test_star_cannot_become_test_evidence(self):
        b=copy.deepcopy(self.bundle);t=b['selectableTestPrep'][0];t['questionIds']=[next(q['id'] for q in b['questions'] if q['tier']=='star-fallback')];self.sign(b)
        with self.assertRaises(ValueError):adapter.convert(b,self.sha)
    def test_current_ids_and_four_choices_are_preserved(self):
        self.assertEqual(len({q['id'] for q in self.bundle['questions']}),len(self.bundle['questions']))
        self.assertTrue(any(len(q['choices'])==4 for q in self.bundle['questions']))
        ids={q['id']:q for q in self.bundle['questions']}
        for t in self.bundle['selectableTestPrep']:
            if t['label']=='Religion Ch. 3':
                self.assertTrue(all(ids[i]['skill']=='religion-chapter-3' for i in t['questionIds']))
    def test_future_refresh_cannot_reuse_an_id_for_changed_content(self):
        b=copy.deepcopy(self.bundle);b['questions'][0]['prompt']='Changed prompt';self.sign(b)
        with self.assertRaises(ValueError):adapter.convert(b,self.sha,previous=self.bundle)
        b=copy.deepcopy(self.bundle);b['questions'][0]['choices'].reverse();self.sign(b)
        adapter.convert(b,self.sha,previous=self.bundle)
    def test_refresh_cannot_silently_drop_a_previously_approved_question(self):
        b=copy.deepcopy(self.bundle)
        deleted=b['questions'].pop()['id']
        b['mixedReview'].remove(deleted)
        for refs in b['currentSubjectPractice'].values():
            if deleted in refs: refs.remove(deleted)
        for t in b['selectableTestPrep']:
            if deleted in t['questionIds']:
                t['questionIds'].remove(deleted)
                t['supported']=bool(t['questionIds'])
        self.sign(b)
        with self.assertRaisesRegex(ValueError,'Previously approved question IDs'):
            adapter.convert(b,self.sha,previous=self.bundle)
    def test_lua_unicode_and_control_escape(self):
        self.assertEqual(adapter.lua('café\n"\\'),'"café\\010\\"\\\\"')
if __name__=='__main__':unittest.main()
