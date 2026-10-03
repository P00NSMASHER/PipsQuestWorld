#!/usr/bin/env python3
import argparse, hashlib, json, os, re, struct, sys
from collections import Counter
from pathlib import Path

try:
    import lz4.block
except Exception as exc:
    print(f'ERROR: lz4.block unavailable: {exc}', file=sys.stderr)
    sys.exit(2)

MAGIC = b'<roblox!'
DOMAINS = {
    'housing': ['house','housing','home','furn','furniture','wall','paint','build','chair','lamp','landlord','edit house','hide walls'],
    'vehicles': ['vehicle','car','truck','bike','motor','drive','seat','garage','spawn car','spawn vehicle'],
    'avatar_shopping': ['avatar','outfit','clothing','shirt','pants','hair','hat','accessory','shop','store','buy','purchase','wardrobe','customiz'],
    'jobs': ['job','work','cash','paycheck','salary','cafe','barista','cashier','cook','janitor','teacher'],
    'school_class': ['school','class','period','schedule','teacher','student','attendance','bell','math','science','english','history','lunch'],
    'ui_mobile': ['gui','menu','button','hud','icon','mobile','touch','textbutton','imagelabel','frame','scroll','screen'],
    'world_presentation': ['spawn','town','campus','road','lighting','sky','music','animation','camera','environment','day','night'],
}
ASSET_RE = re.compile(r'(?:rbxassetid://|https?://(?:www\.)?roblox\.com/(?:asset/\?id=|library/)|assetId[^0-9]{0,12})(\d{4,})', re.I)

def git_blob_sha(data: bytes) -> str:
    h = hashlib.sha1(); h.update(f'blob {len(data)}\0'.encode()); h.update(data); return h.hexdigest()

def ascii_strings(data: bytes, min_len=4):
    out=[]; start=None
    for i,b in enumerate(data):
        if 32 <= b <= 126 or b in (9,10,13):
            if start is None: start=i
        else:
            if start is not None and i-start >= min_len:
                out.append((start, data[start:i].decode('utf-8','replace')))
            start=None
    if start is not None and len(data)-start >= min_len:
        out.append((start, data[start:].decode('utf-8','replace')))
    return out

def utf16le_strings(data: bytes, min_chars=4):
    out=[]; pat=re.compile(rb'(?:[\x20-\x7e]\x00){%d,}' % min_chars)
    for m in pat.finditer(data):
        try: out.append((m.start(), m.group().decode('utf-16le')))
        except Exception: pass
    return out

def parse_chunks(data: bytes):
    chunks=[]
    if not data.startswith(MAGIC): return chunks, 'unexpected_magic'
    pos=32; idx=0
    while pos+16 <= len(data):
        tag=data[pos:pos+4]; tag_text=tag.decode('ascii','replace')
        comp_len, raw_len, reserved=struct.unpack_from('<III',data,pos+4); pos+=16
        payload_len=comp_len if comp_len else raw_len
        if pos+payload_len>len(data):
            chunks.append({'index':idx,'tag':tag_text,'offset':pos-16,'error':'payload_bounds','compressedLength':comp_len,'rawLength':raw_len})
            break
        payload=data[pos:pos+payload_len]; pos+=payload_len
        if comp_len:
            try: raw=lz4.block.decompress(payload,uncompressed_size=raw_len); status='lz4'
            except Exception as exc: raw=b''; status='decompress_error:'+str(exc)
        else: raw=payload; status='raw'
        chunks.append({'index':idx,'tag':tag_text,'offset':pos-payload_len-16,'compressedLength':comp_len,'rawLength':raw_len,'reserved':reserved,'status':status,'data':raw})
        idx+=1
        if tag.startswith(b'END'): break
    return chunks,None

