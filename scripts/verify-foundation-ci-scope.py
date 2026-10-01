#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
workflow = root / ".github/workflows/school-pivot-ci.yml"
text = workflow.read_text()

required = (
    '- "school/**"',
    '- rebuild/high-school-foundation',
    'python3 scripts/verify-school-pivot.py',
    'python3 scripts/verify-foundation-ci-scope.py',
)
for token in required:
    if token not in text:
        raise SystemExit(f"foundation CI missing required canonical token: {token}")

for forbidden in (
    '"highschool/**"',
    "highschool/tests",
    'rebuild/high-school-*',
):
    if forbidden in text:
        raise SystemExit(f"foundation CI references noncanonical parallel scope: {forbidden}")

if text.count('- rebuild/high-school-foundation') != 1:
    raise SystemExit("foundation CI must name exactly one canonical rebuild branch")

print("FOUNDATION_CI_SCOPE_OK")
