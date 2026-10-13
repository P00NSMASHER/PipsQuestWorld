-- Native regression: manufactured ceiling detail, not whole-scene acceptance.
local root=assert(workspace:FindFirstChild("ABVMClassroomReplica"),"ROOM_MISSING")
local diffusers,grids,crowns=0,0,0
local failures={}
local function check(ok,message) if not ok then table.insert(failures,message) end end
for _,p in ipairs(root:GetDescendants()) do
    if p:IsA("BasePart") then
        if p.Name=="Frosted fluorescent diffuser" then
            diffusers+=1
            local gui=p:FindFirstChild("FrostedPanelFace")
            check(gui and gui:IsA("SurfaceGui") and gui.Face==Enum.NormalId.Bottom,
                "DIFFUSER_FACE_MISSING")
            if gui then
                check(gui.LightInfluence==0 and not gui.AlwaysOnTop and gui.Brightness<=1.3,
                    "DIFFUSER_OVERLAY_OR_EXCESS_GLOW")
                local face=gui:FindFirstChild("PrismaticFrost")
                check(face and face:IsA("Frame") and face.BackgroundTransparency==0,
                    "DIFFUSER_NOT_FROSTED")
            end
            check(not p.CanCollide and p.Size.X<7 and p.Size.Z<4,"FIXTURE_OVERSIZED")
        elseif p.Name=="Ceiling grid cross" then
            grids+=1
            -- Tile centers remain -28,-16,-4,8,20; rails belong at cell edges.
            local cell=(p.Position.Z+22)/12
            check(math.abs(cell-math.round(cell))<.01,"GRID_CROSSES_TILE_CENTER")
        elseif p.Name=="Wall-to-ceiling crown molding" then
            crowns+=1
            if p.Size.Z>p.Size.X then
                check(math.abs(math.abs(p.Position.X)-36.55)<.1,"CROWN_FLOATS_INSIDE_ROOM")
            end
        end
    end
end
assert(diffusers==6 and grids==5 and crowns==4,"CEILING_LANDMARK_COUNT_CHANGED")
assert(#failures==0,table.concat(failures,","))
return {native=true,litDiffusers=diffusers,tileBoundaryRails=grids,wallMountedCrowns=crowns}
