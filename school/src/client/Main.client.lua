local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("SchoolShared")
local Config = require(shared:WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("SchoolRemotes")

local stateEvent = remotes:WaitForChild("State")
local classEvent = remotes:WaitForChild("ClassActivity")
local actionEvent = remotes:WaitForChild("Action")
local notifyEvent = remotes:WaitForChild("Notify")

local screen = Instance.new("ScreenGui")
screen.Name = "SchoolLifeUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = player:WaitForChild("PlayerGui")

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = parent
end

local function stroke(parent, transparency)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 1
	uiStroke.Transparency = transparency or 0.5
	uiStroke.Color = Color3.fromRGB(255, 255, 255)
	uiStroke.Parent = parent
end

local function label(parent, text, size, position, fontSize, align)
	local object = Instance.new("TextLabel")
	object.BackgroundTransparency = 1
	object.Text = text
	object.Size = size
	object.Position = position or UDim2.new()
	object.Font = Enum.Font.Gotham
	object.TextSize = fontSize or 18
	object.TextColor3 = Color3.fromRGB(245, 247, 252)
	object.TextXAlignment = align or Enum.TextXAlignment.Left
	object.Parent = parent
	return object
end

local function button(parent, text, size, position)
	local object = Instance.new("TextButton")
	object.AutoButtonColor = true
	object.BackgroundColor3 = Color3.fromRGB(54, 64, 90)
	object.TextColor3 = Color3.fromRGB(255, 255, 255)
	object.Font = Enum.Font.GothamBold
	object.TextSize = 18
	object.Text = text
	object.Size = size
	object.Position = position
	object.Parent = parent
	round(object, 12)
	return object
end

local top = Instance.new("Frame")
top.Name = "TopBar"
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.fromScale(0.5, 0.025)
top.Size = UDim2.new(0.92, 0, 0, 64)
top.BackgroundColor3 = Color3.fromRGB(27, 31, 43)
top.BackgroundTransparency = 0.08
top.Parent = screen
round(top, 16)
stroke(top, 0.72)

local clockText = label(top, "7:30 AM", UDim2.fromScale(0.25, 1), UDim2.fromScale(0.03, 0), 20)
clockText.Font = Enum.Font.GothamBold

local periodText = label(top, "Before School", UDim2.fromScale(0.45, 1), UDim2.fromScale(0.28, 0), 20, Enum.TextXAlignment.Center)
periodText.Font = Enum.Font.GothamBold

local moneyText = label(top, "150 C • 0 XP", UDim2.fromScale(0.25, 1), UDim2.fromScale(0.72, 0), 17, Enum.TextXAlignment.Right)

local phoneButton = button(screen, "PHONE", UDim2.fromOffset(104, 52), UDim2.new(1, -122, 1, -76))
phoneButton.AnchorPoint = Vector2.new(0, 0)

local phone = Instance.new("Frame")
phone.Name = "Phone"
phone.AnchorPoint = Vector2.new(1, 1)
phone.Position = UDim2.new(1, -18, 1, -138)
phone.Size = UDim2.new(0.86, 0, 0, 365)
phone.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
phone.Visible = false
phone.Parent = screen
round(phone, 22)
stroke(phone, 0.72)

local phoneTitle = label(phone, Config.GameName, UDim2.new(1, -36, 0, 50), UDim2.fromOffset(18, 12), 24)
phoneTitle.Font = Enum.Font.GothamBold

local scheduleTitle = label(phone, "TODAY", UDim2.new(1, -36, 0, 30), UDim2.fromOffset(18, 64), 15)
scheduleTitle.TextColor3 = Color3.fromRGB(150, 190, 255)
scheduleTitle.Font = Enum.Font.GothamBold

local scheduleText = label(phone, "", UDim2.new(1, -36, 0, 176), UDim2.fromOffset(18, 96), 16)
scheduleText.TextWrapped = true
scheduleText.TextYAlignment = Enum.TextYAlignment.Top

local statusTitle = label(phone, "MY LIFE", UDim2.new(1, -36, 0, 30), UDim2.fromOffset(18, 270), 15)
statusTitle.TextColor3 = Color3.fromRGB(150, 190, 255)
statusTitle.Font = Enum.Font.GothamBold

local statusText = label(phone, "Home: none\nCafe job: off", UDim2.new(1, -36, 0, 66), UDim2.fromOffset(18, 302), 16)
statusText.TextWrapped = true
statusText.TextYAlignment = Enum.TextYAlignment.Top

local modal = Instance.new("Frame")
modal.Name = "ClassModal"
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.55)
modal.Size = UDim2.new(0.9, 0, 0, 390)
modal.BackgroundColor3 = Color3.fromRGB(23, 27, 40)
modal.Visible = false
modal.Parent = screen
round(modal, 20)
stroke(modal, 0.68)

