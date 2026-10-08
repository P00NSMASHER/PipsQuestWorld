"""Import a pinned, reviewed content artifact into the active server-only classroom."""
import argparse
import hashlib
import json
from pathlib import Path
import re

TIERS = ('current', 'archive', 'star-fallback')
ROOT = {'schemaVersion','contentOnly','generatedAt','schoolTimeZone','source','policy','questions','currentSubjectPractice','mixedReview','selectableTestPrep','printableGuides','verticalScripts','curriculumPackets','contentSha256'}
QKEYS = {'id','subject','skill','prompt','answer','explanation','sourceFact','choices','hint','questionType','difficulty','dok','tier','provenance'}
TKEYS = {'id','date','label','source','questionIds','supported','disclaimer'}

def compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':'))

def require(condition, message):
    if not condition:
        raise ValueError(message)

def string(value):
    return isinstance(value, str) and bool(value.strip())

def lua(value):
    if isinstance(value, str):
        # Lua has no JSON \u escape; preserve unicode and escape ASCII controls.
        return '"' + ''.join('\\"' if c=='"' else '\\\\' if c=='\\' else f'\\{ord(c):03d}' if ord(c)<32 else c for c in value) + '"'
    if isinstance(value, bool): return 'true' if value else 'false'
    if isinstance(value, (int,float)): return str(value)
    if isinstance(value, list): return '{'+','.join(lua(v) for v in value)+'}'
    if isinstance(value, dict): return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in value.items())+'}'
    raise ValueError('Unsupported Lua value')

