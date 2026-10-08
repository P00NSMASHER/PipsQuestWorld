# Emma Study Classroom

This branch replaces the open-world school/neighborhood game with one intentionally tiny loop:

1. Emma spawns in one classroom.
2. A recognizable ABVM teacher/staff NPC walks in.
3. The NPC asks one question drawn from Emma's real Grade 2 ABVM study pack.
4. Wrong answers cost nothing and show a hint.
5. A correct answer earns one star.
6. The NPC leaves and the next adult walks in.
7. Ten correct answers completes the study session.

There are no houses, cars, shops, jobs, leaderboards, giant school maps, or currency systems in this mode. The entire purpose is to make doing real schoolwork feel like a Roblox activity.

## Curriculum source

The reviewed ABVM teacher pack, cumulative archive and original worksheet practice
are now imported through the deterministic Study Universe v2 exporter. The pinned
server bank includes 357 questions: 134 current, 65 cumulative and 158 original
STAR-style fallback. Mix exhausts those tiers in order; the progress chip selects
named test practice without confusing grammar, spelling, operations or chapters.

See [SHARED_CURRICULUM.md](SHARED_CURRICULUM.md) and the exact source receipt for
refresh commands, privacy boundaries, automatic-update limits and release gates.
The live game remains on its previous published bank until runtime/device acceptance.

## Design rule

Keep this simple. If a proposed feature does not help Emma answer schoolwork questions, it probably does not belong here.


## Visual gold standard

The user-approved classroom concept image is the visual-quality target for this tiny mode. Because the product is intentionally one room, polish is concentrated instead of spread across a fake open world.

Non-negotiable room cues:
- warm yellow ABVM classroom walls with deep blue trim and dark varnished wood floor
- old-school chalkboard plus a modern interactive smartboard
- wood-framed windows, blue valances, radiators and warm daylight
- built-in cubbies with colorful bins, books, plants, globe, teacher desk and lived-in desk clutter
- alphabet border, crucifix, “Let Your Light Shine,” ABVM values and personalized Emma desk
- small photo-inspired blue-gray/tan-brick hallway visible through the classroom doors
- restrained cinematic lighting, not neon theme-park lighting

Teacher/staff quality target:
- distinct stylized Roblox silhouettes rather than colored rectangles
- face, hair, hands, shoes, clothing layers, lanyard, staff badge and classroom prop
- smooth walk-in/walk-out motion with limb swing
- compact in-world nameplate, with the actual question and explanation in the phone UI
- question mirrored on the classroom smartboard while the teacher is at the front

See [REFERENCE_PASS.md](REFERENCE_PASS.md) for the October 7 recording-derived candidate and its verification limits. The question bank now lives in `server/QuestionBank.lua`; shared Data contains only staff and week metadata.

The visual profiles are stylized native-Roblox interpretations. They must not be described as portrait-exact likenesses unless separately verified against labeled reference photographs.
