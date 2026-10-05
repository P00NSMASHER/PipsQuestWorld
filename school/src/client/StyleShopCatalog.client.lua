--!strict
-- Polished catalog surface that augments the canonical STYLE SHOP panel.
-- Price, ownership, purchase, and equip authority stay on the server.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopRemotes = ReplicatedStorage:WaitForChild("SchoolFoundation")
    :WaitForChild("FreeRoam")
    :WaitForChild("StyleShop")
local getState = shopRemotes:WaitForChild("GetState")
local purchaseItem = shopRemotes:WaitForChild("PurchaseItem")
local equipItem = shopRemotes:WaitForChild("EquipItem")

local screenGui = playerGui:WaitForChild("RobloxHighSchoolLegacyUI", 30)
if screenGui == nil then return end
local panel = screenGui:WaitForChild("FeaturePanel_shop", 30)
if panel == nil then return end
local body = panel:WaitForChild("Body", 10)
if body == nil or body:GetAttribute("StyleCatalogMounted") == true then return end

body:SetAttribute("StyleCatalogMounted", true)
body:ClearAllChildren()
body.ClipsDescendants = true

local BLUE_DARK = Color3.fromRGB(35, 67, 98)
local BLUE = Color3.fromRGB(55, 126, 168)
local PAPER = Color3.fromRGB(245, 250, 253)
local GREEN = Color3.fromRGB(74, 164, 104)
local GOLD = Color3.fromRGB(229, 168, 50)
local MUTED = Color3.fromRGB(103, 126, 145)

