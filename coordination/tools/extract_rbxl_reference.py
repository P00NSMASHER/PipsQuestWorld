#!/usr/bin/env python3
import argparse, hashlib, json, re, struct, urllib.request
from pathlib import Path

RBXL_SIG = bytes.fromhex('3c726f626c6f782189ff0d0a1a0a')
PRINTABLE = set(range(0x20, 0x7f)) | {9, 10, 13}
MAX_TEXT_FILE_BYTES = 700_000
MAX_RUN_BYTES = 120_000


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(f'blob {len(data)}\0'.encode('ascii') + data).hexdigest()


def download(url: str) -> bytes:
    req = urllib.request.Request(url, headers={'User-Agent': 'PipsQuestWorld-binary-reference-extractor/2'})
    with urllib.request.urlopen(req, timeout=120) as response:
        return response.read()


def lz4_block_decompress(src: bytes, expected_size: int) -> bytes:
    i = 0
    out = bytearray()
    while i < len(src):
        token = src[i]
        i += 1
        literal_len = token >> 4
        if literal_len == 15:
            while True:
                if i >= len(src):
                    raise ValueError('truncated LZ4 literal length')
                b = src[i]
                i += 1
                literal_len += b
                if b != 255:
                    break
        if i + literal_len > len(src):
            raise ValueError('truncated LZ4 literals')
        out.extend(src[i:i + literal_len])
        i += literal_len
        if i >= len(src):
            break
        if i + 2 > len(src):
            raise ValueError('truncated LZ4 match offset')
        offset = src[i] | (src[i + 1] << 8)
        i += 2
        if offset == 0 or offset > len(out):
            raise ValueError(f'invalid LZ4 offset {offset} at output {len(out)}')
        match_len = token & 0x0F
        if match_len == 15:
            while True:
                if i >= len(src):
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
        chunks.append({'index': idx, 'signature': name, 'compressedLength': compressed_len,
                       'uncompressedLength': uncompressed_len, 'payload': payload})
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


def slug(text: str) -> str:
    s = re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')
    return s or 'term'


def capped_write(path: Path, records, max_bytes=MAX_TEXT_FILE_BYTES):
    used = 0
    count = 0
    truncated = False
    with path.open('w', encoding='utf-8') as f:
        for record in records:
            data = record.encode('utf-8', 'replace')
            if used + len(data) > max_bytes:
                truncated = True
                break
            f.write(record)
            used += len(data)
            count += 1
        if truncated:
            marker = f'\n--- TRUNCATED at {used} bytes; refine the keyword to narrow evidence ---\n'
            f.write(marker)
            used += len(marker.encode('utf-8'))
    return {'recordsWritten': count, 'bytesWritten': used, 'truncated': truncated}


