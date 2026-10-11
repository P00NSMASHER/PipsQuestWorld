#!/usr/bin/env python3
"""Native Roblox primitive safety audit: Ball minimum-axis size regression.

Roblox Ball Parts render a true sphere whose diameter is min(Size.X,Y,Z).
The old flattened cloud/ray Balls appeared as dots on native iPhone even
though the independent geometry renderer interpreted them as ellipsoids.
Run the real classroom Lua constructor and test physical Shape, orientation,
non-collision and negative regressions. This is not native visual acceptance.
"""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
-- Original activity rug is a 16x9 black rectangle. Its photograph shows
-- staggered colored spots, not a mechanically perfect chessboard.
local function dotcheck()
    local rug=nil
    local spots={}
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.Name=="Front teaching rug" then
                assert(rug==nil,"RUG_PHOTO_DUPLICATE_MAT")
                rug=p
            elseif p.Name=="Front rug color dot" then
                table.insert(spots,p)
            end
        end
    end
    assert(rug and #spots==25 and
        math.abs(rug.Position.X+25)<.03 and
        math.abs(rug.Position.Z+20)<.03 and
        math.abs(rug.Size.X-16)<.03 and
        math.abs(rug.Size.Z-9)<.03,
        "RUG_PHOTO_MAT_OR_COUNT_INVALID")
    local xs,zs,sizes,tones={},{},{},{}
    local stagger=0
    for i,p in ipairs(spots) do
        local x,z=p.Position.X,p.Position.Z
        local radius=p.Size.Y/2
        assert(p.Shape==Enum.PartType.Cylinder
            and p.Material==Enum.Material.Fabric
            and p.Anchored and not p.CanCollide
            and not p.CanTouch and not p.CanQuery
            and not p.CastShadow
            and math.abs(p.CFrame.m[4])>.99
            and math.abs(p.Position.Y-.632)<.03
            and p.Size.X<.035 and radius>.54 and radius<.66,
            "RUG_PHOTO_DOT_PHYSICS_INVALID")
        assert(x-radius>rug.Position.X-rug.Size.X/2+.18
            and x+radius<rug.Position.X+rug.Size.X/2-.18
            and z-radius>rug.Position.Z-rug.Size.Z/2+.18
            and z+radius<rug.Position.Z+rug.Size.Z/2-.18,
            "RUG_PHOTO_DOT_OUTSIDE_RUG")
        local nearest=math.floor((x+31)/3+.5)
        if math.abs(x-(-31+nearest*3))>.18 then stagger+=1 end
        xs[string.format("%.2f",x)]=true
        zs[string.format("%.2f",z)]=true
        sizes[string.format("%.2f",p.Size.Y)]=true
        tones[string.format("%.2f:%.2f:%.2f",p.Color.R,
            p.Color.G,p.Color.B)]=true
        for j=1,i-1 do
            local q=spots[j]
            local dx,dz=x-q.Position.X,z-q.Position.Z
            local gap=math.sqrt(dx*dx+dz*dz)-(p.Size.Y+q.Size.Y)/2
            assert(gap>.10,"RUG_PHOTO_DOT_OVERLAP")
        end
    end
    local nx,nz,ns,nt=0,0,0,0
    for _ in pairs(xs) do nx+=1 end
    for _ in pairs(zs) do nz+=1 end
    for _ in pairs(sizes) do ns+=1 end
    for _ in pairs(tones) do nt+=1 end
    assert(stagger>=15 and nx>=20 and nz>=20
        and ns>=5 and nt>=5,
        "RUG_PHOTO_REGULAR_GRID_RETURNED")
    return spots
end

