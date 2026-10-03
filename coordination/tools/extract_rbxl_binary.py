#!/usr/bin/env python3
import argparse, hashlib, json, os, re, struct, sys
from pathlib import Path

try:
    import lz4.block
except Exception as exc:
    print(f'ERROR: lz4.block unavailable: {exc}', file=sys.stderr)
    sys.exit(2)

MAGIC = b'<roblox!'

def git_blob_sha(data: bytes) -> str:
    h = hashlib.sha1()
    h.update(f'blob {len(data)}\0'.encode())
    h.update(data)
    return h.hexdigest()

def ascii_strings(data: bytes, min_len=4):
    out=[]
    start=None
    for i,b in enumerate(data):
        if 32 <= b <= 126 or b in (9,10,13):
            if start is None:
                start=i
        else:
            if start is not None and i-start >= min_len:
                out.append((start, data[start:i].decode('utf-8','replace')))
            start=None
    if start is not None and len(data)-start >= min_len:
        out.append((start, data[start:].decode('utf-8','replace')))
    return out

def utf16le_strings(data: bytes, min_chars=4):
    out=[]
    pat = re.compile(rb'(?:[\x20-\x7e]\x00){%d,}' % min_chars)
    for m in pat.finditer(data):
        try:
            out.append((m.start(), m.group().decode('utf-16le')))
        except Exception:
            pass
    return out

def parse_chunks(data: bytes):
    chunks=[]
    if not data.startswith(MAGIC):
        return chunks, 'unexpected_magic'
    pos=32
    idx=0
    while pos+16 <= len(data):
        tag=data[pos:pos+4]
        tag_text=tag.decode('ascii','replace')
        comp_len, raw_len, reserved = struct.unpack_from('<III', data, pos+4)
        pos += 16
        payload_len = comp_len if comp_len else raw_len
        if pos+payload_len > len(data):
            chunks.append({'index':idx,'tag':tag_text,'offset':pos-16,'error':'payload_bounds','compressedLength':comp_len,'rawLength':raw_len})
            break
        payload=data[pos:pos+payload_len]
        pos += payload_len
        if comp_len:
            try:
                raw=lz4.block.decompress(payload, uncompressed_size=raw_len)
                status='lz4'
            except Exception as exc:
                raw=b''
                status='decompress_error:'+str(exc)
        else:
            raw=payload
            status='raw'
        chunks.append({'index':idx,'tag':tag_text,'offset':pos-payload_len-16,'compressedLength':comp_len,'rawLength':raw_len,'reserved':reserved,'status':status,'data':raw})
        idx += 1
        if tag.startswith(b'END'):
            break
    return chunks, None

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('rbxl')
    ap.add_argument('--expected-blob-sha')
    ap.add_argument('--expected-sha256')
    ap.add_argument('--out-dir', required=True)
    args=ap.parse_args()
    data=Path(args.rbxl).read_bytes()
    out=Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    sha256=hashlib.sha256(data).hexdigest()
    blob=git_blob_sha(data)
    if args.expected_blob_sha and blob != args.expected_blob_sha:
        raise SystemExit(f'git blob SHA mismatch: {blob} != {args.expected_blob_sha}')
    if args.expected_sha256 and sha256 != args.expected_sha256:
        raise SystemExit(f'SHA256 mismatch: {sha256} != {args.expected_sha256}')

    chunks, parse_error = parse_chunks(data)
    keyword_re=re.compile(r'(furn|house|home|wall|paint|build|chair|lamp|utilit|other|move|rotate|sell|buy|place|edit|save|asset|texture|mesh|decal)', re.I)
    asset_re=re.compile(r'(?:rbxassetid://|https?://(?:www\.)?roblox\.com/(?:asset/\?id=|library/)|assetId[^0-9]{0,12})(\d{4,})', re.I)
    findings=[]
    assets=set()
    all_strings=[]

    for ch in chunks:
        raw=ch.pop('data', b'')
        for enc, seq in [('ascii',ascii_strings(raw)),('utf16le',utf16le_strings(raw))]:
            for off,s in seq:
                if len(s)>2000:
                    s=s[:2000]+'…'
                item={'chunk':ch['index'],'tag':ch['tag'],'encoding':enc,'offset':off,'text':s}
                all_strings.append(item)
                if keyword_re.search(s):
                    findings.append(item)
                for m in asset_re.finditer(s):
                    assets.add(m.group(1))

    for enc, seq in [('ascii-raw',ascii_strings(data)),('utf16le-raw',utf16le_strings(data))]:
        for off,s in seq:
            if keyword_re.search(s):
                findings.append({'chunk':None,'tag':'RAW','encoding':enc,'offset':off,'text':s[:2000]})
            for m in asset_re.finditer(s):
                assets.add(m.group(1))

    manifest={
      'file':os.path.basename(args.rbxl),
      'size':len(data),
      'sha256':sha256,
      'gitBlobSha':blob,
      'magicHex':data[:16].hex(),
      'parseError':parse_error,
      'chunkCount':len(chunks),
      'chunks':chunks,
      'stringCount':len(all_strings),
      'keywordFindingCount':len(findings),
      'assetIdCount':len(assets),
      'assetIds':sorted(assets,key=lambda x:int(x))
    }

    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (out/'keyword_findings.json').write_text(json.dumps(findings,indent=2)+'\n')
    (out/'strings.txt').write_text('\n'.join(f"[{x['chunk']}:{x['tag']}:{x['encoding']}:{x['offset']}] {x['text']}" for x in all_strings)+'\n', errors='replace')
    print(json.dumps({k:manifest[k] for k in ('size','sha256','gitBlobSha','parseError','chunkCount','stringCount','keywordFindingCount','assetIdCount')},indent=2))

if __name__=='__main__':
    main()
