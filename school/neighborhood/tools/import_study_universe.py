#!/usr/bin/env python3
"""Convert a reviewed universe export to the existing server-only Roblox bank shape."""
from pathlib import Path
import argparse,hashlib,json,collections
ROOMS={'Math':('math','Math'),'Reading':('reading','Reading'),'Spelling':('spelling','Spelling'),'Religion':('religion','Religion')}
def room_for(row):
 skill=row['skill'].lower()
 if any(x in skill for x in ('predicate','subject-predicate','possessive','punctuation','capital','noun','verb')):return 'grammar','Grammar'
 if any(x in skill for x in ('vocabulary','synonym','antonym','word-meaning')):return 'vocabulary','Vocabulary'
 if row['subject'] not in ROOMS:raise ValueError('Unknown subject')
 return ROOMS[row['subject']]
def build(raw):
 if raw.get('schemaVersion')!=1 or raw.get('contentOnly') is not True or not isinstance(raw.get('questions'),list):raise ValueError('Reviewed content-only export required')
 allowed={'id','subject','skill','prompt','choices','answer','explanation','hint','tier','sourceId'}
 rows=[];seen={}
 for item in raw['questions']:
  if set(item)-allowed:raise ValueError('Unexpected/private question field')
  if not all(isinstance(item.get(k),str) and item[k].strip() for k in ['id','subject','skill','prompt','answer','explanation','sourceId']):raise ValueError('Missing question content')
  if item['tier'] not in ['current','archive','fallback']:raise ValueError('Unknown source tier')
  choices=item['choices']
  if not isinstance(choices,list) or not 2<=len(choices)<=4 or any(not isinstance(c,str) or not c.strip() for c in choices) or len(set(choices))!=len(choices) or choices.count(item['answer'])!=1:raise ValueError('Invalid choices/answer')
  subject,room=room_for(item)
  stem=(room,' '.join(item['prompt'].split()).casefold())
  if stem in seen:
   if seen[stem]!=item['answer']:raise ValueError('Conflicting answer')
   continue
  seen[stem]=item['answer']
  # Stable IDs match the legacy importer, preserving existing player question progress.
  fp=hashlib.sha256((room+'\0'+stem[1]+'\0'+item['answer'].casefold()).encode()).hexdigest()
  rows.append({**item,'id':'abvm-'+fp[:20],'sourceQuestionId':item['id'],'subject':subject,'room':room,'answerIndex':choices.index(item['answer'])+1})
 if not rows:raise ValueError('Empty learning pack')
 def quote(s):return json.dumps(s,ensure_ascii=False)
 lines=['--!strict','-- Reviewed educational content only. SERVER ONLY.','local bank={Source={repository="P00NSMASHER/abvmschoolstarworld",grade=2,officialStarItems=false},Questions={}}']
 for x in rows:
  fields={'id':quote(x['id']),'subject':quote(x['subject']),'room':quote(x['room']),'skill':quote(x['skill']),'prompt':quote(x['prompt']),'choices':'{'+','.join(quote(c) for c in x['choices'])+'}','answer':str(x['answerIndex']),'explanation':quote(x['explanation']),'hint':quote(x.get('hint') or 'Read the question again and look for a clue.'),'difficulty':'2','sourceTier':quote({'archive':'worksheet','fallback':'practice'}.get(x['tier'],'current')),'sourceId':quote(x['sourceQuestionId'])}
  lines.append('table.insert(bank.Questions,{'+','.join(k+'='+v for k,v in fields.items())+'})')
 lines.append('return bank')
 output='\n'.join(lines)+'\n'
 receipt={'schemaVersion':1,'imported':len(rows),'rooms':dict(collections.Counter(x['room'] for x in rows)),'sourceCheckedAt':raw.get('sourceCheckedAt'),'outputSha256':hashlib.sha256(output.encode()).hexdigest(),'privateMetadataExported':False,'liveGamePublished':False}
 return output,receipt
def main():
 parser=argparse.ArgumentParser();parser.add_argument('pack',type=Path);parser.add_argument('--out',type=Path,required=True);parser.add_argument('--receipt',type=Path,required=True);a=parser.parse_args()
 output,receipt=build(json.loads(a.pack.read_text()))
 a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(output)
 a.receipt.parent.mkdir(parents=True,exist_ok=True);a.receipt.write_text(json.dumps(receipt,indent=2)+'\n')
 print(json.dumps(receipt))
if __name__=='__main__':main()
