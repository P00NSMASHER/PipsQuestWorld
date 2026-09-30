# RHS source layout

## baseline/

Immutable licensed reference build. Its byte identity must always match `BASELINE.json`.

## working/

Active compatibility-restoration build. It starts identical to baseline and may later diverge only through documented, deterministic repairs.

## Rule

Never "clean up" the baseline. If an old API, dead URL, broken asset, or deprecated service needs repair, patch the working copy and record the deviation.
