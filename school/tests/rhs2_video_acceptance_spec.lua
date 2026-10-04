local reference = dofile("school/tests/fixtures/rhs2_video_acceptance_reference.lua")

local function expect(condition, message)
    if not condition then error(message, 2) end
end

local function nonEmpty(value)
    return type(value) == "string" and value ~= ""
end

expect(reference.schemaVersion == 1, "unexpected reference schema")
expect(reference.inputSha == "23cc398bd7ae3232835a0fee1d5ab32abb8a315b", "reference input SHA drift")
expect(reference.timingPolicy:find("DO_NOT_DERIVE", 1, true) ~= nil, "2x timing exclusion missing")
expect(reference.exactParityPolicy:find("CANNOT_CERTIFY", 1, true) ~= nil, "rendered-parity limitation missing")

local knownClips = {}
for clipId, clip in pairs(reference.clips) do
    expect(clipId == "A" or clipId == "B" or clipId == "C", "unknown clip id")
    expect(nonEmpty(clip.libraryFileId), "clip Library id missing")
    expect(nonEmpty(clip.fileName), "clip filename missing")
    expect(type(clip.durationSeconds) == "number" and clip.durationSeconds > 0, "clip duration invalid")
    expect(clip.width == 1112 and clip.height == 512, "clip dimensions drift")
    expect(nonEmpty(clip.sha256) and #clip.sha256 == 64, "clip hash invalid")
    knownClips[clipId] = clip
end

local gate = reference.functionalGate
expect(gate.candidateSha == "9bb1c4c76927195edb22abff96c7d9679685f342", "functional gate head drift")
expect(gate.status == "PASS_EXACT_HEAD_CLOUD", "functional gate is not exact-head PASS")
expect(gate.limits.visual == "NOT_TESTED", "functional evidence overclaims visual status")
expect(gate.limits.interaction == "NOT_RENDERED_TESTED", "functional evidence overclaims interaction status")
expect(gate.limits.device == "NOT_TESTED", "functional evidence overclaims device status")

local seen = {}
for _, case in ipairs(reference.cases) do
    expect(nonEmpty(case.id) and not seen[case.id], "acceptance case id missing or duplicated")
    seen[case.id] = true
    expect(case.category == "visual" or case.category == "interaction", "unsupported acceptance category")
    expect(nonEmpty(case.owner), "acceptance owner missing")
    expect(nonEmpty(case.observation), "observation missing")
    expect(nonEmpty(case.acceptance), "acceptance criteria missing")
    expect(nonEmpty(case.blocker), "blocker missing")
    expect(nonEmpty(case.nextHandoff), "next handoff missing")
    expect(case.candidateStatus ~= "PASS" and case.candidateStatus:find("NOT_", 1, true) ~= nil,
        "reference case incorrectly claims candidate parity")

    local clip = knownClips[case.clip]
    expect(clip ~= nil, "case references unknown clip")
    expect(type(case.timestamps) == "table" and #case.timestamps > 0, "timestamps missing")
    for _, timestamp in ipairs(case.timestamps) do
        expect(type(timestamp) == "number" and timestamp >= 0 and timestamp <= clip.durationSeconds,
            "timestamp outside clip duration")
    end

    if case.frameSha256 then
        for _, hash in ipairs(case.frameSha256) do
            expect(nonEmpty(hash) and #hash == 64, "frame hash invalid")
        end
    end

    if case.crossClip then
        local cross = knownClips[case.crossClip.clip]
        expect(cross ~= nil, "cross-clip reference unknown")
        for _, timestamp in ipairs(case.crossClip.timestamps or {}) do
            expect(type(timestamp) == "number" and timestamp >= 0 and timestamp <= cross.durationSeconds,
                "cross-clip timestamp outside duration")
        end
    end
end

expect(seen["VIS-SCHOOL-FRONTAGE-A005"], "school frontage case missing")
expect(seen["VIS-HUD-HIERARCHY-A005-C005"], "HUD hierarchy case missing")
expect(seen["VIS-TRAVEL-MENU-C005"], "Travel case missing")
expect(seen["VIS-DEALERSHIP-B035-B045"], "dealership case missing")
expect(seen["VIS-JOB-RESULT-C065"], "job result case missing")
expect(seen["INT-JOB-C005-C100"], "job transition case missing")

print("HIGH_SCHOOL_RHS2_VIDEO_ACCEPTANCE_REFERENCE_PASS")
