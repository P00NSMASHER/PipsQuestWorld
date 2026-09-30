# QA State

Verdict: BLOCKED

Candidate fingerprint: `016fd9d84f777f85334131787f7db9355fd6416a2299811b5786721e659de59d`

Education exact head `f50083fd0ad472a0a6a6be97ca9dc58dbfb2f1d3` fails GitHub Actions run 36733662578 at `Verify backend-only education contract`; parent `6e8490ae18bc09cf2aaaa30d4e06e97310e1d1b7` passed run 36730808735.

The new static test requires literal `reason = ...` table fields, while the implementation routes the same reasons through `failOpen(...)`. This is a branch-owned test-harness mismatch rather than a reproduced Maze World gameplay defect.

Owner: Education Engine.

Contract Guardian head: `e751135bce4afc6bc80d8aa23b55a1e4f58c3421`; review blob `06443e1fb5877d2f7d1b3c04e85eb5c2a8b0fde7`; verdict `STANDALONE PREP PASS / GAMEPLAY INTEGRATION BLOCKED`. The review is stale for the current producer heads.

Foundation `a56bbe499dfc6c2c961863b648b50bdc9fec0071` passes run 36747240304. Pip Rewards `4c216ac7e97325f764947ef55b6c1de41b652429` passes run 36746131557. Content-QA `aa67c1e0f7b5b103b387eaf2e7d21796a50c891b` passes runs 36742669645 and 36742703302.

Stopped on the first release-blocking root cause. No tests were weakened or deleted. No merge or Roblox deployment was performed.
