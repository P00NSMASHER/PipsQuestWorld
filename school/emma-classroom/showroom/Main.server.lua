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
local teacher=StaffModel.create(benulis)
teacher.Name="Mrs. Benulis - Board"
teacher:SetAttribute("ShowroomStationaryTeacher",true)
-- This single showroom teacher should read as the adult in the supplied
-- portrait, not at the smaller shared staff-preview scale.
teacher:ScaleTo(1.06)
teacher:PivotTo(CFrame.new(-11,3.15,-29)*CFrame.Angles(0,math.pi,0))
local lowest=math.huge
for _,item in ipairs(teacher:GetDescendants()) do
    if item:IsA("BasePart") then
        lowest=math.min(lowest,item.Position.Y-item.Size.Y/2)
    end
end
if lowest<math.huge then
    teacher:PivotTo(teacher:GetPivot()+Vector3.new(0,.52-lowest,0))
end
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
