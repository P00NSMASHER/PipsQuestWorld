local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local shared = ReplicatedStorage:WaitForChild("SchoolShared")
local Config = require(shared:WaitForChild("Config"))
local QuestionBank = require(script.Parent:WaitForChild("QuestionBank"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local remotes = ReplicatedStorage:FindFirstChild("SchoolRemotes") or Instance.new("Folder")
remotes.Name = "SchoolRemotes"
remotes.Parent = ReplicatedStorage

local stateEvent = remotes:FindFirstChild("State") or Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes

local classEvent = remotes:FindFirstChild("ClassActivity") or Instance.new("RemoteEvent")
classEvent.Name = "ClassActivity"
classEvent.Parent = remotes

local actionEvent = remotes:FindFirstChild("Action") or Instance.new("RemoteEvent")
actionEvent.Name = "Action"
actionEvent.Parent = remotes

local notifyEvent = remotes:FindFirstChild("Notify") or Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = remotes

local profileStore = DataStoreService:GetDataStore(Config.ProfileStoreName)
local world = WorldBuilder.build(Config)

local profiles = {}
local pendingQuestions = {}
local completedPhase = {}
local claimedPlots = {}
local playerPlot = {}
local spawnedHomes = {}
local spawnedCars = {}
local jobState = {}

local phaseIndex = 1
local phaseStartedAt = os.clock()
local dayNumber = 1

local function copyProfile(source)
	local result = {}
	for key, value in pairs(Config.DefaultProfile) do
		result[key] = source and source[key] ~= nil and source[key] or value
	end
	return result
end

local function profileKey(player)
	return "player_" .. player.UserId
end

local function loadProfile(player)
	local data
	local ok, err = pcall(function()
		data = profileStore:GetAsync(profileKey(player))
	end)
	if not ok then
		warn("Profile load failed for " .. player.Name .. ": " .. tostring(err))
	end

	local profile = copyProfile(data)
	profiles[player] = profile

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local credits = Instance.new("IntValue")
	credits.Name = "Credits"
	credits.Value = profile.Credits
	credits.Parent = leaderstats

	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = profile.XP
	xp.Parent = leaderstats
end

local function saveProfile(player)
	local profile = profiles[player]
	if not profile then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local credits = leaderstats:FindFirstChild("Credits")
		local xp = leaderstats:FindFirstChild("XP")
		if credits then
			profile.Credits = credits.Value
		end
		if xp then
			profile.XP = xp.Value
		end
	end

	local ok, err = pcall(function()
		profileStore:SetAsync(profileKey(player), profile)
	end)
	if not ok then
		warn("Profile save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

local function addReward(player, creditsAmount, xpAmount)
	local profile = profiles[player]
	local stats = player:FindFirstChild("leaderstats")
	if not profile or not stats then
		return
	end

	local credits = stats:FindFirstChild("Credits")
	local xp = stats:FindFirstChild("XP")
	if credits then
		credits.Value += creditsAmount or 0
		profile.Credits = credits.Value
	end
	if xp then
		xp.Value += xpAmount or 0
		profile.XP = xp.Value
	end
end

local function currentPhase()
	return Config.DayPhases[phaseIndex]
end

local function phaseKey()
	return tostring(dayNumber) .. ":" .. currentPhase().id
end

local function formatClock(minutes)
	minutes = math.floor(minutes + 0.5)
	local hour24 = math.floor(minutes / 60) % 24
	local minute = minutes % 60
	local suffix = hour24 >= 12 and "PM" or "AM"
	local hour = hour24 % 12
	if hour == 0 then
		hour = 12
	end
	return string.format("%d:%02d %s", hour, minute, suffix)
end

local function getClockText()
	local phase = currentPhase()
	local elapsed = math.clamp(os.clock() - phaseStartedAt, 0, phase.duration)
	local alpha = phase.duration > 0 and elapsed / phase.duration or 0
	local minutes = phase.clockStart + (phase.clockEnd - phase.clockStart) * alpha
	return formatClock(minutes)
end

local function sendState(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	local credits = stats and stats:FindFirstChild("Credits")
	local xp = stats and stats:FindFirstChild("XP")
	local phase = currentPhase()

	stateEvent:FireClient(player, {
		day = dayNumber,
		phaseId = phase.id,
		phaseName = phase.name,
		phaseKind = phase.kind,
		classId = phase.classId,
		clock = getClockText(),
		credits = credits and credits.Value or profile.Credits,
		xp = xp and xp.Value or profile.XP,
		homePlot = playerPlot[player],
		jobActive = jobState[player] ~= nil,
	})
end

local function sendStateAll()
	for _, player in ipairs(Players:GetPlayers()) do
		sendState(player)
	end
end

local function chooseQuestion(player, classId)
	local questions = QuestionBank[classId]
	if not questions or #questions == 0 then
		return nil
	end
	local seed = player.UserId + dayNumber * 97 + phaseIndex * 31
	local index = (seed % #questions) + 1
	return questions[index]
end

local function beginClass(player, classId)
	local phase = currentPhase()
	if phase.kind ~= "class" or phase.classId ~= classId then
		notifyEvent:FireClient(player, "That class is not in session right now.")
		return
	end

	local doneForPhase = completedPhase[player] and completedPhase[player][phaseKey()]
	if doneForPhase then
		notifyEvent:FireClient(player, "You already completed this class period.")
		return
	end

	local question = chooseQuestion(player, classId)
	if not question then
		notifyEvent:FireClient(player, "This class activity is unavailable.")
		return
	end

	pendingQuestions[player] = {
		phaseKey = phaseKey(),
		classId = classId,
		questionId = question.id,
		correct = question.correct,
		explanation = question.explanation,
	}

	classEvent:FireClient(player, {
		classId = classId,
		title = (Config.ClassRooms[classId] and Config.ClassRooms[classId].displayName or classId) .. " Activity",
		prompt = question.prompt,
		choices = question.choices,
	})
end

local function claimHome(player, plotIndex)
	if playerPlot[player] then
		notifyEvent:FireClient(player, "You already have Home " .. playerPlot[player] .. " in this server.")
		return
	end
	if claimedPlots[plotIndex] then
		notifyEvent:FireClient(player, "That home is already claimed.")
		return
	end

	claimedPlots[plotIndex] = player
	playerPlot[player] = plotIndex
	local center = world.HomePlots[plotIndex]
	spawnedHomes[player] = world.BuildHome(player.DisplayName, center)

	notifyEvent:FireClient(player, "Home " .. plotIndex .. " is yours for this server.")
	sendState(player)
end

local function destroyCar(player)
	local car = spawnedCars[player]
	if car and car.Parent then
		car:Destroy()
	end
	spawnedCars[player] = nil
end

local function spawnCar(player)
	destroyCar(player)

	local model = Instance.new("Model")
	model.Name = player.Name .. "_Car"
	model.Parent = world.Root

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(7, 1.2, 11)
	chassis.CFrame = world.VehicleSpawnCFrame
	chassis.Color = Color3.fromRGB(75, 155, 235)
	chassis.Material = Enum.Material.Metal
	chassis.Anchored = false
	chassis.Parent = model

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(3.5, 1, 4)
	seat.CFrame = chassis.CFrame * CFrame.new(0, 1.1, 0.5)
	seat.Color = Color3.fromRGB(35, 40, 48)
	seat.Anchored = false
	seat.Parent = model

	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = chassis
	seatWeld.Part1 = seat
	seatWeld.Parent = seat

	for _, offset in ipairs({
		Vector3.new(-3.2, -0.2, -3.6),
		Vector3.new(3.2, -0.2, -3.6),
		Vector3.new(-3.2, -0.2, 3.6),
		Vector3.new(3.2, -0.2, 3.6),
	}) do
		local wheel = Instance.new("Part")
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Size = Vector3.new(1.5, 2.2, 2.2)
		wheel.CFrame = chassis.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
		wheel.Color = Color3.fromRGB(25, 25, 28)
		wheel.Material = Enum.Material.Rubber
		wheel.CanCollide = false
		wheel.Anchored = false
		wheel.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = chassis
		weld.Part1 = wheel
		weld.Parent = wheel
	end

	model.PrimaryPart = chassis
	spawnedCars[player] = model

	task.delay(0.25, function()
		if chassis.Parent then
			pcall(function()
				chassis:SetNetworkOwner(player)
			end)
		end
	end)

	notifyEvent:FireClient(player, "Starter car spawned in the vehicle lot.")
end

local function applyStyle(player)
	local profile = profiles[player]
	local character = player.Character
	if not profile or not character then
		return
	end

	profile.StylePreset = (profile.StylePreset % #Config.StylePresets) + 1
	local preset = Config.StylePresets[profile.StylePreset]
	local colors = character:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	colors.Name = "Body Colors"
	colors.HeadColor = BrickColor.new(preset.head)
	colors.LeftArmColor = BrickColor.new(preset.arms)
	colors.RightArmColor = BrickColor.new(preset.arms)
	colors.TorsoColor = BrickColor.new(preset.torso)
	colors.LeftLegColor = BrickColor.new(preset.legs)
	colors.RightLegColor = BrickColor.new(preset.legs)
	colors.Parent = character

	notifyEvent:FireClient(player, "Style changed to " .. preset.name .. ".")
end

local function startJob(player)
	if jobState[player] then
		notifyEvent:FireClient(player, "Finish your current delivery shift first.")
		return
	end
	local firstTarget = ((player.UserId + dayNumber) % #world.DeliveryPrompts) + 1
	jobState[player] = {
		target = firstTarget,
		completed = 0,
	}
	notifyEvent:FireClient(player, "Cafe shift started. Deliver order #" .. firstTarget .. ".")
	sendState(player)
end

local function completeDelivery(player, targetIndex)
	local state = jobState[player]
	if not state then
		notifyEvent:FireClient(player, "Start a cafe shift first.")
		return
	end
	if state.target ~= targetIndex then
		notifyEvent:FireClient(player, "Your current order goes to delivery #" .. state.target .. ".")
		return
	end

	state.completed += 1
	addReward(player, Config.Job.DeliveryReward, 2)
	local profile = profiles[player]
	if profile then
		profile.JobDeliveries += 1
	end

	if state.completed >= Config.Job.DeliveriesPerShift then
		jobState[player] = nil
		notifyEvent:FireClient(player, "Shift complete! Nice work.")
	else
		state.target = (state.target % #world.DeliveryPrompts) + 1
		notifyEvent:FireClient(player, "Delivery complete. Next stop: #" .. state.target .. ".")
	end
	sendState(player)
end

for classId, prompt in pairs(world.ClassPrompts) do
	prompt.Triggered:Connect(function(player)
		beginClass(player, classId)
	end)
end

for index, prompt in pairs(world.HomePrompts) do
	prompt.Triggered:Connect(function(player)
		claimHome(player, index)
	end)
end

world.VehiclePrompt.Triggered:Connect(spawnCar)
world.StylePrompt.Triggered:Connect(applyStyle)
world.JobPrompt.Triggered:Connect(startJob)

for index, prompt in pairs(world.DeliveryPrompts) do
	prompt.Triggered:Connect(function(player)
		completeDelivery(player, index)
	end)
end

actionEvent.OnServerEvent:Connect(function(player, action, payload)
	if action ~= "SubmitAnswer" or type(payload) ~= "table" then
		return
	end

	local pending = pendingQuestions[player]
	if not pending or pending.phaseKey ~= phaseKey() then
		classEvent:FireClient(player, { result = "expired", message = "That class activity expired. Check in again." })
		pendingQuestions[player] = nil
		return
	end

	local answerIndex = tonumber(payload.answerIndex)
	if answerIndex == pending.correct then
		completedPhase[player] = completedPhase[player] or {}
		if not completedPhase[player][pending.phaseKey] then
			completedPhase[player][pending.phaseKey] = true
			local phase = currentPhase()
			addReward(player, phase.rewardCredits or 0, phase.rewardXP or 0)
			local profile = profiles[player]
			if profile then
				profile.ClassCompletions += 1
			end
		end

		classEvent:FireClient(player, {
			result = "correct",
			message = "Correct! " .. pending.explanation,
		})
		pendingQuestions[player] = nil
		sendState(player)
	else
		classEvent:FireClient(player, {
			result = "retry",
			message = "Not quite. Try another choice.",
		})
	end
end)

Players.PlayerAdded:Connect(function(player)
	loadProfile(player)
	completedPhase[player] = {}
	task.delay(1, function()
		if player.Parent then
			sendState(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	saveProfile(player)
	pendingQuestions[player] = nil
	completedPhase[player] = nil
	jobState[player] = nil
	destroyCar(player)

	local plotIndex = playerPlot[player]
	if plotIndex then
		claimedPlots[plotIndex] = nil
	end
	playerPlot[player] = nil

	local home = spawnedHomes[player]
	if home and home.Parent then
		home:Destroy()
	end
	spawnedHomes[player] = nil
	profiles[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadProfile, player)
end

RunService.Heartbeat:Connect(function()
	for player, car in pairs(spawnedCars) do
		if player.Parent and car.Parent and car.PrimaryPart then
			local seat = car:FindFirstChild("DriverSeat")
			local chassis = car.PrimaryPart
			if seat and seat.Occupant then
				local throttle = seat.ThrottleFloat
				local steer = seat.SteerFloat
				local look = chassis.CFrame.LookVector
				local currentY = chassis.AssemblyLinearVelocity.Y
				chassis.AssemblyLinearVelocity = Vector3.new(look.X * throttle * Config.Vehicle.Speed, currentY, look.Z * throttle * Config.Vehicle.Speed)
				chassis.AssemblyAngularVelocity = Vector3.new(0, -steer * Config.Vehicle.TurnRate, 0)
			end
		end
	end
end)

task.spawn(function()
	while true do
		local phase = currentPhase()
		phaseStartedAt = os.clock()
		sendStateAll()

		local elapsed = 0
		while elapsed < phase.duration do
			task.wait(1)
			elapsed = os.clock() - phaseStartedAt
			if math.floor(elapsed) % 5 == 0 then
				sendStateAll()
			end
		end

		for player, pending in pairs(pendingQuestions) do
			if pending.phaseKey == phaseKey() then
				pendingQuestions[player] = nil
				classEvent:FireClient(player, { result = "expired", message = "Class period ended." })
			end
		end

		phaseIndex += 1
		if phaseIndex > #Config.DayPhases then
			phaseIndex = 1
			dayNumber += 1
			for player in pairs(completedPhase) do
				completedPhase[player] = {}
			end
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveProfile(player)
	end
end)
