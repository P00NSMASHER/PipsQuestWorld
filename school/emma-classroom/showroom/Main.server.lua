--!strict
-- The showroom remains a quiet walk-through: room construction, one stationary
-- Mrs. Benulis display, and player spawn. No questions, remotes, score service,
-- curriculum, or DataStore are loaded.
local Players=game:GetService("Players")
local Room=require(script.Parent:WaitForChild("World")).build()
local GalleryPass=require(script.Parent:WaitForChild("GalleryPass"))
GalleryPass.decorate(Room.Root)
local StaffModel=require(script.Parent:WaitForChild("StaffModel"))
local StaffData=require(script.Parent:WaitForChild("StaffData"))
local benulis
for _,teacher in ipairs(StaffData.Teachers) do
    if teacher.name=="Mrs. Benulis" then benulis=teacher;break end
end
assert(benulis,"Mrs. Benulis showroom profile is required")
-- Build Mrs. Benulis at adult scale inside the constructor so its floor and
-- pose geometry are finalized once, before it enters Workspace.
local teacher=StaffModel.create(benulis,1.10)
teacher.Name="Mrs. Benulis - Board"
teacher:SetAttribute("ShowroomStationaryTeacher",true)
teacher:PivotTo(CFrame.new(-11,3.15,-29)*CFrame.Angles(0,math.pi,0))
teacher.Parent=Room.Root
-- Owner-created GLB models replace primitive visuals ONLY after authorized
-- Roblox model IDs load successfully. Otherwise the complete room is intact.
local FurnitureMeshAdapter=require(script.Parent:WaitForChild("FurnitureMeshAdapter"))
FurnitureMeshAdapter.apply(Room.Root)
-- Configure the optional material; native texture streaming never gates spawn.
local finishOk=pcall(Room.applyPhotoFloorFinish,Room.Root)
if not finishOk then
    warn("Classroom floor finish unavailable; retaining native wood.")
end

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
