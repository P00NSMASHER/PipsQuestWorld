# Emma / ABVM Roblox release-provenance continuation — version 82

## Next prompt executed

Act as a Roblox release engineer and secure CI maintainer for Emma's **current
classroom-only photo-hallway candidate**, not the historical study game.
Reconcile its confirmed publisher receipt with the last independently
verified Roblox publication. Prevent a stacked hallway PR from replacing a
later recorded live place version with older publication metadata, or
silently substituting a different source commit, GitHub Actions run or
binary checksum for the *same* numbered publication.

Do not change gameplay or geometry; do not alter the child's photo work
pipeline, original school photos, active scheduled tasks, live Roblox place,
publication authorization or native iPhone acceptance criteria.

## Grounded publication evidence

The older candidate recorded version **81** (`5dd8e046...`), but the
parent hallway review branch recorded the newer **82** publication.
This was verified **independently** against the completed
[GitHub Actions publication run 38115148189]
(https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/38115148189):

- GitHub Actions job `publish` completed successfully.
- Checkout and `SOURCE_SHA` are
  `4a834d1e90253f3f5cced709fe16a878896126c5`.
- Actual publisher response artifact `publish-response.json` says
  `{"versionNumber":82}`.
- The saved `version.txt` says `Roblox place version: 82`.
- The saved `place.sha256` digest is exactly
  `b931b6a20ae219b0c39196351acbfe8a6ac2aff6ea43f23743d78114b3d20555`.
- Target place is `114603280760042` in universe `10769455759`.
- The publication run artifact is
  `emma-replica-publish-38115148189` (artifact ID `11693162544`).

The v82 receipt is **historical publication evidence**, not proof that
a newer candidate branch head or PR has been published, and not Roblox
Studio / native iPhone visual acceptance.

## Changes on stacked draft PR #344

1. `RELEASE_RECEIPT.json` is synchronized **verbatim** with the independently
   verified v82 parent branch receipt. No fabricated timestamp, approval,
   new publication or place ID is introduced.
2. `verify_release_receipt.py` now requires an actual 64-character
   hexadecimal published binary SHA256 and can compare a candidate
   receipt with a PR target-branch receipt using `--compare-base`.
   Versions may **never decrease** relative to the target branch.
   Equal-numbered versions must preserve exact source, action run,
   workflow URL, place/universe, mode, acceptance and binary checksum.
   A structurally later version is only reported as *unverified newer
   publication* until separate successful publisher run/artifact evidence
   establishes it.
3. Negative tests reject forged older versions, same-version source/run/
   checksum substitutions, invalid checksums, production furniture
   activation and invented native iPhone acceptance.
4. `.github/workflows/emma-showroom-ci.yml` performs the comparison
   early against the actual current head of the PR's base branch,
   retrieved read-only from Git. It does **not** use a stale merge-base
   SHA or self-declared publication version. Archive branches without a
   comparable receipt are reported as unverifiable rather than
   falsely marked reconciled.

## Release constraints

- The v82 preview may be live; the **unmerged hallway junction and
  visual-camera candidate is not proven published**.
- No automatic Roblox publish, merge, release approval or invocation
  of publisher secrets is part of this task.
- The existing `PREVIEW_REQUEST` and single-use release gates remain
  unchanged. Non-native source-derived render success does not confirm
  smartphone movement, physics, lighting, glass quality or FPS.
- Tests comparing reports establish **consistency**, not independent
  Roblox API attestation for future versions. A later v83/v84 must be
  independently verified against the actual successful publisher job
  and its saved binary digest before updating the receipt.

Keep the parent hallway PR #343 and stacked PR #344 draft until reviewed.
