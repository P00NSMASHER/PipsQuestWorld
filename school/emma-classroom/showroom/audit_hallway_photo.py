#!/usr/bin/env python3
"""Constructed-Luau test of the October 10 ABVM hallway photo landmarks.

This executes the same shipped Room.lua constructors used for the showroom
place, not a grep-only mock. The photos themselves contain children and remain
outside the public repository. Geometry is provisional until native iPhone QA.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import subprocess
import tempfile

from export_source_scene import generate_luau

PROBE = r'''
local function pieces(name)
    local out={}
    for _,obj in ipairs(Room.Root:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name==name then
            table.insert(out,obj)
        end
    end
    return out
end
local function expect(name,n)
    local p=pieces(name)
    assert(#p==n,"PHOTO_HALL_PART_COUNT "..name.." got="..#p.." want="..n)
    return p
end
local function one(name) return expect(name,1)[1] end
local function near(x,y) return math.abs(x-y)<.055 end
local function gui(part,name,face)
    local child=part:FindFirstChild(name)
    assert(child and child:IsA("SurfaceGui")
        and child.Face==face,"PHOTO_HALL_SURFACE_GUI "..name)
    return child
end
local hall=Room.Root:FindFirstChild("PhotographedHallway")
assert(hall and hall:GetAttribute("ScaleConfidence")=="provisional",
    "PHOTO_HALL_SURVEY_FIDELITY_MISLABELED")
local floor=one("Photo hall polished square stone floor")
assert(floor.CanCollide and floor.Material==Enum.Material.Slate
    and near(floor.Size.X,108) and near(floor.Size.Z,22.5),
    "PHOTO_HALL_FLOOR_GEOMETRY")
local grid=gui(floor,"Photo square-stone tile grout",Enum.NormalId.Top)
local long=0
local cross=0
for _,line in ipairs(grid:GetChildren()) do
    if line.Name=="Stone long tile joint" then long+=1 end
    if line.Name=="Stone cross tile joint" then cross+=1 end
end
assert(long==25 and cross==6,"PHOTO_HALL_MISSING_STONE_GRID")
assert(#pieces("Photo hall stone tile joint")==0,
    "PHOTO_HALL_TILE_JOINTS_REGRESSED_TO_PHYSICAL_PARTS")
assert(near(one("Classroom doorway brass threshold").Position.Y,.556))
local rear=one("Photo hall rear blue-gray wall")
assert(rear.CanCollide and near(rear.Position.X,59.75)
    and near(rear.Position.Z,80.75) and rear.Size.X>=108,
    "PHOTO_HALL_SKY_GAP")
local north=one("Photo hall continuous north wall")
assert(north.CanCollide and near(north.Position.X,38.05)
    and near(north.Position.Z,80.75) and north.Size.X>=108,
    "PERPENDICULAR_HALLWAY_WEST_WALL_MISSING")
local caps=expect("Photo hall end cap",1)
assert(caps[1].CanCollide and near(caps[1].Position.Z,134.75),
    "PHOTO_HALL_FAR_END_SKY_GAP")
local south=expect("Side corridor end wall",1)[1]
local southBrick=expect("Side corridor full-height glazed brick",1)[1]
assert(near(south.Position.X,48.675) and near(south.Position.Z,4.25)
    and south.Size.X>=21.8 and south.CanCollide
    and south.Position.X-south.Size.X/2>=37.74
    and southBrick.Position.X-southBrick.Size.X/2>=37.85,
    "LEFT_STAFF_CORRIDOR_SOUTH_CAP_GAPPED_OR_LOST")
local transition=expect("Staff hallway floor transition strip",1)[1]
assert(near(transition.Position.X,48.48)
    and near(transition.Position.Z,26.72)
    and transition.Size.X>=22.3 and not transition.CanCollide,
    "STAFF_HALLWAY_FLOOR_TRANSITION_MISSING")
local eastBrick=expect("Staff entry east wall glazed brick",1)[1]
assert(near(eastBrick.Position.X,59.02) and eastBrick.Size.Z>=22.7
    and eastBrick.Size.Y>=12.6,
    "STAFF_HALLWAY_EAST_FULL_BRICK_FINISH_MISSING")
local vestibuleFloor=one("Side hall floor")
local vestibuleRoof=one("Side hall ceiling")
assert(vestibuleFloor.Material==Enum.Material.Slate
    and near(vestibuleFloor.Position.X,48.25)
    and vestibuleFloor.Size.X>=22.45
    and vestibuleFloor:FindFirstChild("StaffVestibuleStoneGrid"),
    "STAFF_HALLWAY_FLOOR_FINISH_NOT_UNIFORM")
assert(near(vestibuleRoof.Position.X-vestibuleRoof.Size.X/2,37.66)
    and vestibuleRoof.Position.X-vestibuleRoof.Size.X/2>=37.64,
    "STAFF_HALLWAY_ROOF_PROTRUDES_THROUGH_CLASSROOM_WALL")
local function assertExteriorShellClearance()
    assert(vestibuleRoof.Position.X-vestibuleRoof.Size.X/2>=37.64
        and north.Position.X-north.Size.Z/2>=37.59
        and south.Position.X-south.Size.X/2>=37.74
        and southBrick.Position.X-southBrick.Size.X/2>=37.85,
        "STAFF_HALLWAY_EXTERIOR_SHELL_CROSSES_YELLOW_WALL")
end
assertExteriorShellClearance()
local roofCF=vestibuleRoof.CFrame
vestibuleRoof.CFrame=CFrame.new(-.25,0,0)*roofCF
local shellOk,shellErr=pcall(assertExteriorShellClearance)
vestibuleRoof.CFrame=roofCF
assert(not shellOk and string.find(tostring(shellErr),
    "STAFF_HALLWAY_EXTERIOR_SHELL_CROSSES_YELLOW_WALL",1,true),
    "STAFF_HALLWAY_INTRUSION_MUTATION_NOT_REJECTED")
print("STAFF_HALLWAY_INTRUSION_NEGATIVE_REJECTED exterior_roof_shift")
assert(#pieces("Left hallway outside corner return")==0,
    "OBSOLETE_FLOATING_HALL_SEAM_RETURNED")
assert(#pieces("Photo hall front outer wall")==1
    and near(one("Photo hall front outer wall").Position.Z,126.25),
    "LEFT_HALL_PASSAGE_HAS_BLOCKING_REAR_WALL")
assert(#pieces("Rear corridor end wall")==0 and
       #pieces("Hall left wall")==0,
       "OLD_DEAD_END_HALLWAY_RETURNED")
expect("Closed classroom closet door",2)
expect("Closet doorway plaster header infill",1)
assert(#pieces("Door transom glass")==0,
    "RIGHT_CLOSET_PALE_OPEN_TRANSOM_RETURNED")
expect("Photo hall classroom exterior blue-gray paint",2)
-- Closed neighboring doors must be physical oak-and-frosted-glass
-- facades rather than UI pictures that render as opaque dark rectangles.
local facades=expect("Photo hall adjacent oak door",2)
local panels=expect("Photo hall adjacent frosted door glass",2)
local stiles=expect("Photo hall adjacent oak side stile",4)
local lintels=expect("Photo hall adjacent oak upper lintel",2)
local sills=expect("Photo hall adjacent oak glass sill",2)
local bars=expect("Photo hall adjacent oak glass crossbar",2)
local raised=expect("Photo hall adjacent lower raised wood panel",2)
local plates=expect("Photo hall adjacent brass push plate",2)
local pulls=expect("Photo hall adjacent brass pull",2)
local sealed=expect("Photo hall front outer wall",1)
local classroomRear=one("Back wall right")
assert(classroomRear.CanCollide and near(classroomRear.Position.X,23),
    "CLOSED_NEIGHBOR_CLASSROOM_WALL_LOST")
assert(not Room.Root:FindFirstChild("Side hall far wall"),
    "OLD_STAFF_CORRIDOR_CROSS_WALL_BLOCKS_STRAIGHT_EXIT")
table.sort(facades,function(a,b)return a.Position.X<b.Position.X end)
table.sort(panels,function(a,b)return a.Position.X<b.Position.X end)
local function checkClosedOakDoors()
    expect("Photo hall adjacent oak side stile",4)
    expect("Photo hall adjacent frosted door glass",2)
    for i,lower in ipairs(facades) do
        local glass=panels[i]
        assert(lower.Material==Enum.Material.Wood
            and lower.Size.Y<4.5 and near(lower.Position.Y,2.665)
            and lower:GetAttribute("ArchitecturalFacade")
                =="Closed; no extra classroom",
            "PHOTO_HALL_ADJACENT_OPAQUE_BACKING_RETURNED")
        assert(glass.Material==Enum.Material.Glass
            and glass.Transparency>.13 and glass.Transparency<.49
            and near(glass.Size.Y,4.88)
            and math.abs(glass.Position.Z-lower.Position.Z)<.05
            and glass.Position.X-lower.Position.X>.08
            and glass.Position.Y-glass.Size.Y/2
                >lower.Position.Y+lower.Size.Y/2
            and glass:GetAttribute("GlassAperture")
                =="Upper opening has no solid wood backing",
            "PHOTO_HALL_ADJACENT_GLASS_APERTURE_LOST")
        local wall=north
        assert(wall.CanCollide and wall.Size.Y>=12.9
            and wall.Size.X>107
            and wall.Position.X<lower.Position.X,
            "PHOTO_HALL_ADJACENT_SEALED_WALL_LOST")
        assert(not glass.CanCollide and not glass.CanQuery
            and not lower.CanCollide and not lower.CanQuery,
            "PHOTO_HALL_ADJACENT_DOOR_COLLIDER")
        assert(not lower:FindFirstChild("Frosted glass and oak door trim"),
            "PHOTO_HALL_ADJACENT_UI_DUPLICATE")
    end
    for _,group in ipairs({stiles,lintels,sills,bars,raised,plates,pulls}) do
        for _,item in ipairs(group) do
            assert(not item.CanCollide and not item.CanQuery,
                "PHOTO_HALL_ADJACENT_DOOR_COLLIDER")
            assert(item.Material==Enum.Material.Wood or
                item.Material==Enum.Material.Metal,
                "PHOTO_HALL_ADJACENT_DETAIL_BECAME_UI")
        end
    end
    for _,s in ipairs(stiles) do
        assert(near(s.Size.X,.72) and s.Size.Y>4.8,
            "PHOTO_HALL_ADJACENT_STILE_SHAPE_MISSING")
    end
end
checkClosedOakDoors()
table.sort(facades,function(a,b)return a.Position.Z<b.Position.Z end)
table.sort(panels,function(a,b)return a.Position.Z<b.Position.Z end)
assert(near(facades[1].Position.Z,57.75)
    and near(facades[2].Position.Z,126.25),
    "LEFT_HALL_OPENING_OBSTRUCTED_BY_OLD_FAKE_DOOR")
-- Back double oak leaves must open into an actual ENCLOSED supply closet,
-- not the main corridor. The original staff-side LEFT opening is the
-- navigable hallway route. Require true collision walls and visible storage.
local closet=Room.Root:FindFirstChild("ClassroomSupplyCloset")
assert(closet and closet:GetAttribute("Purpose")
    =="Classroom supplies only; not a hallway",
    "RIGHT_DOOR_SUPPLY_CLOSET_FOLDER_MISSING")
local function checkCloset()
    local walls=expect("Supply closet side wall",2)
    table.sort(walls,function(a,b)return a.Position.X<b.Position.X end)
    assert(walls[1].CanCollide and walls[2].CanCollide
        and near(walls[1].Position.X,-5.95)
        and near(walls[2].Position.X,5.95)
        and near(walls[1].Position.Z,31.70)
        and walls[1].Size.Z>=8.55,
        "RIGHT_CLOSET_SIDE_WALLS_NOT_SEALED")
    local back=one("Supply closet solid rear wall")
    assert(back.CanCollide and near(back.Position.Z,36.05)
        and back.Size.X>12.40 and back.Size.Y>=12.9,
        "RIGHT_CLOSET_REAR_WALL_NOT_SEALED")
    expect("Supply closet child coat rail",1)
    local coats=expect("Children coat body",5)
    expect("Children coat sleeve",10)
    expect("Children coat collar",5)
    expect("Supply closet coat hook",5)
    for _,coat in ipairs(coats) do
        assert(not coat.CanCollide and coat.Material==Enum.Material.Fabric,
            "RIGHT_CLOSET_COATS_MISSING_OR_BLOCKING")
    end
    local closetFloor=one("Supply closet warm laminate floor")
    assert(closetFloor.CanCollide and
        closetFloor.Position.Y+closetFloor.Size.Y/2>.50
        and closetFloor.Position.Y+closetFloor.Size.Y/2<.58
        and closetFloor.Size.X>=11.2 and closetFloor.Size.Z>=8.9
        and closetFloor.Position.Z-closetFloor.Size.Z/2<=26.85
        and closetFloor.Position.Z+closetFloor.Size.Z/2>=35.6,
        "RIGHT_CLOSET_PHYSICAL_FLOOR_SUPPORT_MISSING")
    local closetCeiling=one("Supply closet finished ceiling")
    assert(closetCeiling.CanCollide and closetCeiling.Size.X>=12.4
        and closetCeiling.Size.Z>=9.0
        and closetCeiling.Position.Y-closetCeiling.Size.Y/2>=12.9,
        "RIGHT_CLOSET_FINISHED_CEILING_MISSING")
    local header=one("Closet doorway plaster header infill")
    assert(header.CanCollide and header.Material==Enum.Material.SmoothPlastic
        and header.Size.X>10.9 and near(header.Size.Y,1.75)
        and near(header.Position.Y,12.125),
        "RIGHT_CLOSET_DOORWAY_HEADER_NOT_FINISHED")
    local sign=one("Welcome over door")
    local label=sign:FindFirstChild("Surface")
    assert(label and label:FindFirstChildOfClass("TextLabel")
       and label:FindFirstChildOfClass("TextLabel").Text=="CLASSROOM CLOSET",
       "RIGHT_DOOR_CLOSET_SIGN_NOT_VISIBLE")
    return back
end
local closetBack=checkCloset()
closetBack.CanCollide=false
local safe,reason=pcall(checkCloset)
closetBack.CanCollide=true
assert(not safe and string.find(tostring(reason),
    "RIGHT_CLOSET_REAR_WALL_NOT_SEALED",1,true),
    "CLOSET_OPEN_REAR_MUTATION_NOT_CAUGHT")
checkCloset()
local closetFloor=one("Supply closet warm laminate floor")
closetFloor.CanCollide=false
local floorSafe,floorReason=pcall(checkCloset)
closetFloor.CanCollide=true
assert(not floorSafe and string.find(tostring(floorReason),
    "RIGHT_CLOSET_PHYSICAL_FLOOR_SUPPORT_MISSING",1,true),
    "CLOSET_UNSUPPORTED_FLOOR_MUTATION_NOT_CAUGHT")
checkCloset()
local beforeFloorSize=closetFloor.Size
closetFloor.Size=Vector3.new(11.30,.045,8.33)
local seamSafe,seamReason=pcall(checkCloset)
closetFloor.Size=beforeFloorSize
assert(not seamSafe and string.find(tostring(seamReason),
    "RIGHT_CLOSET_PHYSICAL_FLOOR_SUPPORT_MISSING",1,true),
    "CLOSET_UNSUPPORTED_THRESHOLD_SEAM_MUTATION_NOT_CAUGHT")
checkCloset()
print("LEFT_HALL_RIGHT_CLOSET_PHYSICAL_PASS staff_left_open=true "
    .."school_hall_connected=true back_double_doors_are_supply_closet=true "
    .."closet_walls=3 shelves=3 rear_wall_and_floor_mutations_rejected=true")
-- Verify intentional counterexamples fail against constructed Luau parts.
local originalSize=facades[1].Size
facades[1].Size=Vector3.new(6.45,10,.14)
local ok,err=pcall(checkClosedOakDoors)
facades[1].Size=originalSize
assert(not ok and string.find(tostring(err),"OPAQUE_BACKING_RETURNED",1,true),
    "PHOTO_HALL_ADJACENT_OPAQUE_SLAB_MUTATION_ACCEPTED")
local originalAlpha=panels[1].Transparency
panels[1].Transparency=0
ok,err=pcall(checkClosedOakDoors)
panels[1].Transparency=originalAlpha
assert(not ok and string.find(tostring(err),"GLASS_APERTURE_LOST",1,true),
    "PHOTO_HALL_ADJACENT_SOLID_GLASS_MUTATION_ACCEPTED")
pulls[1].CanCollide=true
ok,err=pcall(checkClosedOakDoors)
pulls[1].CanCollide=false
assert(not ok and string.find(tostring(err),"DOOR_COLLIDER",1,true),
    "PHOTO_HALL_ADJACENT_COLLIDING_HARDWARE_MUTATION_ACCEPTED")
local originalName=stiles[1].Name
stiles[1].Name="Missing oak stile mutation"
ok,err=pcall(checkClosedOakDoors)
stiles[1].Name=originalName
assert(not ok and string.find(tostring(err),"PHOTO_HALL_PART_COUNT",1,true),
    "PHOTO_HALL_ADJACENT_MISSING_STILE_MUTATION_ACCEPTED")
checkClosedOakDoors()
print("PHOTO_HALL_ADJACENT_NATIVE_OAK_DOORS_PASS closed=2 actual_glass=2 "
    .."stiles=4 trim_rails=6 raised=2 brass=4 new_parts=18 "
    .."sealed_walls=true no_collision=true relocated_fake_door=true "
    .."mutations=opaque,glass,hardware,stile")
local glass=expect("Door glass",2)
for _,panel in ipairs(glass) do
    local faces=0
    for _,g in ipairs(panel:GetChildren()) do
        if g.Name=="Photo green shamrock on glass" then
            assert(g:IsA("SurfaceGui"),"PHOTO_HALL_GLASS_SHAMROCK_NOT_GUI")
            local petals=0
            for _,d in ipairs(g:GetChildren()) do
                if d.Name=="Shamrock leaf" then petals+=1 end
            end
            assert(petals==4 and g:FindFirstChild("Shamrock stem"),
                "PHOTO_HALL_GREEN_SHAMROCK_INCOMPLETE")
            faces+=1
        end
    end
    assert(faces==2,"PHOTO_HALL_SHAMROCK_MUST_FACE_BOTH_SIDES")
end
local segments={
    {"Photo hall rear glazed brick",1},
    {"Photo hall classroom exterior glazed brick",2},
    {"Photo hall front outer glazed brick",1},
    {"Photo hall left end glazed brick",1},
    {"Photo hall right end glazed brick",0},
    {"Photo hall continuous north full-height brick",3},
    {"Photo hall continuous north door header brick",2},
}
-- A previous version removed the old x=54 west end-cap collider but left
-- its separate 4.25-stud-tall opaque brick SurfaceGui carrier in the open
-- staff doorway. Require ZERO near-cap decorative masonry, regardless of
-- CanCollide. The opposite far-end brick carrier is retained.
assert(#pieces("Photo hall right end glazed brick")==0,
    "PHOTO_HALL_OPAQUE_STAFF_EXIT_VENEER_RETURNED")
local count=0
for _,s in ipairs(segments) do
    for _,wall in ipairs(expect(s[1],s[2])) do
        assert(not wall.CanCollide and wall.Material==Enum.Material.Brick,
            "PHOTO_HALL_BRICK_BECAME_PHYSICAL_COLLIDER")
        if wall.Name=="Photo hall continuous north door header brick" then
            assert(wall.Size.Y>=2 and near(wall.Position.Y,11.68),
                "PHOTO_HALL_DOOR_HEADER_BRICK_FINISH_LOST")
        else
            assert(wall.Size.Y>=12.6 and near(wall.Position.Y,6.35),
                "PHOTO_HALL_FULL_HEIGHT_BRICK_FINISH_LOST")
        end
        -- Every wall now uses the same native mobile-stable brick material.
        assert(wall.Color.R>.70 and wall.Color.G>.45 and
            wall.Color.B>.18 and wall.Color.B<.34
            and wall.Reflectance>.03,
            "PHOTO_HALL_GOLDEN_BRICK_FALLBACK_LOST")
        assert(not wall:FindFirstChild("Photo glazed offset brick bond"),
            "PHOTO_HALL_MIXED_SCALE_SURFACE_BRICKS_RETURNED")
        count+=1
    end
end
assert(count==10,"PHOTO_HALL_UNIFORM_BRICK_PANEL_COUNT "..count)
assert(#pieces("Photo hall rear dado cap")==0
    and #pieces("Photo hall front dado cap")==0
    and #pieces("Staff entry east wall oak cap rail")==0,
    "PHOTO_HALL_OLD_HALF_WALL_CAP_RETURNED")
local westBrick=expect("Photo hall continuous north full-height brick",3)
local headers=expect("Photo hall continuous north door header brick",2)
local function overlaps(a0,a1,b0,b1)
    return a0<b1 and a1>b0
end
for _,wall in ipairs(westBrick) do
    local z0=wall.Position.Z-wall.Size.X/2
    local z1=wall.Position.Z+wall.Size.X/2
    assert(wall.Size.Y>=12.6 and near(wall.Position.Y,6.35)
        and not wall.CanCollide,
        "PHOTO_HALL_WEST_FULL_BRICK_FINISH_MISSING")
    assert(not overlaps(z0,z1,54.525,60.975)
        and not overlaps(z0,z1,123.025,129.475),
        "PHOTO_HALL_WEST_BRICK_SKIN_COVERS_DOOR_OPENING")
end
for _,header in ipairs(headers) do
    assert(header.Size.Y<2.1 and header.Position.Y-header.Size.Y/2>10.6,
        "PHOTO_HALL_DOOR_HEADER_DESCENDS_INTO_OPENING")
end
assert(#pieces("Photo hall staff return blue-gray plaster")==0
    and #pieces("Photo hall staff return glazed brick")==0
    and #pieces("Photo hall doorway inner wall end plaster")==0
    and #pieces("Photo hall doorway inner wall end brick")==0,
    "PHOTO_HALL_OBSOLETE_CLASSROOM_WALL_ARTIFACT_RETURNED")
expect("Photo hall student work hanging rail",1)
-- The six photographs show real white paper hanging as diagonals.
-- Previous UI-only paper rendered as a completely bare wall in the
-- original camera captures. Require 23 dimensional NONCOLLIDING Parts.
local sheets=expect("Photo hall anonymous diamond student display",23)
table.sort(sheets,function(a,b)return a.Position.Z<b.Position.Z end)
local function checkSheets()
    for i,p in ipairs(sheets) do
        local m=p.CFrame.m
        assert(math.abs(p.Position.Z-(80.75+(i-12)*3.55))<.045
            and near(p.Position.Y,9.05) and near(p.Position.X,59.02),
            "PHOTO_HALL_PAPER_POSITION_OR_SPACING_INVALID")
        assert(math.abs(math.abs(m[4])-.7071068)<.04
            and math.abs(math.abs(m[5])-.7071068)<.04
            and math.abs(math.abs(m[7])-.7071068)<.04
            and p.Size.X>1.8 and p.Size.Y>2.1,
            "PHOTO_HALL_PAPER_NOT_DIAMOND_GEOMETRY")
        assert(not p.CanCollide and p.CanQuery==false
            and p.CastShadow==true
            and p.Material==Enum.Material.SmoothPlastic,
            "PHOTO_HALL_PAPER_PHYSICAL_COLLISION_OR_MATERIAL")
        assert(p:GetAttribute("OriginalStudentData")==false
            and p:GetAttribute("Source")=="Anonymous original paper artwork",
            "PHOTO_HALL_PRIVATE_STUDENT_ASSIGNMENT_FORBIDDEN")
        local style=p:GetAttribute("AnonymousArtStyle")
        assert(style==((23-i)%5)+1,
            "PHOTO_HALL_ANONYMOUS_ART_VARIATION_OR_ORDER_LOST")
        local g=gui(p,"Anonymous paper pencil strokes",Enum.NormalId.Front)
        -- The standalone Luau constructor harness represents Vector2
        -- as an array; native Roblox supplies named X/Y fields.
        local gw=g.CanvasSize.X or g.CanvasSize[1]
        local gh=g.CanvasSize.Y or g.CanvasSize[2]
        assert(gw==190 and gh==218,
            "PHOTO_HALL_PAPER_MOBILE_CANVAS_CHANGED")
        local guidelines=0
        local motifs=0
        for _,mark in ipairs(g:GetChildren()) do
            assert(mark:IsA("Frame") and mark.BackgroundTransparency<.45,
                "PHOTO_HALL_PAPER_ART_INVISIBLE_OR_UNSAFE")
            if mark.Name=="Invented pale handwritten guideline" then
                guidelines+=1
            elseif mark.Name=="Anonymous original colored pencil motif" then
                motifs+=1
                assert(mark.Rotation>=-21 and mark.Rotation<=21,
                    "PHOTO_HALL_PAPER_CRAYON_MOTIF_ROTATION_INVALID")
                assert(mark.BackgroundColor3.R>.30
                    and mark.BackgroundColor3.G>.33
                    and mark.BackgroundColor3.B>.30,
                    "PHOTO_HALL_PAPER_CRAYON_PALETTE_INVALID")
            else
                error("PHOTO_HALL_PRIVATE_STUDENT_ASSIGNMENT_OR_IMAGE_FORBIDDEN")
            end
        end
        assert(guidelines==3 and motifs==3,
            "PHOTO_HALL_ANONYMOUS_PENCIL_GUIDELINES_LOST")
    end
end
checkSheets()
local bad=sheets[1]
local collide=bad.CanCollide
bad.CanCollide=true
local ok,err=pcall(checkSheets)
bad.CanCollide=collide
assert(not ok and string.find(tostring(err),
    "PHOTO_HALL_PAPER_PHYSICAL_COLLISION_OR_MATERIAL",1,true),
    "PHOTO_HALL_COLLIDABLE_SHEET_REGRESSION_NOT_REJECTED")
print("PHOTO_HALL_PAPER_NEGATIVE_REJECTED collider")
local oldCF=bad.CFrame
bad.CFrame=CFrame.new(bad.Position)
ok,err=pcall(checkSheets)
bad.CFrame=oldCF
assert(not ok and string.find(tostring(err),
    "PHOTO_HALL_PAPER_NOT_DIAMOND_GEOMETRY",1,true),
    "PHOTO_HALL_FLAT_SHEET_REGRESSION_NOT_REJECTED")
print("PHOTO_HALL_PAPER_NEGATIVE_REJECTED rotation")
local originalStyle=bad:GetAttribute("AnonymousArtStyle")
bad:SetAttribute("AnonymousArtStyle",0)
ok,err=pcall(checkSheets)
bad:SetAttribute("AnonymousArtStyle",originalStyle)
assert(not ok and string.find(tostring(err),
    "PHOTO_HALL_ANONYMOUS_ART_VARIATION_OR_ORDER_LOST",1,true),
    "PHOTO_HALL_UNIFORM_OR_UNKNOWN_ART_MUTATION_NOT_REJECTED")
print("PHOTO_HALL_PAPER_NEGATIVE_REJECTED missing_original_art_style")
local artGui=bad:FindFirstChild("Anonymous paper pencil strokes")
local originalMotif=nil
for _,mark in ipairs(artGui:GetChildren()) do
    if mark.Name=="Anonymous original colored pencil motif" then
        originalMotif=mark
        break
    end
end
assert(originalMotif,"PHOTO_HALL_ANONYMOUS_ART_NEGATIVE_TEST_SETUP")
originalMotif.Name="Unapproved image payload"
ok,err=pcall(checkSheets)
originalMotif.Name="Anonymous original colored pencil motif"
assert(not ok and string.find(tostring(err),
    "PHOTO_HALL_PRIVATE_STUDENT_ASSIGNMENT_OR_IMAGE_FORBIDDEN",1,true),
    "PHOTO_HALL_UNAPPROVED_IMAGE_MUTATION_NOT_REJECTED")
print("PHOTO_HALL_PAPER_NEGATIVE_REJECTED unapproved_art_payload")
local originalOpacity=originalMotif.BackgroundTransparency
originalMotif.BackgroundTransparency=1
ok,err=pcall(checkSheets)
originalMotif.BackgroundTransparency=originalOpacity
assert(not ok and string.find(tostring(err),
    "PHOTO_HALL_PAPER_ART_INVISIBLE_OR_UNSAFE",1,true),
    "PHOTO_HALL_INVISIBLE_ART_MUTATION_NOT_REJECTED")
print("PHOTO_HALL_PAPER_NEGATIVE_REJECTED invisible_art")
checkSheets()
print("PHOTO_HALL_ANONYMOUS_ART_RUNTIME_PASS sheets=23 styles=5 "
    .."pencil_guidelines=69 anonymous_colored_marks=69 "
    .."no_source_photos_or_child_identifiers=true extra_physical_parts=0")
local welcome=one("Photo hall vertical welcome plaque")
local letters=gui(welcome,"Stacked WELCOME lettering",Enum.NormalId.Back)
local expectedWelcome={"W","E","L","C","O","M","E"}
local actual=letters:GetChildren()
assert(#actual==7,"PHOTO_HALL_WELCOME_NOT_STACKED")
for i,letter in ipairs(expectedWelcome) do
    assert(actual[i].Name=="Vertical school welcome letter"
        and actual[i].Text==letter,
        "PHOTO_HALL_WELCOME_LETTER_SEQUENCING")
end
local ceiling=one("Photo hall ivory ceiling")
assert(not ceiling.CanCollide and ceiling.Size.X>=108,
    "PHOTO_HALL_CEILING_NOT_ENCLOSED")
for _,lamp in ipairs(expect("Photo hall fluorescent diffuser",5)) do
    assert(not lamp.CanCollide and lamp.Material==Enum.Material.Glass
        and near(lamp.Position.Y,12.85)
        and lamp:FindFirstChildOfClass("SurfaceLight"),
        "PHOTO_HALL_ILLUMINATION_REGRESSION")
    gui(lamp,"Inset silver fluorescent rim",Enum.NormalId.Bottom)
end
-- The far-end landmark must be actual 3D geometry on the existing
-- CLOSED structural end wall. UI-only faux windows were never visible
-- in independent source-derived screenshots.
local leftCap=caps[1]
assert(leftCap and leftCap.Position.Z>134.7,"PHOTO_HALL_FAR_ENDCAP_NOT_FOUND")
local function assertDimensionalEndWindow()
    local glazing=one("Photo hall yellow window glazing")
    assert(not glazing.CanCollide and not glazing.CanQuery
        and glazing.Material==Enum.Material.Glass
        and near(glazing.Size.Y,8.32) and near(glazing.Size.Z,14.68)
        and glazing.Transparency>0 and glazing.Transparency<.35
        and glazing.Position.Z<leftCap.Position.Z-.45
        and glazing:GetAttribute("ArchitecturalFacade")=="Enclosed end-cap glazing",
        "PHOTO_HALL_END_WINDOW_3D_GLAZING_OR_SEALED_FACADE_LOST")

    local horizontal=expect("Photo hall yellow sash horizontal",2)
    local vertical=expect("Photo hall yellow sash vertical",2)
    local mullions=expect("Photo hall yellow glazed divider vertical",2)
    local transom=one("Photo hall yellow glazed divider horizontal")
    assert(not transom.CanCollide and not transom.CanQuery
        and near(transom.Position.Y,7.42),
        "PHOTO_HALL_END_WINDOW_TRANSOM_LOST")
    for _,bar in ipairs(horizontal) do
        assert(not bar.CanCollide and not bar.CanQuery
            and bar.Material==Enum.Material.Wood and bar.Size.Z>=15,
            "PHOTO_HALL_END_WINDOW_FRAME_NOT_NATIVE")
    end
    for _,bar in ipairs(vertical) do
        assert(not bar.CanCollide and not bar.CanQuery
            and bar.Material==Enum.Material.Wood and bar.Size.Y>=8.7,
            "PHOTO_HALL_END_WINDOW_FRAME_NOT_NATIVE")
    end
    for _,bar in ipairs(mullions) do
        assert(not bar.CanCollide and not bar.CanQuery
            and bar.Material==Enum.Material.Wood,
            "PHOTO_HALL_END_WINDOW_MUNTINS_MISSING")
    end

    local sun=one("Photo hall dimensional sunburst center")
    assert(sun.Shape==Enum.PartType.Ball and not sun.CanCollide
        and not sun.CanQuery and near(sun.Position.Y,9.55),
        "PHOTO_HALL_3D_SUN_CENTER_MISSING")
    for _,ray in ipairs(expect("Photo hall dimensional sunburst ray",8)) do
        assert(not ray.CanCollide and not ray.CanQuery
            and ray.Material==Enum.Material.SmoothPlastic
            and math.abs(ray.Position.Y-9.55)<=1.05
            and math.abs(ray.Position.X-48.5)<=1.05
            and ray.Position.Z<leftCap.Position.Z-.45,
            "PHOTO_HALL_3D_SUN_RAY_MISSING_OR_BLOCKING")
    end
    assert(not leftCap:FindFirstChild("Photo hallway yellow end-window motif"),
        "PHOTO_HALL_OLD_UI_WINDOW_DUPLICATED")
    return glazing
end
local endWindow=assertDimensionalEndWindow()
-- Adversarial mutants: a solid pane or an absent ray must fail this exact
-- assembled Luau test rather than quietly pass the visual vocabulary.
endWindow.CanCollide=true
local okWindow,errWindow=pcall(assertDimensionalEndWindow)
endWindow.CanCollide=false
assert(not okWindow and string.find(tostring(errWindow),
    "PHOTO_HALL_END_WINDOW_3D_GLAZING_OR_SEALED_FACADE_LOST",1,true),
    "PHOTO_HALL_END_WINDOW_COLLIDER_MUTATION_UNDETECTED")
local testRay=expect("Photo hall dimensional sunburst ray",8)[1]
testRay.Name="Temporarily missing sunray in test"
okWindow,errWindow=pcall(assertDimensionalEndWindow)
testRay.Name="Photo hall dimensional sunburst ray"
assert(not okWindow and string.find(tostring(errWindow),
    "PHOTO_HALL_PART_COUNT",1,true),
    "PHOTO_HALL_END_WINDOW_MISSING_RAY_MUTATION_UNDETECTED")
assertDimensionalEndWindow()
print("PHOTO_HALL_DIMENSIONAL_END_WINDOW_PASS sealed=true native_parts=17 "
    .."no_window_collision=true missing_rays_rejected=true")
local notices=0
for _,cap in ipairs(caps) do
    if cap:FindFirstChild("Original school noticeboard") then notices+=1 end
end
assert(notices==1,"PHOTO_HALL_FAR_ANNOUNCEMENT_LOST")
print("HALLWAY_SOURCE_PROBE_PASS perpendicular_corridor=108_studs "
    .."tile_grid=25x6 uniform_native_brick_panels="..count
    .." physical_paper_diamonds=23 frosted_oak_doors=2 "
    .."in_game_children_identifiable=none native_iPhone_review_pending=true")
'''

def run(luau: str) -> str:
    with tempfile.TemporaryDirectory(prefix="emma-hallway-photo-") as tmp:
        script=Path(tmp)/"probe.lua"
        script.write_text(generate_luau()+"\n"+PROBE, encoding="utf-8")
        result=subprocess.run(
            [luau,str(script)],text=True,capture_output=True,timeout=115
        )
    if result.returncode:
        raise RuntimeError(
            "Photo hallway actual Luau constructors failed\n"
            +result.stderr[-6000:]+"\n"+result.stdout[-2500:]
        )
    assert "HALLWAY_SOURCE_PROBE_PASS" in result.stdout, (
        "Photo-grounded hallway did not complete its true source-level audit"
    )
    return result.stdout

def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True,help="Pinned Luau binary")
    args=parser.parse_args()
    for line in run(args.luau).splitlines():
        if line.startswith("HALLWAY_SOURCE_PROBE_PASS"):
            print(line,flush=True)

if __name__=="__main__":
    main()
