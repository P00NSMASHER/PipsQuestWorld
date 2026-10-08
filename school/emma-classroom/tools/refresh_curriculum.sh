#!/usr/bin/env bash
# Prepare reviewed content; never push, merge or publish a Roblox place.
set -euo pipefail
SOURCE_ROOT="${1:?Path to an exact-SHA ABVM checkout required}"
SOURCE_SHA="$(git -C "$SOURCE_ROOT" rev-parse HEAD)"
SOURCE_ROOT="$(realpath "$SOURCE_ROOT")"
DEST_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test -z "$(git -C "$SOURCE_ROOT" status --porcelain --untracked-files=no)"
STAGE_ROOT="$(mktemp -d)"
trap 'rm -rf "$STAGE_ROOT"' EXIT
(cd "$SOURCE_ROOT" && node --test tests/study-universe.test.mjs)
node "$SOURCE_ROOT/scripts/build-study-universe.mjs" "$STAGE_ROOT/curriculum.json"
python3 "$DEST_ROOT/tools/import_study_universe.py" "$STAGE_ROOT/curriculum.json" \
  --previous-bundle "$DEST_ROOT/curriculum.json" --source-sha "$SOURCE_SHA" --out "$STAGE_ROOT/QuestionBank.lua" --receipt "$STAGE_ROOT/receipt.json"
# All content validation finishes before replacing any checked-in output.
if cmp -s "$STAGE_ROOT/curriculum.json" "$DEST_ROOT/curriculum.json"; then
  echo "Accepted educational content already matches this reviewed source."
  exit 0
fi
cp "$STAGE_ROOT/curriculum.json" "$DEST_ROOT/curriculum.json"
cp "$STAGE_ROOT/QuestionBank.lua" "$DEST_ROOT/server/QuestionBank.lua"
cp "$STAGE_ROOT/receipt.json" "$DEST_ROOT/curriculum-receipt.json"
python3 -m unittest discover -s "$DEST_ROOT/tests" -p test_curriculum_import.py