local modalTitle = label(modal, "CLASS", UDim2.new(1, -36, 0, 42), UDim2.fromOffset(18, 16), 23)
modalTitle.Font = Enum.Font.GothamBold

local modalPrompt = label(modal, "", UDim2.new(1, -36, 0, 82), UDim2.fromOffset(18, 64), 20)
modalPrompt.TextWrapped = true
modalPrompt.TextYAlignment = Enum.TextYAlignment.Center
modalPrompt.TextXAlignment = Enum.TextXAlignment.Center

local answersHolder = Instance.new("Frame")
answersHolder.BackgroundTransparency = 1
answersHolder.Size = UDim2.new(1, -36, 0, 198)
answersHolder.Position = UDim2.fromOffset(18, 150)
answersHolder.Parent = modal

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 10)
list.FillDirection = Enum.FillDirection.Vertical
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Parent = answersHolder

local feedback = label(modal, "", UDim2.new(1, -36, 0, 34), UDim2.fromOffset(18, 346), 15, Enum.TextXAlignment.Center)
feedback.TextWrapped = true

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -26)
toast.Size = UDim2.new(0.88, 0, 0, 52)
toast.BackgroundColor3 = Color3.fromRGB(35, 42, 60)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextWrapped = true
toast.Font = Enum.Font.GothamBold
toast.TextSize = 16
toast.Text = ""
toast.Parent = screen
round(toast, 14)

local toastToken = 0
local function showToast(message)
	toastToken += 1
	local token = toastToken
	toast.Text = tostring(message)
	TweenService:Create(toast, TweenInfo.new(0.18), { BackgroundTransparency = 0.08, TextTransparency = 0 }):Play()
	task.delay(3, function()
		if toastToken ~= token then
			return
		end
		TweenService:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
	end)
end

local function rebuildSchedule()
	local lines = {}
	for _, phase in ipairs(Config.DayPhases) do
		if phase.kind == "class" or phase.id == "lunch" or phase.id == "after" then
			table.insert(lines, "• " .. phase.name)
		end
	end
	scheduleText.Text = table.concat(lines, "\n")
end
rebuildSchedule()

phoneButton.Activated:Connect(function()
	phone.Visible = not phone.Visible
end)

local function clearAnswers()
	for _, child in ipairs(answersHolder:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function openQuestion(data)
	clearAnswers()
	modalTitle.Text = data.title or "Class Activity"
	modalPrompt.Text = data.prompt or ""
	feedback.Text = ""
	modal.Visible = true

	for index, choice in ipairs(data.choices or {}) do
		local answer = button(answersHolder, tostring(choice), UDim2.new(1, 0, 0, 42), UDim2.new())
		answer.LayoutOrder = index
		answer.Activated:Connect(function()
			actionEvent:FireServer("SubmitAnswer", { answerIndex = index })
		end)
	end
end

classEvent.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	if data.prompt then
		openQuestion(data)
		return
	end

	if data.result == "correct" then
		feedback.TextColor3 = Color3.fromRGB(115, 235, 145)
		feedback.Text = data.message or "Correct!"
		task.delay(1.4, function()
			modal.Visible = false
		end)
	elseif data.result == "retry" then
		feedback.TextColor3 = Color3.fromRGB(255, 213, 110)
		feedback.Text = data.message or "Try again."
	elseif data.result == "expired" then
		feedback.TextColor3 = Color3.fromRGB(255, 150, 150)
		feedback.Text = data.message or "Class ended."
		task.delay(1.5, function()
			modal.Visible = false
		end)
	end
end)

notifyEvent.OnClientEvent:Connect(showToast)

stateEvent.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" then
		return
	end
	clockText.Text = state.clock or "--:--"
	periodText.Text = state.phaseName or "School Day"
	moneyText.Text = string.format("%d C • %d XP", state.credits or 0, state.xp or 0)

	local home = state.homePlot and ("Home " .. state.homePlot) or "none"
	local job = state.jobActive and "active" or "off"
	statusText.Text = "Home: " .. home .. "\nCafe job: " .. job
end)
