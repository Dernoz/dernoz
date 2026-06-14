local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")
local CONFIG = {
    Hotkey      = Enum.KeyCode.X,
    MenuHotkey  = Enum.KeyCode.F2,
    ExcludeSelf = false,
    DefaultColor            = 1,
    DefaultFillTransparency = 0.45,
    DefaultOutlineTransparency = 0,
    ShowNames   = true,
    ShowDistance = true,
    ShowTeamColor = false,
    NameTagSize = 13,
    Colors = {
        { name = "Orange", fill = Color3.fromRGB(255,160,0),   outline = Color3.fromRGB(255,80,0)   },
        { name = "Red",   fill = Color3.fromRGB(255,50,50),   outline = Color3.fromRGB(180,0,0)    },
        { name = "Blue",     fill = Color3.fromRGB(60,140,255),  outline = Color3.fromRGB(0,80,220)   },
        { name = "Green",   fill = Color3.fromRGB(50,220,100),  outline = Color3.fromRGB(0,150,50)   },
        { name = "Purple",    fill = Color3.fromRGB(180,80,255),  outline = Color3.fromRGB(120,0,200)  },
        { name = "White",     fill = Color3.fromRGB(240,240,255), outline = Color3.fromRGB(160,160,200)},
        { name = "Pink",   fill = Color3.fromRGB(255,100,180), outline = Color3.fromRGB(200,0,120)  },
        { name = "Cyan",      fill = Color3.fromRGB(0,220,220),   outline = Color3.fromRGB(0,150,180)  },
        { name = "Gold",   fill = Color3.fromRGB(255,210,0),   outline = Color3.fromRGB(200,150,0)  },
        { name = "Rainbow",    fill = Color3.fromRGB(255,255,255), outline = Color3.fromRGB(200,200,200)},
    },
}
local State = {
    enabled       = false,
    menuVisible   = true,
    colorIndex    = CONFIG.DefaultColor,
    fillTrans     = CONFIG.DefaultFillTransparency,
    outlineTrans  = CONFIG.DefaultOutlineTransparency,
    excludeSelf   = CONFIG.ExcludeSelf,
    showNames     = CONFIG.ShowNames,
    showDistance  = CONFIG.ShowDistance,
    showTeamColor = CONFIG.ShowTeamColor,
    nameTagSize   = CONFIG.NameTagSize,
    excludedNames = {},
    highlights    = {},
    billboards    = {},
    charConnections = {},
    rainbowHue    = 0,
}
local createHighlight, removeHighlight, applyColorToAll
local function getColor()
    return CONFIG.Colors[State.colorIndex]
end
local function tween(obj, props, t, style, dir)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(
        t or 0.2,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    ), props):Play()
end
local function isExcluded(player)
    if State.excludeSelf and player == LocalPlayer then return true end
    if State.excludedNames[player.Name] then return true end
    return false
end
local function getRainbowColor()
    State.rainbowHue = (State.rainbowHue + 0.002) % 1
    return Color3.fromHSV(State.rainbowHue, 1, 1)
end
local function getDistanceStr(player)
    if not State.showDistance then return "" end
    local lchar = LocalPlayer.Character
    local pchar = player.Character
    if not lchar or not pchar then return "" end
    local lhrp = lchar:FindFirstChild("HumanoidRootPart")
    local phrp = pchar:FindFirstChild("HumanoidRootPart")
    if not lhrp or not phrp then return "" end
    local dist = math.floor((lhrp.Position - phrp.Position).Magnitude)
    return " [" .. dist .. "m]"