local function check()
    local rays, tips, centers, lobes, labels={},{},{},{},{}
    for _,v in ipairs(Room.Root:GetDescendants()) do
        if v:IsA("BasePart") then
            if v.Name=="Photo rug sun ray" then table.insert(rays,v)
            elseif v.Name=="Photo rug sun ray rounded tip" then table.insert(tips,v)
            elseif v.Name=="Photo rug number cloud body" then table.insert(centers,v)
            elseif v.Name=="Photo rug number cloud lobe" then table.insert(lobes,v)
            elseif v.Name=="Photo rug number cloud numeral" then table.insert(labels,v)
            end
        end
    end
    assert(#rays==16 and #tips==16
        and #centers==10 and #lobes==20 and #labels==10,
        "RUG_NATIVE_PART_COUNT_INVALID")
    for _,p in ipairs(rays) do
        assert(p.Shape==Enum.PartType.Block,
            "RUG_NATIVE_FLATTENED_BALL_RAY")
        assert(p.Size.X>.75 and p.Size.Y<=.11 and p.Size.Z>.20
            and p.Size.Z<=.31,"RUG_NATIVE_RAY_DIMENSIONS_INVALID")
    end
    for _,p in ipairs(tips) do
        assert(p.Shape==Enum.PartType.Cylinder,
            "RUG_NATIVE_RAY_TIP_SHAPE_INVALID")
        assert(p.Size.X<=.11 and p.Size.Y>.20
            and math.abs(p.CFrame.m[4])>.99,
            "RUG_NATIVE_RAY_TIP_ORIENTATION_INVALID")
    end
    for _,p in ipairs(centers) do
        assert(p.Shape==Enum.PartType.Block,
            "RUG_NATIVE_CLOUD_BODY_BALL_INVALID")
        assert(p.Size.X>1.1 and p.Size.Y<.14
            and p.Size.Z>.60,"RUG_NATIVE_CLOUD_BODY_DIMENSIONS_INVALID")
    end
    for _,p in ipairs(lobes) do
        assert(p.Shape==Enum.PartType.Cylinder,
            "RUG_NATIVE_CLOUD_LOBE_BALL_INVALID")
        assert(p.Size.X<=.13 and p.Size.Y>.90 and p.Size.Z>.90
            and math.abs(p.CFrame.m[4])>.99,
            "RUG_NATIVE_CLOUD_LOBE_ORIENTATION_INVALID")
    end
    for _,p in ipairs(labels) do
        assert(p.Transparency>=.99 and p.Shape==Enum.PartType.Block
            and p.Size.Y<=.02,"RUG_NATIVE_NUMERAL_LABEL_INVALID")
        local gui=p:FindFirstChildOfClass("SurfaceGui")
        assert(gui and gui.Face==Enum.NormalId.Top,
            "RUG_NATIVE_NUMERAL_FACE_INVALID")
    end
    for _,set in ipairs({rays,tips,centers,lobes,labels}) do
        for _,p in ipairs(set) do
            assert(not p.CanCollide and not p.CanTouch,
                "RUG_NATIVE_DECORATIVE_COLLISION_INVALID")
        end
    end
    return rays,lobes
end
-- Real photo: the numbered sun-and-cloud reading rug is open floor space.
-- Exact previously rendered source showed the student chair at (-24,7.48)
-- covering its lower letters/clouds. Resolve only that pair's clearance;
-- keep all original rug coordinates and other fifteen student pairs.
local function checkReadingRugClearance()
    local mat=nil
    local seats,backs,desks,baskets={},{},{},{}
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.Name=="Alphabet rug" then
                assert(mat==nil,"RUG_CLEARANCE_MULTIPLE_ALPHABET_RUGS")
                mat=p
            elseif p.Name=="Student chair seat" then
                table.insert(seats,p)
            elseif p.Name=="Student chair contoured back collision" then
                table.insert(backs,p)
            elseif p.Name=="Student desk top" then
                table.insert(desks,p)
            elseif p.Name=="Supply basket" then
                table.insert(baskets,p)
            end
        end
    end
    assert(mat and #seats==16 and #backs==16 and #desks==16
        and #baskets==3,
        "RUG_READING_ORIGINAL_FURNITURE_COUNT_CHANGED")
    assert(math.abs(mat.Position.X+25)<.025
        and math.abs(mat.Position.Z-14)<.025
        and math.abs(mat.Size.Y-14.2)<.025,
        "RUG_READING_CARPET_ANCHOR_CHANGED")
    local radius=mat.Size.Y/2
    local function edgeDistance(part)
        local m,s=part.CFrame.m,part.Size
        local halfX=(math.abs(m[1])*s.X+math.abs(m[2])*s.Y
            +math.abs(m[3])*s.Z)/2
        local halfZ=(math.abs(m[7])*s.X+math.abs(m[8])*s.Y
            +math.abs(m[9])*s.Z)/2
        local dx=math.max(0,math.abs(part.Position.X-mat.Position.X)-halfX)
        local dz=math.max(0,math.abs(part.Position.Z-mat.Position.Z)-halfZ)
        return math.sqrt(dx*dx+dz*dz)-radius
    end
    local nearest=math.huge
    for _,family in ipairs({seats,backs,desks}) do
        for _,part in ipairs(family) do
            local gap=edgeDistance(part)
            nearest=math.min(nearest,gap)
            assert(gap>.12,"RUG_READING_FURNITURE_OCCLUDES_CLOUDS")
        end
    end
    local movedSeat,movedDesk,movedBack,movedBasket
    for _,seat in ipairs(seats) do
        if math.abs(seat.Position.X+24)<.03
            and seat.Position.Z>0 and seat.Position.Z<10 then
            movedSeat=seat
        end
    end
    for _,desk in ipairs(desks) do
        if math.abs(desk.Position.X+24)<.03
            and desk.Position.Z>0 and desk.Position.Z<10 then
            movedDesk=desk
        end
    end
    for _,back in ipairs(backs) do
        if math.abs(back.Position.X+24)<.03
            and back.Position.Z>0 and back.Position.Z<10 then
            movedBack=back
        end
    end
    for _,basket in ipairs(baskets) do
        if math.abs(basket.Position.X+24)<.03 then
            movedBasket=basket
        end
    end
    assert(movedSeat and movedDesk and movedBack and movedBasket,
        "RUG_READING_ADJUSTED_PAIR_OR_BASKET_MISSING")
    assert(math.abs(movedDesk.Position.Z-1.60)<.03
        and math.abs(movedSeat.Position.Z-5.08)<.03
        and math.abs(movedBack.Position.Z-6.01)<.04
        and math.abs(movedBasket.Position.Z-2.40)<.03
        and math.abs(movedBasket.Position.Y-3.24)<.03,
        "RUG_READING_BASKET_OR_PAIR_DISCONNECTED")
    return movedSeat,movedBasket,nearest
