"""Fail-closed acceptance of a nonpublishable mesh-review Roblox place.

The production Rojo graph and config must remain byte-for-byte mapped to
disabled furniture. Only an explicit review-place graph may enable the two
creator-approved asset IDs. Neither graph includes educational gameplay.
"""
from pathlib import Path
import copy
import json
import sys
import xml.etree.ElementTree as ET

school=Path(__file__).resolve().parents[2]
release=json.loads((school/"emma-showroom.project.json").read_text())
review=json.loads((school/"emma-mesh-review.project.json").read_text())
production_config=school/"emma-classroom/showroom/FurnitureMeshConfig.lua"
review_config=school/"emma-classroom/mesh/FurnitureMeshReviewConfig.lua"
receipt=json.loads((school/"emma-classroom/mesh/imported_models.json").read_text())
expected_assets={
    "abvm_student_chair":"132417338693200",
    "abvm_student_desk":"75559376486007",
}
assert {x["name"]:str(x["assetId"]) for x in receipt["assets"]}==expected_assets
assert all(x["operationModeration"]=="Approved" for x in receipt["assets"])
assert receipt["productionEnabled"] is False

release_text=production_config.read_text()
preview_text=review_config.read_text()
assert "Enabled = false" in release_text
assert "Enabled = true" in preview_text
for name,id in (("ChairModelAssetId",expected_assets["abvm_student_chair"]),
                ("DeskModelAssetId",expected_assets["abvm_student_desk"])):
    assert f"{name} = {id}" in release_text and f"{name} = {id}" in preview_text
release_graph=release["tree"]["ServerScriptService"]["ClassroomReplica"]
review_graph=review["tree"]["ServerScriptService"]["ClassroomReplica"]
assert release_graph["FurnitureMeshConfig"]["$path"]=="emma-classroom/showroom/FurnitureMeshConfig.lua"
assert review_graph["FurnitureMeshConfig"]["$path"]=="emma-classroom/mesh/FurnitureMeshReviewConfig.lua"
expected=copy.deepcopy(release)
expected["name"]="ABVMClassroomMeshReview_NOT_FOR_PUBLISH"
expected["tree"]["ServerScriptService"]["ClassroomReplica"]["FurnitureMeshConfig"]["$path"]=(
    "emma-classroom/mesh/FurnitureMeshReviewConfig.lua"
)
assert review==expected, "Review project differs from production by more than config and name"
publisher=(school.parent/".github/workflows/publish-emma-classroom.yml").read_text()
assert "school/emma-showroom.project.json" in publisher
assert "school/emma-mesh-review.project.json" not in publisher
print("PASS_NONPUBLISHABLE_REVIEW_PROJECT_EXACTLY_ONE_MODULE_OVERRIDE")

if len(sys.argv)>1:
    xml=ET.parse(sys.argv[1]).getroot()
    modules=[]
    for item in xml.iter("Item"):
        if item.get("class") != "ModuleScript":
            continue
        props=item.find("Properties")
        if props is None:continue
        name=props.findtext("./string[@name='Name']")
        if name=="FurnitureMeshConfig":
            modules.append(props.findtext("./ProtectedString[@name='Source']",default=""))
    assert len(modules)==1,"Review place must contain exactly one FurnitureMeshConfig module"
    text=modules[0]
    assert "Enabled = true" in text, "Approved furniture not enabled in review binary"
    assert "ChairModelAssetId = 132417338693200" in text
    assert "DeskModelAssetId = 75559376486007" in text
    assert "Enabled = false" not in text, "Review binary contains production config"
    print("PASS_ASSEMBLED_PREVIEW_BINARIES_CONTAIN_ACTUAL_APPROVED_IDS")
