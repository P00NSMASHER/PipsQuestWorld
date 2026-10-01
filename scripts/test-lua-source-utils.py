#!/usr/bin/env python3
from lua_source_utils import mask_lua_comments

sample = '''local live = true
-- fake.OnServerEvent:Connect(function(plr) end)
local text = "-- not a comment"
--[[
dead.OnServerInvoke = function(plr, amount)
    cash.Value = cash.Value + amount
end
]]
live.OnServerInvoke = function(plr, value)
    return value
end
local long = [[-- still string content]]
'''

masked = mask_lua_comments(sample)

assert len(masked) == len(sample)
assert masked.count("\n") == sample.count("\n")
assert "fake.OnServerEvent" not in masked
assert "dead.OnServerInvoke" not in masked
assert "cash.Value" not in masked
assert 'local text = "-- not a comment"' in masked
assert "live.OnServerInvoke" in masked
assert "[[-- still string content]]" in masked

eq_sample = '''--[=[
blocked.OnServerInvoke = function(plr) end
]=]
allowed.OnServerEvent:Connect(function(plr) end)
'''
eq_masked = mask_lua_comments(eq_sample)
assert "blocked.OnServerInvoke" not in eq_masked
assert "allowed.OnServerEvent" in eq_masked
assert len(eq_masked) == len(eq_sample)
assert eq_masked.count("\n") == eq_sample.count("\n")

print("LUA_COMMENT_MASKER_TEST_OK")
