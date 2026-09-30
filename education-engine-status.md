# Education Engine Adapter Status

STATUS: READY
FOUNDATION_BASE: b7eb3fbe1eb65f31f36bc08a1aeda7830f736a71
BRANCH: rebuild/education-engine-adapter
OBJECTIVE: Standalone server-authoritative Grade-2 question engine with zero Maze World gameplay/UI ownership and no client-reachable answer authority.

VERIFIED:
- schema accepts 2-4 unique choices;
- engine now lives under ServerStorage; correctIndex and answer validation are not client-reachable; clientView still omits correctIndex;
- current-material tier is exhausted before STAR fallback;
- no repeated question inside one five-question quest;
- maximum difficulty increase is capped at +1;
- at least one transfer/application item is forced by the final slot when available;
- same-skill comeback remains scheduled after a miss;
- first miss clue -> second miss support -> third miss model;
- assisted resolutions are distinguishable from independent mastery;
- first-try = 25 points, corrected = 20, modeled = 0; percentages normalize over five questions;
- A/B/C/Practice grade bands are available as evidence metadata;
- mastery titles use independent-correct count only, so supported answers cannot inflate mastery.

TESTS:
- PipsEducationEngine.lua Luau compile PASS.
- test-pips-education-engine.luau Luau compile PASS.
- deterministic standalone test suite PASS.

BOUNDARIES:
- no Maze World protected files changed;
- no answer-key ModuleScript remains under ReplicatedStorage/common;
- no geometry, HUD, camera, finish, reward, RemoteEvent, or world ownership;
- no publish authority.

EXIT: READY for Contract Guardian once committed at an exact SHA.