end
-- A different obstruction remained after the blue chair was cleared:
-- the *rolling supply cart* overlapped the round sun/cloud rug. Test
-- exact constructed scene geometry rather than only seat/chair families.
local function checkSupplyCartClearance()
    local function named(name)
        local parts={}
        for _,p in ipairs(Room.Root:GetDescendants()) do
            if p:IsA("BasePart") and p.Name==name then
                table.insert(parts,p)
            end
        end
        return parts
    end
    local function one(name)
        local hits=named(name)
        assert(#hits==1,"RUG_STORAGE_CART_PART_COUNT_INVALID "..name)
        return hits[1]
    end
    local mat=one("Alphabet rug")
    local top=one("Rolling cart top")
    local shelves=named("Rolling cart shelf")
    local wheels=named("Cart wheel")
    local rails=named("Cart vertical rail")
    local papers=one("Cart paper stack")
    local lamp=one("Reading fabric drum lampshade")
    local library=one("Reading shelf back")
    assert(#shelves==3 and #wheels==4 and #rails==4,
        "RUG_STORAGE_CART_COMPONENTS_SPLIT")
    local function halfspan(part,axis)
        local m,s=part.CFrame.m,part.Size
        local offset=(axis-1)*3
        return (math.abs(m[offset+1])*s.X
            +math.abs(m[offset+2])*s.Y
            +math.abs(m[offset+3])*s.Z)/2
    end
    local function rugGap(part)
        local hx,hz=halfspan(part,1),halfspan(part,3)
        local dx=math.max(0,math.abs(part.Position.X-mat.Position.X)-hx)
        local dz=math.max(0,math.abs(part.Position.Z-mat.Position.Z)-hz)
        return math.sqrt(dx*dx+dz*dz)-mat.Size.Y/2
    end
    local cartGap=rugGap(top)
    assert(cartGap>2.0,"RUG_STORAGE_CART_COVERS_ALPHABET")
    assert(math.abs(top.Position.X+33.6)<.025
        and math.abs(top.Position.Y-3.5)<.025
        and math.abs(top.Position.Z-23.5)<.025
        and math.abs(top.Size.X-3.2)<.025
        and math.abs(top.Size.Z-5.5)<.025
        and top.Anchored and top.CanCollide,
        "RUG_STORAGE_CART_PLACEMENT_INVALID")
    local frontZ=top.Position.Z-halfspan(top,3)
    local rearZ=top.Position.Z+halfspan(top,3)
    local leftX=top.Position.X-halfspan(top,1)
    local rightX=top.Position.X+halfspan(top,1)
    assert(leftX>-36.45 and rearZ<26.40
        and rightX<library.Position.X-library.Size.X/2-.5
        and frontZ>lamp.Position.Z+lamp.Size.Z/2+.5,
        "RUG_STORAGE_CART_CLIPS_LIBRARY_OR_LAMP")
    local levels={}
    for _,shelf in ipairs(shelves) do
        assert(math.abs(shelf.Position.X-top.Position.X)<.025
            and math.abs(shelf.Position.Z-top.Position.Z)<.025
            and math.abs(shelf.Size.X-3.0)<.025
            and math.abs(shelf.Size.Z-5.2)<.025
            and not shelf.CanCollide,
            "RUG_STORAGE_CART_COMPONENTS_SPLIT")
        assert(rugGap(shelf)>2.0,
            "RUG_STORAGE_CART_COVERS_ALPHABET")
        levels[string.format("%.1f",shelf.Position.Y)]=true
    end
    assert(levels["1.0"] and levels["2.1"] and levels["3.2"],
        "RUG_STORAGE_CART_SHELF_LEVELS_INVALID")
    local positions={}
    for _,family in ipairs({wheels,rails}) do
        for _,part in ipairs(family) do
            local dx=math.abs(part.Position.X-top.Position.X)
            local dz=math.abs(part.Position.Z-top.Position.Z)
            assert(math.abs(dx-1.2)<.03
                and math.abs(dz-2.2)<.03 and part.Anchored
                and not part.CanCollide,
                "RUG_STORAGE_CART_COMPONENTS_SPLIT")
            assert(rugGap(part)>1.8,
                "RUG_STORAGE_CART_COVERS_ALPHABET")
        end
    end
    assert(math.abs(papers.Position.X-(top.Position.X+.4))<.03
        and math.abs(papers.Position.Z-(top.Position.Z+.8))<.03
        and math.abs(papers.Position.Y-2.35)<.03
        and papers.Position.Y-papers.Size.Y/2>2.21
        and math.abs(papers.Position.X-top.Position.X)+
            papers.Size.X/2<top.Size.X/2
        and math.abs(papers.Position.Z-top.Position.Z)+
            papers.Size.Z/2<top.Size.Z/2,
        "RUG_STORAGE_CART_SUPPLIES_FLOATING")
    -- Books must be on the cart too, not left at the old (-29.8,21.7)
    -- position. The open classroom already contains many OTHER named
    -- books; bind these two by cart-relative geometry, not global counts.
    local books,pages,spines={},{},{}
    for _,item in ipairs(Room.Root:GetDescendants()) do
        if item:IsA("BasePart") then
            local x,z,y=item.Position.X,item.Position.Z,item.Position.Y
            if item.Name=="Classroom book"
                and math.abs(x-(top.Position.X-.1))<.03
                and math.abs(z-(top.Position.Z-1.0))<.04 then
                table.insert(books,item)
            elseif item.Name=="Book pages"
                and math.abs(x-(top.Position.X-.085))<.06
                and math.abs(z-(top.Position.Z-1.0))<.08
                and y>3.85 and y<4.40 then
                table.insert(pages,item)
            elseif item.Name=="Notebook spine"
                and x>top.Position.X-1.35
                and x<top.Position.X-.90
                and math.abs(z-(top.Position.Z-1.0))<.15
                and y>3.85 and y<4.40 then
                table.insert(spines,item)
            end
        end
    end
    assert(#books==2 and #pages==2 and #spines==2,
        "RUG_STORAGE_CART_BOOKS_LEFT_BEHIND")
    table.sort(books,function(a,b) return a.Position.Y<b.Position.Y end)
    assert(math.abs(books[1].Position.Y-3.82)<.03
        and math.abs(books[2].Position.Y-4.09)<.03,
        "RUG_STORAGE_CART_BOOKS_UNSUPPORTED")
    for _,item in ipairs(books) do
        assert(item.Anchored and not item.CanCollide
            and item.Position.Y-item.Size.Z/2>top.Position.Y+top.Size.Y/2
            and math.abs(item.Position.X-top.Position.X)+1.25<
                top.Size.X/2+.15
            and math.abs(item.Position.Z-top.Position.Z)+1.45<
                top.Size.Z/2+.15,
            "RUG_STORAGE_CART_BOOKS_UNSUPPORTED")
    end
    return top,wheels,papers,cartGap,books
end

-- The potted plant next to the blue ABC rug was grazing its edge.
-- Its six existing Parts are retained; only the original planted
-- object's scale changes .85 -> .65. Real photo parity is still pending.
local function checkReadingCornerPlant()
    local mat,plant=nil,nil
    local leaves={}
    for _,part in ipairs(Room.Root:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Name=="Alphabet rug" then mat=part end
            if part.Name=="Plant pot"
                and math.abs(part.Position.X+31)<.10
                and math.abs(part.Position.Z-20)<.10 then
                assert(plant==nil,"RUG_READING_DUPLICATE_PLANT")
                plant=part
            end
            if part.Name=="Plant leaf"
                and part.Position.X>-33 and part.Position.X< -29
                and part.Position.Z>18 and part.Position.Z<22
                and part.Position.Y<5 then
                table.insert(leaves,part)
            end
        end
    end
    assert(mat and plant and #leaves==5,
        "RUG_READING_PLANT_PARTS_MISSING")
    assert(math.abs(plant.Position.Y-.685)<.03
        and math.abs(plant.Size.X-1.17)<.03
        and math.abs(plant.Size.Y-1.43)<.03
        and plant.Shape==Enum.PartType.Cylinder,
        "RUG_READING_PLANT_SCALE_REGRESSION")
    local function clearance(item)
        local m,s=item.CFrame.m,item.Size
        local xhalf=(math.abs(m[1])*s.X+
            math.abs(m[2])*s.Y+math.abs(m[3])*s.Z)/2
        local zhalf=(math.abs(m[7])*s.X+
            math.abs(m[8])*s.Y+math.abs(m[9])*s.Z)/2
        local dx=math.max(0,math.abs(item.Position.X-mat.Position.X)-xhalf)
        local dz=math.max(0,math.abs(item.Position.Z-mat.Position.Z)-zhalf)
        return math.sqrt(dx*dx+dz*dz)-mat.Size.Y/2
    end
    local minimum=math.huge
    for _,part in ipairs({plant,table.unpack(leaves)}) do
        assert(part.Anchored and not part.CanCollide
            and not part.CanTouch,
            "RUG_READING_PLANT_COLLIDES")
        minimum=math.min(minimum,clearance(part))
        assert(clearance(part)>.20,
            "RUG_READING_PLANT_OVERLAPS_ABC")
    end
    return plant,leaves,minimum
end

-- The moved cart and the downsized plant are individually clear of the
-- ABC rug, but they are now adjacent. Guard their mutual clearance too.
-- The cart/plant closest pair is roughly .29 studs apart in the previous
-- real constructed RBXMX after applying these two source transforms.
-- This is conservative 2D rotated OBB geometry, not native Roblox physics.
local function checkCartPlantClearance()
    local cartParts,plantParts={},{}
    local cartNames={
        ["Rolling cart top"]=true,
        ["Rolling cart shelf"]=true,
        ["Cart wheel"]=true,
        ["Cart vertical rail"]=true,
    }
    for _,part in ipairs(Room.Root:GetDescendants()) do
        if part:IsA("BasePart") then
            local name=part.Name
            if cartNames[name] then
                table.insert(cartParts,part)
            elseif name=="Plant pot"
                and math.abs(part.Position.X+31)<.10
                and math.abs(part.Position.Z-20)<.10 then
                table.insert(plantParts,part)
            elseif name=="Plant leaf"
                and part.Position.X>-33 and part.Position.X< -29
                and part.Position.Z>18 and part.Position.Z<22
                and part.Position.Y<5 then
                table.insert(plantParts,part)
            end
        end
    end
    assert(#cartParts==12 and #plantParts==6,
        "RUG_CART_PLANT_COMPONENT_COUNTS_CHANGED")
    local function halfwidth(part,axis)
        local m,s=part.CFrame.m,part.Size
        local offset=(axis-1)*3
        return (math.abs(m[offset+1])*s.X
            +math.abs(m[offset+2])*s.Y
            +math.abs(m[offset+3])*s.Z)/2
    end
    local nearest=math.huge
    for _,cart in ipairs(cartParts) do
        for _,plant in ipairs(plantParts) do
            local gapX=math.max(0,
                math.abs(cart.Position.X-plant.Position.X)
                -halfwidth(cart,1)-halfwidth(plant,1))
            local gapZ=math.max(0,
                math.abs(cart.Position.Z-plant.Position.Z)
                -halfwidth(cart,3)-halfwidth(plant,3))
            local gap=math.sqrt(gapX*gapX+gapZ*gapZ)
            nearest=math.min(nearest,gap)
            assert(gap>.20,
                "RUG_CART_PLANT_VISUAL_INTERSECTION")
        end
    end
    return nearest,plantParts
end

local rays,lobes=check()
print("RUG_NATIVE_PRIMITIVES_PASS rays=16 caps=16 "
    .."cloud_bodies=10 flat_cylinder_lobes=20 "
    .."transparent_numbers=10 collision_free=true")
local saved=lobes[1].Shape
lobes[1].Shape=Enum.PartType.Ball
local ok,err=pcall(check)
lobes[1].Shape=saved
assert(not ok and string.find(tostring(err),
    "RUG_NATIVE_CLOUD_LOBE_BALL_INVALID",1,true),
    "RUG_NATIVE_BALL_CLOUD_NOT_REJECTED")
print("RUG_NATIVE_ADVERSARIAL_REJECTED flattened_cloud_ball")
saved=rays[1].Shape
rays[1].Shape=Enum.PartType.Ball
ok,err=pcall(check)
rays[1].Shape=saved
assert(not ok and string.find(tostring(err),
    "RUG_NATIVE_FLATTENED_BALL_RAY",1,true),
    "RUG_NATIVE_BALL_RAY_NOT_REJECTED")
local cart,wheels,paper,cartGap,cartBooks=checkSupplyCartClearance()
local plant,plantLeaves,plantGap=checkReadingCornerPlant()
print(string.format("RUG_READING_PLANT_CLEAR_PASS parts=6 "
    .."min_clearance_studs=%.2f scale=.65",plantGap))
print(string.format("RUG_STORAGE_CART_CLEAR_PASS "
    .."round_rug_clearance=%.2f studs cart_shelves=3 "
    .."wheels=4 rails=4 supplies_supported=true",cartGap))
local oldCart=cart.CFrame
cart.CFrame=CFrame.new(-29,3.5,22)
local oldCartOk,oldCartErr=pcall(checkSupplyCartClearance)
cart.CFrame=oldCart
assert(not oldCartOk and string.find(tostring(oldCartErr),
    "RUG_STORAGE_CART_COVERS_ALPHABET",1,true),
    "RUG_STORAGE_CART_OLD_CARPET_OVERLAP_NOT_REJECTED")
print("RUG_STORAGE_CART_ADVERSARIAL_REJECTED rug_intrusion")
local oldWheel=wheels[1].CFrame
wheels[1].CFrame=CFrame.new(-31.2,.45,20.8)*
    CFrame.Angles(0,0,math.pi/2)
local wheelOK,wheelErr=pcall(checkSupplyCartClearance)
wheels[1].CFrame=oldWheel
assert(not wheelOK and string.find(tostring(wheelErr),
    "RUG_STORAGE_CART_COMPONENTS_SPLIT",1,true),
    "RUG_STORAGE_CART_DETACHED_WHEEL_NOT_REJECTED")
print("RUG_STORAGE_CART_ADVERSARIAL_REJECTED detached_wheel")
local oldPaper=paper.CFrame
paper.CFrame=CFrame.new(-27.6,2.35,21.9)
local paperOK,paperErr=pcall(checkSupplyCartClearance)
paper.CFrame=oldPaper
assert(not paperOK and string.find(tostring(paperErr),
    "RUG_STORAGE_CART_SUPPLIES_FLOATING",1,true),
    "RUG_STORAGE_CART_FLOATING_PAPERS_NOT_REJECTED")
print("RUG_STORAGE_CART_ADVERSARIAL_REJECTED floating_papers")
local movedBook=cartBooks[1]
local oldBookCF=movedBook.CFrame
movedBook.CFrame=CFrame.new(-29.8,3.82,21.7)
local bookOK,bookErr=pcall(checkSupplyCartClearance)
movedBook.CFrame=oldBookCF
assert(not bookOK and string.find(tostring(bookErr),
    "RUG_STORAGE_CART_BOOKS_LEFT_BEHIND",1,true),
    "RUG_STORAGE_CART_DETACHED_BOOK_NOT_REJECTED")
print("RUG_STORAGE_CART_ADVERSARIAL_REJECTED detached_book")
local formerPotSize=plant.Size
plant.Size=Vector3.new(1.53,1.87,1.87)
local potOK,potErr=pcall(checkReadingCornerPlant)
plant.Size=formerPotSize
assert(not potOK and (string.find(tostring(potErr),
    "RUG_READING_PLANT_SCALE_REGRESSION",1,true) or
    string.find(tostring(potErr),
    "RUG_READING_PLANT_OVERLAPS_ABC",1,true)),
    "RUG_READING_OLD_OVERSIZED_PLANT_NOT_REJECTED")
print("RUG_READING_ADVERSARIAL_REJECTED oversized_plant")
checkSupplyCartClearance()
checkReadingCornerPlant()

local cartPlantGap,cartPlantPieces=checkCartPlantClearance()
print(string.format("RUG_CART_PLANT_GAP_PASS cart_parts=12 plant_parts=6 "
    .."min_clearance_studs=%.2f",cartPlantGap))
local collisionLeaf=nil
for _,item in ipairs(cartPlantPieces) do
    if item.Name=="Plant leaf" then
        collisionLeaf=item
        break
    end
end
assert(collisionLeaf,"RUG_CART_PLANT_TEST_LEAF_MISSING")
local formerLeafCF=collisionLeaf.CFrame
collisionLeaf.CFrame=CFrame.new(-32.0,2.0,20.80)
local nearOK,nearErr=pcall(checkCartPlantClearance)
collisionLeaf.CFrame=formerLeafCF
assert(not nearOK and string.find(tostring(nearErr),
    "RUG_CART_PLANT_VISUAL_INTERSECTION",1,true),
    "RUG_CART_PLANT_OVERLAP_NOT_REJECTED")
print("RUG_CART_PLANT_ADVERSARIAL_REJECTED overlapping_leaf")
checkCartPlantClearance()
local movedSeat,movedBasket,clearance=checkReadingRugClearance()
print(string.format("RUG_READING_OPEN_FLOOR_PASS student_pairs=16 "
    .."round_rug_unchanged=true nearest_clearance_studs=%.2f "
    .."one_supported_basket=true",clearance))
local spots=dotcheck()
print("RUG_PHOTO_POLKADOT_PASS dots=25 unique_spots=true "
    .."diameters=5 palette>=5 minimum_gap>.10 grid=false")
local oldSpot=spots[1].CFrame
spots[1].CFrame=spots[2].CFrame
ok,err=pcall(dotcheck)
spots[1].CFrame=oldSpot
assert(not ok and string.find(tostring(err),
    "RUG_PHOTO_DOT_OVERLAP",1,true),
    "RUG_PHOTO_OVERLAP_NOT_REJECTED")
print("RUG_NATIVE_ADVERSARIAL_REJECTED overlapping_spots")
spots[1].CFrame=CFrame.new(-34,.632,-22)*
    CFrame.Angles(0,0,math.pi/2)
ok,err=pcall(dotcheck)
spots[1].CFrame=oldSpot
assert(not ok and string.find(tostring(err),
    "RUG_PHOTO_DOT_OUTSIDE_RUG",1,true),
    "RUG_PHOTO_EDGE_MUTATION_NOT_REJECTED")
print("RUG_NATIVE_ADVERSARIAL_REJECTED outside_rug")
table.sort(spots,function(a,b)
    if math.abs(a.Position.Z-b.Position.Z)<.45 then
        return a.Position.X<b.Position.X
    end
    return a.Position.Z<b.Position.Z
end)
local frames={}
for i,p in ipairs(spots) do
    frames[i]=p.CFrame
    local row=math.floor((i-1)/5)
    local col=(i-1)%5
    p.CFrame=CFrame.new(-31+col*3,.632,-23.45+row*1.70)*
        CFrame.Angles(0,0,math.pi/2)
end
ok,err=pcall(dotcheck)
for i,p in ipairs(spots) do p.CFrame=frames[i] end
assert(not ok and string.find(tostring(err),
    "RUG_PHOTO_REGULAR_GRID_RETURNED",1,true),
    "RUG_PHOTO_GRID_REVERSION_NOT_REJECTED "..tostring(err))
print("RUG_NATIVE_ADVERSARIAL_REJECTED uniform_grid")
dotcheck()
check()
-- Fail closed on the exact old chair position that was seen covering the
-- circular rug in the owner-facing screenshot.
local oldChairCF=movedSeat.CFrame
movedSeat.CFrame=CFrame.new(-24,1.62,7.48)
local okReading,errReading=pcall(checkReadingRugClearance)
movedSeat.CFrame=oldChairCF
assert(not okReading and string.find(tostring(errReading),
    "RUG_READING_FURNITURE_OCCLUDES_CLOUDS",1,true),
    "RUG_READING_OLD_CLOUD_BLOCKING_CHAIR_NOT_REJECTED")
print("RUG_READING_ADVERSARIAL_REJECTED chair_over_clouds")
local oldBasketCF=movedBasket.CFrame
movedBasket.CFrame=CFrame.new(-24,3.24,4.8)
okReading,errReading=pcall(checkReadingRugClearance)
movedBasket.CFrame=oldBasketCF
assert(not okReading and string.find(tostring(errReading),
    "RUG_READING_BASKET_OR_PAIR_DISCONNECTED",1,true),
    "RUG_READING_UNSUPPORTED_BASKET_NOT_REJECTED")
print("RUG_READING_ADVERSARIAL_REJECTED basket_left_behind")
checkReadingRugClearance()
print("RUG_NATIVE_NEGATIVE_TESTS_PASS cloud_ball ray_ball dots_overlap edge grid reading_access")
'''
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-native-rug-") as tmp:
        path=Path(tmp)/"verify.lua"
        path.write_text(source,encoding="utf-8")
        result=subprocess.run([args.luau,str(path)],capture_output=True,
            text=True,timeout=115,check=False)
    if result.returncode:
        raise RuntimeError("Native rug construction audit failed:\n"
            +result.stderr[-3000:]+"\n"+result.stdout[-2500:])
    markers=("RUG_CART_PLANT_GAP_PASS",
             "RUG_CART_PLANT_ADVERSARIAL_REJECTED overlapping_leaf",
             "RUG_READING_PLANT_CLEAR_PASS",
             "RUG_READING_ADVERSARIAL_REJECTED oversized_plant",
             "RUG_STORAGE_CART_ADVERSARIAL_REJECTED detached_book",
             "RUG_STORAGE_CART_CLEAR_PASS",
             "RUG_STORAGE_CART_ADVERSARIAL_REJECTED rug_intrusion",
             "RUG_STORAGE_CART_ADVERSARIAL_REJECTED detached_wheel",
             "RUG_STORAGE_CART_ADVERSARIAL_REJECTED floating_papers",
             "RUG_READING_OPEN_FLOOR_PASS",
             "RUG_READING_ADVERSARIAL_REJECTED chair_over_clouds",
             "RUG_READING_ADVERSARIAL_REJECTED basket_left_behind",
             "RUG_NATIVE_PRIMITIVES_PASS",
             "RUG_NATIVE_ADVERSARIAL_REJECTED flattened_cloud_ball",
             "RUG_PHOTO_POLKADOT_PASS",
             "RUG_NATIVE_ADVERSARIAL_REJECTED overlapping_spots",
             "RUG_NATIVE_ADVERSARIAL_REJECTED outside_rug",
             "RUG_NATIVE_ADVERSARIAL_REJECTED uniform_grid",
             "RUG_NATIVE_NEGATIVE_TESTS_PASS cloud_ball ray_ball dots_overlap edge grid reading_access")
    lines=result.stdout.splitlines()
    for marker in markers:
        assert any(x.startswith(marker) for x in lines), marker
    for line in lines:
        if line.startswith(("RUG_CART_PLANT_GAP_PASS",
                            "RUG_CART_PLANT_ADVERSARIAL_REJECTED",
                            "RUG_READING_PLANT_CLEAR_PASS",
                            "RUG_READING_ADVERSARIAL_REJECTED",
                            "RUG_STORAGE_CART_CLEAR_PASS",
                            "RUG_STORAGE_CART_ADVERSARIAL_REJECTED",
                            "RUG_READING_OPEN_FLOOR_PASS",
                            "RUG_READING_ADVERSARIAL_REJECTED",
                            "RUG_PHOTO_POLKADOT_PASS",
                            "RUG_NATIVE_PRIMITIVES_PASS",
                            "RUG_NATIVE_ADVERSARIAL_REJECTED",
                            "RUG_NATIVE_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