end
if PlayerGui:FindFirstChild("DernozGui") then
    PlayerGui:FindFirstChild("DernozGui"):Destroy()
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "DernozGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = PlayerGui
local Shadow = Instance.new("ImageLabel")
Shadow.Name           = "Shadow"
Shadow.AnchorPoint    = Vector2.new(0.5, 0)
Shadow.Size           = UDim2.new(0, 290, 0, 30)
Shadow.Position       = UDim2.new(0.5, 0, 0, 55)
Shadow.BackgroundTransparency = 1
Shadow.Image          = "rbxassetid://6014261993"
Shadow.ImageColor3    = Color3.new(0,0,0)
Shadow.ImageTransparency = 1
Shadow.ScaleType      = Enum.ScaleType.Slice
Shadow.SliceCenter    = Rect.new(49,49,450,450)
Shadow.ZIndex         = 1
Shadow.Parent         = ScreenGui
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.AnchorPoint      = Vector2.new(0.5, 0)
Main.Size             = UDim2.new(0, 270, 0, 30)
Main.Position         = UDim2.new(0.5, 0, 0, 60)
Main.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.ZIndex           = 2
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color     = Color3.fromRGB(60, 60, 95)
MainStroke.Thickness = 1.5
MainStroke.Parent    = Main
local Header = Instance.new("Frame")
Header.Name             = "Header"
Header.Size             = UDim2.new(1, 0, 0, 56)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
Header.BorderSizePixel  = 0
Header.ZIndex           = 3
Header.Parent           = Main
local HeaderGrad = Instance.new("UIGradient")
HeaderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 220)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 80, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 38)),
})
HeaderGrad.Rotation = 90
HeaderGrad.Parent   = Header
local Accent = Instance.new("Frame")
Accent.Name             = "Accent"
Accent.Size             = UDim2.new(1, 0, 0, 3)
Accent.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
Accent.BorderSizePixel  = 0
Accent.ZIndex           = 4
Accent.Parent           = Main
local AccentGrad = Instance.new("UIGradient")
AccentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(120, 60,  220)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(200, 80,  255)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 100, 200)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 160, 80)),
})
AccentGrad.Parent = Accent
local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size               = UDim2.new(0, 36, 0, 36)
TitleIcon.Position           = UDim2.new(0, 12, 0, 10)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text               = "#"
TitleIcon.TextColor3         = Color3.fromRGB(180, 100, 255)
TitleIcon.TextSize           = 24
TitleIcon.Font               = Enum.Font.GothamBold
TitleIcon.ZIndex             = 4
TitleIcon.Parent             = Header
local TitleText = Instance.new("TextLabel")
TitleText.Size               = UDim2.new(0, 140, 0, 22)
TitleText.Position           = UDim2.new(0, 46, 0, 8)
TitleText.BackgroundTransparency = 1
TitleText.Text               = "DERNOZ"
TitleText.TextColor3         = Color3.fromRGB(230, 210, 255)
TitleText.TextSize           = 18
TitleText.Font               = Enum.Font.GothamBold
TitleText.TextXAlignment     = Enum.TextXAlignment.Left
TitleText.ZIndex             = 4
TitleText.Parent             = Header
local SubText = Instance.new("TextLabel")
SubText.Size               = UDim2.new(0, 160, 0, 16)
SubText.Position           = UDim2.new(0, 46, 0, 32)
SubText.BackgroundTransparency = 1
SubText.Text               = "ESP - F2 menu - X toggle"
SubText.TextColor3         = Color3.fromRGB(110, 100, 150)
SubText.TextSize           = 9
SubText.Font               = Enum.Font.Gotham
SubText.TextXAlignment     = Enum.TextXAlignment.Left
SubText.ZIndex             = 4
SubText.Parent             = Header
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 28, 0, 28)
MinBtn.Position         = UDim2.new(1, -66, 0, 14)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
MinBtn.Text             = "-"
MinBtn.TextColor3       = Color3.fromRGB(180, 180, 220)
MinBtn.TextSize         = 18
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.BorderSizePixel  = 0
MinBtn.ZIndex           = 4
MinBtn.Parent           = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
CloseBtn.Position         = UDim2.new(1, -34, 0, 14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text             = "X"
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize         = 13
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.BorderSizePixel  = 0
CloseBtn.ZIndex           = 4
CloseBtn.Parent           = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name                  = "ScrollFrame"
ScrollFrame.Size                  = UDim2.new(1, 0, 1, -59)
ScrollFrame.Position              = UDim2.new(0, 0, 0, 59)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel       = 0
ScrollFrame.ScrollBarThickness    = 3
ScrollFrame.ScrollBarImageColor3  = Color3.fromRGB(120, 60, 220)
ScrollFrame.CanvasSize            = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
ScrollFrame.ZIndex                = 3
ScrollFrame.Parent                = Main
local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding             = UDim.new(0, 6)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.SortOrder           = Enum.SortOrder.LayoutOrder
ListLayout.Parent              = ScrollFrame
local ListPad = Instance.new("UIPadding")
ListPad.PaddingTop    = UDim.new(0, 10)
ListPad.PaddingBottom = UDim.new(0, 14)
ListPad.Parent        = ScrollFrame
local function Section(text, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(0.92, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.LayoutOrder      = order
    f.Parent           = ScrollFrame
    local line = Instance.new("Frame")
    line.Size             = UDim2.new(1, 0, 0, 1)
    line.Position         = UDim2.new(0, 0, 0.5, 8)
    line.BackgroundColor3 = Color3.fromRGB(45, 45, 68)
    line.BorderSizePixel  = 0
    line.Parent           = f
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize      = Enum.AutomaticSize.X
    lbl.BackgroundColor3   = Color3.fromRGB(13, 13, 20)
    lbl.BackgroundTransparency = 0
    lbl.Text               = "  " .. text .. "  "
    lbl.TextColor3         = Color3.fromRGB(160, 100, 255)
    lbl.TextSize           = 9
    lbl.Font               = Enum.Font.GothamBold
    lbl.Parent             = f
    return f
end
local function Card(height, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(0.92, 0, 0, height)
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order
    f.Parent           = ScrollFrame
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke")
    st.Color     = Color3.fromRGB(45, 45, 70)
    st.Thickness = 1
    st.Parent    = f
    return f
end
local function MakeToggle(parent, xOff, yOff, width, height, isSmall)
    width  = width  or 52
    height = height or 28
    local knobSize = isSmall and 18 or 22
    local knobOff  = isSmall and 2  or 3
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, width, 0, height)
    track.Position         = UDim2.new(xOff, 0, yOff, 0)
    track.AnchorPoint      = Vector2.new(xOff, 0.5)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    track.BorderSizePixel  = 0
    track.Parent           = parent
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, knobSize, 0, knobSize)
    knob.Position         = UDim2.new(0, knobOff, 0.5, -knobSize/2)
    knob.BackgroundColor3 = Color3.fromRGB(140, 140, 180)
    knob.BorderSizePixel  = 0
    knob.Parent           = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local hit = Instance.new("TextButton")
    hit.Size               = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text               = ""
    hit.Parent             = track
    return track, knob, hit
end
local function SetToggleVisual(track, knob, on, width, height, isSmall)
    local knobSize = isSmall and 18 or 22
    local knobOff  = isSmall and 2  or 3
    tween(knob, {
        Position = on
            and UDim2.new(1, -(knobSize + knobOff), 0.5, -knobSize/2)
            or  UDim2.new(0, knobOff, 0.5, -knobSize/2),
        BackgroundColor3 = on
            and Color3.fromRGB(255, 255, 255)
            or  Color3.fromRGB(140, 140, 180),
    }, 0.2)
    tween(track, {
        BackgroundColor3 = on
            and Color3.fromRGB(120, 60, 220)
            or  Color3.fromRGB(45, 45, 65),
    }, 0.2)
end
Section("CONTROL", 1)
local Card1 = Card(80, 2)
local StatusDot = Instance.new("Frame")
StatusDot.Size             = UDim2.new(0, 10, 0, 10)
StatusDot.Position         = UDim2.new(0, 14, 0, 14)
StatusDot.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
StatusDot.BorderSizePixel  = 0
StatusDot.Parent           = Card1
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size               = UDim2.new(0, 120, 0, 18)
StatusLabel.Position           = UDim2.new(0, 30, 0, 10)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text               = "DISABLED"
StatusLabel.TextColor3         = Color3.fromRGB(200, 50, 50)
StatusLabel.TextSize           = 12
StatusLabel.Font               = Enum.Font.GothamBold
StatusLabel.TextXAlignment     = Enum.TextXAlignment.Left
StatusLabel.Parent             = Card1
local HotkeyLabel = Instance.new("TextLabel")
HotkeyLabel.Size               = UDim2.new(1, -14, 0, 14)
HotkeyLabel.Position           = UDim2.new(0, 14, 0, 32)
HotkeyLabel.BackgroundTransparency = 1
HotkeyLabel.Text               = "ESP: [ X ]   Menu: [ F2 ]"
HotkeyLabel.TextColor3         = Color3.fromRGB(80, 80, 115)
HotkeyLabel.TextSize           = 10
HotkeyLabel.Font               = Enum.Font.Gotham
HotkeyLabel.TextXAlignment     = Enum.TextXAlignment.Left
HotkeyLabel.Parent             = Card1
local ToggleTrack, ToggleKnob, ToggleHit = MakeToggle(Card1, 1, 0, 52, 28, false)
ToggleTrack.Position = UDim2.new(1, -66, 0, 26)
ToggleTrack.AnchorPoint = Vector2.new(0, 0)
local CountCard = Card(34, 3)
local CountLabel = Instance.new("TextLabel")
CountLabel.Size               = UDim2.new(1, -60, 1, 0)
CountLabel.Position           = UDim2.new(0, 14, 0, 0)
CountLabel.BackgroundTransparency = 1
CountLabel.Text               = "Highlighted: 0 players"
CountLabel.TextColor3         = Color3.fromRGB(130, 130, 175)
CountLabel.TextSize           = 12
CountLabel.Font               = Enum.Font.GothamSemibold
CountLabel.TextXAlignment     = Enum.TextXAlignment.Left
CountLabel.Parent             = CountCard
local CountBadge = Instance.new("TextLabel")
CountBadge.Size               = UDim2.new(0, 32, 0, 22)
CountBadge.Position           = UDim2.new(1, -42, 0.5, -11)
CountBadge.BackgroundColor3   = Color3.fromRGB(120, 60, 220)
CountBadge.Text               = "0"
CountBadge.TextColor3         = Color3.fromRGB(255, 255, 255)
CountBadge.TextSize           = 12
CountBadge.Font               = Enum.Font.GothamBold
CountBadge.Parent             = CountCard
Instance.new("UICorner", CountBadge).CornerRadius = UDim.new(0, 6)
Section("HIGHLIGHT COLOR", 4)
local ColorCard = Card(118, 5)
local ColorPreview = Instance.new("Frame")
ColorPreview.Size             = UDim2.new(1, -28, 0, 32)
ColorPreview.Position         = UDim2.new(0, 14, 0, 10)
ColorPreview.BackgroundColor3 = getColor().fill
ColorPreview.BorderSizePixel  = 0
ColorPreview.Parent           = ColorCard
Instance.new("UICorner", ColorPreview).CornerRadius = UDim.new(0, 8)
local ColorPreviewGrad = Instance.new("UIGradient")
ColorPreviewGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180,180,180)),
})
ColorPreviewGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(1, 0),
})
ColorPreviewGrad.Rotation = 90
ColorPreviewGrad.Parent = ColorPreview
local ColorName = Instance.new("TextLabel")
ColorName.Size               = UDim2.new(1, 0, 1, 0)
ColorName.BackgroundTransparency = 1
ColorName.Text               = getColor().name
ColorName.TextColor3         = Color3.fromRGB(255, 255, 255)
ColorName.TextSize           = 14
ColorName.Font               = Enum.Font.GothamBold
ColorName.TextStrokeTransparency = 0.4
ColorName.Parent             = ColorPreview
local PrevColorBtn = Instance.new("TextButton")
PrevColorBtn.Size             = UDim2.new(0, 38, 0, 36)
PrevColorBtn.Position         = UDim2.new(0, 14, 0, 54)
PrevColorBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
PrevColorBtn.Text             = "<"
PrevColorBtn.TextColor3       = Color3.fromRGB(180, 160, 255)
PrevColorBtn.TextSize         = 16
PrevColorBtn.Font             = Enum.Font.GothamBold
PrevColorBtn.BorderSizePixel  = 0
PrevColorBtn.Parent           = ColorCard
Instance.new("UICorner", PrevColorBtn).CornerRadius = UDim.new(0, 8)
local ColorIndexLabel = Instance.new("TextLabel")
ColorIndexLabel.Size               = UDim2.new(1, -128, 0, 36)
ColorIndexLabel.Position           = UDim2.new(0, 60, 0, 54)
ColorIndexLabel.BackgroundTransparency = 1
ColorIndexLabel.Text               = "1 / " .. #CONFIG.Colors
ColorIndexLabel.TextColor3         = Color3.fromRGB(130, 120, 170)
ColorIndexLabel.TextSize           = 12
ColorIndexLabel.Font               = Enum.Font.GothamSemibold
ColorIndexLabel.Parent             = ColorCard
local NextColorBtn = Instance.new("TextButton")
NextColorBtn.Size             = UDim2.new(0, 38, 0, 36)
NextColorBtn.Position         = UDim2.new(1, -52, 0, 54)
NextColorBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
NextColorBtn.Text             = ">"
NextColorBtn.TextColor3       = Color3.fromRGB(180, 160, 255)
NextColorBtn.TextSize         = 16
NextColorBtn.Font             = Enum.Font.GothamBold
NextColorBtn.BorderSizePixel  = 0
NextColorBtn.Parent           = ColorCard
Instance.new("UICorner", NextColorBtn).CornerRadius = UDim.new(0, 8)
local RainbowBadge = Instance.new("TextLabel")
RainbowBadge.Size               = UDim2.new(0, 60, 0, 18)
RainbowBadge.Position           = UDim2.new(0.5, -30, 0, 96)
RainbowBadge.BackgroundColor3   = Color3.fromRGB(35, 35, 52)
RainbowBadge.Text               = "RAINBOW"
RainbowBadge.TextColor3         = Color3.fromRGB(255, 200, 255)
RainbowBadge.TextSize           = 8
RainbowBadge.Font               = Enum.Font.GothamBold
RainbowBadge.Visible            = false
RainbowBadge.Parent             = ColorCard
Instance.new("UICorner", RainbowBadge).CornerRadius = UDim.new(0, 5)
Section("FILL TRANSPARENCY", 6)
local TransCard = Card(60, 7)
local TransValueLabel = Instance.new("TextLabel")
TransValueLabel.Size               = UDim2.new(1, -28, 0, 20)
TransValueLabel.Position           = UDim2.new(0, 14, 0, 8)
TransValueLabel.BackgroundTransparency = 1
TransValueLabel.Text               = "Fill: " .. math.floor((1-State.fillTrans)*100) .. "%"
TransValueLabel.TextColor3         = Color3.fromRGB(170, 160, 210)
TransValueLabel.TextSize           = 11
TransValueLabel.Font               = Enum.Font.GothamSemibold
TransValueLabel.TextXAlignment     = Enum.TextXAlignment.Left
TransValueLabel.Parent             = TransCard
local SliderBg = Instance.new("Frame")
SliderBg.Size             = UDim2.new(1, -28, 0, 8)
SliderBg.Position         = UDim2.new(0, 14, 0, 38)
SliderBg.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
SliderBg.BorderSizePixel  = 0
SliderBg.Parent           = TransCard
Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
local SliderFill = Instance.new("Frame")
SliderFill.Size             = UDim2.new(1 - State.fillTrans, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
SliderFill.BorderSizePixel  = 0
SliderFill.Parent           = SliderBg
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
local SliderGrad = Instance.new("UIGradient")
SliderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 255)),
})
SliderGrad.Parent = SliderFill
local SliderKnob = Instance.new("Frame")
SliderKnob.Size             = UDim2.new(0, 16, 0, 16)
SliderKnob.AnchorPoint      = Vector2.new(0.5, 0.5)
SliderKnob.Position         = UDim2.new(1 - State.fillTrans, 0, 0.5, 0)
SliderKnob.BackgroundColor3 = Color3.fromRGB(230, 220, 255)
SliderKnob.BorderSizePixel  = 0
SliderKnob.ZIndex           = 4
SliderKnob.Parent           = SliderBg
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)
local KnobStroke = Instance.new("UIStroke")
KnobStroke.Color     = Color3.fromRGB(120, 60, 220)
KnobStroke.Thickness = 2
KnobStroke.Parent    = SliderKnob
Section("OUTLINE TRANSPARENCY", 8)
local OutlineCard = Card(60, 9)
local OutlineValueLabel = Instance.new("TextLabel")
OutlineValueLabel.Size               = UDim2.new(1, -28, 0, 20)
OutlineValueLabel.Position           = UDim2.new(0, 14, 0, 8)
OutlineValueLabel.BackgroundTransparency = 1
OutlineValueLabel.Text               = "Outline: " .. math.floor((1-State.outlineTrans)*100) .. "%"
OutlineValueLabel.TextColor3         = Color3.fromRGB(170, 160, 210)
OutlineValueLabel.TextSize           = 11
OutlineValueLabel.Font               = Enum.Font.GothamSemibold
OutlineValueLabel.TextXAlignment     = Enum.TextXAlignment.Left
OutlineValueLabel.Parent             = OutlineCard
local OSliderBg = Instance.new("Frame")
OSliderBg.Size             = UDim2.new(1, -28, 0, 8)
OSliderBg.Position         = UDim2.new(0, 14, 0, 38)
OSliderBg.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
OSliderBg.BorderSizePixel  = 0
OSliderBg.Parent           = OutlineCard
Instance.new("UICorner", OSliderBg).CornerRadius = UDim.new(1, 0)
local OSliderFill = Instance.new("Frame")
OSliderFill.Size             = UDim2.new(1 - State.outlineTrans, 0, 1, 0)
OSliderFill.BackgroundColor3 = Color3.fromRGB(255, 100, 200)
OSliderFill.BorderSizePixel  = 0
OSliderFill.Parent           = OSliderBg
Instance.new("UICorner", OSliderFill).CornerRadius = UDim.new(1, 0)
local OSliderGrad = Instance.new("UIGradient")
OSliderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 80, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
})
OSliderGrad.Parent = OSliderFill
local OSliderKnob = Instance.new("Frame")
OSliderKnob.Size             = UDim2.new(0, 16, 0, 16)
OSliderKnob.AnchorPoint      = Vector2.new(0.5, 0.5)
OSliderKnob.Position         = UDim2.new(1 - State.outlineTrans, 0, 0.5, 0)
OSliderKnob.BackgroundColor3 = Color3.fromRGB(230, 220, 255)
OSliderKnob.BorderSizePixel  = 0
OSliderKnob.ZIndex           = 4
OSliderKnob.Parent           = OSliderBg
Instance.new("UICorner", OSliderKnob).CornerRadius = UDim.new(1, 0)
local OKnobStroke = Instance.new("UIStroke")
OKnobStroke.Color     = Color3.fromRGB(255, 100, 200)
OKnobStroke.Thickness = 2
OKnobStroke.Parent    = OSliderKnob
Section("PLAYER TAGS", 10)
local TagCard = Card(140, 11)
local NamesLabel = Instance.new("TextLabel")
NamesLabel.Size               = UDim2.new(1, -80, 0, 30)
NamesLabel.Position           = UDim2.new(0, 14, 0, 8)
NamesLabel.BackgroundTransparency = 1
NamesLabel.Text               = "Show names"
NamesLabel.TextColor3         = Color3.fromRGB(170, 160, 210)
NamesLabel.TextSize           = 12
NamesLabel.Font               = Enum.Font.GothamSemibold
NamesLabel.TextXAlignment     = Enum.TextXAlignment.Left
NamesLabel.Parent             = TagCard
local NamesTrack, NamesKnob, NamesHit = MakeToggle(TagCard, 1, 0, 42, 22, true)
NamesTrack.Position = UDim2.new(1, -56, 0, 12)
NamesTrack.AnchorPoint = Vector2.new(0, 0)
SetToggleVisual(NamesTrack, NamesKnob, State.showNames, 42, 22, true)
if State.showNames then
    NamesTrack.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
    NamesKnob.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
    NamesKnob.Position          = UDim2.new(1, -20, 0.5, -9)
