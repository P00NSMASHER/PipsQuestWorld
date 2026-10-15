-- Run only through Studio tooling against an isolated showroom copy.
-- Not mapped into school/emma-showroom.project.json or the live runtime.
-- This test was run against real Roblox properties, not the headless doubles.
local source = game.ServerScriptService:FindFirstChild("ClassroomReplica")
assert(source, "REPLICA_MODULES_MISSING")
local candidate = source:Clone()
candidate.Name = "NativeReviewModules"
candidate.Parent = game.ServerStorage
local ok, result = xpcall(function()
    local room = require(candidate.World).build()
    task.wait()
    require(candidate.GalleryPass).decorate(room.Root)
    require(candidate.FurnitureMeshAdapter).apply(room.Root)
    local face = room.Root:FindFirstChild("Photo flipchart dry erase face", true)
    assert(face, "NATIVE_FLIPCHART_MISSING")
    local gui = face:FindFirstChild("Printed detail")
    assert(gui and gui.Face == Enum.NormalId.Back, "NATIVE_FLIPCHART_FACE_INVALID")
    local text = gui:FindFirstChild("Printed text")
    assert(text and text.Text == "", "NATIVE_FLIPCHART_NOT_NEUTRAL")
    assert(room.Root:FindFirstChild("PhotographedHallway"), "NATIVE_HALL_MISSING")
    assert(room.Root:FindFirstChild("ClassroomReplicaSpawn"), "NATIVE_SPAWN_MISSING")
    local parts = 0
    for _, object in ipairs(room.Root:GetDescendants()) do
        if object:IsA("BasePart") then parts += 1 end
    end
    assert(parts <= 3050, "NATIVE_PART_BUDGET_EXCEEDED")
    return {parts=parts, completeConstructor=true, native=true}
end, debug.traceback)
candidate:Destroy()
assert(ok, result)
return result
