#!/usr/bin/env python3
import argparse, hashlib, json, struct, urllib.request
from pathlib import Path

RBXL_SIG = bytes.fromhex('3c726f626c6f782189ff0d0a1a0a')
PRINTABLE = set(range(0x20, 0x7f)) | {9, 10, 13}


def git_blob_sha(data: bytes) -> str:
    prefix = f'blob {len(data)}\0'.encode('ascii')
    return hashlib.sha1(prefix + data).hexdigest()


def download(url: str) -> bytes:
    req = urllib.request.Request(url, headers={'User-Agent': 'PipsQuestWorld-binary-reference-extractor/1'})
    with urllib.request.urlopen(req, timeout=120) as response:
        return response.read()


def lz4_block_decompress(src: bytes, expected_size: int) -> bytes:
    i = 0
    out = bytearray()
    n = len(src)
    while i < n:
        token = src[i]
        i += 1
        literal_len = token >> 4
        if literal_len == 15:
            while True:
                if i >= n:
                    raise ValueError('truncated LZ4 literal length')
                b = src[i]
                i += 1
                literal_len += b
                if b != 255:
                    break
        if i + literal_len > n:
            raise ValueError('truncated LZ4 literals')
        out.extend(src[i:i + literal_len])
        i += literal_len
        if i >= n:
            break
        if i + 2 > n:
            raise ValueError('truncated LZ4 match offset')
        offset = src[i] | (src[i + 1] << 8)
        i += 2
        if offset == 0 or offset > len(out):
            raise ValueError(f'invalid LZ4 offset {offset} at output {len(out)}')
        match_len = token & 0x0F
        if match_len == 15:
            while True:
                if i >= n:
                    raise ValueError('truncated LZ4 match length')
                b = src[i]
                i += 1
                match_len += b
                if b != 255:
                    break
        match_len += 4
        start = len(out) - offset
        for _ in range(match_len):
            out.append(out[start])
            start += 1
    if expected_size and len(out) != expected_size:
        raise ValueError(f'LZ4 size mismatch: expected {expected_size}, got {len(out)}')
    return bytes(out)


def parse_chunks(data: bytes):
    if not data.startswith(RBXL_SIG):
        if data.startswith(b'<roblox'):
            return {'format': 'rbxlx', 'version': None, 'classCount': None, 'instanceCount': None}, [
                {'index': 0, 'signature': 'XML', 'compressedLength': 0, 'uncompressedLength': len(data), 'payload': data}
            ]
        raise ValueError('not an RBXL/RBXLX file')
    if len(data) < 32:
        raise ValueError('truncated RBXL header')
    version = struct.unpack_from('<H', data, 14)[0]
    if version != 0:
        raise ValueError(f'unsupported RBXL version {version}')
    class_count, instance_count = struct.unpack_from('<II', data, 16)
    header = {'format': 'rbxl', 'version': version, 'classCount': class_count, 'instanceCount': instance_count}
    chunks = []
    pos = 32
    idx = 0
    while pos + 16 <= len(data):
        sig = data[pos:pos + 4]
        compressed_len, uncompressed_len = struct.unpack_from('<II', data, pos + 4)
        pos += 16
        payload_len = compressed_len if compressed_len else uncompressed_len
        if pos + payload_len > len(data):
            raise ValueError(f'truncated chunk {idx} {sig!r}')
        stored = data[pos:pos + payload_len]
        pos += payload_len
        payload = lz4_block_decompress(stored, uncompressed_len) if compressed_len else stored
        name = 'END' if sig == b'END\x00' else sig.decode('ascii', 'replace')
        chunks.append({
            'index': idx,
            'signature': name,
            'compressedLength': compressed_len,
            'uncompressedLength': uncompressed_len,
            'payload': payload,
        })
        idx += 1
        if sig == b'END\x00':
            break
    if not chunks or chunks[-1]['signature'] != 'END':
        raise ValueError('RBXL END chunk not found')
    return header, chunks


def printable_runs(payload: bytes, min_len: int = 4):
    start = None
    for i, b in enumerate(payload):
        if b in PRINTABLE:
            if start is None:
                start = i
        elif start is not None:
            if i - start >= min_len:
                yield start, payload[start:i].decode('utf-8', 'replace')
            start = None
    if start is not None and len(payload) - start >= min_len:
        yield start, payload[start:].decode('utf-8', 'replace')