end
local DistLabel = Instance.new("TextLabel")
DistLabel.Size               = UDim2.new(1, -80, 0, 30)
DistLabel.Position           = UDim2.new(0, 14, 0, 46)
DistLabel.BackgroundTransparency = 1
DistLabel.Text               = "Show distance"
DistLabel.TextColor3         = Color3.fromRGB(170, 160, 210)
DistLabel.TextSize           = 12
DistLabel.Font               = Enum.Font.GothamSemibold
DistLabel.TextXAlignment     = Enum.TextXAlignment.Left
DistLabel.Parent             = TagCard
local DistTrack, DistKnob, DistHit = MakeToggle(TagCard, 1, 0, 42, 22, true)
DistTrack.Position = UDim2.new(1, -56, 0, 50)
DistTrack.AnchorPoint = Vector2.new(0, 0)
SetToggleVisual(DistTrack, DistKnob, State.showDistance, 42, 22, true)
if State.showDistance then
    DistTrack.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
    DistKnob.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
    DistKnob.Position          = UDim2.new(1, -20, 0.5, -9)
end
local TagSizeLabel = Instance.new("TextLabel")
TagSizeLabel.Size               = UDim2.new(1, -28, 0, 20)
TagSizeLabel.Position           = UDim2.new(0, 14, 0, 86)
TagSizeLabel.BackgroundTransparency = 1
TagSizeLabel.Text               = "Text size: " .. State.nameTagSize
TagSizeLabel.TextColor3         = Color3.fromRGB(170, 160, 210)
TagSizeLabel.TextSize           = 11
TagSizeLabel.Font               = Enum.Font.GothamSemibold
TagSizeLabel.TextXAlignment     = Enum.TextXAlignment.Left
TagSizeLabel.Parent             = TagCard
local TSSliderBg = Instance.new("Frame")
TSSliderBg.Size             = UDim2.new(1, -28, 0, 8)
TSSliderBg.Position         = UDim2.new(0, 14, 0, 114)
TSSliderBg.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
TSSliderBg.BorderSizePixel  = 0
TSSliderBg.Parent           = TagCard
Instance.new("UICorner", TSSliderBg).CornerRadius = UDim.new(1, 0)
local minTS, maxTS = 8, 24
local TSRatio = (State.nameTagSize - minTS) / (maxTS - minTS)
local TSSliderFill = Instance.new("Frame")
TSSliderFill.Size             = UDim2.new(TSRatio, 0, 1, 0)
TSSliderFill.BackgroundColor3 = Color3.fromRGB(255, 160, 80)
TSSliderFill.BorderSizePixel  = 0
TSSliderFill.Parent           = TSSliderBg
Instance.new("UICorner", TSSliderFill).CornerRadius = UDim.new(1, 0)
local TSSliderKnob = Instance.new("Frame")
TSSliderKnob.Size             = UDim2.new(0, 16, 0, 16)
TSSliderKnob.AnchorPoint      = Vector2.new(0.5, 0.5)
TSSliderKnob.Position         = UDim2.new(TSRatio, 0, 0.5, 0)
TSSliderKnob.BackgroundColor3 = Color3.fromRGB(255, 220, 180)
TSSliderKnob.BorderSizePixel  = 0
TSSliderKnob.ZIndex           = 4
TSSliderKnob.Parent           = TSSliderBg
Instance.new("UICorner", TSSliderKnob).CornerRadius = UDim.new(1, 0)
Section("EXCLUDE NICKNAMES", 12)
local ExcNickCard = Card(110, 13)
local ExcNickInput = Instance.new("TextBox")
ExcNickInput.Size               = UDim2.new(1, -80, 0, 32)
ExcNickInput.Position           = UDim2.new(0, 12, 0, 10)
ExcNickInput.BackgroundColor3   = Color3.fromRGB(30, 30, 48)
ExcNickInput.BorderSizePixel    = 0
ExcNickInput.Text               = ""
ExcNickInput.PlaceholderText    = "Enter nickname..."
ExcNickInput.PlaceholderColor3  = Color3.fromRGB(80, 80, 110)
ExcNickInput.TextColor3         = Color3.fromRGB(210, 200, 255)
ExcNickInput.TextSize           = 12
ExcNickInput.Font               = Enum.Font.Gotham
ExcNickInput.ClearTextOnFocus   = false
ExcNickInput.Parent             = ExcNickCard
Instance.new("UICorner", ExcNickInput).CornerRadius = UDim.new(0, 8)
local ExcNickStroke = Instance.new("UIStroke")
ExcNickStroke.Color     = Color3.fromRGB(70, 60, 110)
ExcNickStroke.Thickness = 1
ExcNickStroke.Parent    = ExcNickInput
local ExcAddBtn = Instance.new("TextButton")
ExcAddBtn.Size             = UDim2.new(0, 54, 0, 32)
ExcAddBtn.Position         = UDim2.new(1, -66, 0, 10)
ExcAddBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
ExcAddBtn.Text             = "+ Add"
ExcAddBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
ExcAddBtn.TextSize         = 9
ExcAddBtn.Font             = Enum.Font.GothamBold
ExcAddBtn.BorderSizePixel  = 0
ExcAddBtn.Parent           = ExcNickCard
Instance.new("UICorner", ExcAddBtn).CornerRadius = UDim.new(0, 8)
local ExcListFrame = Instance.new("ScrollingFrame")
ExcListFrame.Size                  = UDim2.new(1, -24, 0, 54)
ExcListFrame.Position              = UDim2.new(0, 12, 0, 50)
ExcListFrame.BackgroundColor3      = Color3.fromRGB(18, 18, 30)
ExcListFrame.BorderSizePixel       = 0
ExcListFrame.ScrollBarThickness    = 2
ExcListFrame.ScrollBarImageColor3  = Color3.fromRGB(120, 60, 220)
ExcListFrame.CanvasSize            = UDim2.new(0, 0, 0, 0)
ExcListFrame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
ExcListFrame.Parent                = ExcNickCard
Instance.new("UICorner", ExcListFrame).CornerRadius = UDim.new(0, 6)
local ExcListLayout = Instance.new("UIListLayout")
ExcListLayout.Padding    = UDim.new(0, 2)
ExcListLayout.SortOrder  = Enum.SortOrder.LayoutOrder
ExcListLayout.Parent     = ExcListFrame
local ExcListPad = Instance.new("UIPadding")
ExcListPad.PaddingTop  = UDim.new(0, 3)
ExcListPad.PaddingLeft = UDim.new(0, 4)
ExcListPad.Parent      = ExcListFrame
local ExcEmptyLabel = Instance.new("TextLabel")
ExcEmptyLabel.Size               = UDim2.new(1, -8, 0, 20)
ExcEmptyLabel.BackgroundTransparency = 1
ExcEmptyLabel.Text               = "List is empty"
ExcEmptyLabel.TextColor3         = Color3.fromRGB(70, 70, 100)
ExcEmptyLabel.TextSize           = 10
ExcEmptyLabel.Font               = Enum.Font.Gotham
ExcEmptyLabel.Parent             = ExcListFrame
local function rebuildExcList()
    for _, ch in ipairs(ExcListFrame:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    local count = 0
    for name, _ in pairs(State.excludedNames) do
        count = count + 1
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, -6, 0, 18)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
        row.BorderSizePixel  = 0
        row.Parent           = ExcListFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
        local nl = Instance.new("TextLabel")
        nl.Size               = UDim2.new(1, -28, 1, 0)
        nl.Position           = UDim2.new(0, 6, 0, 0)
        nl.BackgroundTransparency = 1
        nl.Text               = name
        nl.TextColor3         = Color3.fromRGB(200, 180, 255)
        nl.TextSize           = 10
        nl.Font               = Enum.Font.GothamSemibold
        nl.TextXAlignment     = Enum.TextXAlignment.Left
        nl.Parent             = row
        local rb = Instance.new("TextButton")
        rb.Size               = UDim2.new(0, 20, 0, 16)
        rb.Position           = UDim2.new(1, -22, 0.5, -8)
        rb.BackgroundColor3   = Color3.fromRGB(160, 40, 40)
        rb.Text               = "X"
        rb.TextColor3         = Color3.fromRGB(255, 255, 255)
        rb.TextSize           = 9
        rb.Font               = Enum.Font.GothamBold
        rb.BorderSizePixel    = 0
        rb.Parent             = row
        Instance.new("UICorner", rb).CornerRadius = UDim.new(0, 4)
        local capName = name
        rb.MouseButton1Click:Connect(function()
            State.excludedNames[capName] = nil
            rebuildExcList()
            if State.enabled then
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Name == capName then
                        createHighlight(pl)
                    end
                end
            end
        end)
    end
    ExcEmptyLabel.Visible = (count == 0)
