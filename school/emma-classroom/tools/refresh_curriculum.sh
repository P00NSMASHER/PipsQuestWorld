#!/usr/bin/env bash
# Governed ABVM -> Emma data-only build. No pushes, merges, release edits or Roblox publishing.
set -euo pipefail
SOURCE_ROOT="${1:?Pass a clean, exact-commit ABVM checkout}"
SOURCE_ROOT="$(realpath "$SOURCE_ROOT")"
SOURCE_SHA="$(git -C "$SOURCE_ROOT" rev-parse HEAD)"
DEST_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[[ "$SOURCE_SHA" =~ ^[a-f0-9]{40}$ ]] || { echo "An exact ABVM commit is required" >&2; exit 1; }
test -z "$(git -C "$SOURCE_ROOT" status --porcelain --untracked-files=no)"
STAGE_ROOT="$(mktemp -d)"
trap 'rm -rf "$STAGE_ROOT"' EXIT

# Verify the public educator-reviewed source before constructing any consumer files.
(cd "$SOURCE_ROOT" && node --test tests/study-universe.test.mjs)
node "$SOURCE_ROOT/scripts/build-study-universe.mjs" "$STAGE_ROOT/curriculum.json"
python3 "$DEST_ROOT/tools/import_study_universe.py" "$STAGE_ROOT/curriculum.json" \
  --previous-bundle "$DEST_ROOT/curriculum.json" --source-sha "$SOURCE_SHA" \
  --out "$STAGE_ROOT/QuestionBank.lua" --receipt "$STAGE_ROOT/receipt.json"

# A matching JSON bundle alone does NOT mean this pipeline is healthy: an
# otherwise untouched rebuild can accidentally delete or edit the generated
# server-only answer bank or its receipt. Verify the complete accepted trio.
# If the public source commit advanced with byte-identical content, keep the
# previously accepted source SHA and avoid a meaningless receipt-only PR.
if cmp -s "$STAGE_ROOT/curriculum.json" "$DEST_ROOT/curriculum.json"; then
  ACCEPTED_SHA="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["sourceCommit"])' "$DEST_ROOT/curriculum-receipt.json")"
  [[ "$ACCEPTED_SHA" =~ ^[a-f0-9]{40}$ ]] || { echo "Invalid accepted receipt source" >&2; exit 1; }
  python3 "$DEST_ROOT/tools/import_study_universe.py" "$DEST_ROOT/curriculum.json" \
    --previous-bundle "$DEST_ROOT/curriculum.json" --source-sha "$ACCEPTED_SHA" \
    --out "$STAGE_ROOT/accepted-QuestionBank.lua" --receipt "$STAGE_ROOT/accepted-receipt.json" >/dev/null
  if cmp -s "$STAGE_ROOT/accepted-QuestionBank.lua" "$DEST_ROOT/server/QuestionBank.lua" &&
     cmp -s "$STAGE_ROOT/accepted-receipt.json" "$DEST_ROOT/curriculum-receipt.json"; then
    echo "NO_CHANGE: governed content, answer bank and accepted receipt all match."
    exit 0
  fi
  echo "REPAIR_REQUIRED: reviewed content matches but generated bank/receipt has drifted."
fi

# Validate all generated files before editing the working tree. Source provenance,
# names/keys, historical IDs, answer privacy and tier/test boundaries are guarded
# by the deterministic importer. CI will also recheck the updated working tree.
cp "$STAGE_ROOT/curriculum.json" "$DEST_ROOT/curriculum.json"
cp "$STAGE_ROOT/QuestionBank.lua" "$DEST_ROOT/server/QuestionBank.lua"
cp "$STAGE_ROOT/receipt.json" "$DEST_ROOT/curriculum-receipt.json"
python3 -m unittest discover -s "$DEST_ROOT/tests" -p test_curriculum_import.py
echo "CONTENT_CANDIDATE_READY: exact ABVM commit $SOURCE_SHA; no Roblox publication."
