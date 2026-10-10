request: upload-two-original-abvm-furniture-models-only
production-release: prohibited

This is the explicit one-time source-controlled activation of the nonproduction
Roblox Assets API upload workflow for the two ORIGINAL ABVM student furniture
GLBs generated in this branch. It authorizes uploading exactly one chair model
and one desk model into the Roblox creator-owned model library IF and ONLY IF
the connected API key genuinely permits this and the owner is independently
resolved from the known game universe. No game publishing, no model auto-enable,
no teacher/question/UI changes, no token disclosure, and no reuse of unidentified
third-party assets. Successful asset IDs must be inspected before use.


## Creator ownership resolution (October 8)

The previous import preflight used `games.roblox.com/v1/games` and
incorrectly considered this universe unverifiable because its private/unrated
record returns creator id 0. The alternative official developer universe API
`develop.roblox.com/v1/universes/10769455759` returned:
- root place 114603280760042
- creatorType User
- creatorTargetId 6064228083 (DadSharkins)

The separate official place relationship endpoint
`apis.roblox.com/universes/v1/places/114603280760042/universe`
corroborated universe 10769455759. These values must still be checked live by
the importer before the request; they are NOT hardcoded as permission bypasses.

Re-run this already-authorized model-only upload against the resolved target
creator, with expected upload price 0 Robux. No place publication, no enabling
model visuals, no live game modifications and no token output.
