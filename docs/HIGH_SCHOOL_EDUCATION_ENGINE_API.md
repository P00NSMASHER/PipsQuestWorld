# High School Education Engine API

This unit is a standalone, server-authoritative activity engine for Pip High. It is intentionally independent of the school clock, attendance, grades, rewards, world geometry, UI, remotes, and persistence.

## Server-only activity schema

Each catalog activity passed to `EducationEngine.new` uses:

- `id: string` — unique stable identifier.
- `subject: string` — selection partition.
- `difficulty: integer 1..5` — session-local adaptive metadata.
- `prompt: string`.
- `choices: {string}` — at least two choices.
- `correctIndex: integer` — **server-only** answer key.
- `hint: string` — returned after an incorrect attempt.
- `explanation: string` — returned after completion.
- `misconceptions: {[choiceIndex]: string}?` — optional targeted feedback for incorrect choices.

The constructor rejects duplicate ids and normalized duplicate prompts.

## Public ModuleScript contract

`EducationEngine.new(catalog, options?) -> engine`

Creates an isolated in-memory engine. Supported options are `maxAttempts` and `maxDifficultyJump`.

`engine:beginSession(sessionId, subject, initialDifficulty?) -> snapshot`

Creates an ephemeral deterministic subject session. Calling it again with the same session id and subject is idempotent.

`engine:nextActivity(sessionId) -> activityView?, status`

Returns either the existing active activity or the next unseen deterministic activity. The client-safe activity view contains only `id`, `subject`, `difficulty`, `prompt`, and a copied `choices` array. It never contains `correctIndex`, answer keys, misconception maps, hints, or explanations.

`engine:submit(sessionId, activityId, submissionId, choiceIndex) -> response, status`

Validates answers against the private server catalog. `submissionId` is an idempotency key: replaying the same key for the same activity returns the original response without incrementing attempts or history. Reusing a key for another activity is rejected as `idempotency_conflict`.

Independent first-attempt correctness may raise the session-local difficulty target by one. A retry-supported correct answer does not count as independent mastery and does not raise the target. Exhausted incorrect attempts may lower the target by one. No persistent progression is written.

`engine:getSessionSnapshot(sessionId) -> snapshot`

Returns safe ephemeral session state and completion history without any answer keys.

`engine:closeSession(sessionId) -> snapshot`

Closes the ephemeral session and clears any active activity.

## Ownership boundary

Class Loop may call this API and decide when to open or close an education session. This engine does **not** own or mutate:

- bell/school clock state;
- attendance or room travel;
- grades, points, rewards, or progression persistence;
- Workspace/world geometry;
- client UI;
- RemoteEvents or RemoteFunctions;
- DataStores.

The Rojo project maps the module only under `ServerScriptService/SchoolFoundation/EducationEngine`.
