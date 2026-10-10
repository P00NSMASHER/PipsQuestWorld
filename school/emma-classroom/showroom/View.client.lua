--!strict
-- First-person walk-through: no custom ScreenGui, overlays or educational UI.
-- Roblox's own touch thumbstick/jump controls remain available for movement.
local Players=game:GetService("Players")
local StarterGui=game:GetService("StarterGui")
local Workspace=game:GetService("Workspace")
local player=Players.LocalPlayer

for _,kind in ipairs({
    Enum.CoreGuiType.Backpack,
    Enum.CoreGuiType.PlayerList,
    Enum.CoreGuiType.Chat,
    Enum.CoreGuiType.Health,
}) do
    pcall(function() StarterGui:SetCoreGuiEnabled(kind,false) end)
end

player.CameraMinZoomDistance=.5
player.CameraMaxZoomDistance=16
player.CameraMode=Enum.CameraMode.LockFirstPerson

local function useNormalMovementCamera(character:Model)
    local humanoid=character:WaitForChild("Humanoid",10)
    if not (humanoid and humanoid:IsA("Humanoid")) then return end
    local camera=Workspace.CurrentCamera
    if camera then
        camera.CameraType=Enum.CameraType.Custom
        camera.CameraSubject=humanoid
    end
end

player.CharacterAdded:Connect(useNormalMovementCamera)
if player.Character then task.defer(useNormalMovementCamera,player.Character) end