local function rounded(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function stroke(instance, color, thickness)
    local line = Instance.new("UIStroke")
    line.Color = color
    line.Thickness = thickness or 1
    line.Transparency = 0.12
    line.Parent = instance
    return line
end

local function rgb(value, fallback)
    if type(value) ~= "table" or #value < 3 then return fallback end
    return Color3.fromRGB(value[1], value[2], value[3])
end

local toolbar = Instance.new("Frame")
toolbar.Name = "CatalogToolbar"
toolbar.Size = UDim2.new(1, 0, 0, 34)
toolbar.BackgroundTransparency = 1
toolbar.ZIndex = 23
toolbar.Parent = body

local balanceLabel = Instance.new("TextLabel")
balanceLabel.Name = "Balance"
balanceLabel.Size = UDim2.fromOffset(84, 30)
balanceLabel.BackgroundColor3 = Color3.fromRGB(227, 240, 248)
balanceLabel.Font = Enum.Font.GothamBold
balanceLabel.Text = "$ --"
balanceLabel.TextColor3 = BLUE_DARK
balanceLabel.TextSize = 14
balanceLabel.ZIndex = 24
balanceLabel.Parent = toolbar
rounded(balanceLabel, 9)

local categoryBar = Instance.new("Frame")
categoryBar.Name = "Categories"
categoryBar.Position = UDim2.fromOffset(90, 0)
categoryBar.Size = UDim2.new(1, -90, 0, 30)
categoryBar.BackgroundTransparency = 1
categoryBar.ZIndex = 23
categoryBar.Parent = toolbar

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.Padding = UDim.new(0, 5)
categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
categoryLayout.Parent = categoryBar

local catalogScroll = Instance.new("ScrollingFrame")
catalogScroll.Name = "CatalogList"
catalogScroll.Position = UDim2.fromOffset(0, 40)
catalogScroll.Size = UDim2.new(0.57, -5, 1, -62)
catalogScroll.BackgroundColor3 = PAPER
catalogScroll.BorderSizePixel = 0
catalogScroll.ScrollBarThickness = 5
catalogScroll.ScrollBarImageColor3 = BLUE
catalogScroll.CanvasSize = UDim2.fromOffset(0, 0)
catalogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
catalogScroll.ZIndex = 23
catalogScroll.Parent = body
rounded(catalogScroll, 9)
stroke(catalogScroll, Color3.fromRGB(185, 211, 226), 1)

local catalogPadding = Instance.new("UIPadding")
catalogPadding.PaddingTop = UDim.new(0, 6)
catalogPadding.PaddingBottom = UDim.new(0, 6)
catalogPadding.PaddingLeft = UDim.new(0, 6)
catalogPadding.PaddingRight = UDim.new(0, 6)
catalogPadding.Parent = catalogScroll

local catalogLayout = Instance.new("UIListLayout")
catalogLayout.Padding = UDim.new(0, 6)
catalogLayout.SortOrder = Enum.SortOrder.LayoutOrder
catalogLayout.Parent = catalogScroll

local detail = Instance.new("Frame")
detail.Name = "ItemDetail"
detail.AnchorPoint = Vector2.new(1, 0)
detail.Position = UDim2.new(1, 0, 0, 40)
detail.Size = UDim2.new(0.43, -5, 1, -62)
detail.BackgroundColor3 = PAPER
detail.BorderSizePixel = 0
detail.ClipsDescendants = true
detail.ZIndex = 23
detail.Parent = body
rounded(detail, 9)
stroke(detail, Color3.fromRGB(185, 211, 226), 1)

local detailSwatch = Instance.new("Frame")
detailSwatch.Name = "Preview"
detailSwatch.Position = UDim2.fromOffset(10, 10)
detailSwatch.Size = UDim2.new(1, -20, 0, 50)
detailSwatch.BackgroundColor3 = BLUE
detailSwatch.BorderSizePixel = 0
detailSwatch.ZIndex = 24
detailSwatch.Parent = detail
rounded(detailSwatch, 8)

local accentSwatch = Instance.new("Frame")
accentSwatch.Name = "Accent"
accentSwatch.AnchorPoint = Vector2.new(1, 1)
accentSwatch.Position = UDim2.new(1, -8, 1, -8)
accentSwatch.Size = UDim2.fromOffset(42, 12)
accentSwatch.BackgroundColor3 = Color3.new(1, 1, 1)
accentSwatch.BorderSizePixel = 0
accentSwatch.ZIndex = 25
accentSwatch.Parent = detailSwatch
rounded(accentSwatch, 6)

local detailName = Instance.new("TextLabel")
detailName.Name = "ItemName"
detailName.Position = UDim2.fromOffset(10, 66)
detailName.Size = UDim2.new(1, -20, 0, 38)
detailName.BackgroundTransparency = 1
detailName.Font = Enum.Font.GothamBold
detailName.Text = "Pick a style"
detailName.TextColor3 = BLUE_DARK
detailName.TextSize = 17
detailName.TextWrapped = true
detailName.TextXAlignment = Enum.TextXAlignment.Left
detailName.TextYAlignment = Enum.TextYAlignment.Top
detailName.ZIndex = 24
detailName.Parent = detail

local detailDescription = Instance.new("TextLabel")
detailDescription.Name = "Description"
detailDescription.Position = UDim2.fromOffset(10, 106)
detailDescription.Size = UDim2.new(1, -20, 1, -164)
detailDescription.BackgroundTransparency = 1
detailDescription.Font = Enum.Font.Gotham
detailDescription.Text = "Browse original campus styles made for Pip High."
detailDescription.TextColor3 = MUTED
detailDescription.TextSize = 12
detailDescription.TextWrapped = true
detailDescription.TextXAlignment = Enum.TextXAlignment.Left
detailDescription.TextYAlignment = Enum.TextYAlignment.Top
detailDescription.ZIndex = 24
detailDescription.Parent = detail

local action = Instance.new("TextButton")
action.Name = "PurchaseOrEquip"
action.AnchorPoint = Vector2.new(0, 1)
action.Position = UDim2.new(0, 10, 1, -10)
action.Size = UDim2.new(1, -20, 0, 42)
action.BackgroundColor3 = GREEN
action.Font = Enum.Font.GothamBold
action.Text = "SELECT AN ITEM"
action.TextColor3 = Color3.new(1, 1, 1)
action.TextSize = 13
action.TextWrapped = true
action.AutoButtonColor = true
action.ZIndex = 24
action.Parent = detail
rounded(action, 8)

local status = Instance.new("TextLabel")
status.Name = "CatalogStatus"
status.AnchorPoint = Vector2.new(0, 1)
status.Position = UDim2.new(0, 0, 1, 0)
status.Size = UDim2.new(1, 0, 0, 18)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.Text = "Play-earned cash only • original in-game styles"
status.TextColor3 = MUTED
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.ZIndex = 23
status.Parent = body

-- A minimum-height feature panel leaves an 86px detail pane at 480x300.
-- Reflow that pane horizontally so its preview, name, and purchase action all
-- remain distinct and tappable. The taller desktop composition is unchanged.
local function applyResponsiveCatalogLayout()
    local compact = body.AbsoluteSize.Y > 0 and body.AbsoluteSize.Y < 190
    if compact then
        catalogScroll.Size = UDim2.new(0.5, -4, 1, -62)
        detail.Size = UDim2.new(0.5, -4, 1, -62)
        detailSwatch.Position = UDim2.fromOffset(8, 8)
        detailSwatch.Size = UDim2.new(0, 52, 1, -16)
        accentSwatch.Position = UDim2.new(1, -5, 1, -5)
        accentSwatch.Size = UDim2.fromOffset(20, 8)
        detailName.Position = UDim2.fromOffset(68, 7)
        detailName.Size = UDim2.new(1, -76, 0, 18)
        detailName.TextSize = 12
        detailName.TextWrapped = false
        detailName.TextTruncate = Enum.TextTruncate.AtEnd
        detailDescription.Position = UDim2.fromOffset(68, 25)
        detailDescription.Size = UDim2.new(1, -76, 0, 12)
        detailDescription.TextSize = 9
        detailDescription.TextWrapped = false
        detailDescription.TextTruncate = Enum.TextTruncate.AtEnd
        action.Position = UDim2.new(0, 68, 1, -8)
        action.Size = UDim2.new(1, -76, 0, 38)
        action.TextSize = 11
    else
        catalogScroll.Size = UDim2.new(0.57, -5, 1, -62)
        detail.Size = UDim2.new(0.43, -5, 1, -62)
        detailSwatch.Position = UDim2.fromOffset(10, 10)
        detailSwatch.Size = UDim2.new(1, -20, 0, 50)
        accentSwatch.Position = UDim2.new(1, -8, 1, -8)
        accentSwatch.Size = UDim2.fromOffset(42, 12)
        detailName.Position = UDim2.fromOffset(10, 66)
        detailName.Size = UDim2.new(1, -20, 0, 38)
        detailName.TextSize = 17
        detailName.TextWrapped = true
        detailName.TextTruncate = Enum.TextTruncate.None
        detailDescription.Position = UDim2.fromOffset(10, 106)
        detailDescription.Size = UDim2.new(1, -20, 1, -164)
        detailDescription.TextSize = 12
        detailDescription.TextWrapped = true
        detailDescription.TextTruncate = Enum.TextTruncate.None
        action.Position = UDim2.new(0, 10, 1, -10)
        action.Size = UDim2.new(1, -20, 0, 42)
        action.TextSize = 13
    end
end

body:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyResponsiveCatalogLayout)
applyResponsiveCatalogLayout()