def normalized_fragments(text: str):
    for line in text.splitlines() or [text]:
        line = line.strip('\x00')
        if line.strip():
            yield line


def write_request(req, root: Path):
    rid = req['id']
    url = req['source_url']
    expected_git = req.get('expected_git_blob_sha', '').lower()
    expected_sha256 = req.get('expected_sha256', '').lower()
    keywords = [k.lower() for k in req.get('keywords', []) if k]
    data = download(url)
    actual_git = git_blob_sha(data)
    actual_sha256 = hashlib.sha256(data).hexdigest()
    if expected_git and actual_git != expected_git:
        raise ValueError(f'{rid}: Git blob mismatch expected={expected_git} actual={actual_git}')
    if expected_sha256 and actual_sha256 != expected_sha256:
        raise ValueError(f'{rid}: SHA-256 mismatch expected={expected_sha256} actual={actual_sha256}')

    header, chunks = parse_chunks(data)
    out_dir = root / rid
    out_dir.mkdir(parents=True, exist_ok=True)
    inventory = []
    all_runs = []
    hit_records = []
    for chunk in chunks:
        payload = chunk.pop('payload')
        inventory.append({**chunk, 'payloadSha256': hashlib.sha256(payload).hexdigest()})
        for off, text in printable_runs(payload):
            all_runs.append((chunk['index'], chunk['signature'], off, text))
            lower = text.lower()
            matched = sorted({k for k in keywords if k in lower})
            if matched:
                fragments = []
                for line in normalized_fragments(text):
                    ll = line.lower()
                    line_matches = [k for k in matched if k in ll]
                    if line_matches:
                        fragments.append({'keywords': line_matches, 'text': line[:4000]})
                if not fragments:
                    fragments.append({'keywords': matched, 'text': text[:4000]})
                hit_records.append({
                    'chunkIndex': chunk['index'],
                    'chunkSignature': chunk['signature'],
                    'offset': off,
                    'keywords': matched,
                    'fragments': fragments[:200],
                })

    manifest = {
        'schemaVersion': 1,
        'id': rid,
        'sourceUrl': url,
        'sizeBytes': len(data),
        'gitBlobSha': actual_git,
        'sha256': actual_sha256,
        'expectedGitBlobSha': expected_git or None,
        'expectedSha256': expected_sha256 or None,
        'hashesVerified': (not expected_git or actual_git == expected_git) and (not expected_sha256 or actual_sha256 == expected_sha256),
        'header': header,
        'chunkCount': len(chunks),
        'printableRunCount': len(all_runs),
        'hitRecordCount': len(hit_records),
        'keywords': req.get('keywords', []),
    }
    (out_dir / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    (out_dir / 'chunks.json').write_text(json.dumps(inventory, indent=2) + '\n', encoding='utf-8')
    with (out_dir / 'strings.txt').open('w', encoding='utf-8') as f:
        for idx, sig, off, text in all_runs:
            f.write(f'--- chunk={idx} type={sig} offset={off} chars={len(text)} ---\n')
            f.write(text)
            if not text.endswith('\n'):
                f.write('\n')
    with (out_dir / 'hits.json').open('w', encoding='utf-8') as f:
        json.dump(hit_records, f, indent=2)
        f.write('\n')
    with (out_dir / 'hits.txt').open('w', encoding='utf-8') as f:
        for rec in hit_records:
            f.write(f"### chunk={rec['chunkIndex']} type={rec['chunkSignature']} offset={rec['offset']} keywords={','.join(rec['keywords'])}\n")
            for frag in rec['fragments']:
                f.write(f"[{','.join(frag['keywords'])}] {frag['text']}\n")
    return manifest


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('request_file')
    ap.add_argument('output_dir')
    args = ap.parse_args()
    request_doc = json.loads(Path(args.request_file).read_text(encoding='utf-8'))
    root = Path(args.output_dir)
    root.mkdir(parents=True, exist_ok=True)
    manifests = []
    for req in request_doc.get('requests', []):
        m = write_request(req, root)
        manifests.append(m)
        print('BINARY_REFERENCE_EXTRACT_PASS', json.dumps({
            'id': m['id'], 'gitBlobSha': m['gitBlobSha'], 'sha256': m['sha256'],
            'chunks': m['chunkCount'], 'runs': m['printableRunCount'], 'hits': m['hitRecordCount']
        }, sort_keys=True))
    (root / 'index.json').write_text(json.dumps({'schemaVersion': 1, 'requests': manifests}, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
