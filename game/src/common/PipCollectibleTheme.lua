local CollectionService = game:GetService('CollectionService')

local PipCollectibleTheme = {}

local MINT = Color3.fromRGB(126, 245, 201)
local GOLD = Color3.fromRGB(255, 220, 92)

local function getPrimaryPart(instance)
	if instance:IsA('BasePart') then
		return instance
	end
	if instance:IsA('Model') then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA('BasePart', true)
	end
	return nil
end

function PipCollectibleTheme:apply(instance)
	-- Visual-only adaptation. Do not change tags, itemId, touch listeners, values,
	-- respawn timing, sounds, or datastore behavior from Maze World.
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA('BasePart') then
			descendant.Material = Enum.Material.Neon
			descendant.Color = GOLD
			descendant.CastShadow = false
		end
	end

	local anchor = getPrimaryPart(instance)
	if anchor then
		anchor.Material = Enum.Material.Neon
		anchor.Color = GOLD
		anchor.CastShadow = false

		local light = anchor:FindFirstChild('PipGlow')
		if not light then
			light = Instance.new('PointLight')
			light.Name = 'PipGlow'
			light.Color = MINT
			light.Range = 8
			light.Brightness = 1.35
			light.Parent = anchor
		end

		local highlight = instance:FindFirstChild('PipHighlight')
		if not highlight then
			highlight = Instance.new('Highlight')
			highlight.Name = 'PipHighlight'
			highlight.FillColor = GOLD
			highlight.FillTransparency = 0.78
			highlight.OutlineColor = MINT
			highlight.OutlineTransparency = 0.18
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.Adornee = instance
			highlight.Parent = instance
		end
	end

	return instance
end

return PipCollectibleTheme