local state = nil
local selectedId = nil
local selectedCategory = "All"
local busy = false
local cards = {}
local categoryButtons = {}
local pendingRequestIds = {}

local function selectedItem()
    if not state or type(state.items) ~= "table" then return nil end
    for _, item in ipairs(state.items) do
        if item.id == selectedId then return item end
    end
    return nil
end

local function refreshDetail()
    balanceLabel.Text = "$ " .. tostring(state and state.balance or "--")
    local item = selectedItem()
    if item == nil then
        detailName.Text = "Pick a style"
        detailDescription.Text = "Browse original campus styles made for Pip High."
        action.Text = "SELECT AN ITEM"
        action.Active = false
        action.BackgroundColor3 = MUTED
        return
    end

    detailSwatch.BackgroundColor3 = rgb(item.primary, BLUE)
    accentSwatch.BackgroundColor3 = rgb(item.secondary, Color3.new(1, 1, 1))
    detailName.Text = item.displayName
    detailDescription.Text = item.description .. "\n\n" .. item.category

    local owned = state.owned and state.owned[item.id] == true
    local equipped = state.equipped and state.equipped[item.slot] == item.id
    action.Active = not busy and not equipped
    action.AutoButtonColor = action.Active
    if busy then
        action.Text = "PLEASE WAIT..."
        action.BackgroundColor3 = MUTED
    elseif equipped then
        action.Text = "EQUIPPED"
        action.BackgroundColor3 = BLUE
    elseif owned then
        action.Text = "EQUIP"
        action.BackgroundColor3 = GREEN
    else
        action.Text = "BUY  •  $" .. tostring(item.price)
        action.BackgroundColor3 = GOLD
    end
