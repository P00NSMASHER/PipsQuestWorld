# Vehicle Parity Contract — Phase 1

Status: SUPPORT-ONLY PREP FOR THE NEXT CONTROL-TOWER-ASSIGNED VEHICLE SLICE

Canonical base: `92691e009869ee9cd5d9306786502b157a5b6c84`

Product target: the one canonical Pip High / Roblox High School clone currently live on the private Roblox target recorded by Release/Package. This contract must never create or switch to another universe/place.

Phase 2 second-grade schoolwork is explicitly out of scope.

## Purpose

Define the narrow Free-Roam vehicle authority and acceptance surface before runtime implementation. This file adds no gameplay behavior, vehicle models, catalog values, economy writer, persistence writer, world geometry, or client authority.

Exact catalog/model names, prices, performance values, visuals, sounds, entitlement rules, and spawn presentation must come from the authorized Roblox High School parity reference/provenance set. Do not guess or substitute approximate values.

## Existing canonical dependencies

- Foundation owns the world, roads, spawn/world geometry, location registry, and `SchoolConfig.WorldLocations.AutoShop`.
- Progression/Economy owns money, durable transactions, unlock/ownership state, save/rejoin, and conflict/idempotency semantics.
- Free Roam may consume those authorities but must not replace them.
- The canonical economy unlock category for this slice is `vehicle`.

## Exact current canonical bindings

These bindings are verified on canonical `92691e009869ee9cd5d9306786502b157a5b6c84` and must be refreshed if Control Tower advances canonical before Vehicles is assigned.

- Roblox private target from the Release/Package receipt:
  - universe: `10768955678`;
  - place: `87245440673982`.
- Existing canonical remote root: `SchoolConfig.Interfaces.remoteFolder == "SchoolFoundation"`.
- Existing dealership/world anchor: `SchoolConfig.WorldLocations.AutoShop`.
- Existing world physics baseline: Workspace gravity `196.2`; vehicle code must not create a second global physics authority.
- Existing EconomyRepository purchase operation shape:
  - `operationId: string`;
  - `playerId: positive integer`;
  - `delta: integer`;
  - `reason: non-empty string`;
  - `unlock = { category = "vehicle", itemId = <vehicleId> }`.
- Existing EconomyRepository read snapshot exposes `playerId`, `revision`, `balance`, `operationCount`, and sorted `ownership`.
- EconomyRepository already enforces durable replay/idempotency, operation-id conflict rejection, insufficient-funds rejection, already-owned rejection, CAS retry, and reopen/rejoin validation. The vehicle slice must consume those semantics rather than wrapping them in a second ledger.

### Current authority inventory

Canonical `school/default.project.json` currently maps the café Free-Roam authority but maps no vehicle controller, vehicle runtime adapter, vehicle catalog, or vehicle client authority. The assigned Vehicles slice can therefore introduce one vehicle authority cleanly, provided it remains singular.

### Current Foundation dependency gap

Canonical currently exposes the Auto Shop itself, but it does **not** expose a Foundation-owned vehicle spawn location or vehicle-spawn registry.

Therefore the first assigned vehicle runtime candidate must not silently invent a world-space spawn point or derive one from an arbitrary client transform. Before a vehicle is spawned, one of these must be true:

1. Foundation exposes an explicit stable vehicle spawn location/registry on the same canonical lineage; or
2. Control Tower explicitly assigns/approves an equivalent Foundation support contract for the vehicle slice.

A fixed offset privately chosen by Free Roam from `WorldLocations.AutoShop` is not sufficient evidence of Foundation world authority. Until an authorized spawn location exists, purchase/ownership contract work may be tested headlessly, but runtime vehicle spawning remains incomplete.

## Single vehicle authority

The vehicle slice must introduce exactly one server-authoritative vehicle lifecycle owner.

It owns only:

1. owned-vehicle selection;
2. spawn validation;
3. one-active-vehicle-per-player lifecycle;
4. driver/passenger seat lifecycle;
5. drive/steer/brake/reverse behavior;
6. despawn/replacement/reset;
7. vehicle-facing interaction state and client UX.

It must not own:

- money balances;
- durable ownership storage;
- world/road geometry;
- school clock/schedule;
- class state;
- housing/property;
- avatar/outfit state;
- shop/catalog provenance;
- unrelated social systems.

## Suggested Control Tower slicing

This is a support recommendation, not an active assignment. To preserve the one-observable-behavior rule, Vehicles should advance in bounded slices rather than as one oversized candidate:

1. **VEHICLE_4A_FOUNDATION_SPAWN_SEAM** — Foundation exposes the authorized stable vehicle spawn location/registry; no vehicle runtime.
2. **VEHICLE_4B_OWNERSHIP_SPAWN_LIFECYCLE** — one authorized reference vehicle can be purchased/recognized as owned and spawned/despawned exactly once; no broad handling/catalog expansion.
3. **VEHICLE_4C_DRIVE_SEAT_LIFECYCLE** — the same vehicle gains driver/passenger entry, exit, acceleration, steering, brake/reverse, reset and one-active-vehicle enforcement using authorized handling data.
4. **VEHICLE_4D_MOBILE_PRESENTATION** — touch controls, vehicle selector/spawn/despawn UX and HUD coexistence reach the authorized mobile reference.
5. **VEHICLE_4E_CATALOG_PARITY** — expand only after the first vehicle loop is exact-green and smoke-certified.

Every slice must stay on the same private target and exact certified canonical lineage, with QA/Integration/Smoke between product increments when Control Tower requires it.

