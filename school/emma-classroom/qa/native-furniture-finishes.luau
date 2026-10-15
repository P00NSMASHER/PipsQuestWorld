local root=assert(workspace:FindFirstChild("ABVMClassroomReplica"),"ROOM_MISSING")
local steel,wood=0,0
local woods={['Cabinet inset panel']=true,['Cabinet panel stile']=true,
 ['Tall cabinet recessed panel cross rail']=true,['Tall cabinet hardwood cornice']=true,
 ['Tall cabinet cornice routed lip']=true,['Built-in walnut cubby face stile']=true,
 ['Built-in walnut stile routed edge']=true,['Built-in horizontal walnut face rail']=true,
 ['Built-in horizontal fine molding']=true,['Built-in deep hardwood cornice']=true,
 ['Built-in stepped cornice edge']=true}
for _,p in ipairs(root:GetDescendants())do
 if p:IsA("BasePart") then
  if p.Material==Enum.Material.Metal and (p.Name:match('^Student chair') or p.Name=='Desk tubular leg' or p.Name=='Desk contoured base runner') then
   steel+=1
   assert(p.Reflectance>=.10 and p.Reflectance<=.20 and p.Color.R>.65,"SCHOOL_STEEL_TOO_FLAT")
  end
  if woods[p.Name] then
   wood+=1
   assert(p.Material==Enum.Material.Wood and p.Reflectance>=.03 and p.Reflectance<=.08,"CABINET_VARNISH_MISSING")
  end
 end
end
assert(steel==192 and wood==44,"FINISH_FAMILY_COUNT_CHANGED "..steel..' '..wood)
return {native=true,brushedSteelPieces=steel,varnishedJoineryPieces=wood}