end

local function renderCatalog()
    for _, card in ipairs(cards) do card:Destroy() end
    table.clear(cards)
    if not state or type(state.items) ~= "table" then return end

    for _, item in ipairs(state.items) do
        if selectedCategory == "All" or selectedCategory == item.category then
            local card = Instance.new("TextButton")
            card.Name = "Item_" .. item.id
            card.Size = UDim2.new(1, 0, 0, 62)
            card.BackgroundColor3 = selectedId == item.id and Color3.fromRGB(218, 237, 248) or Color3.new(1, 1, 1)
            card.BorderSizePixel = 0
            card.Text = ""
            card.AutoButtonColor = true
            card.ZIndex = 24
            card.Parent = catalogScroll
            rounded(card, 8)
            stroke(card, selectedId == item.id and BLUE or Color3.fromRGB(214, 226, 235), selectedId == item.id and 2 or 1)

            local swatch = Instance.new("Frame")
            swatch.Position = UDim2.fromOffset(7, 7)
            swatch.Size = UDim2.fromOffset(48, 48)
            swatch.BackgroundColor3 = rgb(item.primary, BLUE)
            swatch.BorderSizePixel = 0
            swatch.ZIndex = 25
            swatch.Parent = card
            rounded(swatch, 7)

            local accent = Instance.new("Frame")
            accent.AnchorPoint = Vector2.new(1, 1)
            accent.Position = UDim2.new(1, -5, 1, -5)
            accent.Size = UDim2.fromOffset(20, 8)
            accent.BackgroundColor3 = rgb(item.secondary, Color3.new(1, 1, 1))
            accent.BorderSizePixel = 0
            accent.ZIndex = 26
            accent.Parent = swatch
            rounded(accent, 4)

            local name = Instance.new("TextLabel")
            name.Position = UDim2.fromOffset(64, 8)
            name.Size = UDim2.new(1, -70, 0, 24)
            name.BackgroundTransparency = 1
            name.Font = Enum.Font.GothamBold
            name.Text = item.displayName
            name.TextColor3 = BLUE_DARK
            name.TextSize = 13
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.ZIndex = 25
            name.Parent = card

            local owned = state.owned and state.owned[item.id] == true
            local meta = Instance.new("TextLabel")
            meta.Position = UDim2.fromOffset(64, 32)
            meta.Size = UDim2.new(1, -70, 0, 20)
            meta.BackgroundTransparency = 1
            meta.Font = Enum.Font.Gotham
            meta.Text = owned and "OWNED • " .. item.category or "$" .. tostring(item.price) .. " • " .. item.category
            meta.TextColor3 = owned and GREEN or MUTED
            meta.TextSize = 11
            meta.TextXAlignment = Enum.TextXAlignment.Left
            meta.ZIndex = 25
            meta.Parent = card

            card.Activated:Connect(function()
                selectedId = item.id
                renderCatalog()
                refreshDetail()
            end)
            table.insert(cards, card)
        end
    end
    refreshDetail()
end