end
Section("GENERAL SETTINGS", 14)
local SettCard = Card(52, 15)
local ExcludeLabel = Instance.new("TextLabel")
ExcludeLabel.Size               = UDim2.new(1, -70, 1, 0)
ExcludeLabel.Position           = UDim2.new(0, 14, 0, 0)
ExcludeLabel.BackgroundTransparency = 1
ExcludeLabel.Text               = "Exclude self from ESP"
ExcludeLabel.TextColor3         = Color3.fromRGB(170, 160, 210)
ExcludeLabel.TextSize           = 12
ExcludeLabel.Font               = Enum.Font.GothamSemibold
ExcludeLabel.TextXAlignment     = Enum.TextXAlignment.Left
ExcludeLabel.Parent             = SettCard
local ExcludeTrack, ExcludeKnob, ExcludeHit = MakeToggle(SettCard, 1, 0, 42, 22, true)
ExcludeTrack.Position  = UDim2.new(1, -56, 0.5, -11)
ExcludeTrack.AnchorPoint = Vector2.new(0, 0)
Section("INFO", 16)
local InfoCard = Card(66, 17)
local InfoText = Instance.new("TextLabel")
InfoText.Size               = UDim2.new(1, -28, 1, -10)
InfoText.Position           = UDim2.new(0, 14, 0, 5)
InfoText.BackgroundTransparency = 1
InfoText.Text               = "DERNOZ ESP v3.0\nHighlight via Highlight instance\nRainbow is the last color\nF2 - hide/show menu"
InfoText.TextColor3         = Color3.fromRGB(90, 85, 130)
InfoText.TextSize           = 10
InfoText.Font               = Enum.Font.Gotham
InfoText.TextXAlignment     = Enum.TextXAlignment.Left
InfoText.TextYAlignment     = Enum.TextYAlignment.Top
InfoText.Parent             = InfoCard
local function updateCount()
    local n = 0
    for _ in pairs(State.highlights) do n = n + 1 end
    CountLabel.Text = "Highlighted: " .. n .. " plr."
    CountBadge.Text = tostring(n)
