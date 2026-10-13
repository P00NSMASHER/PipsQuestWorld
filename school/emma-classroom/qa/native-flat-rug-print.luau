-- Native proof that the sun/cloud carpet reads as printed textile, not raised foam.
local root=assert(workspace:FindFirstChild("ABVMClassroomReplica"),"ROOM_MISSING")
local rug=assert(root:FindFirstChild("Alphabet rug"),"RUG_MISSING")
local top=rug.Position.Y+rug.Size.X/2
local names={['Photo rug sun center']=1,['Photo rug sun ray']=16,
 ['Photo rug sun ray rounded tip']=16,['Photo rug number cloud body']=10,
 ['Photo rug number cloud lobe']=20,['Photo rug number cloud numeral']=10}
local counts={};local tallest=0
for _,p in ipairs(root:GetDescendants()) do
 if p:IsA("BasePart") and names[p.Name] then
  local cf=p.CFrame
  local half=(math.abs(cf.RightVector.Y)*p.Size.X+math.abs(cf.UpVector.Y)*p.Size.Y+math.abs(cf.LookVector.Y)*p.Size.Z)/2
  tallest=math.max(tallest,p.Position.Y+half-top)
  assert(p.Position.Y-half>top+.004,"RUG_ART_BURIED")
  assert(p.Position.Y+half-top<=.061,"RUG_ART_RAISED_LIKE_FOAM "..p.Name)
  assert(not p.CanCollide,"RUG_ART_BLOCKS_MOVEMENT")
  counts[p.Name]=(counts[p.Name] or 0)+1
 end
end
for name,n in pairs(names)do assert(counts[name]==n,"RUG_ART_MISSING "..name)end
return {native=true,flatPrintedArtwork=true,maxReliefStuds=tallest,counts=counts}