local function updateCategoryButtons()
    for name, button in pairs(categoryButtons) do
        local active = name == selectedCategory
        button.BackgroundColor3 = active and BLUE or Color3.fromRGB(225, 237, 245)
        button.TextColor3 = active and Color3.new(1, 1, 1) or BLUE_DARK
    end
end

for _, category in ipairs({ "All", "Tops", "Bottoms", "Accessories" }) do
    local chip = Instance.new("TextButton")
    chip.Name = "Category_" .. category
    local chipWidth = category == "Accessories" and 54
        or category == "Bottoms" and 50
        or category == "Tops" and 42
        or 38
    chip.Size = UDim2.fromOffset(chipWidth, 28)
    chip.BackgroundColor3 = Color3.fromRGB(225, 237, 245)
    chip.Font = Enum.Font.GothamBold
    chip.Text = category == "Accessories" and "EXTRAS" or string.upper(category)
    chip.TextColor3 = BLUE_DARK
    chip.TextSize = 9
    chip.ZIndex = 24
    chip.Parent = categoryBar
    rounded(chip, 8)
    chip.Activated:Connect(function()
        selectedCategory = category
        updateCategoryButtons()
        renderCatalog()
    end)
    categoryButtons[category] = chip
end
updateCategoryButtons()

local function applyServerState(response)
    if type(response) ~= "table" then return end
    if type(response.items) == "table" then state = response end
    if state == nil then return end
    if type(response.balance) == "number" then state.balance = response.balance end
    if type(response.owned) == "table" then state.owned = response.owned end
    if type(response.equipped) == "table" then state.equipped = response.equipped end
    if selectedId == nil and state.items[1] then selectedId = state.items[1].id end
    renderCatalog()
end

local function refreshState()
    if busy then return end
    status.Text = "Loading wardrobe..."
    local ok, response = pcall(function()
        return getState:InvokeServer()
    end)
    if ok and type(response) == "table" and response.accepted == true then
        applyServerState(response)
        status.Text = "Play-earned cash only • original in-game styles"
    else
        status.Text = "The wardrobe service is unavailable. Try reopening the shop."
    end
end

action.Activated:Connect(function()
    if busy then return end
    local item = selectedItem()
    if item == nil or state == nil then return end
    busy = true
    refreshDetail()

    local owned = state.owned and state.owned[item.id] == true
    local ok, response
    if owned then
        status.Text = "Equipping " .. item.displayName .. "..."
        ok, response = pcall(function()
            return equipItem:InvokeServer(item.id)
        end)
    else
        status.Text = "Purchasing " .. item.displayName .. "..."
        local requestId = pendingRequestIds[item.id]
        if requestId == nil then
            requestId = HttpService:GenerateGUID(false)
            pendingRequestIds[item.id] = requestId
        end
        ok, response = pcall(function()
            return purchaseItem:InvokeServer(item.id, requestId)
        end)
        if ok and type(response) == "table" and response.retryable ~= true then
            pendingRequestIds[item.id] = nil
        end
    end

    busy = false
    if not ok or type(response) ~= "table" then
        status.Text = "The shop did not respond. Your balance was not changed here."
        refreshDetail()
        return
    end

    applyServerState(response)
    if response.code == "purchased" then
        status.Text = item.displayName .. " is now yours."
    elseif response.code == "purchase_already_processed" or response.code == "already_owned" then
        status.Text = item.displayName .. " is already in your wardrobe."
    elseif response.code == "equipped" then
        status.Text = item.displayName .. " equipped."
    elseif response.code == "insufficient_funds" then
        status.Text = "You need more play-earned cash for this style."
    elseif response.code == "request_id_conflict" then
        status.Text = "That request could not be reused. Please try again."
    elseif response.code == "not_owned" then
        status.Text = "Purchase this style before equipping it."
    else
        status.Text = "That action is unavailable right now."
    end
    refreshDetail()
end)

panel:GetPropertyChangedSignal("Visible"):Connect(function()
    if panel.Visible then task.spawn(refreshState) end
end)

task.spawn(refreshState)
