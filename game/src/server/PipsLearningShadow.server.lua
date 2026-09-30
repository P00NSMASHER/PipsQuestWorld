local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local Modules = ReplicatedStorage:WaitForChild('Modules')
local logger = require(Modules.src.utils.Logger)
local Config = require(Modules.src.PipsOverlayConfig)

assert(Config.mode == 'shadow', 'PipsLearningShadow must remain shadow-only on the foundation branch')
assert(Config.blockFinish == false, 'Shadow mode may not block the Maze World finish')
assert(Config.replaceMazeUI == false, 'Shadow mode may not replace Maze World UI')
assert(Config.replaceMazeRewards == false, 'Shadow mode may not replace Maze World rewards')
assert(Config.replaceMazeGeneration == false, 'Shadow mode may not replace Maze World maze generation')

local place = Workspace:WaitForChild('Place')
local maps = place:WaitForChild('Maps')

local telemetry = ReplicatedStorage:FindFirstChild('PipsShadowTelemetry')
if not telemetry then
	telemetry = Instance.new('Folder')
	telemetry.Name = 'PipsShadowTelemetry'
	telemetry.Parent = ReplicatedStorage
end

telemetry:SetAttribute('Mode', 'shadow')
telemetry:SetAttribute('ObservedMazes', 0)
telemetry:SetAttribute('ObservedFinishes', 0)
telemetry:SetAttribute('LastFinishUserId', 0)
telemetry:SetAttribute('GameplayMutationAllowed', false)

local seenMazes = {}
local finishConnections = {}

local function playerFromHit(hit)
	if not hit then
		return nil
	end
	local character = hit:FindFirstAncestorOfClass('Model')
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function observeFinish(finishPart)
	if not finishPart or not finishPart:IsA('BasePart') or finishConnections[finishPart] then
		return
	end

	finishConnections[finishPart] = finishPart.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player then
			return
		end

		telemetry:SetAttribute(
			'ObservedFinishes',
			(telemetry:GetAttribute('ObservedFinishes') or 0) + 1
		)
		telemetry:SetAttribute('LastFinishUserId', player.UserId)
		logger:i('[PIPS_SHADOW] observed original Maze World finish for ' .. player.Name)
	end)

	finishPart.AncestryChanged:Connect(function(_, parent)
		if parent == nil and finishConnections[finishPart] then
			finishConnections[finishPart]:Disconnect()
			finishConnections[finishPart] = nil
		end
	end)
end

local function observeMaze(mazeFolder)
	if not mazeFolder or mazeFolder.Name ~= 'Maze' or seenMazes[mazeFolder] then
		return
	end

	seenMazes[mazeFolder] = true
	telemetry:SetAttribute(
		'ObservedMazes',
		(telemetry:GetAttribute('ObservedMazes') or 0) + 1
	)

	task.defer(function()
		local spawnPlaceholder = mazeFolder:FindFirstChild('SpawnPlaceholder', true)
		local finishPlaceholder = mazeFolder:FindFirstChild('FinishPlaceholder', true)

		telemetry:SetAttribute('LastMazeHasSpawn', spawnPlaceholder ~= nil)
		telemetry:SetAttribute('LastMazeHasFinish', finishPlaceholder ~= nil)

		if finishPlaceholder then
			observeFinish(finishPlaceholder)
		end

		logger:i(
			('[PIPS_SHADOW] observed Maze World maze; spawn=%s finish=%s'):format(
				tostring(spawnPlaceholder ~= nil),
				tostring(finishPlaceholder ~= nil)
			)
		)
	end)
end

for _, descendant in ipairs(maps:GetDescendants()) do
	if descendant.Name == 'Maze' and descendant:IsA('Folder') then
		observeMaze(descendant)
	end
end

maps.DescendantAdded:Connect(function(descendant)
	if descendant.Name == 'Maze' and descendant:IsA('Folder') then
		observeMaze(descendant)
	end
end)

logger:i('[PIPS_SHADOW] learning integration observer ready; gameplay mutation disabled')
