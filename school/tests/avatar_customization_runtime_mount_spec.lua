local file = assert(io.open("school/default.project.json", "r"))
local project = file:read("*a")
file:close()

local function has(fragment, label)
    if not project:find(fragment, 1, true) then
        error("missing avatar/customization runtime mount: " .. (label or fragment), 2)
    end
end

has('"AvatarCustomization"', "avatar customization project node")
has('"$path": "src/client/AvatarCustomization.client.lua"', "avatar customization source path")

print("HIGH_SCHOOL_AVATAR_CUSTOMIZATION_RUNTIME_MOUNT_PASS")
