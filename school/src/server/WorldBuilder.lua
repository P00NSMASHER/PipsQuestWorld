local WorldBuilder = {}

local function makePart(parent, name, size, cframe, color, material, anchored)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color or Color3.fromRGB(210, 210, 210)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = anchored ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addBillboard(part, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(210, 48)
	gui.StudsOffset = Vector3.new(0, part.Size.Y * 0.5 + 2.5, 0)
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui
end

local function addPrompt(part, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function makeBuilding(parent, name, center, size, wallColor, signText)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	makePart(model, "Floor", Vector3.new(size.X, 1, size.Z), CFrame.new(center + Vector3.new(0, 0.5, 0)), Color3.fromRGB(236, 233, 225), Enum.Material.Concrete)
	makePart(model, "BackWall", Vector3.new(size.X, 18, 1), CFrame.new(center + Vector3.new(0, 9, -size.Z / 2)), wallColor, Enum.Material.Brick)
	makePart(model, "LeftWall", Vector3.new(1, 18, size.Z), CFrame.new(center + Vector3.new(-size.X / 2, 9, 0)), wallColor, Enum.Material.Brick)
	makePart(model, "RightWall", Vector3.new(1, 18, size.Z), CFrame.new(center + Vector3.new(size.X / 2, 9, 0)), wallColor, Enum.Material.Brick)
	makePart(model, "FrontLeft", Vector3.new(size.X * 0.42, 18, 1), CFrame.new(center + Vector3.new(-size.X * 0.29, 9, size.Z / 2)), wallColor, Enum.Material.Brick)
	makePart(model, "FrontRight", Vector3.new(size.X * 0.42, 18, 1), CFrame.new(center + Vector3.new(size.X * 0.29, 9, size.Z / 2)), wallColor, Enum.Material.Brick)

	local sign = makePart(model, "Sign", Vector3.new(18, 4, 1), CFrame.new(center + Vector3.new(0, 13, size.Z / 2 + 0.7)), Color3.fromRGB(30, 35, 55), Enum.Material.SmoothPlastic)
	addBillboard(sign, signText or name)

	return model
end

local function makeDesk(parent, position)
	local top = makePart(parent, "Desk", Vector3.new(6, 0.7, 3), CFrame.new(position + Vector3.new(0, 2.7, 0)), Color3.fromRGB(159, 110, 74), Enum.Material.Wood)
	makePart(parent, "LegA", Vector3.new(0.5, 2.5, 0.5), CFrame.new(position + Vector3.new(-2.2, 1.25, -0.8)), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
	makePart(parent, "LegB", Vector3.new(0.5, 2.5, 0.5), CFrame.new(position + Vector3.new(2.2, 1.25, -0.8)), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
	return top
end

local function buildClassroom(parent, config, classId)
	local info = config.ClassRooms[classId]
	local model = makeBuilding(parent, classId .. "Classroom", info.position, Vector3.new(44, 20, 34), info.accent, info.displayName .. " CLASS")

	for row = -1, 1 do
		for col = -2, 2 do
			makeDesk(model, info.position + Vector3.new(col * 7, 0, row * 7))
		end
	end

	local checkIn = makePart(model, "CheckIn", Vector3.new(5, 5, 2), CFrame.new(info.position + Vector3.new(0, 2.5, 13)), info.accent, Enum.Material.Neon)
	addBillboard(checkIn, "CHECK IN")
	local prompt = addPrompt(checkIn, "Attend", info.displayName)

	return prompt
end

local function makeHouseShell(parent, ownerName, center)
	local model = Instance.new("Model")
	model.Name = "StarterHome_" .. ownerName
	model.Parent = parent

	makePart(model, "Foundation", Vector3.new(34, 1, 28), CFrame.new(center + Vector3.new(0, 0.5, 0)), Color3.fromRGB(220, 220, 220), Enum.Material.Concrete)
	makePart(model, "Back", Vector3.new(34, 12, 1), CFrame.new(center + Vector3.new(0, 6, -14)), Color3.fromRGB(236, 226, 210), Enum.Material.WoodPlanks)
	makePart(model, "Left", Vector3.new(1, 12, 28), CFrame.new(center + Vector3.new(-17, 6, 0)), Color3.fromRGB(236, 226, 210), Enum.Material.WoodPlanks)
	makePart(model, "Right", Vector3.new(1, 12, 28), CFrame.new(center + Vector3.new(17, 6, 0)), Color3.fromRGB(236, 226, 210), Enum.Material.WoodPlanks)
	makePart(model, "FrontLeft", Vector3.new(13, 12, 1), CFrame.new(center + Vector3.new(-10.5, 6, 14)), Color3.fromRGB(236, 226, 210), Enum.Material.WoodPlanks)
	makePart(model, "FrontRight", Vector3.new(13, 12, 1), CFrame.new(center + Vector3.new(10.5, 6, 14)), Color3.fromRGB(236, 226, 210), Enum.Material.WoodPlanks)
	makePart(model, "Roof", Vector3.new(36, 1, 30), CFrame.new(center + Vector3.new(0, 12.5, 0)), Color3.fromRGB(70, 78, 95), Enum.Material.Slate)

	local bed = makePart(model, "Bed", Vector3.new(8, 2, 4), CFrame.new(center + Vector3.new(-9, 1.2, -7)), Color3.fromRGB(130, 170, 240), Enum.Material.Fabric)
	local tableTop = makePart(model, "Table", Vector3.new(6, 0.8, 6), CFrame.new(center + Vector3.new(8, 2.8, -5)), Color3.fromRGB(150, 105, 72), Enum.Material.Wood)
	makePart(model, "TableLeg", Vector3.new(1, 2.5, 1), CFrame.new(center + Vector3.new(8, 1.25, -5)), Color3.fromRGB(90, 75, 60), Enum.Material.Wood)

	local sign = makePart(model, "OwnerSign", Vector3.new(10, 3, 1), CFrame.new(center + Vector3.new(0, 8, 14.8)), Color3.fromRGB(50, 60, 85), Enum.Material.SmoothPlastic)
	addBillboard(sign, ownerName .. "'s Home")
	bed.CanCollide = true
	tableTop.CanCollide = true

	return model
end

function WorldBuilder.build(config)
	local old = workspace:FindFirstChild("SchoolWorld")
	if old then
		old:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "SchoolWorld"
	world.Parent = workspace

	makePart(world, "Ground", Vector3.new(900, 2, 900), CFrame.new(0, -1, 60), Color3.fromRGB(109, 174, 92), Enum.Material.Grass)
	makePart(world, "MainRoad", Vector3.new(70, 1, 900), CFrame.new(150, 0.05, 60), Color3.fromRGB(55, 58, 63), Enum.Material.Asphalt)
	makePart(world, "CrossRoad", Vector3.new(900, 1, 60), CFrame.new(0, 0.06, 155), Color3.fromRGB(55, 58, 63), Enum.Material.Asphalt)

	local school = Instance.new("Model")
	school.Name = "SchoolCampus"
	school.Parent = world

	makePart(school, "CampusFloor", Vector3.new(190, 1, 125), CFrame.new(0, 0.5, 0), Color3.fromRGB(226, 222, 210), Enum.Material.Concrete)
	makePart(school, "BackWall", Vector3.new(190, 22, 2), CFrame.new(0, 11, -62), Color3.fromRGB(190, 70, 72), Enum.Material.Brick)
	makePart(school, "LeftWall", Vector3.new(2, 22, 125), CFrame.new(-95, 11, 0), Color3.fromRGB(190, 70, 72), Enum.Material.Brick)
	makePart(school, "RightWall", Vector3.new(2, 22, 125), CFrame.new(95, 11, 0), Color3.fromRGB(190, 70, 72), Enum.Material.Brick)
	makePart(school, "FrontLeft", Vector3.new(82, 22, 2), CFrame.new(-54, 11, 62), Color3.fromRGB(190, 70, 72), Enum.Material.Brick)
	makePart(school, "FrontRight", Vector3.new(82, 22, 2), CFrame.new(54, 11, 62), Color3.fromRGB(190, 70, 72), Enum.Material.Brick)

	local schoolSign = makePart(school, "SchoolSign", Vector3.new(32, 6, 2), CFrame.new(0, 16, 63.5), Color3.fromRGB(35, 40, 60), Enum.Material.SmoothPlastic)
	addBillboard(schoolSign, "SCHOOL LIFE ACADEMY")

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CampusSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, 1, 86)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(245, 245, 245)
	spawn.Material = Enum.Material.Concrete
	spawn.Parent = world

	local classPrompts = {}
	for classId in pairs(config.ClassRooms) do
		classPrompts[classId] = buildClassroom(school, config, classId)
	end

	local cafeteria = makeBuilding(world, "Cafeteria", Vector3.new(-120, 0, 95), Vector3.new(70, 34, 48), Color3.fromRGB(240, 180, 85), "CAFETERIA")
	for i = -2, 2 do
		makeDesk(cafeteria, Vector3.new(-120 + i * 10, 3, 95))
	end

	local cafe = makeBuilding(world, "Cafe", Vector3.new(-150, 0, -115), Vector3.new(55, 34, 42), Color3.fromRGB(112, 78, 62), "AFTER SCHOOL CAFE")
	local jobCounter = makePart(cafe, "JobCounter", Vector3.new(12, 5, 3), CFrame.new(-150, 3, -98), Color3.fromRGB(95, 65, 48), Enum.Material.Wood)
	addBillboard(jobCounter, "CAFE JOB")
	local jobPrompt = addPrompt(jobCounter, "Start Shift", "Cafe Delivery")

	local styleBooth = makeBuilding(world, "StyleBooth", Vector3.new(235, 0, -60), Vector3.new(44, 28, 34), Color3.fromRGB(130, 105, 210), "STYLE STUDIO")
	local stylePad = makePart(styleBooth, "StylePad", Vector3.new(8, 1, 8), CFrame.new(235, 1, -60), Color3.fromRGB(218, 184, 255), Enum.Material.Neon)
	local stylePrompt = addPrompt(stylePad, "Change Style", "Style Studio")

	local vehicleLot = makePart(world, "VehicleLot", Vector3.new(80, 1, 75), CFrame.new(245, 0.5, 30), Color3.fromRGB(85, 88, 92), Enum.Material.Asphalt)
	local vehiclePad = makePart(world, "VehiclePad", Vector3.new(14, 1, 22), CFrame.new(245, 1.1, 30), Color3.fromRGB(90, 190, 245), Enum.Material.Neon)
	addBillboard(vehiclePad, "SPAWN CAR")
	local vehiclePrompt = addPrompt(vehiclePad, "Spawn", "Starter Car")

	local homePrompts = {}
	local homePlots = {}
	for i = 1, 6 do
		local row = math.floor((i - 1) / 3)
		local col = (i - 1) % 3
		local center = Vector3.new(-255 + col * 82, 0, 185 + row * 80)
		local plot = makePart(world, "HomePlot" .. i, Vector3.new(58, 1, 54), CFrame.new(center + Vector3.new(0, 0.5, 0)), Color3.fromRGB(120, 185, 105), Enum.Material.Grass)
		local claim = makePart(world, "HomeClaim" .. i, Vector3.new(6, 2, 6), CFrame.new(center + Vector3.new(0, 1.5, 20)), Color3.fromRGB(255, 224, 105), Enum.Material.Neon)
		addBillboard(claim, "HOME " .. i)
		homePrompts[i] = addPrompt(claim, "Claim", "Starter Home")
		homePlots[i] = center
		plot:SetAttribute("PlotIndex", i)
	end

	local deliveryPrompts = {}
	local deliveryPositions = {
		Vector3.new(235, 2, -60),
		Vector3.new(250, 2, 115),
		Vector3.new(-245, 2, 155),
		Vector3.new(-120, 2, 95),
	}
	for i, position in ipairs(deliveryPositions) do
		local marker = makePart(world, "Delivery" .. i, Vector3.new(5, 5, 5), CFrame.new(position), Color3.fromRGB(255, 208, 70), Enum.Material.Neon)
		marker.Transparency = 0.15
		addBillboard(marker, "DELIVERY " .. i)
		deliveryPrompts[i] = addPrompt(marker, "Deliver", "Cafe Order")
	end

	return {
		Root = world,
		ClassPrompts = classPrompts,
		HomePrompts = homePrompts,
		HomePlots = homePlots,
		VehiclePrompt = vehiclePrompt,
		VehicleSpawnCFrame = CFrame.new(245, 4, 30),
		StylePrompt = stylePrompt,
		JobPrompt = jobPrompt,
		DeliveryPrompts = deliveryPrompts,
		BuildHome = function(ownerName, center)
			return makeHouseShell(world, ownerName, center)
		end,
	}
end

return WorldBuilder