## Required observable loop

The vehicle milestone is not complete until at least one authorized reference vehicle can complete this deterministic player-visible loop:

1. Player enters the authorized vehicle selection/purchase flow.
2. Server exposes the exact authorized vehicle entry from a server-trusted catalog.
3. If purchase is required, the server submits one idempotent EconomyRepository operation with:
   - a stable purchase operation id;
   - the exact canonical player id;
   - the authorized price as a negative delta;
   - a vehicle-specific reason;
   - `unlock = { category = "vehicle", itemId = <vehicleId> }`.
4. Duplicate purchase cannot double-charge and an already-owned vehicle cannot be purchased again.
5. Insufficient funds cannot create ownership or spawn a paid vehicle.
6. An owned/free-entitled vehicle can be spawned only at an authorized spawn point.
7. Spawning a replacement deterministically removes or retires the player's prior active vehicle.
8. The owner can enter the driver seat and drive using the authorized reference handling contract.
9. Other allowed seats behave according to the authorized reference.
10. Exit leaves the vehicle in a valid stopped/parked state.
11. Despawn/reset removes the active runtime vehicle without removing durable ownership.
12. Save/rejoin restores ownership from EconomyRepository state.
13. The player can spawn the owned vehicle again after rejoin.

## Server contract

The runtime adapter should expose one narrow Free-Roam vehicle interface beneath the existing canonical remote root.

Minimum operations:

- read vehicle catalog/ownership snapshot;
- purchase/unlock vehicle when the parity reference requires purchase;
- spawn owned/entitled vehicle;
- request despawn;
- read current active-vehicle state.

All server mutations must validate the invoking player. The client may request actions but may not authoritatively set:

- ownership;
- price;
- balance delta;
- spawn location;
- active vehicle identity;
- top speed/acceleration/handling;
- seat ownership;
- vehicle transform.

## Catalog contract

The vehicle catalog is server-trusted data.

Every entry used by runtime must have a stable `vehicleId` and the exact authorized parity metadata required by the implementation. Values must be sourced from the verified reference/provenance set rather than inferred from this contract.

The runtime must reject unknown, duplicate, malformed, or client-invented vehicle ids.

## Spawn contract

Foundation remains authoritative for world locations and geometry.

The vehicle system may consume explicit authorized spawn locations but must not generate roads, parking lots, dealership buildings, or other world geometry.

At minimum, spawning must reject:

- unowned/non-entitled vehicles;
- unknown vehicle ids;
- invalid player state;
- a spawn request without a valid authorized spawn location;
- duplicate/replayed purchase requests that conflict with the original transaction.

The first runtime slice should preserve one active vehicle per player to prevent orphaned duplicates and authority ambiguity.

## Economy and ownership contract

Free Roam never writes persistence directly.

All paid vehicle unlocks must go through the existing EconomyRepository. The implementation must preserve its canonical semantics:

- durable exactly-once operation identity;
- duplicate replay returns the already-committed state;
- operation-id conflicts fail closed;
- insufficient funds fail closed;
- already-owned unlocks fail closed;
- ownership survives repository reopen/rejoin.

Free Roam may cache runtime active-vehicle state only; durable ownership remains Progression/Economy authority.

## Driving/physics contract

The runtime vehicle instance and its physical controls are Free-Roam authority.

Exact handling parameters must come from the authorized reference vehicle data. The implementation must not invent parity values merely to make a car move.

The first assigned runtime slice must define deterministic bounds for:

- forward acceleration;
- reverse;
- braking;
- steering;
- maximum speed;
- seat/driver handoff;
- vehicle reset/despawn.

Exploit-resistant server validation must prevent a client from directly setting protected handling or ownership state.

## Mobile and presentation contract

Vehicle interaction must remain usable on the same mobile target as the canonical Pip High UI.

The first runtime slice must provide:

- a touch-accessible vehicle selection/spawn action;
- clear owned/locked state;
- no HUD overlap that blocks the existing school/class controls;
- a reliable exit/despawn path;
- presentation that follows the exact authorized parity reference rather than a new unrelated design.

## Deterministic acceptance tests for the assigned runtime slice

The eventual producer candidate must cover at least:

- owned vehicle spawns;
- unowned paid vehicle rejected;
- insufficient-funds purchase rejected without unlock;
- successful purchase charges once and unlocks once;
- exact replay does not double-charge;
- conflicting replay fails closed;
- duplicate spawn replaces/reuses according to the chosen authoritative lifecycle and never leaves two owned active instances;
- despawn removes runtime instance without removing ownership;
- rejoin/reopen preserves vehicle ownership;
- unknown vehicle id rejected;
- client-supplied price/ownership/handling mutation ignored or rejected;
- no second economy/persistence/world/class authority introduced.

## Runtime-only evidence

Static/headless tests are not enough to certify exact vehicle parity.

After the assigned vehicle candidate is exact-green and integrated, Smoke should request LOCAL_ONLY_REQUIRED evidence for the same exact SHA when needed to verify:

- visible vehicle/model presentation;
- spawn placement on the private-server world;
- driver/passenger seating;
- steering/acceleration/braking feel;
- collision/stability;
- camera/mobile controls;
- despawn/reset;
- no regression to school/class/free-roam UI.

## Exit criterion for this support artifact

This contract is preparation only. It becomes actionable runtime scope only after Control Tower explicitly assigns the Vehicles parity slice on the current certified canonical lineage. Until then it must not be treated as a product candidate or permission to implement vehicle runtime behavior.