def write_request(req, root: Path):
    rid = req['id']
    url = req['source_url']
    expected_git = req.get('expected_git_blob_sha', '').lower()
    expected_sha256 = req.get('expected_sha256', '').lower()
    keywords = list(dict.fromkeys(k for k in req.get('keywords', []) if k))
    keyword_lowers = {k: k.lower() for k in keywords}
    data = download(url)
    actual_git = git_blob_sha(data)
    actual_sha256 = hashlib.sha256(data).hexdigest()
    if expected_git and actual_git != expected_git:
        raise ValueError(f'{rid}: Git blob mismatch expected={expected_git} actual={actual_git}')
    if expected_sha256 and actual_sha256 != expected_sha256:
        raise ValueError(f'{rid}: SHA-256 mismatch expected={expected_sha256} actual={actual_sha256}')

    header, chunks = parse_chunks(data)
    out_dir = root / rid
    keyword_dir = out_dir / 'keywords'
    run_dir = out_dir / 'runs'
    keyword_dir.mkdir(parents=True, exist_ok=True)
    run_dir.mkdir(parents=True, exist_ok=True)

    inventory = []
    printable_run_count = 0
    matched_run_count = 0
    fragments = {k: [] for k in keywords}
    runs = {k: [] for k in keywords}
    matched_counts = {k: 0 for k in keywords}
    fragment_seen = {k: set() for k in keywords}
    run_seen = {k: set() for k in keywords}

    for chunk in chunks:
        payload = chunk.pop('payload')
        inventory.append({**chunk, 'payloadSha256': hashlib.sha256(payload).hexdigest()})
        for off, text in printable_runs(payload):
            printable_run_count += 1
            lower = text.lower()
            matched = [k for k in keywords if keyword_lowers[k] in lower]
            if not matched:
                continue
            matched_run_count += 1
            for k in matched:
                matched_counts[k] += 1
                for line in text.splitlines() or [text]:
                    if keyword_lowers[k] in line.lower():
                        clean = line.strip('\x00')
                        if clean and clean not in fragment_seen[k]:
                            fragment_seen[k].add(clean)
                            fragments[k].append(
                                f'chunk={chunk["index"]} type={chunk["signature"]} offset={off} | {clean[:4000]}\n'
                            )
                run_key = hashlib.sha256(text.encode('utf-8', 'replace')).hexdigest()
                if run_key not in run_seen[k]:
                    run_seen[k].add(run_key)
                    clipped = text
                    encoded = clipped.encode('utf-8', 'replace')
                    if len(encoded) > MAX_RUN_BYTES:
                        clipped = encoded[:MAX_RUN_BYTES].decode('utf-8', 'replace') + '\n--- RUN CLIPPED ---\n'
                    runs[k].append(
                        f'=== chunk={chunk["index"]} type={chunk["signature"]} offset={off} runSha256={run_key} ===\n{clipped}\n'
                    )

    keyword_index = {}
    for k in keywords:
        name = slug(k)
        frag_meta = capped_write(keyword_dir / f'{name}.txt', fragments[k])
        run_meta = capped_write(run_dir / f'{name}.txt', runs[k])
        keyword_index[k] = {
            'matchedRunCount': matched_counts[k],
            'uniqueFragmentCount': len(fragments[k]),
            'uniqueFullRunCount': len(runs[k]),
            'fragmentFile': f'keywords/{name}.txt',
            'runFile': f'runs/{name}.txt',
            'fragmentFileStatus': frag_meta,
            'runFileStatus': run_meta,
        }

    manifest = {
        'schemaVersion': 2,
        'id': rid,
        'sourceUrl': url,
        'sizeBytes': len(data),
        'gitBlobSha': actual_git,
        'sha256': actual_sha256,
        'expectedGitBlobSha': expected_git or None,
        'expectedSha256': expected_sha256 or None,
        'hashesVerified': True,
        'header': header,
        'chunkCount': len(chunks),
        'printableRunCount': printable_run_count,
        'matchedRunCount': matched_run_count,
        'keywords': keywords,
    }
    (out_dir / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    (out_dir / 'chunks.json').write_text(json.dumps(inventory, indent=2) + '\n', encoding='utf-8')
    (out_dir / 'keyword-index.json').write_text(json.dumps(keyword_index, indent=2) + '\n', encoding='utf-8')
    return manifest, keyword_index


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
        manifest, keyword_index = write_request(req, root)
        manifests.append(manifest)
        print('BINARY_REFERENCE_EXTRACT_PASS', json.dumps({
            'id': manifest['id'], 'gitBlobSha': manifest['gitBlobSha'], 'sha256': manifest['sha256'],
            'chunks': manifest['chunkCount'], 'runs': manifest['printableRunCount'],
            'matchedRuns': manifest['matchedRunCount'],
            'keywordMatches': {k: v['matchedRunCount'] for k, v in keyword_index.items() if v['matchedRunCount']}
        }, sort_keys=True))
    (root / 'index.json').write_text(json.dumps({'schemaVersion': 2, 'requests': manifests}, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
