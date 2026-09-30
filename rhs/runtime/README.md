# RHS runtime evidence

Runtime evidence is intentionally **not** checked into the repository by default.

Use `scripts/prepare-rhs-studio-smoke.ps1` before a Studio run and
`scripts/collect-rhs-studio-smoke.ps1` afterward to capture the candidate
hash plus relevant Roblox Studio log lines into a local JSON receipt.

The collector is evidence-only. A clean log does not replace the direct
Gate A / Gate B observations required by `docs/RHS_RUNTIME_SMOKE.md`.

Do not upload raw Studio logs unless they have been reviewed for account,
machine, path, or other local identifiers.
