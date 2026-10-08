"""Fail closed if the publishable replica accidentally packages study gameplay.

This checks the actual Rojo project and (when supplied) the assembled RBXLX.
It does NOT certify Roblox rendering or actual iPhone visual quality.
"""
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

base = Path(__file__).resolve().parents[2]
project = base / "emma-showroom.project.json"
data = json.loads(project.read_text())
assert data["name"] == "ABVMClassroomReplica"
tree = data["tree"]
server = tree["ServerScriptService"]["ClassroomReplica"]
client = tree["StarterPlayer"]["StarterPlayerScripts"]
expected = {
    "Main": "emma-classroom/showroom/Main.server.lua",
    "World": "emma-classroom/showroom/Room.lua",
    "GalleryPass": "emma-classroom/showroom/GalleryPass.lua",
    "ArtPass": "emma-classroom/showroom/ArtPass.lua",
}
for key, path in expected.items():
    assert server[key]["$path"] == path, f"Unexpected mapping for {key}"
    assert (base / path).is_file()
assert client["ClassroomView"]["$path"] == "emma-classroom/showroom/View.client.lua"
assert set(server) == {"$className", *expected}
assert set(client) == {"$className", "ClassroomView"}
assert "ReplicatedStorage" not in tree, "No lesson authority or answer payloads should replicate"
assert "QuestionBank" not in project.read_text()
view = (base / "emma-classroom/showroom/View.client.lua").read_text()
main = (base / "emma-classroom/showroom/Main.server.lua").read_text()
room = (base / "emma-classroom/showroom/Room.lua").read_text()
assert "LockFirstPerson" in view and "Enum.CameraType.Custom" in view
assert "Instance.new(\"ScreenGui\")" not in view
assert "Instance.new(\"RemoteFunction\")" not in main
assert "Instance.new(\"RemoteEvent\")" not in main
assert "DataStoreService" not in main
assert "StaffModel" not in room and "teacherModel" not in room
assert "QuestionBoard" not in room and "World.setBoardQuestion" not in room
assert "ClassroomReplicaSpawn" in room
assert "ArtPass.decorate(root)" in room
assert "Vector3.new(5.78,.16,3.86)" in room, "Desk rim returned to bulky dark prototype"
assert "Color3.fromRGB(126,121,109)" in room, "Thin laminate desk surround unexpectedly changed"
assert "Vector3.new(2.38,1.90,.22)" in room, "Missing single contoured-back chair collider"
assert 'name.." seamless molded back shell"' in room, "Continuous molded chair shell missing"
assert "Vector3.new(2.42,2.02,.31)" in room, "Chair shell proportions regressed"
assert 'name.." molded back panel"' not in room and "bandProfile={" not in room, "Rejected segmented chair returned"
assert 'name.." underseat frame runner"' in room, "Chair steel runner missing"
assert 'Vector3.new(1.10,.55,.55)' in room, "Oversized bottle was reintroduced"
assert 'Frosted fluorescent diffuser' in room, "Glaring neon ceiling fixture returned"
assert 'for _,x in ipairs({-18,18}) do' in room, "Nine-fixture neon grid returned"
assert 'local center=CFrame.new(20.55,5.87,-26.4)' in room, "Teacher globe moved off its desk"
assert "CFrame.new(x,2.93,z+4.39)" in (base / "emma-classroom/showroom/ArtPass.lua").read_text(), "Desk/chair detailing no longer follows geometry"
assert "GalleryPass.decorate(Room.Root)" in main
assert 'sign(root,"Rule card "' not in room, "Old oversized classroom cards returned"
assert 'for i,x in ipairs({-24,-8,12}) do' in room, "Unsupported basket placement returned"
assert '"Number learning card"' not in (base / "emma-classroom/showroom/ArtPass.lua").read_text(), "Rear wall gallery would overlap number cards"

if len(sys.argv) > 1:
    root = ET.parse(sys.argv[1]).getroot()
    paths = []
    sources = []
    def walk(item, path):
        name = item.findtext("./Properties/string[@name='Name']") or item.get("class")
        current = path + (name,)
        paths.append(current)
        src = item.findtext("./Properties/ProtectedString[@name='Source']") or ""
        if src:
            sources.append((current, src))
        for child in item.findall("Item"):
            walk(child, current)
    for item in root.findall("Item"):
        walk(item, ())
    all_names = {component for path in paths for component in path}
    for name in ("QuestionBank", "EmmaStudyClient", "EmmaStudyUI", "EmmaStudy",
                 "EmmaStudyShared", "EmmaClassroomRemotes"):
        assert name not in all_names, f"Educational runtime leaked into built place: {name}"
    for forbidden in ("ScreenGui", "RemoteFunction", "RemoteEvent"):
        assert forbidden not in all_names, f"{forbidden} object in gallery place"
    for component in ("ClassroomReplica", "Main", "World", "ArtPass",
                      "GalleryPass", "ClassroomView"):
        assert component in all_names, f"Missing replica component {component}"
    for path, src in sources:
        assert 'Instance.new("ScreenGui")' not in src, f"Custom HUD code at {path}"
        assert 'GetDataStore(' not in src, f"Study persistence linked at {path}"
        assert 'require(script.Parent:WaitForChild("QuestionBank"))' not in src
    print("PASS: assembled classroom-only place excludes all study UI, question bank, quiz remotes and saved-score runtime")
else:
    print("PASS: classroom-only project maps 4 architectural scripts + 1 camera script, no study system")
