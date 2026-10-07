# Teacher face repair from the October 7, 4:11 PM iPhone recording

The recording of published version 55 fails the visual acceptance gate. Mr. Yordy and Mrs. Benulis have nearly invisible eyes and smiles, separate hair blobs and thin side-hair streaks. Mrs. Urban's skin and blouse are washed out. Passing the earlier constructor tests did not establish visual quality: the test double treated SpecialMesh.Head as the Part bounds while Roblox documents Head mesh scaling as nonstandard.

## Repair

- Head silhouette now uses six explicit native parts with known bounds and a flat front. No Head mesh or guessed mesh dimensions.
- Two open eyes, subtle brows and one gentle curved smile are drawn as flat SurfaceGui ink on that front, with LightInfluence=0. No protruding eyeballs, teeth, mouth mask or spikes. No external face asset dependencies.
- One connected rounded hair cap replaces the separate locks; side/back hair intersects the cap. Fine hair lines are removed.
- Glasses are transparent flat outlines around the eyes. One smooth beard silhouette stays beneath the smile.
- Lowered overlapping ceiling fills, window fill and exposure to address washed-out skin/clothing visible in the recording.
- Study camera switches to free movement only on intentional humanoid movement, so spawn settling cannot change the view.

## Checks and limits

All 18 actual staff constructors are executed with math/service doubles: flat face bounds, two eyes, complete smile, connected hair cap, no legacy buried features, original 180-part budget, floor/door fit, limbs/accessories moving together. Full existing server behavior checks exercise load/save retries, first handshake, wrong hint/retry, invalid/replayed tokens, 10-question completion, restart, skip, monotonic saves and shutdown. The reviewed 134-question server-only bank remains intact.

The supplied video is real device evidence of the failed version 55, not of this revision. No native Studio or physical-iPhone rendered acceptance is claimed. The authorized laptop was offline during this repair. Any software inspection is only of source geometry/GUI; it does not substitute for the Roblox renderer, actual touch controls or native lighting. Release is for the already-authorized user playtest.
