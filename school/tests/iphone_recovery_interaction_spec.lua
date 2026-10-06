-- Real entry-point callbacks with deterministic server responses, not live service evidence.
_G.RECOVERY_BOOT_HELPER_ONLY=true
local boot=dofile('school/tests/iphone_recovery_boot_spec.lua')
_G.RECOVERY_BOOT_HELPER_ONLY=nil
local c=boot(852,393,58,true)
local root='SchoolFoundation/FreeRoam/Outfits/'
local saved, saves, requestIds=nil,0,{}
c.player.Character:FindFirstChildOfClass('Humanoid').GetAppliedDescription=function()
    -- Synthetic IDs exercise extraction only. They are never published as assets.
    return {Shirt=101,Pants=202,Face=303,HatAccessory='404,505,606,707'}
end
c:remote(root..'LoadOutfit',function(slot) return {accepted=true,status='noload',slot=slot} end)
c:remote(root..'LoadOutfitPage',function()
    return {accepted=true,outfits=saved and {{slot=3,outfit=saved}} or {}}
end)
c:remote(root..'GetFilteredNamesForOutfit',function(input)
    assert(input.OutfitName=='My look','Name input not sent to server filter')
    return {accepted=true,OutfitName=input.OutfitName}
end)
c:remote(root..'SaveOutfit',function(slot,input,requestId)
    assert(slot==3,'Wrong save slot')
    saves=saves+1; requestIds[saves]=requestId
    if saves==1 then return {accepted=false,retryable=true} end
    saved=input
    return {accepted=true,outfit=input}
end)
c:remote(root..'WearOutfit',function(slot)
    assert(slot==3,'Wrong wear slot')
    return {accepted=true,outfit=saved}
end)
c:press('RailAvatar'); c:press('Slot3')
c:find('SavedLookName').Text='My look'
c:press('SaveOutfitLabel'); c:press('SaveOutfitLabel')
assert(saves==2 and requestIds[1]==requestIds[2],'Retry must preserve save identity')
assert(saved.Shirt==101 and saved.Pants==202 and saved.Face==303,'Current clothing was not captured')
assert(saved.Hat1==404 and saved.Hat2==505 and saved.Hat3==606,'Only three current hats should be captured')
assert(saved.Hat4==nil,'Unsupported fourth hat')
assert(c:find('Slot3').Text=='My look','Saved slot name not refreshed')
c:press('WearOutfitLabel')
assert(c:find('SavedLookStatus').Text=='Saved look applied.','Wear acknowledgement not shown')
c:find('OutfitInputsMobileShell'):FindFirstChild('RecoveryClose').Activated:Fire()

-- Pending progression cannot be dismissed as completed or submitted twice by another action.
c.class.canEnter=true; c:pump(); c:press('QuickSlot1'); c:pump()
c.class.progressionPending=true; c:pump()
c:find('ClassActivityModalMobileShell'):FindFirstChild('RecoveryClose').Activated:Fire()
assert(c:find('ClassActivityModal').Visible,'Pending save was incorrectly dismissed')
c.class.progressionPending=false; c:pump()
c:find('ClassActivityModalMobileShell'):FindFirstChild('RecoveryClose').Activated:Fire()
assert(not c:find('ClassActivityModal').Visible,'Class leave failed after pending state cleared')

-- Camera replacement must rebind both viewport handling and the avatar subject.
local camera=c.instance('Camera','ReplacementCamera',c.services.Workspace)
camera.ViewportSize=c.vector(844,390)
c.services.Workspace.CurrentCamera=camera; c:pump()
assert(camera.CameraSubject==c.player.Character:FindFirstChildOfClass('Humanoid'),'Camera subject not rebound')
assert(camera.CameraType=='CameraType.Custom','Default camera behavior not restored')
assert(c:find('RobloxHighSchoolLegacyUI').Enabled,'HUD did not bind replacement camera')
print('IPHONE_RECOVERY_SAVE_RETRY_CLASS_CAMERA_PASS__STUB_ONLY')
