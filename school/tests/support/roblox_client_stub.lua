-- Deterministic API stub for executing the actual client entry point.
-- This tests bootstrap/callbacks only, not Roblox rendering, physics or networking.
local Stub = {}
function Stub.new(width, height, topInset, touch)
    local ctx = { tasks = {}, warnings = {}, calls = {}, remotes = {}, objects = {} }
    local function signal()
        local s = { handlers = {} }
        function s:Connect(fn)
            local connection = { Connected = true }
            function connection:Disconnect() self.Connected = false end
            table.insert(self.handlers, { fn = fn, connection = connection })
            return connection
        end
        function s:Fire(...)
            local copy = { table.unpack(self.handlers) }
            for _, h in ipairs(copy) do if h.connection.Connected then h.fn(...) end end
        end
        return s
    end
    local vmt = {}
    local function vector(x,y,z) return setmetatable({ X=x or 0,Y=y or 0,Z=z or 0 },vmt) end
    vmt.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
    vmt.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
    vmt.__mul=function(a,b)
        if type(a)=='number' then a,b=b,a end
        return vector(a.X*b,a.Y*b,a.Z*b)
    end
    vmt.__index=function(a,k) if k=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end end
    local cfmt = {}
    local function cf(x,y,z)
        if type(x)=='table' then x,y,z=x.X,x.Y,x.Z end
        return setmetatable({ Position=vector(x,y,z),X=x or 0,Y=y or 0,Z=z or 0 },cfmt)
    end
    cfmt.__mul=function(a,b) return cf(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
    cfmt.__add=function(a,b) return cf(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
    local function udim(s,o) return { Scale=s,Offset=o } end
    local function udim2(xs,xo,ys,yo) return { X=udim(xs,xo),Y=udim(ys,yo) } end
    local methods={}
    function methods:GetChildren() return { table.unpack(self._children) } end
    function methods:GetDescendants()
        local result={}
        for _,v in ipairs(self._children) do
            table.insert(result,v)
            for _,d in ipairs(v:GetDescendants()) do table.insert(result,d) end
        end
        return result
    end
    function methods:FindFirstChild(name,recursive)
        for _,v in ipairs(self._children) do if v.Name==name then return v end end
        if recursive then for _,v in ipairs(self._children) do local d=v:FindFirstChild(name,true); if d then return d end end end
    end
    function methods:WaitForChild(name,timeout)
        local child=self:FindFirstChild(name)
        if child then return child end
        if timeout then return nil end
        error('Unseeded WaitForChild: '..self:GetFullName()..'/'..name)
    end
    function methods:GetFullName()
        return (self.Parent and self.Parent:GetFullName()..'/' or '')..self.Name
    end
    function methods:IsA(name)
        local c=self.ClassName
        if c==name or name=='Instance' then return true end
        if name=='BasePart' then return c=='Part' or c=='SpawnLocation' or c=='WedgePart' or c=='Seat' end
        if name=='GuiButton' then return c=='TextButton' or c=='ImageButton' end
        if name=='GuiObject' then return c=='Frame' or c=='ScrollingFrame' or c=='TextLabel' or c=='TextButton' or c=='ImageLabel' or c=='ImageButton' or c=='TextBox' end
        return false
    end
    function methods:FindFirstChildOfClass(name)
        for _,v in ipairs(self._children) do if v:IsA(name) then return v end end
    end
    function methods:FindFirstAncestorOfClass(name)
        local p=self.Parent
        while p do if p:IsA(name) then return p end; p=p.Parent end
    end
    function methods:GetPropertyChangedSignal(name)
        if not self._signals[name] then self._signals[name]=signal() end
        return self._signals[name]
    end
    function methods:SetAttribute(name,value) self._attributes[name]=value end
    function methods:GetAttribute(name) return self._attributes[name] end
    function methods:Destroy()
        self.Destroying:Fire()
        for _,child in ipairs(self:GetChildren()) do child:Destroy() end
        self.Parent=nil
        self._props.Destroyed=true
    end
    function methods:InvokeServer(...)
        table.insert(ctx.calls,{ path=self:GetFullName(),args={...} })
        assert(self.handler,'Missing remote handler: '..self:GetFullName())
        return self.handler(...)
    end
    function methods:FireServer(...) table.insert(ctx.calls,{path=self:GetFullName(),args={...}}) end
    local mt={}
    mt.__index=function(self,k)
        if methods[k] then return methods[k] end
        if k=='Position' and self:IsA('BasePart') and self._props.CFrame then return self._props.CFrame.Position end
        if self._props[k]~=nil then return self._props[k] end
        if k=='Activated' or k=='Destroying' or k=='CharacterAdded' or k=='InputBegan' or k=='InputEnded' or k=='Heartbeat' or k=='FocusLost' then
            return self:GetPropertyChangedSignal('$'..k)
        end
        return self:FindFirstChild(k)
    end
    mt.__newindex=function(self,k,value)
        if self._props[k]==value then return end
        if k=='Parent' then
            local previous=self._props.Parent
            if previous then for i,v in ipairs(previous._children) do if v==self then table.remove(previous._children,i); break end end end
            if value then table.insert(value._children,self) end
        end
        self._props[k]=value
        if self._signals[k] then self._signals[k]:Fire() end
    end
    local function instance(class,name,parent)
        local o=setmetatable({ _props={ClassName=class,Name=name or class,Visible=true,Enabled=true,Active=true,CanCollide=true,CanQuery=true,Position=udim2(0,0,0,0),Size=udim2(0,0,0,0),AnchorPoint=vector(0,0),Value=0},_children={},_attributes={},_signals={} },mt)
        if class=='Part' or class=='SpawnLocation' or class=='WedgePart' then o.Size=vector(4,1,2); o.CFrame=cf(0,0,0) end
        table.insert(ctx.objects,o)
        if parent then o.Parent=parent end
        return o
    end
    ctx.instance=instance
    ctx.vector=vector
    local services={}
    for _,name in ipairs({'Players','ReplicatedStorage','Workspace','GuiService','HttpService','ContextActionService','UserInputService','RunService','Lighting'}) do services[name]=instance(name,name) end
    ctx.services=services
    local player=instance('Player','Player',services.Players)
    services.Players.LocalPlayer=player
    ctx.player=player
    player.Character=instance('Model','Character',services.Workspace)
    instance('Humanoid','Humanoid',player.Character)
    local hrp=instance('Part','HumanoidRootPart',player.Character); hrp.Position=vector(0,3,177); hrp.CFrame=cf(0,3,177)
    instance('PlayerGui','PlayerGui',player)
    local camera=instance('Camera','Camera',services.Workspace)
    camera.ViewportSize=vector(width,height)
    services.Workspace.CurrentCamera=camera
    ctx.camera=camera
    services.UserInputService.TouchEnabled=touch~=false
    services.UserInputService.KeyboardEnabled=touch==false
    services.UserInputService.GamepadEnabled=false
    services.GuiService.GetGuiInset=function() return vector(0,topInset),vector(0,0) end
    services.GuiService.GetInsetArea=function(_,kind)
        local w,h=camera.ViewportSize.X,camera.ViewportSize.Y
        if kind=='ScreenInsets.DeviceSafeInsets' then return {Min=vector(47,0),Max=vector(w-47,h-21)} end
        return {Min=vector(0,0),Max=vector(w,h)}
    end
    local guid=0
    services.HttpService.GenerateGUID=function() guid=guid+1; return 'test-guid-'..guid end
    for _,name in ipairs({'BindAction','UnbindAction','SetTitle','SetPosition'}) do services.ContextActionService[name]=function() end end
    local color={}
    function color:Lerp(other,t) return self end
    local env=setmetatable({},{__index=_G})
    env.Instance={new=instance}
    env.Vector2={new=vector}; env.Vector3={new=vector}
    env.CFrame={new=cf,Angles=function() return cf(0,0,0) end}
    env.UDim={new=udim}
    env.UDim2={new=udim2,fromOffset=function(x,y) return udim2(0,x,0,y) end,fromScale=function(x,y) return udim2(x,0,y,0) end}
    env.Color3={fromRGB=function() return color end,new=function() return color end}
    env.ColorSequence={new=function(v) return v end}; env.ColorSequenceKeypoint={new=function(t,v) return {t,v} end}
    env.Enum=setmetatable({},{__index=function(t,k)
        local v=setmetatable({},{__index=function(_,n) return k..'.'..n end}); rawset(t,k,v); return v
    end})
    env.game={GetService=function(_,name) return assert(services[name],'Unseeded service: '..name) end}
    env.task={}
    local function enqueue(fn,...)
        local co=coroutine.create(fn)
        table.insert(ctx.tasks,{ co=co,args={...} })
    end
    env.task.spawn=enqueue; env.task.defer=enqueue; env.task.delay=function(_,fn,...) enqueue(fn,...) end
    env.task.wait=function() return coroutine.yield() end
    env.warn=function(message) table.insert(ctx.warnings,tostring(message)) end
    env.typeof=function(v) if type(v)=='table' and v.ClassName then return 'Instance' end; return type(v) end
    env.table=setmetatable({clone=function(t) local x={}; for k,v in pairs(t) do x[k]=v end; return x end},{__index=table})
    env.math=setmetatable({clamp=function(v,a,b) return math.max(a,math.min(b,v)) end},{__index=math})
    local shared=instance('Folder','Shared',services.ReplicatedStorage)
    for _,name in ipairs({'SchoolConfig','Rhs2UiStyle','ResponsiveHudLayout','FeaturePanelController','LegacyOutfitEntry','LegacyShoppingBoundary','MobilePanelShell'}) do
        local m=instance('ModuleScript',name,shared); m.SourcePath='school/src/shared/'..name..'.lua'
    end
    local loaded={}
    env.require=function(module)
        if loaded[module] then return loaded[module] end
        local fn=assert(loadfile(assert(module.SourcePath),'t',env)); loaded[module]=fn(); return loaded[module]
    end
    ctx.env=env
    ctx.shared=shared
    function ctx:remote(path,response)
        local p=services.ReplicatedStorage
        local parts={}; for s in path:gmatch('[^/]+') do table.insert(parts,s) end
        for i,name in ipairs(parts) do
            local child=p:FindFirstChild(name)
            if not child then child=instance(i==#parts and 'RemoteFunction' or 'Folder',name,p) end
            p=child
        end
        p.handler=type(response)=='function' and response or function() return response end
        self.remotes[path]=p
        return p
    end
    function ctx:pump()
        local count=#self.tasks
        for i=1,count do
            local t=self.tasks[i]
            if coroutine.status(t.co)~='dead' then
                local ok,err=coroutine.resume(t.co,table.unpack(t.args)); t.args={}
                assert(ok,debug.traceback(t.co,tostring(err)))
            end
        end
    end
    function ctx:load(path) return assert(loadfile(path,'t',env))() end
    function ctx:find(name) return player:FindFirstChild('PlayerGui'):FindFirstChild(name,true) end
    function ctx:press(name)
        local item=assert(self:find(name),'Missing UI: '..name)
        assert(item:IsA('GuiButton'),'Not a button: '..name)
        item.Activated:Fire()
    end
    return ctx
end
return Stub
