--!strict
-- One session-locked profile per player. No default overwrite on read failure.
-- Pure reducers are applied inside UpdateAsync, not on a client-owned wallet.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Learning = require(script.Parent.Learning)
local Store = {}
Store.__index = Store
local LEASE_SECONDS = 180
function Store.new()
    return setmetatable({data=DataStoreService:GetDataStore("PipNeighborhoodV1"),
        token=game.JobId..":"..HttpService:GenerateGUID(false), profiles={}, busy={}, studio={}},Store)
end
function Store:operate(id, reducer, release)
    if self.busy[id] then return {ok=false,code="saving"} end
    self.busy[id] = true
    local result = {ok=false,code="save_unavailable"}
    local ok, updated = pcall(function()
        local function transform(envelope)
            envelope = envelope or {profile=Learning.newProfile(),lease={}}
            if type(envelope)~="table" or type(envelope.profile)~="table" then
                error("invalid_stored_profile")
            end
            Learning.normalize(envelope.profile)
            if not Learning.valid(envelope.profile) then
                error("invalid_stored_profile")
            end
            local lease=envelope.lease or {}
            if lease.owner and lease.owner~=self.token and type(lease.untilTime)=="number" and lease.untilTime>os.time() then
                result={ok=false,code="profile_in_use"}
                return nil
            end
            local candidate = Learning.copy(envelope.profile)
            result = reducer(candidate)
            assert(Learning.valid(candidate),"invalid_profile_mutation")
            return {profile=candidate,lease=release and {} or {owner=self.token,untilTime=os.time()+LEASE_SECONDS}}
        end
        -- Explicit opt-in only for local Studio inspection. Published servers never fall back to volatile data.
        if RunService:IsStudio() and game:GetAttribute("NeighborhoodVolatilePreview")==true then
            local nextEnvelope=transform(self.studio[id])
            self.studio[id]=nextEnvelope or self.studio[id]
            return nextEnvelope
        end
        return self.data:UpdateAsync("player:"..tostring(id),transform)
    end)
    self.busy[id] = nil
    if not ok or not updated then
        return {ok=false,code=result.code=="profile_in_use" and "profile_in_use" or "save_unavailable"}
    end
    self.profiles[id] = updated.profile
    return result
end
function Store:load(id)
    return self:operate(id,function() return {ok=true} end,false)
end
function Store:transact(id,reducer)
    if not self.profiles[id] then return {ok=false,code="profile_not_ready"} end
    return self:operate(id,reducer,false)
end
function Store:renew(id)
    if self.profiles[id] then return self:operate(id,function() return {ok=true} end,false) end
    return {ok=false}
end
function Store:release(id)
    for _=1,30 do if not self.busy[id] then break end; task.wait(0.1) end
    if not self.profiles[id] then return end
    self:operate(id,function() return {ok=true} end,true)
    self.profiles[id]=nil
end
return Store