def snippets(text: str, terms, radius=150):
    low=text.lower(); spans=[]
    for term in terms:
        t=term.lower(); start=0
        while True:
            i=low.find(t,start)
            if i<0: break
            spans.append((max(0,i-radius),min(len(text),i+len(t)+radius),term))
            start=i+max(1,len(t))
    spans.sort()
    merged=[]
    for a,b,term in spans:
        if merged and a <= merged[-1][1]:
            merged[-1]=(merged[-1][0],max(merged[-1][1],b),merged[-1][2]+'|'+term)
        else: merged.append((a,b,term))
    return [(a,b,term,text[a:b].replace('\x00','')) for a,b,term in merged]

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('rbxl'); ap.add_argument('--expected-blob-sha'); ap.add_argument('--expected-sha256'); ap.add_argument('--out-dir',required=True); args=ap.parse_args()
    data=Path(args.rbxl).read_bytes(); out=Path(args.out_dir); out.mkdir(parents=True,exist_ok=True)
    sha256=hashlib.sha256(data).hexdigest(); blob=git_blob_sha(data)
    if args.expected_blob_sha and blob!=args.expected_blob_sha: raise SystemExit(f'git blob SHA mismatch: {blob} != {args.expected_blob_sha}')
    if args.expected_sha256 and sha256!=args.expected_sha256: raise SystemExit(f'SHA256 mismatch: {sha256} != {args.expected_sha256}')
    chunks,parse_error=parse_chunks(data)
    chunk_stats=Counter(); strings=[]; assets=set()
    for ch in chunks:
        raw=ch.pop('data',b''); chunk_stats[(ch['tag'],ch['status'])]+=1
        for enc,seq in [('ascii',ascii_strings(raw)),('utf16le',utf16le_strings(raw))]:
            for off,s in seq:
                strings.append({'chunk':ch['index'],'tag':ch['tag'],'encoding':enc,'offset':off,'text':s})
                for m in ASSET_RE.finditer(s): assets.add(m.group(1))
    reports={}
    for domain,terms in DOMAINS.items():
        hits=[]; seen=set(); counts=Counter()
        for item in strings:
            s=item['text']; low=s.lower(); matched=[t for t in terms if t.lower() in low]
            if not matched: continue
            for t in matched: counts[t]+=1
            for a,b,term,snip in snippets(s,matched):
                snip=' '.join(snip.split())
                if len(snip)>500: snip=snip[:500]+'…'
                key=(item['chunk'],item['tag'],snip)
                if key in seen: continue
                seen.add(key)
                ids=sorted(set(m.group(1) for m in ASSET_RE.finditer(snip)),key=lambda x:int(x))
                hits.append({'chunk':item['chunk'],'tag':item['tag'],'encoding':item['encoding'],'offset':item['offset']+a,'terms':sorted(set(term.split('|'))),'assetIds':ids,'text':snip})
        hits.sort(key=lambda x:(x['chunk'] if x['chunk'] is not None else 10**9,x['offset']))
        reports[domain]={'terms':terms,'termCounts':dict(counts),'hitCount':len(hits),'hits':hits[:750],'truncated':len(hits)>750}
        (out/f'{domain}.json').write_text(json.dumps(reports[domain],indent=2)+'\n')
    manifest={
      'file':os.path.basename(args.rbxl),'size':len(data),'sha256':sha256,'gitBlobSha':blob,'magicHex':data[:16].hex(),'parseError':parse_error,
      'chunkCount':len(chunks),'chunkStats':[{ 'tag':k[0],'status':k[1],'count':v} for k,v in sorted(chunk_stats.items())],
      'stringCount':len(strings),'assetIdCount':len(assets),'assetIds':sorted(assets,key=lambda x:int(x)),
      'domainHitCounts':{d:r['hitCount'] for d,r in reports.items()}
    }
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    lines=['# Licensed ROBLOX High School binary extraction','',f'- Size: {len(data):,} bytes',f'- SHA-256: `{sha256}`',f'- Git blob SHA: `{blob}`',f'- Parsed chunks: {len(chunks):,}',f'- Extracted printable strings: {len(strings):,}',f'- Asset IDs observed: {len(assets):,}','']
    for d,r in reports.items(): lines.append(f'- {d}: {r["hitCount"]:,} indexed matches')
    lines += ['', 'All reports are evidence indexes only. A matched string or asset ID is not automatically a product authorization; provenance/ownership rules still apply.']
    (out/'SUMMARY.md').write_text('\n'.join(lines)+'\n')
    print(json.dumps({k:manifest[k] for k in ('size','sha256','gitBlobSha','parseError','chunkCount','stringCount','assetIdCount','domainHitCounts')},indent=2))

if __name__=='__main__': main()
