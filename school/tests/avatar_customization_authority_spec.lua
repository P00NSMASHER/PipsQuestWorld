local function read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local project = read("school/default.project.json")
local client = read("school/src/client/CanonicalSchoolClient.client.lua")
local entry = read("school/src/shared/LegacyOutfitEntry.lua")

local function countPlain(text, fragment)
    local count = 0
    local start = 1
    while true do
        local i = text:find(fragment, start, true)
        if not i then
            return count
        end
        count = count + 1
        start = i + #fragment
    end
end

local function equals(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
    end
end

local function lacks(text, fragment, label)
    if text:find(fragment, 1, true) then
        error("client authority boundary violated: " .. (label or fragment), 2)
    end
end

-- Idempotency / single-runtime authority: exactly one project mapping and one canonical mount.
equals(countPlain(project, '"$path": "src/shared/LegacyOutfitEntry.lua"'), 1, "LegacyOutfitEntry project mapping")
equals(countPlain(project, '"$path": "src/client/AvatarCustomization.client.lua"'), 0, "standalone avatar client mapping")
equals(countPlain(client, 'require(shared:WaitForChild("LegacyOutfitEntry"))'), 1, "LegacyOutfitEntry canonical require")
equals(countPlain(client, 'LegacyOutfitEntry(player, UserInputService)'), 1, "LegacyOutfitEntry canonical mount")

-- Client/shared presentation code must never become persistence or server authority.
for _, fragment in ipairs({
    "DataStoreService",
    "MemoryStoreService",
    ":GetDataStore(",
    ":GetOrderedDataStore(",
    ":GetAsync(",
    ":SetAsync(",
    ":UpdateAsync(",
    'Instance.new("RemoteEvent")',
    'Instance.new("RemoteFunction")',
    ".OnServerEvent",
    ".OnServerInvoke",
}) do
    lacks(client, fragment, "canonical client contains " .. fragment)
    lacks(entry, fragment, "LegacyOutfitEntry contains " .. fragment)
end

-- Presentation may identify verified UI, but must not assert unverified geometry as exact.
equals(countPlain(entry, 'gui:SetAttribute("ReferenceExactIdentity", true)'), 1, "exact device identity marker")
if countPlain(entry, 'SetAttribute("ReferenceExactLayout", false)') < 2 then
    error("unverified layout must remain explicitly non-exact", 2)
end
lacks(entry, 'SetAttribute("ReferenceExactLayout", true)', "unverified layout promoted to exact")

-- Keep the pinned baseline isolated from later public revisions.
lacks(entry, "Hat4", "later nine-hat revision leaked into pinned baseline")
lacks(entry, "Hat9", "later nine-hat revision leaked into pinned baseline")

print("HIGH_SCHOOL_AVATAR_CUSTOMIZATION_AUTHORITY_PASS")
