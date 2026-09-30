local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Modules = ReplicatedStorage:WaitForChild('Modules')

local EducationEngine = require(Modules.src.education.EducationEngine)
local QuestionBank = require(Modules.src.education.QuestionBank)
local TouchItem = require(Modules.src.TouchItem)

local LearningGate = {}
local activeByUserId = {}
local historyByUserId = {}

local function newPart(parent, name, size, cframe, color, material)
	local part = Instance.new('Part')
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addBillboard(parent, size, offset)
	local gui = Instance.new('BillboardGui')
	gui.Name = 'LearningGateGui'
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffset = offset or Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 55
	gui.LightInfluence = 0
	gui.Parent = parent
	return gui
end

local function makeLabel(parent, text, textSize, color)
	local label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(33, 26, 49)
	label.BackgroundTransparency = 0.08
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Text = text
	label.TextWrapped = true
	label.TextScaled = false
	label.TextSize = textSize or 20
	label.Font = Enum.Font.GothamBold
	label.BorderSizePixel = 0
	label.Parent = parent

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	local padding = Instance.new('UIPadding')
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = label

	return label
end

local function filteredBank()
	local pool = {}
	for _, question in ipairs(QuestionBank) do
		local kind = question.questionType
		local difficulty = tonumber(question.difficulty) or 1
		if (kind == 'transfer' or kind == 'reasoning') and difficulty >= 2 then
			table.insert(pool, question)
		end
	end
	return #pool > 0 and pool or QuestionBank
end

local GateBank = filteredBank()

local function getHistory(player)
	local history = historyByUserId[player.UserId]
	if not history then
		history = EducationEngine.newHistory()
		historyByUserId[player.UserId] = history
	end
	return history
end

local function chooseQuestion(player)
	local history = getHistory(player)
	EducationEngine.beginQuest(history)
	local seed = math.floor((os.clock() * 100000) + player.UserId) % 2147483647
	local question = EducationEngine.pickNextQuestion(GateBank, history, Random.new(seed))
	EducationEngine.markShown(history, question)
	return question
end

local function destroyGate(state)
	if not state then
		return
	end
	for _, touchHandle in ipairs(state.touchHandles or {}) do
		if touchHandle and touchHandle.Disconnect then
			touchHandle:Disconnect()
		end
	end
	if state.model and state.model.Parent then
		state.model:Destroy()
	end
	activeByUserId[state.userId] = nil
end

function LearningGate:cancel(player)
	destroyGate(activeByUserId[player.UserId])
end

function LearningGate:challenge(player, finishPart, onSuccess)
	local existing = activeByUserId[player.UserId]
	if existing then
		return
	end

	local question = chooseQuestion(player)
	local model = Instance.new('Model')
	model.Name = 'PipsLearningGate_' .. tostring(player.UserId)
	model.Parent = finishPart.Parent

	local board = newPart(
		model,
		'QuestionBoard',
		Vector3.new(13, 6.6, 0.6),
		finishPart.CFrame * CFrame.new(0, 5, -3.8),
		Color3.fromRGB(82, 52, 122),
		Enum.Material.SmoothPlastic
	)
	board.CanTouch = false

	local promptGui = addBillboard(board, Vector2.new(420, 150), Vector3.new(0, 0.5, 0))
	local promptLabel = makeLabel(promptGui, question.prompt, 21)

	local feedbackGui = addBillboard(board, Vector2.new(360, 54), Vector3.new(0, -2.3, 0))
	local feedbackLabel = makeLabel(
		feedbackGui,
		'Choose the best answer to finish the maze.',
		15,
		Color3.fromRGB(220, 239, 255)
	)

	local colors = {
		Color3.fromRGB(72, 139, 219),
		Color3.fromRGB(211, 92, 151),
		Color3.fromRGB(223, 169, 57),
	}

	local state = {
		userId = player.UserId,
		model = model,
		question = question,
		touchHandles = {},
		resolved = false,
	}
	activeByUserId[player.UserId] = state

	for index = 1, 3 do
		local offset = (index - 2) * 6
		local pad = newPart(
			model,
			'Answer' .. index,
			Vector3.new(5.1, 0.7, 4),
			finishPart.CFrame * CFrame.new(offset, 0.5, 3.2),
			colors[index],
			Enum.Material.Neon
		)
		local answerGui = addBillboard(pad, Vector2.new(180, 74), Vector3.new(0, 2.2, 0))
		makeLabel(answerGui, question.options[index], 18)

		local touchHandle = TouchItem.create(pad, function(touchedPlayer)
			if touchedPlayer ~= player or state.resolved then
				return
			end

			if EducationEngine.isCorrect(question, index) then
				state.resolved = true
				feedbackLabel.Text = EducationEngine.getExplanation(question)
				feedbackLabel.TextColor3 = Color3.fromRGB(128, 255, 177)
				pad.Color = Color3.fromRGB(66, 213, 126)
				task.delay(0.55, function()
					if activeByUserId[player.UserId] ~= state then
						return
					end
					destroyGate(state)
					onSuccess()
				end)
			else
				local message = EducationEngine.getWrongFeedback(question, index, 1)
				feedbackLabel.Text = message
				feedbackLabel.TextColor3 = Color3.fromRGB(255, 207, 115)
				local original = colors[index]
				pad.Color = Color3.fromRGB(207, 72, 72)
				task.delay(0.45, function()
					if pad.Parent then
						pad.Color = original
					end
				end)
			end
		end)

		table.insert(state.touchHandles, touchHandle)
	end
end

return LearningGate
