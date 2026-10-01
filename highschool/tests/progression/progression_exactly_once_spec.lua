local Ledger = assert(loadfile("highschool/src/progression/ProgressionLedger.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local a = {
    completionId = "math-001",
    playerId = 101,
    classId = "math",
    score = 25,
    completedAt = "2026-10-01T15:00:00Z",
}

local ledger = Ledger.new()

local first = ledger:apply(a)
eq(first.status, "applied", "first status")
eq(first.applied, true, "first applied")
eq(first.totalScore, 25, "first score")
eq(first.completionCount, 1, "first count")

local duplicate = ledger:apply(a)
eq(duplicate.status, "duplicate", "duplicate status")
eq(duplicate.applied, false, "duplicate applied")

local afterDuplicate = ledger:getPlayerState(101)
eq(afterDuplicate.totalScore, 25, "duplicate changed score")
eq(afterDuplicate.completionCount, 1, "duplicate changed count")

local conflicting = {
    completionId = a.completionId,
    playerId = a.playerId,
    classId = a.classId,
    score = 125,
    completedAt = a.completedAt,
}

local conflict = ledger:apply(conflicting)
eq(conflict.status, "conflict", "conflict status")
eq(conflict.applied, false, "conflict applied")
eq(conflict.error, "COMPLETION_ID_CONFLICT", "conflict error")

local afterConflict = ledger:getPlayerState(101)
eq(afterConflict.totalScore, 25, "conflict changed score")
eq(afterConflict.completionCount, 1, "conflict changed count")

local second = ledger:apply({
    completionId = "math-002",
    playerId = 101,
    classId = "math",
    score = 20,
    completedAt = "2026-10-01T15:05:00Z",
})
eq(second.status, "applied", "second status")

local third = ledger:apply({
    completionId = "ela-001",
    playerId = 101,
    classId = "ela",
    score = 30,
    completedAt = "2026-10-01T15:10:00Z",
})
eq(third.status, "applied", "third status")

local final = ledger:getPlayerState(101)
eq(final.totalScore, 75, "final score")
eq(final.completionCount, 3, "final count")
eq(#final.classes, 2, "class count")
eq(final.classes[1].classId, "ela", "class sort 1")
eq(final.classes[1].score, 30, "ela score")
eq(final.classes[2].classId, "math", "class sort 2")
eq(final.classes[2].score, 45, "math score")
eq(final.classes[2].completionCount, 2, "math count")

local rejected = ledger:apply({
    completionId = "bad-001",
    playerId = 101,
    classId = "science",
    score = -1,
    completedAt = "2026-10-01T15:20:00Z",
})
eq(rejected.status, "rejected", "invalid status")
eq(rejected.error, "INVALID_SCORE", "invalid error")
eq(ledger:getPlayerState(101).totalScore, 75, "invalid changed score")

print("HIGH_SCHOOL_PROGRESSION_EXACTLY_ONCE_PASS")