end
function applyColorToAll()
    local col = getColor()
    local isRainbow = (State.colorIndex == #CONFIG.Colors)
    RainbowBadge.Visible = isRainbow
    for player, hl in pairs(State.highlights) do
        if not isRainbow then
            hl.FillColor    = col.fill
            hl.OutlineColor = col.outline
        end
        hl.FillTransparency    = State.fillTrans
        hl.OutlineTransparency = State.outlineTrans
        local bb = State.billboards[player]
        if bb then
            local lbl = bb:FindFirstChildOfClass("TextLabel")
            if lbl and not isRainbow then
                lbl.TextColor3 = col.fill
            end
        end
    end
    if not isRainbow then
        ColorPreview.BackgroundColor3 = col.fill
        ColorName.Text = col.name
    else
        ColorName.Text = "Rainbow"
    end
    ColorIndexLabel.Text = State.colorIndex .. " / " .. #CONFIG.Colors
end
function createHighlight(player)
    if State.highlights[player] then return end
    if isExcluded(player) then return end
    local char = player.Character
    if not char then return end
    local col = getColor()
    local isRainbow = (State.colorIndex == #CONFIG.Colors)
    local hl = Instance.new("Highlight")
    hl.FillColor           = isRainbow and getRainbowColor() or col.fill
    hl.OutlineColor        = isRainbow and getRainbowColor() or col.outline
    hl.FillTransparency    = State.fillTrans
    hl.OutlineTransparency = State.outlineTrans
    hl.Adornee             = char
    hl.Parent              = ScreenGui
    State.highlights[player] = hl
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and State.showNames then
        local bb = Instance.new("BillboardGui")
        bb.Size        = UDim2.new(0, 140, 0, 30)
        bb.StudsOffset = Vector3.new(0, 3.6, 0)
        bb.AlwaysOnTop = true
        bb.Adornee     = hrp
        bb.Parent      = ScreenGui
        local nl = Instance.new("TextLabel")
        nl.Size                   = UDim2.new(1, 0, 1, 0)
        nl.BackgroundTransparency = 1
        nl.Text                   = player.Name .. getDistanceStr(player)
        nl.TextColor3             = isRainbow and getRainbowColor() or col.fill
        nl.TextSize               = State.nameTagSize
        nl.Font                   = Enum.Font.GothamBold
        nl.TextStrokeTransparency = 0.3
        nl.Parent                 = bb
        State.billboards[player] = bb
    end
    updateCount()
end
function removeHighlight(player)
    if State.highlights[player] then
        State.highlights[player]:Destroy()
        State.highlights[player] = nil
    end
    if State.billboards[player] then
        State.billboards[player]:Destroy()
        State.billboards[player] = nil
    end
    updateCount()
end
local function refreshAll()
    for _, player in ipairs(Players:GetPlayers()) do
        removeHighlight(player)
        if State.enabled then
            createHighlight(player)
        end
    end
end
local drag = {active = false, start = Vector2.new(), startPos = UDim2.new()}
RunService.RenderStepped:Connect(function()
    if State.enabled and State.colorIndex == #CONFIG.Colors then
        local rc = getRainbowColor()
        for player, hl in pairs(State.highlights) do
            hl.FillColor    = rc
            hl.OutlineColor = rc
            local bb = State.billboards[player]
            if bb then
                local lbl = bb:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.TextColor3 = rc end
            end
        end
        ColorPreview.BackgroundColor3 = rc
    end
    if State.enabled and State.showDistance then
        for player, bb in pairs(State.billboards) do
            local lbl = bb:FindFirstChildOfClass("TextLabel")
            if lbl then
                lbl.Text = player.Name .. getDistanceStr(player)
            end
        end
    end
    if drag.active then
        local m  = UserInputService:GetMouseLocation()
        local d  = m - drag.start
        local np = UDim2.new(
            drag.startPos.X.Scale, drag.startPos.X.Offset + d.X,
            drag.startPos.Y.Scale, drag.startPos.Y.Offset + d.Y
        )
        Main.Position   = np
        Shadow.Position = UDim2.new(
            drag.startPos.X.Scale, drag.startPos.X.Offset + d.X,
            drag.startPos.Y.Scale, drag.startPos.Y.Offset + d.Y - 5
        )
    end
end)
local function setToggleVisualMain(on)
    SetToggleVisual(ToggleTrack, ToggleKnob, on, 52, 28, false)
    StatusDot.BackgroundColor3 = on and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(200, 50, 50)
    StatusLabel.Text = on and "ENABLED" or "DISABLED"
    StatusLabel.TextColor3 = on and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(200, 50, 50)
end
local function setEnabled(on)
    State.enabled = on
    setToggleVisualMain(on)
    refreshAll()
end
ToggleHit.MouseButton1Click:Connect(function()
    setEnabled(not State.enabled)
end)
ExcludeHit.MouseButton1Click:Connect(function()
    State.excludeSelf = not State.excludeSelf
    SetToggleVisual(ExcludeTrack, ExcludeKnob, State.excludeSelf, 42, 22, true)
    if State.enabled then
        if State.excludeSelf then
            removeHighlight(LocalPlayer)
        else
            createHighlight(LocalPlayer)
        end
    end
end)
NamesHit.MouseButton1Click:Connect(function()
    State.showNames = not State.showNames
    SetToggleVisual(NamesTrack, NamesKnob, State.showNames, 42, 22, true)
    if State.enabled then refreshAll() end
end)
DistHit.MouseButton1Click:Connect(function()
    State.showDistance = not State.showDistance
    SetToggleVisual(DistTrack, DistKnob, State.showDistance, 42, 22, true)
end)
local function changeColor(dir)
    State.colorIndex = ((State.colorIndex - 1 + dir) % #CONFIG.Colors) + 1
    applyColorToAll()
end
PrevColorBtn.MouseButton1Click:Connect(function() changeColor(-1) end)
NextColorBtn.MouseButton1Click:Connect(function() changeColor(1)  end)
for _, btn in ipairs({PrevColorBtn, NextColorBtn}) do
    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(55, 50, 80)}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(35, 35, 52)}, 0.15)
    end)