def convert(bundle, source_sha, previous=None):
    require(re.fullmatch('[a-f0-9]{40}', source_sha) is not None, 'Pin a full ABVM Git source SHA')
    require(isinstance(bundle, dict) and set(bundle)==ROOT, 'Unsupported or extra bundle fields')
    require(bundle['schemaVersion']==2 and bundle['contentOnly'] is True, 'Content-only schema v2 required')
    require(bundle['schoolTimeZone']=='America/New_York', 'Wrong school timezone')
    require(set(bundle['source'])=={'repository','sourceHash','weekLabel'}, 'Invalid source metadata')
    require(bundle['source']['repository']=='P00NSMASHER/abvmschoolstarworld', 'Wrong source repository')
    require(all(string(v) for v in bundle['source'].values()), 'Missing source metadata')
    require(bundle['policy']=={'priorityOrder':['current-school-material','cumulative-reviewed-material','original-star-style-fallback'],'privateLearnerDataIncluded':False,'officialStarItems':False,'hiddenTeacherTestItemsClaimed':False}, 'Wrong governance policy')
    content={k:v for k,v in bundle.items() if k!='contentSha256'}
    require(hashlib.sha256(compact(content).encode()).hexdigest()==bundle['contentSha256'], 'Content checksum mismatch')
    def privacy(value):
        if isinstance(value,dict):
            for k,v in value.items():
                require(re.fullmatch(r'learnerResponses?|teacherMarks?|studentName|studentId|privateHistory|targetingReasons?|grades?|marks|rawPhotos?|ocrDump|email',k,re.I) is None, 'Private field in content artifact')
                privacy(v)
        elif isinstance(value,list):
            for v in value: privacy(v)
    privacy(bundle)
    rows=bundle['questions'];require(isinstance(rows,list) and rows, 'Missing questions')
    ids={};prompts={}
    for q in rows:
        require(isinstance(q,dict) and set(q)==QKEYS, 'Invalid question fields')
        require(all(string(q[k]) for k in ('id','subject','skill','prompt','answer','explanation','sourceFact','hint','questionType')), 'Invalid question strings')
        require(re.fullmatch('[a-zA-Z0-9][a-zA-Z0-9_-]*',q['id']) is not None, 'Invalid question ID')
        require(q['id'] not in ids, 'Duplicate question ID')
        require(q['tier'] in TIERS, 'Unknown content tier')
        choices=q['choices']
        require(isinstance(choices,list) and 2<=len(choices)<=4 and all(string(c) for c in choices), 'Invalid choices')
        require(len({c.strip() for c in choices})==len(choices) and choices.count(q['answer'])==1, 'Malformed answer key')
        require(type(q['difficulty']) is int and 1<=q['difficulty']<=5 and type(q['dok']) is int and 1<=q['dok']<=4, 'Invalid difficulty/DOK')
        p=q['provenance'];require(isinstance(p,dict), 'Missing provenance')
        kind=p.get('kind')
        expected={'teacher-page':{'kind','sourceHash','captureHash','evidenceHash','sourceUrl'},'reviewed-archive':{'kind','sourceHashes'},'reviewed-original-schoolwork':{'kind','lessonId'},'original-star-style':{'kind'}}
        require(kind in expected and set(p)==expected[kind], 'Unreviewed or private provenance')
        require((q['tier']=='star-fallback')==(kind=='original-star-style'), 'Fallback provenance mismatch')
        if kind=='teacher-page':
            require(p['sourceHash']==bundle['source']['sourceHash'] and re.fullmatch('[a-f0-9]{64}',p['captureHash']) is not None and re.fullmatch('sha256:[a-f0-9]{64}',p['evidenceHash']) is not None, 'Invalid teacher lineage')
        if kind=='reviewed-archive': require(isinstance(p['sourceHashes'],list) and p['sourceHashes'] and all(string(h) for h in p['sourceHashes']), 'Invalid archive lineage')
        if kind=='reviewed-original-schoolwork': require(string(p['lessonId']), 'Invalid lesson lineage')
        prompt=(q['subject'].casefold(),q['prompt'].casefold());require(prompt not in prompts, 'Duplicate/ambiguous prompt')
        prompts[prompt]=q['answer'];ids[q['id']]=q
    if previous is not None:
        old={q['id']:q for q in previous['questions']}
        require(set(old).issubset(ids), 'Previously approved question IDs cannot silently disappear; require reviewed retirement')
        for ident,q in ids.items():
            if ident in old:
                signature=lambda row:(row['subject'],row['skill'],row['prompt'],row['answer'],sorted(row['choices']))
                require(signature(q)==signature(old[ident]), 'Question ID reused for changed content; assign a reviewed new ID')
    def references(refs, ordered=True):
        require(isinstance(refs,list) and len(refs)==len(set(refs)) and all(i in ids for i in refs), 'Invalid question references')
        if ordered:
            ranks=[TIERS.index(ids[i]['tier']) for i in refs];require(ranks==sorted(ranks), 'Tier ordering violation')
    references(bundle['mixedReview']);require(set(bundle['mixedReview'])==set(ids), 'Mixed review must retain the entire pool')
    for subject,refs in bundle['currentSubjectPractice'].items():
        references(refs);require(all(ids[i]['subject']==subject for i in refs), 'Subject mismatch')
    tests=bundle['selectableTestPrep'];test_ids=set()
    for t in tests:
        require(set(t)==TKEYS and all(string(t[k]) for k in ('id','date','label','source','disclaimer')), 'Invalid test fields')
        require(t['id'] not in test_ids, 'Duplicate test ID');test_ids.add(t['id']);references(t['questionIds'])
        require(type(t['supported']) is bool and t['supported']==bool(t['questionIds']), 'Test availability mismatch')
        require(all(ids[i]['tier']!='star-fallback' for i in t['questionIds']), 'STAR cannot invent teacher test coverage')
    lines=['--!strict',f'-- GENERATED from reviewed ABVM source {source_sha}; do not edit by hand.','-- Answers and test memberships stay in ServerScriptService.','local Questions = {']
    for q in rows:
        # Keep legacy priority for compatibility; runtime enforces tier precedence.
        fields={k:q[k] for k in ('id','subject','skill','prompt','answer','hint','explanation','choices','tier','sourceFact','provenance')}
        fields['priority']=1
        lines.append('    {'+','.join(k+'='+lua(v) for k,v in fields.items())+'},')
    lines += ['}', 'Questions.Tests = '+lua(tests), 'Questions.WeekLabel = '+lua(bundle['source']['weekLabel']), 'Questions.SourceCommit = '+lua(source_sha), 'Questions.ContentSha256 = '+lua(bundle['contentSha256']), 'return Questions', '']
    receipt={'schemaVersion':2,'sourceRepository':bundle['source']['repository'],'sourceCommit':source_sha,'contentSha256':bundle['contentSha256'],'imported':len(rows),'tiers':{t:sum(q['tier']==t for q in rows) for t in TIERS},'tests':[{'id':t['id'],'label':t['label'],'date':t['date'],'count':len(t['questionIds']),'supported':t['supported']} for t in tests], 'privateLearnerDataIncluded':False,'published':False}
    return '\n'.join(lines),receipt

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('bundle',type=Path);parser.add_argument('--source-sha',required=True);parser.add_argument('--out',type=Path,required=True);parser.add_argument('--receipt',type=Path,required=True);parser.add_argument('--previous-bundle',type=Path)
    a=parser.parse_args();source=json.loads(a.bundle.read_text());bank,receipt=convert(source,a.source_sha,json.loads(a.previous_bundle.read_text()) if a.previous_bundle else None)
    # Validate everything before touching either output.
    a.out.parent.mkdir(parents=True,exist_ok=True);a.receipt.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(bank);a.receipt.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n');print(json.dumps(receipt))
