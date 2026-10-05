--!strict
-- Shared RHS2 visual language for canonical client presentation.
-- Colors are compression-tolerant targets derived from authorized reference footage;
-- they are not claims about the original hidden RGB constants.

local Style = {}

Style.Palette = {
    ShellNavy = Color3.fromRGB(20, 28, 52),
    HeaderBlue = Color3.fromRGB(0, 104, 240),
    TabBlue = Color3.fromRGB(0, 72, 180),
    ActiveGold = Color3.fromRGB(244, 176, 20),
    ProgressPurple = Color3.fromRGB(180, 52, 236),
    White = Color3.fromRGB(255, 255, 255),
    Ink = Color3.fromRGB(35, 40, 52),
    SoftGrey = Color3.fromRGB(226, 229, 236),
    Shadow = Color3.fromRGB(8, 12, 24),
    ShopRed = Color3.fromRGB(224, 61, 54),
    AvatarCyan = Color3.fromRGB(41, 182, 228),
    HouseGreen = Color3.fromRGB(76, 190, 65),
    TravelGold = Color3.fromRGB(238, 173, 31),
    ConfirmGreen = Color3.fromRGB(54, 201, 105),
}

Style.Font = {
    Bold = Enum.Font.GothamBold,
    Medium = Enum.Font.GothamMedium,
    Regular = Enum.Font.Gotham,
}

Style.Radius = {
    Panel = 8,
    Tile = 10,
    Small = 6,
    Round = 999,
}

local function ensureCorner(guiObject, radius)
    local corner = guiObject:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Parent = guiObject
    end
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

local function ensureStroke(guiObject, thickness, color, transparency)
    local stroke = guiObject:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = guiObject
    end
    stroke.Thickness = thickness
    stroke.Color = color
    stroke.Transparency = transparency or 0
    return stroke
end

local function ensureGradient(guiObject, topColor, bottomColor, rotation)
    local gradient = guiObject:FindFirstChild("Rhs2Gradient")
    if not gradient then
        gradient = Instance.new("UIGradient")
        gradient.Name = "Rhs2Gradient"
        gradient.Parent = guiObject
    end
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, topColor),
        ColorSequenceKeypoint.new(1, bottomColor),
    })
    gradient.Rotation = rotation or 90
    return gradient
end

function Style.applyPrimaryPanel(panel)
    panel.BackgroundColor3 = Style.Palette.ShellNavy
    panel.BackgroundTransparency = 0
    ensureCorner(panel, Style.Radius.Panel)
    ensureStroke(panel, 2, Style.Palette.White, 0.72)
end

function Style.applyHeader(header)
    header.BackgroundColor3 = Style.Palette.HeaderBlue
    header.BackgroundTransparency = 0
    if header:IsA("TextLabel") or header:IsA("TextButton") then
        header.Font = Style.Font.Bold
        header.TextColor3 = Style.Palette.White
    end
    ensureGradient(
        header,
        Color3.fromRGB(24, 132, 255),
        Style.Palette.HeaderBlue,
        90
    )
end

function Style.applyPrimaryRailButton(button, color)
    button.BackgroundColor3 = color
    button.Font = Style.Font.Bold
    button.TextColor3 = Style.Palette.White
    ensureCorner(button, Style.Radius.Tile)
    ensureStroke(button, 2, Style.Palette.White, 0.12)
    ensureGradient(
        button,
        color:Lerp(Style.Palette.White, 0.18),
        color:Lerp(Style.Palette.Shadow, 0.18),
        90
    )
end

function Style.applyQuickSlot(slot, color)
    slot.BackgroundColor3 = color
    ensureCorner(slot, Style.Radius.Tile)
    ensureStroke(slot, 2, Style.Palette.White, 0.20)
    ensureGradient(
        slot,
        color:Lerp(Style.Palette.White, 0.20),
        color:Lerp(Style.Palette.Shadow, 0.18),
        90
    )
end

function Style.applyCloseButton(button)
    button.BackgroundColor3 = Style.Palette.ShellNavy
    button.Font = Style.Font.Bold
    button.TextColor3 = Style.Palette.White
    ensureCorner(button, Style.Radius.Round)
    ensureStroke(button, 2, Style.Palette.White, 0)
end

function Style.applyTab(button, active)
    button.BackgroundColor3 = active and Style.Palette.ActiveGold or Style.Palette.TabBlue
    button.Font = Style.Font.Bold
    button.TextColor3 = Style.Palette.White
    ensureCorner(button, Style.Radius.Small)
    ensureStroke(button, 1, Style.Palette.White, active and 0.45 or 0.78)
end

function Style.applyDarkRow(row)
    row.BackgroundColor3 = Style.Palette.ShellNavy
    row.BackgroundTransparency = 0
    if row:IsA("TextLabel") or row:IsA("TextButton") then
        row.Font = Style.Font.Medium
        row.TextColor3 = Style.Palette.White
    end
    ensureCorner(row, Style.Radius.Small)
end

return Style
