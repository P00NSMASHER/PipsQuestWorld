#!/usr/bin/env python3
"""Zero-cost cloud extractor for a pinned Roblox binary .rbxl reference.

Downloads only the configured public GitHub mirrors, verifies the exact Git blob
SHA and SHA-256 before extraction, then emits UTF-8 evidence files that GitHub
connectors can read even when the source .rbxl is binary.

This intentionally does not import the place as product code.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Iterable

DEFAULT_URLS = [
    "https://raw.githubusercontent.com/MisoNotSoupx/Old-Roblox-Place-Archive/"
    "b817aef0eaf77d3382acacdc8f22537e54c76822/"
    "Created%20by%20Users/Cindering/ROBLOX%20High%20School.rbxl",
    "https://raw.githubusercontent.com/IIIStatusIII/Roblox-Uncopylocked-Games/"
    "main/RobloxHighSchool.rbxl",
]
EXPECTED_GIT_BLOB_SHA = "95ee3d762f419bb3572e18db57c03682651dc8c4"
EXPECTED_SHA256 = "d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360"

KEYWORDS = [
    "house", "housing", "furn", "furniture", "wall", "paint", "build", "chair",
    "lamp", "utility", "utilities", "other", "edit", "sell", "buy", "place",
    "move", "rotate", "catalog", "inventory", "landlord", "save", "teleport",
    "asset", "texture", "mesh", "image", "gui", "button", "frame", "label",
]

ASCII_RE = re.compile(rb"[\x20-\x7e]{4,}")
UTF16LE_RE = re.compile(rb"(?:[\x20-\x7e]\x00){4,}")
ASSET_RE = re.compile(
    r"(?:rbxassetid://|asset\?id=|id=)(\d{4,})|"
    r"https?://(?:www\.)?roblox\.com/(?:asset|library)/\?id=(\d{4,})",
    re.IGNORECASE,
)


def git_blob_sha(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def download_verified(urls: Iterable[str]) -> tuple[bytes, str]:
    errors: list[str] = []
    for url in urls:
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "PipsQuestWorld-reference-extractor/1.0"},
            )
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = resp.read()
            blob = git_blob_sha(data)
            sha256 = hashlib.sha256(data).hexdigest()
            if blob != EXPECTED_GIT_BLOB_SHA:
                errors.append(f"{url}: git blob mismatch {blob}")
                continue
            if sha256 != EXPECTED_SHA256:
                errors.append(f"{url}: sha256 mismatch {sha256}")
                continue
            return data, url
        except (OSError, urllib.error.URLError, urllib.error.HTTPError) as exc:
            errors.append(f"{url}: {exc}")
    raise RuntimeError("No verified mirror succeeded:\n" + "\n".join(errors))


def lz4_block_decompress(src: bytes, expected_size: int) -> bytes:
    """Minimal LZ4 block decoder sufficient for Roblox binary chunks."""
    out = bytearray()
    i = 0

    def read_len(initial: int) -> int:
        nonlocal i
        length = initial
        if initial == 15:
            while True:
                if i >= len(src):
                    raise ValueError("truncated LZ4 length")
                b = src[i]
                i += 1
                length += b
                if b != 255:
                    break
        return length

    while i < len(src):
        token = src[i]
        i += 1

        literal_len = read_len(token >> 4)
        if i + literal_len > len(src):
            raise ValueError("truncated LZ4 literal")
        out.extend(src[i : i + literal_len])
        i += literal_len

        if i >= len(src):
            break

        if i + 2 > len(src):
            raise ValueError("truncated LZ4 offset")
        offset = src[i] | (src[i + 1] << 8)
        i += 2
        if offset <= 0 or offset > len(out):
            raise ValueError(f"invalid LZ4 offset {offset}")

        match_len = read_len(token & 0x0F) + 4
        start = len(out) - offset
        for j in range(match_len):
            out.append(out[start + j])

    if expected_size and len(out) != expected_size:
        raise ValueError(
            f"LZ4 size mismatch: got {len(out)}, expected {expected_size}"
        )
    return bytes(out)


def parse_chunks(data: bytes) -> list[dict]:
    chunks: list[dict] = []
    if not data.startswith(b"<roblox!"):
        return chunks

    # Binary RBXL header: 14-byte signature, version u16, class count u32,
    # instance count u32, reserved u64. Chunks begin at byte 32.
    pos = 32
    index = 0
    while pos + 16 <= len(data):
        name_raw = data[pos : pos + 4]
        name = name_raw.decode("ascii", errors="replace")
        compressed_len, uncompressed_len, reserved = struct.unpack_from(
            "<III", data, pos + 4
        )
        pos += 16

        payload_len = compressed_len if compressed_len else uncompressed_len
        if pos + payload_len > len(data):
            break
        raw_payload = data[pos : pos + payload_len]
        pos += payload_len

        decode_error = None
        if compressed_len:
            try:
                payload = lz4_block_decompress(raw_payload, uncompressed_len)
            except Exception as exc:
                payload = raw_payload
                decode_error = str(exc)
        else:
            payload = raw_payload

        chunks.append(
            {
                "index": index,
                "name": name,
                "compressedLength": compressed_len,
                "uncompressedLength": uncompressed_len,
                "reserved": reserved,
                "payload": payload,
                "decodeError": decode_error,
            }
        )
        index += 1
        if name.startswith("END"):
            break
    return chunks


def extract_strings(payload: bytes, source: str) -> list[dict]:
    records: list[dict] = []
    for match in ASCII_RE.finditer(payload):
        text = match.group().decode("ascii", errors="replace")
        records.append(
            {"source": source, "offset": match.start(), "encoding": "ascii", "text": text}
        )
    for match in UTF16LE_RE.finditer(payload):
        try:
            text = match.group().decode("utf-16le")
        except UnicodeDecodeError:
            continue
        records.append(
            {"source": source, "offset": match.start(), "encoding": "utf16le", "text": text}
        )
    return records


def dedupe_records(records: list[dict]) -> list[dict]:
    seen: set[tuple[str, str]] = set()
    out: list[dict] = []
    for rec in records:
        key = (rec["source"], rec["text"])
        if key in seen:
            continue
        seen.add(key)
        out.append(rec)
    return out


def write_outputs(data: bytes, source_url: str, outdir: Path) -> None:
    outdir.mkdir(parents=True, exist_ok=True)
    chunks = parse_chunks(data)

    records = extract_strings(data, "raw")
    for chunk in chunks:
        records.extend(
            extract_strings(
                chunk["payload"],
                f"chunk[{chunk['index']}]:{chunk['name']}",
            )
        )
    records = dedupe_records(records)

    housing_hits = [
        rec
        for rec in records
        if any(k in rec["text"].lower() for k in KEYWORDS)
    ]
    script_hits = [
        rec
        for rec in records
        if len(rec["text"]) >= 24
        and any(
            token in rec["text"]
            for token in ("function ", "local ", "script.", "game.", ":Connect", ":connect")
        )
    ]

    assets: set[str] = set()
    for rec in records:
        for match in ASSET_RE.finditer(rec["text"]):
            asset_id = match.group(1) or match.group(2)
            if asset_id:
                assets.add(asset_id)

    manifest = {
        "sourceUrl": source_url,
        "byteLength": len(data),
        "gitBlobSha": git_blob_sha(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "expectedGitBlobSha": EXPECTED_GIT_BLOB_SHA,
        "expectedSha256": EXPECTED_SHA256,
        "verified": (
            git_blob_sha(data) == EXPECTED_GIT_BLOB_SHA
            and hashlib.sha256(data).hexdigest() == EXPECTED_SHA256
        ),
        "chunkCount": len(chunks),
        "stringRecordCount": len(records),
        "housingHitCount": len(housing_hits),
        "scriptLikeHitCount": len(script_hits),
        "assetIdCount": len(assets),
        "extractor": "scripts/extract-roblox-binary-reference.py",
    }

    chunk_manifest = [
        {k: v for k, v in chunk.items() if k != "payload"}
        for chunk in chunks
    ]

    (outdir / "reference_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    (outdir / "chunk_manifest.json").write_text(
        json.dumps(chunk_manifest, indent=2) + "\n", encoding="utf-8"
    )

    def dump_records(path: Path, values: list[dict]) -> None:
        with path.open("w", encoding="utf-8") as fh:
            for rec in values:
                text = rec["text"].replace("\r", "\\r").replace("\n", "\\n")
                fh.write(
                    f"{rec['source']}\t{rec['offset']}\t{rec['encoding']}\t{text}\n"
                )

    dump_records(outdir / "all_strings.txt", records)
    dump_records(outdir / "housing_hits.txt", housing_hits)
    dump_records(outdir / "script_like_strings.txt", script_hits)
    (outdir / "asset_ids.txt").write_text(
        "\n".join(sorted(assets, key=lambda x: (len(x), x))) + ("\n" if assets else ""),
        encoding="utf-8",
    )

    summary_lines = [
        "# Roblox High School binary reference extraction",
        "",
        f"- verified: {manifest['verified']}",
        f"- source: {source_url}",
        f"- bytes: {manifest['byteLength']}",
        f"- git blob SHA: {manifest['gitBlobSha']}",
        f"- SHA-256: {manifest['sha256']}",
        f"- parsed chunks: {manifest['chunkCount']}",
        f"- extracted strings: {manifest['stringRecordCount']}",
        f"- housing-related hits: {manifest['housingHitCount']}",
        f"- script-like hits: {manifest['scriptLikeHitCount']}",
        f"- distinct asset IDs: {manifest['assetIdCount']}",
        "",
        "## Highest-signal housing hits",
        "",
    ]
    for rec in housing_hits[:250]:
        text = rec["text"].replace("\r", "\\r").replace("\n", "\\n")
        if len(text) > 500:
            text = text[:500] + "..."
        summary_lines.append(
            f"- {rec['source']}@{rec['offset']} ({rec['encoding']}): {text}"
        )
    (outdir / "summary.md").write_text(
        "\n".join(summary_lines) + "\n", encoding="utf-8"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    parser.add_argument("--outdir", type=Path, default=Path("reference-extract"))
    parser.add_argument("--url", action="append", default=[])
    args = parser.parse_args()

    if args.input:
        data = args.input.read_bytes()
        source_url = str(args.input)
        if git_blob_sha(data) != EXPECTED_GIT_BLOB_SHA:
            raise SystemExit(
                f"git blob mismatch: {git_blob_sha(data)} != {EXPECTED_GIT_BLOB_SHA}"
            )
        if hashlib.sha256(data).hexdigest() != EXPECTED_SHA256:
            raise SystemExit(
                f"sha256 mismatch: {hashlib.sha256(data).hexdigest()} != {EXPECTED_SHA256}"
            )
    else:
        urls = args.url or DEFAULT_URLS
        data, source_url = download_verified(urls)

    write_outputs(data, source_url, args.outdir)
    print((args.outdir / "summary.md").read_text(encoding="utf-8"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
