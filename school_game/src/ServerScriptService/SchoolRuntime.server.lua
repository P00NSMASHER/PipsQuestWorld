local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("SchoolConfig"))

local remotes = ReplicatedStorage:FindFirstChild("SchoolRemotes") or Instance.new("Folder")
remotes.Name = "SchoolRemotes"
remotes.Parent = ReplicatedStorage

local stateEvent = remotes:FindFirstChild("State") or Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes

local answerEvent = remotes:FindFirstChild("Answer") or Instance.new("RemoteEvent")
answerEvent.Name = "Answer"
answerEvent.Parent = remotes

local campus = Workspace:FindFirstChild("SchoolCampus") or Instance.new("Model")
campus.Name = "SchoolCampus"
campus.Parent = Workspace

local roomSpawns = {}
local playerState = {}
local phase = "STARTING"
local classIndex = 1
local phaseEndsAt = os.time() + SchoolConfig.StartDelay

local function makePart(parent, name, size, position, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.Position = position
    part.Material = material or Enum.Material.SmoothPlastic
    part.Parent = parent
    return part
end

local function ensureCampus()
    if campus:FindFirstChild("Built") then
        for _, classInfo in ipairs(SchoolConfig.Classes) do
            local room = campus:FindFirstChild(classInfo.id)
            if room and room:FindFirstChild("Spawn") then
                roomSpawns[classInfo.id] = room.Spawn
            end
        end
        return
    end

    local built = Instance.new("BoolValue")
    built.Name = "Built"
    built.Value = true
    built.Parent = campus

    makePart(campus, "Ground", Vector3.new(220, 1, 180), Vector3.new(0, -0.5, 0), Enum.Material.Concrete)
    makePart(campus, "MainFloor", Vector3.new(120, 1, 100), Vector3.new(0, 0.5, 0), Enum.Material.SmoothPlastic)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "MainSpawn"
    spawn.Anchored = true
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.Position = Vector3.new(0, 1.5, 38)
    spawn.Neutral = true
    spawn.Parent = campus

    local roomPositions = {
        homeroom = Vector3.new(-42, 2, 18),
        math = Vector3.new(0, 2, 18),
        science = Vector3.new(42, 2, 18),
        english = Vector3.new(-22, 2, -28),
        art = Vector3.new(22, 2, -28),
    }

    for _, classInfo in ipairs(SchoolConfig.Classes) do
        local room = Instance.new("Model")
        room.Name = classInfo.id
        room.Parent = campus

        local center = roomPositions[classInfo.id]
        makePart(room, "Floor", Vector3.new(34, 1, 28), center + Vector3.new(0, -1.5, 0), Enum.Material.WoodPlanks)
        makePart(room, "BackWall", Vector3.new(34, 12, 1), center + Vector3.new(0, 4, -13.5), Enum.Material.Brick)
        makePart(room, "LeftWall", Vector3.new(1, 12, 28), center + Vector3.new(-16.5, 4, 0), Enum.Material.Brick)
        makePart(room, "RightWall", Vector3.new(1, 12, 28), center + Vector3.new(16.5, 4, 0), Enum.Material.Brick)

        local teacherDesk = makePart(room, "TeacherDesk", Vector3.new(8, 2, 3), center + Vector3.new(0, 0, -8), Enum.Material.Wood)
        teacherDesk.CanCollide = true

        for row = 0, 2 do
            for col = 0, 3 do
                local x = -10 + col * 7
                local z = -1 + row * 6
                makePart(room, "Desk", Vector3.new(4.5, 1.5, 2.5), center + Vector3.new(x, 0, z), Enum.Material.Wood)
            end
        end

        local roomSpawn = makePart(room, "Spawn", Vector3.new(4, 1, 4), center + Vector3.new(0, 0, 9), Enum.Material.Neon)
        roomSpawn.Transparency = 1
        roomSpawn.CanCollide = false
        roomSpawns[classInfo.id] = roomSpawn
    end

    makePart(campus, "AtriumBench1", Vector3.new(12, 2, 3), Vector3.new(-16, 1.5, 38), Enum.Material.Wood)
    makePart(campus, "AtriumBench2", Vector3.new(12, 2, 3), Vector3.new(16, 1.5, 38), Enum.Material.Wood)
end

local function getData(player)
    if not playerState[player] then
        playerState[player] = {
            points = 0,
            questionToken = 0,
            correctChoice = nil,
            answered = false,
        }
    end
    return playerState[player]
end

local function movePlayerToClass(player, classInfo)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local target = roomSpawns[classInfo.id]
    if root and target then
        root.CFrame = target.CFrame + Vector3.new(0, 3, 0)
    end
end

local function chooseQuestion(player, classInfo)
    local bank = SchoolConfig.Questions[classInfo.id] or {}
    if #bank == 0 then
        return nil
    end

    local data = getData(player)
    data.questionToken += 1
    local index = ((player.UserId + data.questionToken + classIndex) % #bank) + 1
    local q = bank[index]
    data.correctChoice = q.correct
    data.answered = false

    return {
        token = data.questionToken,
        prompt = q.prompt,
        choices = q.choices,
    }
end

local function sendState(player, extra)
    local data = getData(player)
    local classInfo = SchoolConfig.Classes[classIndex]
    local payload = {
        phase = phase,
        classId = classInfo and classInfo.id or nil,
        className = classInfo and classInfo.name or nil,
        room = classInfo and classInfo.room or nil,
        points = data.points,
        endsAt = phaseEndsAt,
    }

    if extra then
        for key, value in pairs(extra) do
            payload[key] = value
        end
    end

    stateEvent:FireClient(player, payload)
end

local function beginClass()
    phase = "CLASS"
    phaseEndsAt = os.time() + SchoolConfig.ClassDuration
    local classInfo = SchoolConfig.Classes[classIndex]

    for _, player in ipairs(Players:GetPlayers()) do
        movePlayerToClass(player, classInfo)
        local question = chooseQuestion(player, classInfo)
        sendState(player, { question = question })
    end
end

local function beginPassing()
    phase = "PASSING"
    phaseEndsAt = os.time() + SchoolConfig.PassingDuration
    for _, player in ipairs(Players:GetPlayers()) do
        local data = getData(player)
        data.correctChoice = nil
        data.answered = false
        sendState(player)
    end
end

answerEvent.OnServerEvent:Connect(function(player, token, choice)
    if phase ~= "CLASS" then
        return
    end
    if typeof(token) ~= "number" or typeof(choice) ~= "number" then
        return
    end

    local data = getData(player)
    if token ~= data.questionToken or data.answered or data.correctChoice == nil then
        return
    end

    data.answered = true
    local correct = choice == data.correctChoice
    if correct then
        data.points += SchoolConfig.PointsPerCorrectAnswer
    end

    sendState(player, {
        answerResult = correct and "correct" or "incorrect",
        question = nil,
    })
end)

Players.PlayerAdded:Connect(function(player)
    getData(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if phase == "CLASS" then
            local classInfo = SchoolConfig.Classes[classIndex]
            movePlayerToClass(player, classInfo)
            local question = chooseQuestion(player, classInfo)
            sendState(player, { question = question })
        else
            sendState(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerState[player] = nil
end)

ensureCampus()

task.spawn(function()
    repeat
        task.wait(0.5)
    until os.time() >= phaseEndsAt

    beginClass()

    while true do
        while os.time() < phaseEndsAt do
            task.wait(1)
        end

        if phase == "CLASS" then
            beginPassing()
        else
            classIndex += 1
            if classIndex > #SchoolConfig.Classes then
                classIndex = 1
            end
            beginClass()
        end
    end
end)
