import fs from "node:fs";
import crypto from "node:crypto";

const file = process.argv[2];
if (!file) throw new Error("usage: node scripts/fingerprint-rbxlx.mjs <file.rbxlx>");
const data = fs.readFileSync(file);
const marker = Buffer.from("<SharedStrings>");
const offset = data.indexOf(marker);
if (offset < 0) throw new Error("SharedStrings marker missing");
const prefix = data.subarray(0, offset);
const tail = data.subarray(offset);
const sha256 = (buf) => crypto.createHash("sha256").update(buf).digest("hex");
const tailText = tail.toString("utf8");
const sharedStringCount = (tailText.match(/<SharedString md5=/g) || []).length;
console.log(JSON.stringify({
  bytes: data.length,
  rawSha256: sha256(data),
  structuralPrefixBytes: prefix.length,
  structuralPrefixSha256: sha256(prefix),
  sharedStringsBytes: tail.length,
  sharedStringCount,
}));
