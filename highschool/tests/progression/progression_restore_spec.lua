local Ledger = assert(loadfile("highschool/src/progression/ProgressionLedger.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function deepEqual(a, b, path)
    path = path or "value"
    if type(a) ~= type(b) then
        error(path .. " type mismatch", 2)
    end
    if type(a) ~= "table" then
        eq(a, b, path)
        return
    end
    for key, value in pairs(a) do
        deepEqual(value, b[key], path .. "." .. tostring(key))
    end
    for key, value in pairs(b) do
        if a[key] == nil and value ~= nil then
            error(path .. " missing key " .. tostring(key), 2)
        end
    end
end

local records = {
    {
        completionId = "math-002",
        playerId = 101,
        classId = "math",
        score = 20,
        completedAt = "2026-10-01T15:05:00Z",
    },
    {
        completionId = "math-001",
        playerId = 101,
        classId = "math",
        score = 25,
        completedAt = "2026-10-01T15:00:00Z",
    },
    {
        completionId = "ela-001",
        playerId = 101,
        classId = "ela",
        score = 30,
        completedAt = "2026-10-01T15:10:00Z",
    },
}

local ledger = Ledger.new()
for _, record in ipairs(records) do
    eq(ledger:apply(record).status, "applied", "initial apply")
end

local snapshot = ledger:save()
eq(snapshot.schemaVersion, 1, "schema")
eq(snapshot.completions[1].completionId, "ela-001", "snapshot sort 1")
eq(snapshot.completions[2].completionId, "math-001", "snapshot sort 2")
eq(snapshot.completions[3].completionId, "math-002", "snapshot sort 3")

local restored, restoreError = Ledger.restore(snapshot)
if not restored then
    error("restore failed: " .. tostring(restoreError), 2)
end

deepEqual(restored:getPlayerState(101), ledger:getPlayerState(101), "restored state")

local replay = restored:apply(records[2])
eq(replay.status, "duplicate", "post-rejoin replay")
eq(replay.applied, false, "post-rejoin duplicate applied")
eq(restored:getPlayerState(101).totalScore, 75, "post-rejoin score")

local duplicateSnapshot = {
    schemaVersion = 1,
    completions = { records[1], records[1] },
}
local bad, badError = Ledger.restore(duplicateSnapshot)
eq(bad, nil, "duplicate snapshot ledger")
eq(badError, "DUPLICATE_COMPLETION_IN_SNAPSHOT", "duplicate snapshot error")

local sparseSnapshot = {
    schemaVersion = 1,
    completions = { [2] = records[1] },
}
local sparse, sparseError = Ledger.restore(sparseSnapshot)
eq(sparse, nil, "sparse snapshot ledger")
eq(sparseError, "INVALID_SNAPSHOT", "sparse snapshot error")

local malformedRow, malformedRowError = Ledger.restore({
    schemaVersion = 1,
    completions = { "not-a-record" },
})
eq(malformedRow, nil, "malformed row ledger")
eq(malformedRowError, "INVALID_RECORD", "malformed row error")

local missingId, missingIdError = Ledger.restore({
    schemaVersion = 1,
    completions = {
        {
            playerId = 101,
            classId = "math",
            score = 10,
            completedAt = "2026-10-01T15:00:00Z",
        },
    },
})
eq(missingId, nil, "missing completion id ledger")
eq(missingIdError, "INVALID_COMPLETION_ID", "missing completion id error")

local fresh, freshSource = Ledger.restoreOrDefault(nil)
eq(freshSource, "default", "default state source")
eq(fresh:getPlayerState(101).totalScore, 0, "default score")
eq(fresh:getPlayerState(101).completionCount, 0, "default completion count")

local restoredAgain, restoredSource = Ledger.restoreOrDefault(snapshot)
eq(restoredSource, "restored", "restored state source")
deepEqual(restoredAgain:getPlayerState(101), ledger:getPlayerState(101), "restoreOrDefault restored state")

local invalidDefault, invalidDefaultError = Ledger.restoreOrDefault({
    schemaVersion = 1,
    completions = { false },
})
eq(invalidDefault, nil, "invalid persisted state must not default")
eq(invalidDefaultError, "INVALID_RECORD", "invalid persisted state error")

print("HIGH_SCHOOL_PROGRESSION_RESTORE_PASS")