end
local sliderFillActive = false
local function applyFillSlider(ratio)
    ratio = math.clamp(ratio, 0, 1)
    State.fillTrans = 1 - ratio
    SliderFill.Size       = UDim2.new(ratio, 0, 1, 0)
    SliderKnob.Position   = UDim2.new(ratio, 0, 0.5, 0)
    TransValueLabel.Text  = "Fill: " .. math.floor(ratio * 100) .. "%"
    for _, hl in pairs(State.highlights) do
        hl.FillTransparency = State.fillTrans
    end
end
SliderBg.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderFillActive = true
        applyFillSlider((inp.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X)
    end
end)
local sliderOutlineActive = false
local function applyOutlineSlider(ratio)
    ratio = math.clamp(ratio, 0, 1)
    State.outlineTrans = 1 - ratio
    OSliderFill.Size      = UDim2.new(ratio, 0, 1, 0)
    OSliderKnob.Position  = UDim2.new(ratio, 0, 0.5, 0)
    OutlineValueLabel.Text = "Outline: " .. math.floor(ratio * 100) .. "%"
    for _, hl in pairs(State.highlights) do
        hl.OutlineTransparency = State.outlineTrans
    end
end
OSliderBg.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderOutlineActive = true
        applyOutlineSlider((inp.Position.X - OSliderBg.AbsolutePosition.X) / OSliderBg.AbsoluteSize.X)
    end
