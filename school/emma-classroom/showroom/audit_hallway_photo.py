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
assert(floor.CanCollide and floor.Material==Enum.Material.SmoothPlastic
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
assert(rear.CanCollide and near(rear.Position.Z,49.25)
    and rear.Size.X>=108,"PHOTO_HALL_SKY_GAP")
local caps=expect("Photo hall end cap",2)
for _,wall in ipairs(caps) do
    assert(wall.CanCollide and math.abs(wall.Position.X)>=53.9,
        "PHOTO_HALL_END_SKY_GAP")
end
local south=expect("Side corridor end wall",1)[1]
assert(near(south.Position.Z,5.65) and south.CanCollide,
    "LEFT_STAFF_CORRIDOR_SOUTH_CAP_LOST")
local returnWall=one("Left hallway outside corner return")
assert(returnWall.CanCollide and returnWall.Position.X>53.8
    and returnWall.Position.Z>25.5,"LEFT_HALL_CORNER_EXTERIOR_GAP")
assert(#pieces("Photo hall front outer wall")==1
    and near(one("Photo hall front outer wall").Position.X,-45.5),
    "LEFT_HALL_PASSAGE_HAS_BLOCKING_REAR_WALL")
assert(#pieces("Rear corridor end wall")==0 and
       #pieces("Hall left wall")==0,
       "OLD_DEAD_END_HALLWAY_RETURNED")
expect("Open classroom door",2)
-- Fix the real remaining yellow wall sliver seen by the source hall camera.
-- Check constructed geometry, not just a literal comment in Room.lua.
local function checkExteriorStaffReturn()
    local upper=expect("Photo hall classroom exterior blue-gray paint",2)
    for _,p in ipairs(upper) do
        assert(near(p.Size.Y,13.5) and near(p.Position.Y,11.25)
            and p.Material==Enum.Material.SmoothPlastic
            and not p.CanCollide and not p.CanQuery,
            "HALL_UPPER_REAR_CLASSROOM_YELLOW_BAND_RETURNED")
    end
    local wall=one("Right wall back")
    assert(wall.CanCollide and near(wall.Position.X,37)
        and near(wall.Position.Z,25),
        "HALL_STAFF_RETURN_ORIGINAL_SHELL_LOST")
    local finish=one("Photo hall staff return blue-gray plaster")
    local brick=one("Photo hall staff return glazed brick")
    local cap=one("Photo hall staff return oak cap")
    assert(near(finish.Position.X,37.56)
        and near(finish.Position.Y,9)
        and near(finish.Size.Y,18)
        and finish.Color.B > finish.Color.R
        and not finish.CanCollide and not finish.CanQuery,
        "HALL_STAFF_RETURN_PLASTER_NOT_FACING_CORRIDOR")
    assert(near(brick.Position.X,37.65)
        and near(brick.Position.Y,2.125)
        and near(brick.Size.Y,4.25)
        and brick.Material==Enum.Material.Brick
        and not brick.CanCollide and not brick.CanQuery,
        "HALL_STAFF_RETURN_BRICK_MISSING_OR_BLOCKING")
    assert(near(cap.Position.Y,4.34)
        and cap.Material==Enum.Material.Wood
        and not cap.CanCollide and not cap.CanQuery,
        "HALL_STAFF_RETURN_OAK_CAP_MISSING_OR_BLOCKING")
    return upper,finish,brick,cap
end
local upperReturn,plasterReturn,brickReturn,capReturn=checkExteriorStaffReturn()
local oldUpperY=upperReturn[1].Size
upperReturn[1].Size=Vector3.new(28,8.6,.09)
local accepted,reason=pcall(checkExteriorStaffReturn)
upperReturn[1].Size=oldUpperY
assert(not accepted and string.find(tostring(reason),
    "HALL_UPPER_REAR_CLASSROOM_YELLOW_BAND_RETURNED",1,true),
    "HALL_UPPER_YELLOW_BAND_MUTATION_FALSELY_ACCEPTED")
local oldPlaster=plasterReturn.Color
plasterReturn.Color=Color3.fromRGB(246,232,165)
accepted,reason=pcall(checkExteriorStaffReturn)
plasterReturn.Color=oldPlaster
assert(not accepted and string.find(tostring(reason),
    "HALL_STAFF_RETURN_PLASTER_NOT_FACING_CORRIDOR",1,true),
    "HALL_STAFF_RETURN_YELLOW_PAINT_FALSELY_ACCEPTED")
local oldBrickCollision=brickReturn.CanCollide
brickReturn.CanCollide=true
accepted,reason=pcall(checkExteriorStaffReturn)
brickReturn.CanCollide=oldBrickCollision
assert(not accepted and string.find(tostring(reason),
    "HALL_STAFF_RETURN_BRICK_MISSING_OR_BLOCKING",1,true),
    "HALL_STAFF_RETURN_COLLIDING_DADO_FALSELY_ACCEPTED")
local oldCapName=capReturn.Name
capReturn.Name="test removed return cap"
accepted,reason=pcall(checkExteriorStaffReturn)
capReturn.Name=oldCapName
assert(not accepted and string.find(tostring(reason),
    "PHOTO_HALL_PART_COUNT",1,true),
    "HALL_STAFF_RETURN_CAP_MISSING_FALSELY_ACCEPTED")
checkExteriorStaffReturn()
print("HALL_STAFF_RETURN_FINISH_SOURCE_PASS "
    .."two_upper_rear_plaster_panels_extended=true "
    .."blue_gray_side_return=true original_shell_collidable=true "
    .."three_noncolliding_parts=true corridor_brick_dado_and_oak_cap=true "
    .."four_adversarial_mutations_rejected=true")

-- The earlier flat rear paint panels cannot cover the PERPENDICULAR
-- yellow x-facing return at either edge of the old double-door jamb.
-- Validate all six constructed finish parts and retain original walls.
local function checkDoorwayEndFinishes()
    local plaster=expect("Photo hall doorway inner wall end plaster",2)
    local bricks=expect("Photo hall doorway inner wall end brick",2)
    local caps=expect("Photo hall doorway inner wall end oak cap",2)
    table.sort(plaster,function(a,b)return a.Position.X<b.Position.X end)
    table.sort(bricks,function(a,b)return a.Position.X<b.Position.X end)
    table.sort(caps,function(a,b)return a.Position.X<b.Position.X end)
    for i,side in ipairs({-1,1}) do
        local base=one(side<0 and "Back wall left" or "Back wall right")
        assert(base.CanCollide and near(base.Position.X,side*23)
            and near(base.Position.Z,27)
            and near(base.Size.Y,18),
            "HALL_ORIGINAL_CLASSROOM_REAR_WALL_LOST")
        local endX=side*8.445
        local upper=plaster[i]
        local lower=bricks[i]
        local cap=caps[i]
        assert(near(upper.Position.X,endX)
            and near(upper.Position.Z,27)
            and near(upper.Size.Y,18)
            and near(upper.Size.Z,1.12)
            and upper.Color.B>upper.Color.R
            and upper.Material==Enum.Material.SmoothPlastic
            and not upper.CanCollide and not upper.CanQuery,
            "HALL_DOOR_END_YELLOW_RETURN_REINTRODUCED")
        assert(near(lower.Position.X,endX-side*.04)
            and near(lower.Position.Y,2.125)
            and near(lower.Size.Y,4.25)
            and lower.Material==Enum.Material.Brick
            and not lower.CanCollide and not lower.CanQuery,
            "HALL_DOOR_END_BRICK_REGRESSED")
        assert(near(cap.Position.X,endX-side*.06)
            and near(cap.Position.Y,4.34)
            and cap.Material==Enum.Material.Wood
            and not cap.CanCollide and not cap.CanQuery,
            "HALL_DOOR_END_OAK_CAP_MISSING")
    end
    local allParts=0
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") then allParts+=1 end
    end
    assert(allParts<=3050,"HALL_DOOR_END_EXCEEDED_RESERVED_PART_HEADROOM")
    return plaster,bricks,caps,allParts
end
local endPlaster,endBricks,endCaps,endParts=checkDoorwayEndFinishes()
local oldEdgeColor=endPlaster[2].Color
endPlaster[2].Color=Color3.fromRGB(246,232,165)
local okEnd,errEnd=pcall(checkDoorwayEndFinishes)
endPlaster[2].Color=oldEdgeColor
assert(not okEnd and string.find(tostring(errEnd),
    "HALL_DOOR_END_YELLOW_RETURN_REINTRODUCED",1,true),
    "HALL_DOOR_END_YELLOW_MUTATION_FALSE_ACCEPT")
local oldBrickCollide=endBricks[1].CanCollide
endBricks[1].CanCollide=true
okEnd,errEnd=pcall(checkDoorwayEndFinishes)
endBricks[1].CanCollide=oldBrickCollide
assert(not okEnd and string.find(tostring(errEnd),
    "HALL_DOOR_END_BRICK_REGRESSED",1,true),
    "HALL_DOOR_END_BRICK_COLLIDER_MUTATION_FALSE_ACCEPT")
local oldCapName=endCaps[1].Name
endCaps[1].Name="test: remove jamb cap"
okEnd,errEnd=pcall(checkDoorwayEndFinishes)
endCaps[1].Name=oldCapName
assert(not okEnd and string.find(tostring(errEnd),
    "PHOTO_HALL_PART_COUNT",1,true),
    "HALL_DOOR_END_CAP_MISSING_MUTATION_FALSE_ACCEPT")
local oldEndPos=endPlaster[1].Position
endPlaster[1].Position=Vector3.new(-7.70,9,27)
okEnd,errEnd=pcall(checkDoorwayEndFinishes)
endPlaster[1].Position=oldEndPos
assert(not okEnd and string.find(tostring(errEnd),
    "HALL_DOOR_END_YELLOW_RETURN_REINTRODUCED",1,true),
    "HALL_DOOR_END_MISPLACED_MUTATION_FALSE_ACCEPT")
checkDoorwayEndFinishes()
print("HALL_DOOR_END_SOURCE_PASS two_full_height_blue_gray_returns=true "
    .."ochre_dado_and_oak_cap_both_edges=true "
    .."original_two_collidable_rear_walls=true "
    .."no_added_colliders=true part_count="..endParts
    .." yellow,brick_collision,trim_and_position_mutations_rejected=true")
-- Source-built proof: the wide yellow panels alongside the back double
-- doors were the ORIGINAL x=+/-7.25 plaster infill, not the already fixed
-- narrow x-facing wall ends. Ensure z-facing paint, brick, and oak reach
-- the true opening without changing classroom-facing originals or colliders.
local function checkHallwayBackDoorInfill()
    local originals=expect("Back doorway plaster infill",2)
    table.sort(originals,function(a,b)return a.Position.X<b.Position.X end)
    for i,sgn in ipairs({-1,1}) do
        local p=originals[i]
        assert(p.CanCollide and near(p.Position.X,sgn*7.25)
            and near(p.Position.Z,27) and near(p.Size.X,3.5)
            and p.Color.R>.94 and p.Color.G>.85 and p.Color.B<.70,
            "HALL_CLASSROOM_WARM_INFILL_ORIGINAL_LOST")
    end
    local baseHeader=one("Door header wall")
    assert(baseHeader.CanCollide and near(baseHeader.Position.Y,15.5)
        and baseHeader.Color.R>.94 and baseHeader.Color.G>.85,
        "HALL_CLASSROOM_WARM_HEADER_ORIGINAL_LOST")
    local paint=expect("Photo hall classroom exterior blue-gray paint",2)
    local brick=expect("Photo hall classroom exterior glazed brick",2)
    local caps=expect("Photo hall front dado cap",2)
    table.sort(paint,function(a,b)return a.Position.X<b.Position.X end)
    table.sort(brick,function(a,b)return a.Position.X<b.Position.X end)
    table.sort(caps,function(a,b)return a.Position.X<b.Position.X end)
    for i,sgn in ipairs({-1,1}) do
        local p=paint[i]
        assert(near(p.Position.X,sgn*21.25)
            and near(p.Position.Y,11.125)
            and near(p.Size.X,31.50) and near(p.Size.Y,13.75)
            and near(p.Position.Z,27.565)
            and p.Color.B>p.Color.R
            and not p.CanCollide and not p.CanQuery,
            "HALL_INFILL_OLD_SHORT_PLASTER")
        local b=brick[i]
        assert(near(b.Position.X,sgn*21.25)
            and near(b.Size.X,31.35) and near(b.Position.Y,2.125)
            and not b.CanCollide and not b.CanQuery,
            "HALL_INFILL_OLD_SHORT_BRICK")
    end
    assert(caps[1].Position.X+caps[1].Size.X/2 < -5.5
        and caps[2].Position.X-caps[2].Size.X/2 > 5.5
        and not caps[1].CanCollide and not caps[2].CanCollide,
        "HALL_CAP_BLOCKS_CLASSROOM_DOORWAY")
    assert(near(caps[1].Position.X,-29.65)
        and near(caps[1].Size.X,48.20)
        and near(caps[2].Position.X,21.05)
        and near(caps[2].Size.X,30.90),
        "HALL_INFILL_OLD_SHORT_OAK_CAP")
    local header=one("Photo hall rear doorway header exterior blue-gray paint")
    assert(near(header.Position.X,0) and near(header.Position.Y,15.5)
        and near(header.Position.Z,27.565)
        and near(header.Size.X,18) and near(header.Size.Y,5)
        and header.Color.B>header.Color.R
        and not header.CanCollide and not header.CanQuery,
        "HALL_INFILL_HEADER_YELLOW_OR_COLLIDING")
    local parts=0
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") then parts+=1 end
    end
    assert(parts<=3050,"HALL_INFILL_MOBILE_HEADROOM_LOST")
    return originals,paint,brick,caps,header,parts
end
local infillBase,infillPaint,infillBrick,infillCaps,infillHeader,partCount=
    checkHallwayBackDoorInfill()
local function rejectInfillMutation(change,restore,expectedName)
    change()
    local ok,err=pcall(checkHallwayBackDoorInfill)
    restore()
    assert(not ok and string.find(tostring(err),expectedName,1,true),
        "HALL_INFILL_MUTATION_FALSE_ACCEPT "..expectedName..": "..tostring(err))
end
local oldPaintSize=infillPaint[2].Size
rejectInfillMutation(
    function() infillPaint[2].Size=Vector3.new(28,13.75,.09) end,
    function() infillPaint[2].Size=oldPaintSize end,
    "HALL_INFILL_OLD_SHORT_PLASTER")
local oldBrickSize=infillBrick[1].Size
rejectInfillMutation(
    function() infillBrick[1].Size=Vector3.new(27.85,4.25,.075) end,
    function() infillBrick[1].Size=oldBrickSize end,
    "HALL_INFILL_OLD_SHORT_BRICK")
local oldCapSize=infillCaps[2].Size
rejectInfillMutation(
    function() infillCaps[2].Size=Vector3.new(42,.16,.14) end,
    function() infillCaps[2].Size=oldCapSize end,
    "HALL_CAP_BLOCKS_CLASSROOM_DOORWAY")
local oldHeaderCollision=infillHeader.CanCollide
rejectInfillMutation(
    function() infillHeader.CanCollide=true end,
    function() infillHeader.CanCollide=oldHeaderCollision end,
    "HALL_INFILL_HEADER_YELLOW_OR_COLLIDING")
local oldInfillColor=infillBase[1].Color
rejectInfillMutation(
    function() infillBase[1].Color=Color3.fromRGB(107,117,125) end,
    function() infillBase[1].Color=oldInfillColor end,
    "HALL_CLASSROOM_WARM_INFILL_ORIGINAL_LOST")
checkHallwayBackDoorInfill()
print("HALL_DOUBLE_DOOR_INFILL_EXTERIOR_PASS "
    .."warm_original_walls_and_header_preserved=true "
    .."existing_two_plaster_two_brick_two_oak_spans_extended=true "
    .."one_noncolliding_header_overlay=true "
    .."five_adversarial_mutations_rejected=true "
    .."physical_part_count="..partCount)
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
            and math.abs(glass.Position.X-lower.Position.X)<.05
            and glass.Position.Z>lower.Position.Z
            and glass.Position.Y-glass.Size.Y/2
                >lower.Position.Y+lower.Size.Y/2
            and glass:GetAttribute("GlassAperture")
                =="Upper opening has no solid wood backing",
            "PHOTO_HALL_ADJACENT_GLASS_APERTURE_LOST")
        local wall=lower.Position.X<0 and sealed[1] or classroomRear
        assert(wall.CanCollide and wall.Size.Y>=12.9
            and math.abs(wall.Position.X-lower.Position.X)<.1
            and wall.Position.Z<lower.Position.Z,
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
assert(near(facades[1].Position.X,-45.5)
    and near(facades[2].Position.X,23),
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
    expect("Supply closet oak shelf",3)
    local tubs=expect("Supply closet labeled storage tub",3)
    for _,tub in ipairs(tubs) do
        assert(not tub.CanCollide and
            tub:FindFirstChild("Anonymous classroom supply category"),
            "RIGHT_CLOSET_STORAGE_PROPS_MISSING_OR_BLOCKING")
    end
    expect("Supply closet warm laminate floor",1)
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
print("LEFT_HALL_RIGHT_CLOSET_PHYSICAL_PASS staff_left_open=true "
    .."school_hall_connected=true back_double_doors_are_supply_closet=true "
    .."closet_walls=3 shelves=3 rear_wall_mutation_rejected=true")

-- Source-rendered camera 22 revealed the genuine gameplay problem: the
-- solid closet's beige unpainted exterior projected as an enormous box
-- into the photographed blue-gray/ochre corridor. This audit verifies
-- the REAL room constructor now finishes all exposed faces without hiding
-- the actual closet, weakening its seals or making decorative skins solid.
local function sameColor(actual,want)
    return math.abs(actual.R-want.R)<.015
       and math.abs(actual.G-want.G)<.015
       and math.abs(actual.B-want.B)<.015
end
local function checkClosetHallFinishes()
    local exterior=Color3.fromRGB(107,117,125)
    local cream=Color3.fromRGB(233,220,178)
    local amber=Color3.fromRGB(192,132,63)
    local baseSides=expect("Supply closet side wall",2)
    local baseRear=one("Supply closet solid rear wall")
    for _,p in ipairs(baseSides) do
        assert(p.CanCollide and sameColor(p.Color,exterior)
            and p.Material==Enum.Material.SmoothPlastic,
            "SUPPLY_CLOSET_EXTERIOR_CREAM_WALL_REINTRODUCED")
    end
    assert(baseRear.CanCollide and sameColor(baseRear.Color,exterior),
        "SUPPLY_CLOSET_EXTERIOR_CREAM_WALL_REINTRODUCED")

    local inside=expect("Supply closet interior warm plaster",3)
    table.sort(inside,function(a,b)return a.Position.X<b.Position.X end)
    assert(near(inside[1].Position.X,-5.575)
        and near(inside[2].Position.X,0)
        and near(inside[3].Position.X,5.575)
        and near(inside[2].Position.Z,35.645),
        "SUPPLY_CLOSET_INTERIOR_PLASTER_MISSING")
    for _,p in ipairs(inside) do
        assert(sameColor(p.Color,cream)
            and p.Material==Enum.Material.SmoothPlastic
            and not p.CanCollide and not p.CanQuery and not p.CanTouch,
            "SUPPLY_CLOSET_INTERIOR_PLASTER_MISSING_OR_BLOCKING")
    end

    local dado=expect("Supply closet exterior glazed-brick dado",3)
    table.sort(dado,function(a,b)return a.Position.X<b.Position.X end)
    assert(near(dado[1].Position.X,-6.345)
        and near(dado[2].Position.X,0)
        and near(dado[3].Position.X,6.345)
        and near(dado[2].Position.Z,36.455),
        "SUPPLY_CLOSET_DADO_NOT_FACING_REAL_HALL")
    for _,p in ipairs(dado) do
        assert(sameColor(p.Color,amber)
            and p.Material==Enum.Material.Brick
            and near(p.Size.Y,4.26)
            and not p.CanCollide and not p.CanQuery and not p.CanTouch,
            "SUPPLY_CLOSET_FINISH_COLLIDER_OR_WRONG_BRICK")
    end

    local trim=expect("Supply closet exterior oak cap rail",3)
    for _,p in ipairs(trim) do
        assert(p.Material==Enum.Material.Wood
            and near(p.Position.Y,4.35)
            and not p.CanCollide and not p.CanQuery and not p.CanTouch,
            "SUPPLY_CLOSET_EXTERIOR_CAP_RAIL_LOST")
    end
    local parts=0
    for _,obj in ipairs(Room.Root:GetDescendants()) do
        if obj:IsA("BasePart") then parts+=1 end
    end
    assert(parts<=3050,"SUPPLY_CLOSET_FINISH_MOBILE_BUDGET_REGRESSED")
    return baseRear,inside,dado,trim,parts
end

local extBack,insideFinish,brickFinish,capFinish,finishedCount=
    checkClosetHallFinishes()
local oldExtColor=extBack.Color
extBack.Color=Color3.fromRGB(233,220,178)
local okFinish,errFinish=pcall(checkClosetHallFinishes)
extBack.Color=oldExtColor
assert(not okFinish and string.find(tostring(errFinish),
    "SUPPLY_CLOSET_EXTERIOR_CREAM_WALL_REINTRODUCED",1,true),
    "CLOSET_OLD_BEIGE_EXTERIOR_FALSELY_ACCEPTED")

local oldBrickCollider=brickFinish[1].CanCollide
brickFinish[1].CanCollide=true
okFinish,errFinish=pcall(checkClosetHallFinishes)
brickFinish[1].CanCollide=oldBrickCollider
assert(not okFinish and string.find(tostring(errFinish),
    "SUPPLY_CLOSET_FINISH_COLLIDER_OR_WRONG_BRICK",1,true),
    "CLOSET_BRICK_WALKWAY_COLLIDER_FALSELY_ACCEPTED")

local oldInsideX=insideFinish[1].Position
insideFinish[1].Position=Vector3.new(-4.70,6.5,31.70)
okFinish,errFinish=pcall(checkClosetHallFinishes)
insideFinish[1].Position=oldInsideX
assert(not okFinish and string.find(tostring(errFinish),
    "SUPPLY_CLOSET_INTERIOR_PLASTER_MISSING",1,true),
    "CLOSET_WARM_INTERIOR_FALSELY_ACCEPTED")

local oldCapName=capFinish[1].Name
capFinish[1].Name="test-only removed exterior oak cap"
okFinish,errFinish=pcall(checkClosetHallFinishes)
capFinish[1].Name=oldCapName
assert(not okFinish and string.find(tostring(errFinish),
    "PHOTO_HALL_PART_COUNT",1,true),
    "CLOSET_CAP_MISSING_FALSELY_ACCEPTED")
checkClosetHallFinishes()
print("CLOSET_HALL_EXTERIOR_FINISH_SOURCE_PASS exterior_blue_gray=true "
    .."ochre_native_brick_dado=3 oak_caps=3 "
    .."interior_warm_plaster=3 original_three_closure_walls=true "
    .."nine_new_decorative_parts=true part_count="..finishedCount
    .." occlusion_color_and_collision_mutations_rejected=true "
    .."native_iphone_review_still_required=true")
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
    {"Photo hall right end glazed brick",1},
}
local count=0
for _,s in ipairs(segments) do
    for _,wall in ipairs(expect(s[1],s[2])) do
        assert(not wall.CanCollide and wall.Material==Enum.Material.SmoothPlastic,
            "PHOTO_HALL_BRICK_BECAME_PHYSICAL_COLLIDER")
        -- If SurfaceGuis are hidden by an independent renderer or device
        -- LOD, the shell should be warm gold, NOT dark-brown mortar.
        assert(wall.Color.R>.70 and wall.Color.G>.45 and
            wall.Color.B>.18 and wall.Color.B<.34
            and wall.Reflectance>.04,
            "PHOTO_HALL_GOLDEN_BRICK_FALLBACK_LOST")
        local g=wall:FindFirstChild("Photo glazed offset brick bond")
        assert(g and g:IsA("SurfaceGui"),
            "PHOTO_HALL_BRICK_GUI_MISSING")
        local field=g:FindFirstChild("Warm mortar field")
        assert(field and field.ClipsDescendants,
            "PHOTO_HALL_MORTAR_MISSING")
        local tiles=0
        for _,c in ipairs(field:GetChildren()) do
            if c.Name=="Photo glazed brick" then tiles+=1 end
        end
        assert(tiles>=18,"PHOTO_HALL_BRICK_PATTERN_INCOMPLETE")
        count+=tiles
    end
end
assert(count>=300,"PHOTO_HALL_BRICK_DETAIL_TOO_SPARSE "..count)
expect("Photo hall rear dado cap",1)
expect("Photo hall front dado cap",2)
expect("Photo hall student work hanging rail",1)
-- The six photographs show real white paper hanging as diagonals.
-- Previous UI-only paper rendered as a completely bare wall in the
-- original camera captures. Require 23 dimensional NONCOLLIDING Parts.
local sheets=expect("Photo hall anonymous diamond student display",23)
table.sort(sheets,function(a,b)return a.Position.X<b.Position.X end)
local function checkSheets()
    for i,p in ipairs(sheets) do
        local m=p.CFrame.m
        assert(math.abs(p.Position.X-((i-12)*3.55))<.045
            and near(p.Position.Y,9.05) and near(p.Position.Z,48.52),
            "PHOTO_HALL_PAPER_POSITION_OR_SPACING_INVALID")
        assert(math.abs(m[1]-.7071068)<.04
            and math.abs(m[2]+.7071068)<.04
            and math.abs(m[4]-.7071068)<.04
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
        assert(style==((i-1)%5)+1,
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
bad.CFrame=CFrame.new(-39.05,9.05,48.52)
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
local leftCap=caps[1].Position.X<0 and caps[1] or caps[2]
assert(leftCap and leftCap.Position.X<0,"PHOTO_HALL_LEFT_ENDCAP_NOT_FOUND")
local function assertDimensionalEndWindow()
    local glazing=one("Photo hall yellow window glazing")
    assert(not glazing.CanCollide and not glazing.CanQuery
        and glazing.Material==Enum.Material.Glass
        and near(glazing.Size.Y,8.32) and near(glazing.Size.Z,14.68)
        and glazing.Transparency>0 and glazing.Transparency<.35
        and glazing.Position.X>leftCap.Position.X+.45
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
            and math.abs(ray.Position.Z-38)<=1.05
            and ray.Position.X>leftCap.Position.X+.45,
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
print("HALLWAY_SOURCE_PROBE_PASS rear_corridor=108_studs "
    .."tile_grid=25x6 bond_tiles="..count
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
