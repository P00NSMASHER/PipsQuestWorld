-- QA-owned deterministic validator for PR #165 callback-only shopping notification.
-- Unpromoted prep branch; this file does not implement product semantics.
-- Bound candidate: e3be5dfab4b825064c7ac14616330dc54f3f640f
-- Canonical base: 23cc398bd7ae3232835a0fee1d5ab32abb8a315b
-- Exact-head guards: Foundation 37141490985 / Class 37141490978 / Progression 37141491082

local function read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local function has(text, fragment, label)
    if not text:find(fragment, 1, true) then
        error("shopping callback notification contract missing: " .. (label or fragment), 2)
    end
end

local function lacks(text, fragment, label)
    if text:find(fragment, 1, true) then
        error("shopping callback notification contract forbidden: " .. (label or fragment), 2)
    end
end

local service = read("school/src/server/ShoppingPurchase.server.lua")
local controller = read("school/src/server/ShoppingPurchaseController.lua")
local client = read("school/src/shared/LegacyShoppingBoundary.lua")

local exactSuccess =
    "Item purchased successfully! You can wear it via the Character tab on the ROBLOX website."

-- Content-QA-proven facts remain anchored server-side.
has(controller, exactSuccess, "exact post-purchase Character-tab text")
has(service, "MarketplaceService.PromptPurchaseFinished:Connect", "server purchase callback")

-- A callback receipt must be consumed by runtime, not discarded.
has(service, "local confirmation = controller:confirmPurchase", "captured confirmation receipt")
has(service, 'confirmation.code == "purchase_confirmed"', "first confirmed callback gate")
has(service, "confirmation.successText", "server-owned success payload")
has(service, ":FireClient(player, confirmation.successText)", "targeted player notification delivery")

-- Fail closed against broadcast/client-authored success or spend authority.
lacks(service, ":FireAllClients(", "broadcast purchase success")
lacks(client, exactSuccess, "client-authored exact success")
lacks(service, "PromptPurchase(", "automatic Robux purchase")
lacks(service, "PromptProductPurchase(", "automatic developer-product purchase")
lacks(service, "EconomyRepository", "RHS economy dependency")
lacks(service, "RHS Cash", "RHS Cash debit path")

print("HIGH_SCHOOL_QA_SHOPPING_CALLBACK_NOTIFICATION_PASS")
