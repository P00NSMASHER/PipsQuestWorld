local function readAll(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local source = readAll("school/src/client/CanonicalSchoolClient.client.lua")

local function contains(token, label)
    assert(source:find(token, 1, true), label .. " missing")
end

contains('local UserInputService = game:GetService("UserInputService")', "touch service")
contains('local TweenService = game:GetService("TweenService")', "tween service")
contains("local scheduleBottomMargin = UserInputService.TouchEnabled and 122 or 18", "mobile schedule clearance")
contains("local cafeBottomMargin = UserInputService.TouchEnabled and 116 or 18", "mobile cafe clearance")
contains("action.Size = UDim2.new(1, -28, 0, 44)", "primary 44px touch target")
contains("cafeAction.Size = UDim2.new(1, -28, 0, 44)", "cafe 44px touch target")
contains("modalBackdrop.Visible = visible", "modal backdrop coupling")
contains("setModalVisible(true)", "modal show contract")
contains('title.Text = "PIP HIGH"', "canonical school label")
contains('cafeTitle.Text = "CORNER CAFE"', "cafe label")
contains("polishButton(action, palette.navy, palette.navySoft)", "schedule interaction polish")
contains("setButtonState(action, false)", "schedule disabled-state polish")
contains("setFeedback(", "class feedback tone helper")
contains("polishButton(cafeAction, palette.cafe, palette.cafeHover)", "cafe interaction polish")

assert(not source:find("correctIndex", 1, true), "client presentation must not expose answer authority")
assert(not source:find("QuestionBank", 1, true), "deferred education bank must not leak into canonical presentation")
assert(not source:find("StarBlox", 1, true), "retired product label leaked into canonical presentation")
assert(not source:find("Brookhaven", 1, true), "retired product label leaked into canonical presentation")

print("HIGH_SCHOOL_MOBILE_PRESENTATION_PASS")
