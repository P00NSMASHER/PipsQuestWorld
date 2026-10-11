--!strict
-- The only server behavior in the showroom place is construction and spawn.
-- No QuestionBank, quiz remotes, teachers, score service, or DataStore is loaded.
local Players=game:GetService("Players")
local Room=require(script.Parent:WaitForChild("World")).build()
local GalleryPass=require(script.Parent:WaitForChild("GalleryPass"))
GalleryPass.decorate(Room.Root)
-- Owner-created GLB models replace primitive visuals ONLY after authorized
-- Roblox model IDs load successfully. Otherwise the complete room is intact.
local FurnitureMeshAdapter=require(script.Parent:WaitForChild("FurnitureMeshAdapter"))
FurnitureMeshAdapter.apply(Room.Root)

local function preparePlayer(player:Player)
    local function onCharacter(character:Model)
        local hrp=character:WaitForChild("HumanoidRootPart",10)
        if not (hrp and hrp:IsA("BasePart")) then return end
        character:PivotTo(Room.Spawn*CFrame.new(0,2.8,0))
        local humanoid=character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed=13
            humanoid.AutoRotate=true
            humanoid.Sit=false
        end
    end
    player.CharacterAdded:Connect(onCharacter)
    if player.Character then task.defer(onCharacter,player.Character) end
end

Players.PlayerAdded:Connect(preparePlayer)
for _,player in ipairs(Players:GetPlayers()) do
    preparePlayer(player)
end
