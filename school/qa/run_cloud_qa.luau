-- Headless Roblox engine verification. Does not touch DataStore, HttpService, or the live game.
assert(game.GameId == __QA_UNIVERSE_ID__, "Wrong QA universe")
assert(game.PlaceId == __QA_PLACE_ID__, "Wrong QA place")

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local foundation = ServerScriptService:FindFirstChild("SchoolFoundation")
assert(foundation and foundation:IsA("Folder"), "SchoolFoundation not loaded")
for _, name in ipairs({"EducationEngine", "ClassSessionController", "ClassActivityCatalog"}) do
    assert(foundation:FindFirstChild(name), "Missing server module " .. name)
end

local catalog = require(foundation.ClassActivityCatalog)
local EducationEngine = require(foundation.EducationEngine)
local Controller = require(foundation.ClassSessionController)
assert(type(catalog) == "table" and #catalog >= 4, "Current question catalog not loaded")
assert(ReplicatedStorage:FindFirstChild("Shared"), "Shared configuration not loaded")
assert(not ReplicatedStorage:FindFirstChild("QuestionBank"), "Client-visible answer key")

local ids = {}
local subjects = {}
for _, item in ipairs(catalog) do
    assert(type(item.id) == "string" and #item.id > 0 and not ids[item.id], "Duplicate question ID")
    ids[item.id] = true
    assert(type(item.subject) == "string" and #item.subject > 0, "Question subject missing")
    assert(type(item.prompt) == "string" and #item.prompt > 0, "Question prompt missing")
    assert(type(item.choices) == "table" and #item.choices >= 2, "Question choices missing")
    assert(type(item.correctIndex) == "number" and item.correctIndex >= 1 and item.correctIndex <= #item.choices, "Answer index invalid")
    assert(type(item.hint) == "string" and type(item.explanation) == "string", "Feedback missing")
    subjects[item.subject] = true
end

local engine = EducationEngine.new(catalog, {maxAttempts=2,maxDifficultyJump=1})
local controller = Controller.new(engine)
local total = 0
for subject in pairs(subjects) do
    local playerKey = "cloud-qa:" .. subject
    local classKey = "cloud-qa:class:" .. subject
    local entry = controller:enter(playerKey,classKey,subject,1)
    assert(entry.accepted and entry.activity, "Unable to start " .. subject)
    local activity = entry.activity
    assert(activity.correctIndex == nil and activity.explanation == nil, "Answer leaked in student view")
    local correct
    for _, item in ipairs(catalog) do
        if item.id == activity.id then correct = item.correctIndex end
    end
    assert(correct ~= nil, "Unknown active question")
    local wrongIndex = correct == 1 and 2 or 1
    local bad = controller:submit(playerKey,classKey,activity.id,"wrong:" .. subject,wrongIndex)
    assert(bad.accepted and bad.correct == false and bad.completed == false and bad.attempts == 1, "Wrong-answer path failed")
    assert(type(bad.feedback) == "string" and #bad.feedback > 0, "Feedback missing on wrong answer")
    local replay = controller:submit(playerKey,classKey,activity.id,"wrong:" .. subject,wrongIndex)
    assert(replay.duplicate and replay.attempts == 1, "Wrong-answer replay counted twice")
    local conflict = controller:submit(playerKey,classKey,activity.id,"wrong:" .. subject,correct)
    assert(not conflict.accepted and conflict.code == "idempotency_conflict", "Submission ID collision accepted")
    local fixed = controller:submit(playerKey,classKey,activity.id,"fixed:" .. subject,correct)
    assert(fixed.accepted and fixed.correct and fixed.completed and fixed.classCompleted, "Correct-answer completion failed")
    local again = controller:submit(playerKey,classKey,activity.id,"fixed:" .. subject,correct)
    assert(again.duplicate and again.completionAlreadyRecorded and not again.classCompleted, "Duplicate completion awarded")
    local reenter = controller:enter(playerKey,classKey,subject,1)
    assert(not reenter.accepted and reenter.code == "already_completed", "Completed class replay permitted")
    assert(controller:getPlayerSnapshot(playerKey).completionCount == 1, "Wrong completion count")
    total += 1
end
assert(total >= 4, "Insufficient subject coverage")
return string.format("EMMA_CLOUD_QA_PASS:%d_subjects_%d_questions",total,#catalog)
