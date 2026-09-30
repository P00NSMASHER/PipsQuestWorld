local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local QuestionBank = require(script.Parent:WaitForChild("QuestionBank"))

local randomObject = Random.new()

local remotes = ReplicatedStorage:FindFirstChild("SchoolRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "SchoolRemotes"
    remotes.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name)
    local remote = remotes:FindFirstChild(name)
    if remote then
        return remote
    end
    remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = remotes
    return remote
end

local stateRemote = getOrCreateRemote("SchoolState")
local requestTravelRemote = getOrCreateRemote("RequestTravel")
local requestQuestionRemote = getOrCreateRemote("RequestQuestion")
local submitAnswerRemote = getOrCreateRemote("SubmitAnswer")
local questionPromptRemote = getOrCreateRemote("QuestionPrompt")
local answerFeedbackRemote = getOrCreateRemote("AnswerFeedback")

local periodIndex = 1
local periodCycle = 1
local periodStartedAt = os.clock()

local activeQuestions = {}
local attendance = {}

local function getPointsValue(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    return leaderstats and leaderstats:FindFirstChild("Points")
end

local function addPoints(player, amount)
    local points = getPointsValue(player)
    if points then
        points.Value += amount
    end
end

local function getSecondsRemaining()
    local elapsed = os.clock() - periodStartedAt
    return math.max(0, math.ceil(SchoolConfig.BELL_SECONDS - elapsed))
end

local function currentPeriod()
    return SchoolConfig.Periods[periodIndex]
end

local function sendState(player)
    local period = currentPeriod()
    local nextIndex = (periodIndex % #SchoolConfig.Periods) + 1
    local nextPeriod = SchoolConfig.Periods[nextIndex]
    local points = getPointsValue(player)

    stateRemote:FireClient(player, {
        periodIndex = periodIndex,
        periodCycle = periodCycle,
        label = period.label,
        subject = period.subject,
        room = period.room,
        canQuestion = period.canQuestion,
        nextLabel = nextPeriod.label,
        secondsRemaining = getSecondsRemaining(),
        points = points and points.Value or 0,
    })
end

local function sendStateToAll()
    for _, player in ipairs(Players:GetPlayers()) do
        sendState(player)
    end
end

local function setupPlayer(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local points = Instance.new("IntValue")
    points.Name = "Points"
    points.Value = 0
    points.Parent = leaderstats

    attendance[player.UserId] = {}

    points:GetPropertyChangedSignal("Value"):Connect(function()
        sendState(player)
    end)

    task.defer(function()
        sendState(player)
    end)
end

local function markAttendance(player)
    local userAttendance = attendance[player.UserId]
    if not userAttendance then
        userAttendance = {}
        attendance[player.UserId] = userAttendance
    end

    local key = tostring(periodCycle) .. ":" .. tostring(periodIndex)
    if userAttendance[key] then
        return
    end

    userAttendance[key] = true
    addPoints(player, SchoolConfig.Rewards.attendance)
    answerFeedbackRemote:FireClient(player, {
        kind = "attendance",
        message = "+" .. tostring(SchoolConfig.Rewards.attendance) .. " points for getting to class.",
    })
end

local function getRoomSpawn(roomName)
    local campus = Workspace:FindFirstChild("SchoolCampus")
    if not campus then
        return nil
    end

    local spawns = campus:FindFirstChild("RoomSpawns")
    if not spawns then
        return nil
    end

    return spawns:FindFirstChild(roomName)
end

local function isNearCurrentRoom(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    local roomSpawn = getRoomSpawn(currentPeriod().room)
    if not roomSpawn then
        return false
    end

    return (root.Position - roomSpawn.Position).Magnitude <= 45
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    activeQuestions[player] = nil
    attendance[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

requestTravelRemote.OnServerEvent:Connect(function(player, requestedPeriodIndex)
    if requestedPeriodIndex ~= periodIndex then
        sendState(player)
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local roomSpawn = getRoomSpawn(currentPeriod().room)

    if not root or not roomSpawn then
        answerFeedbackRemote:FireClient(player, {
            kind = "travel",
            message = "Classroom is still loading. Keep exploring and try again.",
        })
        return
    end

    root.CFrame = roomSpawn.CFrame + Vector3.new(0, 3, 0)
    markAttendance(player)
end)

requestQuestionRemote.OnServerEvent:Connect(function(player)
    local period = currentPeriod()

    if not period.canQuestion then
        answerFeedbackRemote:FireClient(player, {
            kind = "question",
            message = "This is a free-roam period. Explore the campus.",
        })
        return
    end

    if not isNearCurrentRoom(player) then
        answerFeedbackRemote:FireClient(player, {
            kind = "question",
            message = "Head to the current classroom first.",
        })
        return
    end

    local question = QuestionBank.getRandom(period.subject, randomObject)
    if not question then
        answerFeedbackRemote:FireClient(player, {
            kind = "question",
            message = "No question is available for this class yet.",
        })
        return
    end

    activeQuestions[player] = {
        question = question,
        attempts = 0,
        periodCycle = periodCycle,
        periodIndex = periodIndex,
    }

    questionPromptRemote:FireClient(player, {
        id = question.id,
        prompt = question.prompt,
        choices = question.choices,
        subject = period.subject,
    })
end)

submitAnswerRemote.OnServerEvent:Connect(function(player, questionId, choiceIndex)
    local active = activeQuestions[player]
    if not active then
        return
    end

    if active.periodCycle ~= periodCycle or active.periodIndex ~= periodIndex then
        activeQuestions[player] = nil
        answerFeedbackRemote:FireClient(player, {
            kind = "answer",
            completed = true,
            message = "The bell rang. Your next class is ready.",
        })
        return
    end

    local question = active.question
    if question.id ~= questionId then
        return
    end

    if typeof(choiceIndex) ~= "number" or choiceIndex % 1 ~= 0 or choiceIndex < 1 or choiceIndex > #question.choices then
        return
    end

    active.attempts += 1

    if choiceIndex == question.correctIndex then
        addPoints(player, SchoolConfig.Rewards.correct)
        activeQuestions[player] = nil
        answerFeedbackRemote:FireClient(player, {
            kind = "answer",
            correct = true,
            completed = true,
            message = "Correct! +" .. tostring(SchoolConfig.Rewards.correct) .. " points.",
            explanation = question.explanation,
        })
        return
    end

    if active.attempts < 2 then
        answerFeedbackRemote:FireClient(player, {
            kind = "answer",
            correct = false,
            completed = false,
            message = "Not quite. " .. question.hint,
        })
        return
    end

    addPoints(player, SchoolConfig.Rewards.completedAfterRetries)
    activeQuestions[player] = nil
    answerFeedbackRemote:FireClient(player, {
        kind = "answer",
        correct = false,
        completed = true,
        message = "Good try. +" .. tostring(SchoolConfig.Rewards.completedAfterRetries) .. " effort points. Ask for another question when you're ready.",
        explanation = question.explanation,
    })
end)

task.spawn(function()
    while true do
        task.wait(1)

        if os.clock() - periodStartedAt >= SchoolConfig.BELL_SECONDS then
            periodIndex = (periodIndex % #SchoolConfig.Periods) + 1
            periodCycle += 1
            periodStartedAt = os.clock()
            activeQuestions = {}
        end

        sendStateToAll()
    end
end)
