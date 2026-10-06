local Stub = dofile('school/tests/support/roblox_client_stub.lua')
local function boot(width,height,inset,touch)
    local c=Stub.new(width,height,inset,touch)
    c.class={academic=true,canEnter=false,active=false,roomDisplayName='Math',classKey='test-class'}
    local root='SchoolFoundation/'
    c:remote(root..'StateSnapshot',{schoolDay=1,periodIndex=2,periodLabel='Math',secondsRemaining=100})
    c:remote(root..'RequestTravel',{accepted=true})
    c:remote(root..'ClassEducation/GetClassState',function() return c.class end)
    c:remote(root..'ClassEducation/GetProgressionState',{available=true,state={totalPoints=10}})
    c:remote(root..'ClassEducation/EnterClass',function()
        c.class.active=true
        return {accepted=true,classKey='test-class',activity={id='activity-test',subject='Math',prompt='Two plus two?',choices={'3','4','5','6'}}}
    end)
    c:remote(root..'ClassEducation/LeaveClass',function()
        c.class.active=false
        return {accepted=true,returnToFreeRoam=true}
    end)
    c:remote(root..'ClassEducation/SubmitAnswer',{accepted=true,progressionCommitted=true,progressionState={totalPoints=20}})
    for _,name in ipairs({'LoadOutfit','LoadOutfitPage','GetFilteredNamesForOutfit','WearOutfit','SaveOutfit'}) do
        c:remote(root..'FreeRoam/Outfits/'..name,{accepted=false,code='test-only'})
    end
    c:remote(root..'FreeRoam/PurchasePermanentItem',{accepted=false,code='unknown_item'})
    for _,name in ipairs({'GetState','StartShift','CompleteTask','LeaveShift'}) do
        c:remote(root..'FreeRoam/CafeJob/'..name,{accepted=false,active=false,atCafe=false})
    end
    for _,name in ipairs({'GetState','Spawn','Despawn','SetControls'}) do
        c:remote(root..'FreeRoam/Vehicles/'..name,{accepted=false,active=false,atAutoShop=false})
    end
    for _,name in ipairs({'GetState','BuyHouse','TeleportToHouse','SetEditMode','SetStyle','GetEditorState','PurchaseFurniture','PlaceFurniture','MoveFurniture','RotateFurniture','RemoveFurniture','SellFurniture','PaintFurniture','SetHideWalls'}) do
        c:remote(root..'FreeRoam/Housing/'..name,{accepted=false,available=true,owned=false,balance=0,price=50})
    end
    c:load('school/src/client/CanonicalSchoolClient.client.lua')
    c:pump(); c:pump()
    assert(c:find('RobloxHighSchoolLegacyUI'):GetAttribute('ClientMounted')==true,'Client bootstrap did not finish')
    return c
end

if _G.RECOVERY_BOOT_HELPER_ONLY then return boot end

for _,fixture in ipairs({{852,393,12},{852,393,36},{852,393,58},{844,390,58},{872,402,58},{1024,768,58}}) do
    local c=boot(table.unpack(fixture))
    assert(#c.warnings==0,table.concat(c.warnings,'; '))
    local gui=c:find('RobloxHighSchoolLegacyUI')
    assert(gui.Enabled,'HUD must be visible after valid landscape bootstrap')
    assert(c:find('CompactSchoolStatus').Size.X.Offset==210,'Phone status remains unreadably small')
    local periodFound=false
    for _,child in ipairs(c:find('CompactSchoolStatus'):GetChildren()) do
        if child.Text=='Math' then periodFound=true; assert(child.TextSize>=14,'Tiny period text') end
    end
    assert(periodFound,'Class state did not reach readable HUD')
    assert(c:find('RHS2ActionRail').Position.X.Offset>600,'Rail stacked at origin')
    for _,name in ipairs({'RailShop','RailTravel','RailAvatar','LegacyHouseButton'}) do
        c:press(name)
        local visible=0
        for _,item in ipairs(gui:GetDescendants()) do
            if item.Name:match('MobileShell$') and item.Visible then
                visible=visible+1
                assert(item:FindFirstChild('RecoveryClose').Size.X.Offset>=44,'Close touch target too small')
                local x,y=item.Position.X.Offset,item.Position.Y.Offset
                local w,h=item.Size.X.Offset,item.Size.Y.Offset
                assert(x>=47 and x+w<=fixture[1]-47,'Mobile shell outside horizontal safe area')
                assert(y>=fixture[3] and y+h<=fixture[2]-21,'Mobile shell outside vertical safe area')
                local model=c.env.require(c.shared:FindFirstChild('ResponsiveHudLayout'))
                for _,zone in ipairs(model.touchExclusionZones({width=fixture[1],height=fixture[2]},{left=47,top=fixture[3],right=47,bottom=21})) do
                    assert(not model.overlaps({x=x,y=y,right=x+w,bottom=y+h},zone),'Modal covers touch controls')
                end
                local scroll=item:FindFirstChild('NativeScaleContent')
                assert(scroll.CanvasSize.Y.Offset>0,'Unreachable scroll content')
                item:FindFirstChild('RecoveryClose').Activated:Fire()
                assert(not item.Visible,'Close leaves panel in the way')
            end
        end
        assert(visible==1,name..' did not open exactly one usable panel')
    end
    assert(c:find('RailShop').Size.Y.Offset>=44,'Rail touch target too small')
    c:press('QuickSlot2'); assert(c:find('LegacyCafePanel').Visible,'Cafe has no entry')
    c:press('QuickSlot3'); assert(c:find('LegacyVehiclePanel').Visible,'Car has no entry')
    assert(not c:find('LegacyCafePanel').Visible,'Context cards overlap')
    c:find('LegacyVehiclePanel'):FindFirstChild('RecoveryClose').Activated:Fire()
    c:press('QuickSlot4'); assert(c:find('LegacyHousePanel').Visible,'House quick action failed')
    c:find('LegacyHousePanelMobileShell'):FindFirstChild('RecoveryClose').Activated:Fire()
    local calls=#c.calls; c:press('QuickSlot1')
    assert(#c.calls==calls+1 and c.calls[#c.calls].path:match('RequestTravel$'),'Class quick action did not request authoritative travel')
    c.class.canEnter=true; c:pump(); c:press('QuickSlot1')
    assert(c:find('ClassActivityModal').Visible,'Class did not open')
    c:pump()
    c:find('ClassActivityModalMobileShell'):FindFirstChild('RecoveryClose').Activated:Fire()
    assert(not c:find('ClassActivityModal').Visible,'Acknowledged class leave must close modal')
    assert(c:find('RHS2QuickBar').Visible,'Free-roam HUD not restored after class')
    print('IPHONE_BOOT_FIXTURE_OK',table.concat(fixture,'x'))
end
for _,size in ipairs({{0,0},{393,852},{1,1}}) do
    local c=boot(size[1],size[2],58)
    assert(not c:find('RobloxHighSchoolLegacyUI').Enabled,'Transient viewport must defer HUD')
    c.camera.ViewportSize=c.vector(852,393)
    assert(c:find('RobloxHighSchoolLegacyUI').Enabled,'HUD did not recover on landscape transition')
    assert(#c.warnings==0,table.concat(c.warnings,'; '))
end
boot(909,483,36,false)
print('IPHONE_RECOVERY_ACTUAL_CLIENT_BOOT_CALLBACKS_PASS__STUB_ONLY')
