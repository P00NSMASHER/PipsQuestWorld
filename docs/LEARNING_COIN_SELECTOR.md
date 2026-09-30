# Native Coin Selection Contract

This helper is **standalone preparation only**. It does not observe Roblox Instances,
connect touch events, grant coins, open UI, or modify Maze World.

`PipsLearningCoinSelector.lua` accepts cached metadata for native coin candidates and:

- filters out `onePerPlayer` treasure;
- filters explicitly ineligible candidates;
- requires stable candidate key + itemId;
- sorts candidates before selection so instance enumeration order cannot change the result;
- selects exactly one candidate deterministically from a run id;
- returns no candidate when only treasure/ineligible items exist.

The future world adapter must create the candidate metadata from native generated Maze World
coins without modifying their tag, itemId, collision, parent, reward handler, or destruction
behavior. The selector has no gameplay authority.