end)
local sliderTSActive = false
local function applyTSSlider(ratio)
    ratio = math.clamp(ratio, 0, 1)
    State.nameTagSize = math.floor(minTS + ratio * (maxTS - minTS))
    TSSliderFill.Size     = UDim2.new(ratio, 0, 1, 0)
    TSSliderKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
    TagSizeLabel.Text = "Text size: " .. State.nameTagSize
    for _, bb in pairs(State.billboards) do
        local lbl = bb:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.TextSize = State.nameTagSize end
    end
end
TSSliderBg.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderTSActive = true
        applyTSSlider((inp.Position.X - TSSliderBg.AbsolutePosition.X) / TSSliderBg.AbsoluteSize.X)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderFillActive    = false
        sliderOutlineActive = false
        sliderTSActive      = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if sliderFillActive then
        applyFillSlider((inp.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X)
    end
    if sliderOutlineActive then
        applyOutlineSlider((inp.Position.X - OSliderBg.AbsolutePosition.X) / OSliderBg.AbsoluteSize.X)
    end
    if sliderTSActive then
        applyTSSlider((inp.Position.X - TSSliderBg.AbsolutePosition.X) / TSSliderBg.AbsoluteSize.X)
    end
end)
ExcAddBtn.MouseButton1Click:Connect(function()
    local name = ExcNickInput.Text:match("^%s*(.-)%s*$")
    if name == "" then return end
    State.excludedNames[name] = true
    ExcNickInput.Text = ""
    rebuildExcList()
    if State.enabled then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Name == name then
                removeHighlight(pl)
            end
        end
    end
end)
rebuildExcList()
local FULL_HEIGHT   = 530
local MINI_HEIGHT   = 59
local minimized     = false
local guiDestroyed  = false
local function showMenu(instant)
    State.menuVisible = true
    local h = minimized and MINI_HEIGHT or FULL_HEIGHT
    if instant then
        Main.Size   = UDim2.new(0, 270, 0, h)
        Shadow.Size = UDim2.new(0, 290, 0, h + 20)
        Main.BackgroundTransparency = 0
        Shadow.ImageTransparency    = 0.55
    else
        tween(Main,   {Size = UDim2.new(0, 270, 0, h), BackgroundTransparency = 0}, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween(Shadow, {Size = UDim2.new(0, 290, 0, h+20), ImageTransparency = 0.55}, 0.32)
    end
end
local function hideMenu()
    State.menuVisible = false
    tween(Main,   {Size = UDim2.new(0, 270, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quart)
    tween(Shadow, {ImageTransparency = 1, Size = UDim2.new(0, 290, 0, 0)}, 0.25)
end
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if guiDestroyed then return end
    if inp.KeyCode == CONFIG.Hotkey then
        setEnabled(not State.enabled)
    elseif inp.KeyCode == CONFIG.MenuHotkey then
        if State.menuVisible then
            hideMenu()
        else
            showMenu(false)
        end
    end
end)
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local h = minimized and MINI_HEIGHT or FULL_HEIGHT
    MinBtn.Text = minimized and "+" or "-"
    tween(Main,   {Size = UDim2.new(0, 270, 0, h)}, 0.28, Enum.EasingStyle.Quart)
    tween(Shadow, {Size = UDim2.new(0, 290, 0, h+20)}, 0.28, Enum.EasingStyle.Quart)
end)
CloseBtn.MouseButton1Click:Connect(function()
    guiDestroyed = true
    setEnabled(false)
    tween(Main,   {Size = UDim2.new(0, 270, 0, 0), BackgroundTransparency = 1}, 0.22)
    tween(Shadow, {ImageTransparency = 1}, 0.22)
    task.delay(0.3, function() ScreenGui:Destroy() end)
end)
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        drag.active   = true
        drag.start    = Vector2.new(inp.Position.X, inp.Position.Y)
        drag.startPos = Main.Position
    end
end)
Header.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        drag.active = false
    end
end)
local function hookPlayer(player)
    if State.charConnections[player] then
        State.charConnections[player]:Disconnect()
    end
    State.charConnections[player] = player.CharacterAdded:Connect(function()
        removeHighlight(player)
        task.wait(0.15)
        if State.enabled then createHighlight(player) end
    end)
    if State.enabled and player.Character then
        createHighlight(player)
    end
end
Players.PlayerAdded:Connect(function(player) hookPlayer(player) end)
Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
    if State.charConnections[player] then
        State.charConnections[player]:Disconnect()
        State.charConnections[player] = nil
    end
end)
for _, player in ipairs(Players:GetPlayers()) do hookPlayer(player) end
Main.Size                   = UDim2.new(0, 270, 0, 0)
Main.BackgroundTransparency = 1
Shadow.ImageTransparency    = 1
Shadow.Size                 = UDim2.new(0, 290, 0, 0)
task.delay(0.1, function()
    showMenu(false)
end)
