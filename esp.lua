-- DERNOZ secure entry
local KEY = _G.DERNOZ_KEY or (getgenv and getgenv().DERNOZ_KEY)
if not KEY or KEY == "" then
    return warn("[Dernoz] Не указан ключ. Используй загрузчик из бота.")
end

local KEYS_URL = "https://raw.githubusercontent.com/Dernoz/dernoz/main/keys.json"
local ok, raw = pcall(function() return game:HttpGet(KEYS_URL) end)
if not ok or not raw then
    return warn("[Dernoz] Не удалось проверить ключ (нет связи).")
end

local HttpService = game:GetService("HttpService")
local okj, keys = pcall(function() return HttpService:JSONDecode(raw) end)
if not okj or type(keys) ~= "table" then
    return warn("[Dernoz] Ошибка данных ключей.")
end

local info = keys[KEY]
if not info then return warn("[Dernoz] Неверный ключ.") end
if info.ban then return warn("[Dernoz] Ключ заблокирован.") end
if info.exp and info.exp ~= 0 and (os.time()*1000) > info.exp then
    return warn("[Dernoz] Срок действия ключа истёк.")
end

-- ═══════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════
--  CONFIG — 20 цветов
-- ═══════════════════════════════════════════
local CONFIG = {
    Colors = {
        { name="Orange",   fill=Color3.fromRGB(255,160,0),   outline=Color3.fromRGB(220,80,0)    },
        { name="Red",      fill=Color3.fromRGB(255,50,50),   outline=Color3.fromRGB(180,0,0)     },
        { name="Blue",     fill=Color3.fromRGB(60,140,255),  outline=Color3.fromRGB(0,80,220)    },
        { name="Green",    fill=Color3.fromRGB(50,220,100),  outline=Color3.fromRGB(0,150,50)    },
        { name="Purple",   fill=Color3.fromRGB(180,80,255),  outline=Color3.fromRGB(120,0,200)   },
        { name="White",    fill=Color3.fromRGB(240,240,255), outline=Color3.fromRGB(160,160,200) },
        { name="Pink",     fill=Color3.fromRGB(255,100,180), outline=Color3.fromRGB(200,0,120)   },
        { name="Cyan",     fill=Color3.fromRGB(0,220,220),   outline=Color3.fromRGB(0,150,180)   },
        { name="Gold",     fill=Color3.fromRGB(255,210,0),   outline=Color3.fromRGB(200,150,0)   },
        { name="Lime",     fill=Color3.fromRGB(120,255,0),   outline=Color3.fromRGB(70,180,0)    },
        { name="Aqua",     fill=Color3.fromRGB(0,255,200),   outline=Color3.fromRGB(0,180,140)   },
        { name="Coral",    fill=Color3.fromRGB(255,100,80),  outline=Color3.fromRGB(200,50,30)   },
        { name="Lavender", fill=Color3.fromRGB(200,180,255), outline=Color3.fromRGB(140,100,220) },
        { name="Mint",     fill=Color3.fromRGB(100,255,200), outline=Color3.fromRGB(0,200,140)   },
        { name="Rose",     fill=Color3.fromRGB(255,80,120),  outline=Color3.fromRGB(180,0,60)    },
        { name="Sky",      fill=Color3.fromRGB(100,200,255), outline=Color3.fromRGB(0,140,220)   },
        { name="Amber",    fill=Color3.fromRGB(255,180,0),   outline=Color3.fromRGB(200,120,0)   },
        { name="Magenta",  fill=Color3.fromRGB(255,0,200),   outline=Color3.fromRGB(180,0,140)   },
        { name="Teal",     fill=Color3.fromRGB(0,180,160),   outline=Color3.fromRGB(0,120,110)   },
        { name="Rainbow",  fill=Color3.fromRGB(255,255,255), outline=Color3.fromRGB(200,200,200) },
    },
}

-- ═══════════════════════════════════════════
--  TOOLTIPS (русский)
-- ═══════════════════════════════════════════
local TIPS = {
    ToggleHit     = "Включить / выключить ESP подсветку игроков",
    PrevBtn       = "Предыдущий цвет подсветки",
    NextBtn       = "Следующий цвет подсветки",
    SliderBg      = "Прозрачность заливки: 0% = невидимо, 100% = полная заливка",
    OSliderBg     = "Прозрачность обводки: 0% = невидимо, 100% = полная обводка",
    TSBg          = "Размер текста имени над игроком",
    NamesHit      = "Показывать / скрывать ник игрока над головой",
    DistHit       = "Показывать / скрывать дистанцию до игрока",
    HealthHit     = "Показывать / скрывать здоровье игрока",
    ToolHit       = "Показывать / скрывать предмет в руках игрока",
    ESPBindBtn    = "Нажми чтобы переназначить клавишу включения ESP",
    MenuBindBtn   = "Нажми чтобы переназначить клавишу открытия меню",
    ExcAddBtn     = "Добавить игрока в список исключений (ESP не будет на нём)",
    ExcSelfHit    = "Не подсвечивать самого себя",
    MinBtn        = "Свернуть / развернуть меню",
    CloseBtn      = "Закрыть меню (ESP продолжит работу если включён)",
}

-- ═══════════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════════
local State = {
    enabled         = false,
    menuVisible     = true,
    minimized       = false,
    guiDestroyed    = false,
    colorIndex      = 1,
    fillTrans       = 0.45,
    outlineTrans    = 0,
    excludeSelf     = false,
    showNames       = true,
    showDistance    = true,
    showHealth      = true,
    showTool        = true,
    nameTagSize     = 13,
    excludedNames   = {},
    highlights      = {},
    billboards      = {},
    charConnections = {},
    rainbowHue      = 0,
    bindingKey      = nil,
    espKey          = Enum.KeyCode.X,
    menuKey         = Enum.KeyCode.F2,
}

local minTS, maxTS = 8, 24

-- ═══════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════
local function tw(obj, props, t, style, dir)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj,
        TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quart,
            dir or Enum.EasingDirection.Out), props):Play()
end

local function isExcluded(p)
    if State.excludeSelf and p == LocalPlayer then return true end
    return State.excludedNames[p.Name] == true
end

local function getRainbow()
    State.rainbowHue = (State.rainbowHue + 0.002) % 1
    return Color3.fromHSV(State.rainbowHue, 1, 1)
end

local function getColor()  return CONFIG.Colors[State.colorIndex] end
local function isRainbow() return State.colorIndex == #CONFIG.Colors end

local function buildTag(player)
    local parts = {}
    if State.showNames    then table.insert(parts, player.Name) end
    if State.showDistance then
        local lc = LocalPlayer.Character
        local pc = player.Character
        if lc and pc then
            local lh = lc:FindFirstChild("HumanoidRootPart")
            local ph = pc:FindFirstChild("HumanoidRootPart")
            if lh and ph then
                table.insert(parts,
                    " [" .. math.floor((lh.Position-ph.Position).Magnitude) .. "m]")
            end
        end
    end
    if State.showHealth then
        local pc = player.Character
        if pc then
            local hum = pc:FindFirstChildOfClass("Humanoid")
            if hum then
                table.insert(parts, " ❤" .. math.floor(hum.Health))
            end
        end
    end
    if State.showTool then
        local pc = player.Character
        if pc then
            local tool = pc:FindFirstChildOfClass("Tool")
            if tool then table.insert(parts, " 🔧"..tool.Name) end
        end
    end
    return table.concat(parts)
end

-- ═══════════════════════════════════════════
--  GUI ROOT
-- ═══════════════════════════════════════════
if PlayerGui:FindFirstChild("DernozGui") then
    PlayerGui:FindFirstChild("DernozGui"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "DernozGui"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset  = true
ScreenGui.Parent          = PlayerGui

-- ═══════════════════════════════════════════
--  TOOLTIP WIDGET (сверху по центру)
-- ═══════════════════════════════════════════
local TooltipFrame = Instance.new("Frame")
TooltipFrame.Name               = "Tooltip"
TooltipFrame.AnchorPoint        = Vector2.new(0.5, 0)
TooltipFrame.Position           = UDim2.new(0.5, 0, 0, 8)
TooltipFrame.Size               = UDim2.new(0, 10, 0, 30)
TooltipFrame.BackgroundColor3   = Color3.fromRGB(12, 12, 22)
TooltipFrame.BorderSizePixel    = 0
TooltipFrame.ZIndex             = 50
TooltipFrame.Visible            = false
TooltipFrame.Parent             = ScreenGui
Instance.new("UICorner", TooltipFrame).CornerRadius = UDim.new(0, 10)

local TipStroke = Instance.new("UIStroke")
TipStroke.Color     = Color3.fromRGB(40, 60, 180)
TipStroke.Thickness = 1.5
TipStroke.Parent    = TooltipFrame

local TipGrad = Instance.new("UIGradient")
TipGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(40, 80, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 140, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(40, 80, 255)),
})
TipGrad.Rotation = 0
TipGrad.Parent   = TipStroke

local TipLabel = Instance.new("TextLabel")
TipLabel.Size               = UDim2.new(1, -20, 1, 0)
TipLabel.Position           = UDim2.new(0, 10, 0, 0)
TipLabel.BackgroundTransparency = 1
TipLabel.Text               = ""
TipLabel.TextColor3         = Color3.fromRGB(160, 200, 255)
TipLabel.TextSize           = 11
TipLabel.Font               = Enum.Font.GothamSemibold
TipLabel.TextXAlignment     = Enum.TextXAlignment.Center
TipLabel.ZIndex             = 51
TipLabel.Parent             = TooltipFrame

local TipGradLabel = Instance.new("UIGradient")
TipGradLabel.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(100, 160, 255)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(180, 220, 255)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 160, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(140, 200, 255)),
})
TipGradLabel.Rotation = 0
TipGradLabel.Parent   = TipLabel

local tipVisible   = false
local tipTargetAlpha = 1

local function showTip(text)
    TipLabel.Text = text
    -- resize to text
    local ts = game:GetService("TextService")
    local sz = ts:GetTextSize(text, 11, Enum.Font.GothamSemibold,
        Vector2.new(600, 30))
    TooltipFrame.Size = UDim2.new(0, sz.X + 24, 0, 30)
    TooltipFrame.Visible = true
    tipVisible = true
    tipTargetAlpha = 0
    tw(TooltipFrame, {BackgroundTransparency = 0}, 0.18)
    tw(TipLabel, {TextTransparency = 0}, 0.18)
end

local function hideTip()
    tipVisible = false
    tipTargetAlpha = 1
    tw(TooltipFrame, {BackgroundTransparency = 1}, 0.15)
    tw(TipLabel, {TextTransparency = 1}, 0.15)
    task.delay(0.2, function()
        if not tipVisible then
            TooltipFrame.Visible = false
        end
    end)
end

local function hookTip(obj, tipKey)
    local tip = TIPS[tipKey]
    if not tip or not obj then return end
    obj.MouseEnter:Connect(function() showTip(tip) end)
    obj.MouseLeave:Connect(function() hideTip() end)
end

-- ═══════════════════════════════════════════
--  SHADOW
-- ═══════════════════════════════════════════
local Shadow = Instance.new("ImageLabel")
Shadow.Name               = "Shadow"
Shadow.AnchorPoint        = Vector2.new(0.5, 0)
Shadow.Size               = UDim2.new(0, 300, 0, 50)
Shadow.Position           = UDim2.new(0.5, 0, 0, 54)
Shadow.BackgroundTransparency = 1
Shadow.Image              = "rbxassetid://6014261993"
Shadow.ImageColor3        = Color3.new(0,0,0)
Shadow.ImageTransparency  = 1
Shadow.ScaleType          = Enum.ScaleType.Slice
Shadow.SliceCenter        = Rect.new(49,49,450,450)
Shadow.ZIndex             = 1
Shadow.Parent             = ScreenGui

-- ═══════════════════════════════════════════
--  MAIN FRAME
-- ═══════════════════════════════════════════
local W      = 278
local FULL_H = 640
local MINI_H = 64
local CENTER  = UDim2.new(0.5, 0, 0, 60)

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.AnchorPoint      = Vector2.new(0.5, 0)
Main.Size             = UDim2.new(0, W, 0, 0)
Main.Position         = CENTER
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.ZIndex           = 2
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color     = Color3.fromRGB(40, 40, 85)
MainStroke.Thickness = 1.5
MainStroke.Parent    = Main

-- ═══════════════════════════════════════════
--  HEADER
-- ═══════════════════════════════════════════
local Header = Instance.new("Frame")
Header.Name             = "Header"
Header.Size             = UDim2.new(1, 0, 0, 64)
Header.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
Header.BorderSizePixel  = 0
Header.ZIndex           = 3
Header.Parent           = Main

local HGrad = Instance.new("UIGradient")
HGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(22, 8,  50)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(12, 12, 30)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 10, 18)),
})
HGrad.Rotation = 90
HGrad.Parent   = Header

-- Accent top line
local Accent = Instance.new("Frame")
Accent.Size             = UDim2.new(1, 0, 0, 2)
Accent.BackgroundColor3 = Color3.fromRGB(60, 80, 255)
Accent.BorderSizePixel  = 0
Accent.ZIndex           = 4
Accent.Parent           = Main
Instance.new("UIGradient", Accent).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(40,  60,  220)),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(80,  140, 255)),
    ColorSequenceKeypoint.new(0.65, Color3.fromRGB(60,  100, 255)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(40,  60,  220)),
})

-- Animated DERNOZ title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size               = UDim2.new(0, 130, 0, 38)
TitleLabel.Position           = UDim2.new(0, 14, 0, 6)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text               = "DERNOZ"
TitleLabel.TextColor3         = Color3.fromRGB(80, 140, 255)
TitleLabel.TextSize           = 24
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
TitleLabel.ZIndex             = 4
TitleLabel.Parent             = Header

local TitleAnimGrad = Instance.new("UIGradient")
TitleAnimGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(40,  80,  255)),
    ColorSequenceKeypoint.new(0.3,  Color3.fromRGB(100, 180, 255)),
    ColorSequenceKeypoint.new(0.6,  Color3.fromRGB(60,  120, 255)),
    ColorSequenceKeypoint.new(0.85, Color3.fromRGB(120, 200, 255)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(40,  80,  255)),
})
TitleAnimGrad.Rotation = 0
TitleAnimGrad.Parent   = TitleLabel

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size               = UDim2.new(0, 60, 0, 14)
VersionLabel.Position           = UDim2.new(0, 14, 0, 44)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text               = "v3.1 · secure"
VersionLabel.TextColor3         = Color3.fromRGB(45, 55, 110)
VersionLabel.TextSize           = 9
VersionLabel.Font               = Enum.Font.Gotham
VersionLabel.TextXAlignment     = Enum.TextXAlignment.Left
VersionLabel.ZIndex             = 4
VersionLabel.Parent             = Header

-- Header buttons
local function makeHBtn(xOff, bg, txt, txtCol)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 26, 0, 26)
    b.Position         = UDim2.new(1, xOff, 0, 19)
    b.BackgroundColor3 = bg
    b.Text             = txt
    b.TextColor3       = txtCol
    b.TextSize         = 13
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.ZIndex           = 5
    b.Parent           = Header
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    -- hover
    b.MouseEnter:Connect(function()
        tw(b, {BackgroundColor3 = b.BackgroundColor3:Lerp(Color3.fromRGB(255,255,255), 0.15)}, 0.15)
    end)
    b.MouseLeave:Connect(function()
        tw(b, {BackgroundColor3 = bg}, 0.15)
    end)
    return b
end

local MinBtn   = makeHBtn(-62, Color3.fromRGB(30,30,52),  "−",  Color3.fromRGB(160,160,220))
local CloseBtn = makeHBtn(-32, Color3.fromRGB(150,25,25), "✕",  Color3.fromRGB(255,255,255))

hookTip(MinBtn,   "MinBtn")
hookTip(CloseBtn, "CloseBtn")

-- ═══════════════════════════════════════════
--  SCROLL
-- ═══════════════════════════════════════════
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                   = UDim2.new(1, 0, 1, -66)
Scroll.Position               = UDim2.new(0, 0, 0, 66)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel        = 0
Scroll.ScrollBarThickness     = 3
Scroll.ScrollBarImageColor3   = Color3.fromRGB(60, 80, 200)
Scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
Scroll.ZIndex                 = 3
Scroll.Parent                 = Main

local LL = Instance.new("UIListLayout")
LL.Padding             = UDim.new(0, 7)
LL.HorizontalAlignment = Enum.HorizontalAlignment.Center
LL.SortOrder           = Enum.SortOrder.LayoutOrder
LL.Parent              = Scroll

local LP = Instance.new("UIPadding")
LP.PaddingTop    = UDim.new(0, 10)
LP.PaddingBottom = UDim.new(0, 16)
LP.Parent        = Scroll

-- ═══════════════════════════════════════════
--  BUILDERS
-- ═══════════════════════════════════════════
local function Section(txt, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(0.93, 0, 0, 20)
    f.BackgroundTransparency = 1
    f.LayoutOrder      = order
    f.Parent           = Scroll

    local line = Instance.new("Frame")
    line.Size             = UDim2.new(1, 0, 0, 1)
    line.Position         = UDim2.new(0, 0, 0.5, 6)
    line.BackgroundColor3 = Color3.fromRGB(30, 30, 58)
    line.BorderSizePixel  = 0
    line.Parent           = f

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize      = Enum.AutomaticSize.X
    lbl.BackgroundColor3   = Color3.fromRGB(10, 10, 18)
    lbl.BackgroundTransparency = 0
    lbl.Text               = "  "..txt.."  "
    lbl.TextColor3         = Color3.fromRGB(60, 100, 255)
    lbl.TextSize           = 8
    lbl.Font               = Enum.Font.GothamBold
    lbl.Parent             = f
    return f
end

local function Card(h, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(0.93, 0, 0, h)
    f.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order
    f.Parent           = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
    local s = Instance.new("UIStroke")
    s.Color     = Color3.fromRGB(32, 32, 60)
    s.Thickness = 1
    s.Parent    = f
    return f
end

local function Lbl(parent, txt, x, y, w, h2, sz, col, bold, xa)
    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(0, w, 0, h2)
    l.Position           = UDim2.new(0, x, 0, y)
    l.BackgroundTransparency = 1
    l.Text               = txt
    l.TextColor3         = col or Color3.fromRGB(155,148,210)
    l.TextSize           = sz or 12
    l.Font               = bold and Enum.Font.GothamBold or Enum.Font.GothamSemibold
    l.TextXAlignment     = xa or Enum.TextXAlignment.Left
    l.Parent             = parent
    return l
end

-- Toggle (44×24)
local function MkToggle(parent, px, py)
    local tw2,th,ks,ko = 44,24,18,3
    local tr = Instance.new("Frame")
    tr.Size             = UDim2.new(0,tw2,0,th)
    tr.Position         = UDim2.new(0,px,0,py)
    tr.BackgroundColor3 = Color3.fromRGB(35,35,58)
    tr.BorderSizePixel  = 0
    tr.Parent           = parent
    Instance.new("UICorner",tr).CornerRadius = UDim.new(1,0)

    local kn = Instance.new("Frame")
    kn.Size             = UDim2.new(0,ks,0,ks)
    kn.Position         = UDim2.new(0,ko,0.5,-ks/2)
    kn.BackgroundColor3 = Color3.fromRGB(110,110,165)
    kn.BorderSizePixel  = 0
    kn.Parent           = tr
    Instance.new("UICorner",kn).CornerRadius = UDim.new(1,0)

    local hi = Instance.new("TextButton")
    hi.Size               = UDim2.new(1,0,1,0)
    hi.BackgroundTransparency = 1
    hi.Text               = ""
    hi.Parent             = tr
    return tr,kn,hi
end

local function SetToggle(tr,kn,on)
    local ks,ko = 18,3
    tw(kn,{
        Position         = on and UDim2.new(1,-(ks+ko),0.5,-ks/2) or UDim2.new(0,ko,0.5,-ks/2),
        BackgroundColor3 = on and Color3.fromRGB(235,235,255) or Color3.fromRGB(110,110,165),
    },0.2)
    tw(tr,{
        BackgroundColor3 = on and Color3.fromRGB(55,35,190) or Color3.fromRGB(35,35,58),
    },0.2)
end

-- Slider
local function MkSlider(parent, x, y, w2, fillCol, ratio)
    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(0,w2,0,8)
    bg.Position         = UDim2.new(0,x,0,y)
    bg.BackgroundColor3 = Color3.fromRGB(26,26,46)
    bg.BorderSizePixel  = 0
    bg.Parent           = parent
    Instance.new("UICorner",bg).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(ratio,0,1,0)
    fill.BackgroundColor3 = fillCol
    fill.BorderSizePixel  = 0
    fill.Parent           = bg
    Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0,16,0,16)
    knob.AnchorPoint      = Vector2.new(0.5,0.5)
    knob.Position         = UDim2.new(ratio,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(215,210,255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 4
    knob.Parent           = bg
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local ks2 = Instance.new("UIStroke")
    ks2.Color     = fillCol
    ks2.Thickness = 2
    ks2.Parent    = knob
    return bg,fill,knob
end

-- ═══════════════════════════════════════════
--  SECTION 1 · CONTROL
-- ═══════════════════════════════════════════
Section("УПРАВЛЕНИЕ", 1)
local C1 = Card(90, 2)

local StatusDot = Instance.new("Frame")
StatusDot.Size             = UDim2.new(0,10,0,10)
StatusDot.Position         = UDim2.new(0,14,0,14)
StatusDot.BackgroundColor3 = Color3.fromRGB(200,45,45)
StatusDot.BorderSizePixel  = 0
StatusDot.Parent           = C1
Instance.new("UICorner",StatusDot).CornerRadius = UDim.new(1,0)

local StatusLbl = Lbl(C1,"ВЫКЛЮЧЕН",30,10,140,18,12,Color3.fromRGB(200,45,45),true)
Lbl(C1,"Управление ESP и меню — раздел ГОРЯЧИЕ КЛАВИШИ",14,32,230,14,
    9,Color3.fromRGB(50,50,96),false)

local TrTrack,TrKnob,ToggleHit = MkToggle(C1, W-88, 30)
hookTip(ToggleHit,"ToggleHit")

local C2 = Card(36,3)
local CntLbl = Lbl(C2,"Подсвечено: 0 игроков",14,0,180,36,12,
    Color3.fromRGB(100,100,155),false)
local CntBadge = Instance.new("TextLabel")
CntBadge.Size               = UDim2.new(0,34,0,22)
CntBadge.Position           = UDim2.new(1,-46,0.5,-11)
CntBadge.BackgroundColor3   = Color3.fromRGB(45,35,150)
CntBadge.Text               = "0"
CntBadge.TextColor3         = Color3.fromRGB(255,255,255)
CntBadge.TextSize           = 12
CntBadge.Font               = Enum.Font.GothamBold
CntBadge.Parent             = C2
Instance.new("UICorner",CntBadge).CornerRadius = UDim.new(0,7)

-- ═══════════════════════════════════════════
--  SECTION 2 · COLOR
-- ═══════════════════════════════════════════
Section("ЦВЕТ ПОДСВЕТКИ", 4)
local CC = Card(130,5)

local CPrev = Instance.new("Frame")
CPrev.Size             = UDim2.new(1,-28,0,36)
CPrev.Position         = UDim2.new(0,14,0,10)
CPrev.BackgroundColor3 = getColor().fill
CPrev.BorderSizePixel  = 0
CPrev.Parent           = CC
Instance.new("UICorner",CPrev).CornerRadius = UDim.new(0,10)
local CPGrad = Instance.new("UIGradient")
CPGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,0.25),
    NumberSequenceKeypoint.new(1,0),
})
CPGrad.Rotation = 90
CPGrad.Parent   = CPrev

local ColorNameLbl = Instance.new("TextLabel")
ColorNameLbl.Size               = UDim2.new(1,0,1,0)
ColorNameLbl.BackgroundTransparency = 1
ColorNameLbl.Text               = getColor().name
ColorNameLbl.TextColor3         = Color3.fromRGB(255,255,255)
ColorNameLbl.TextSize           = 14
ColorNameLbl.Font               = Enum.Font.GothamBold
ColorNameLbl.TextStrokeTransparency = 0.3
ColorNameLbl.TextXAlignment     = Enum.TextXAlignment.Center
ColorNameLbl.Parent             = CPrev

local PrevBtn = Instance.new("TextButton")
PrevBtn.Size             = UDim2.new(0,42,0,36)
PrevBtn.Position         = UDim2.new(0,14,0,60)
PrevBtn.BackgroundColor3 = Color3.fromRGB(22,22,40)
PrevBtn.Text             = "◀"
PrevBtn.TextColor3       = Color3.fromRGB(80,130,255)
PrevBtn.TextSize         = 14
PrevBtn.Font             = Enum.Font.GothamBold
PrevBtn.BorderSizePixel  = 0
PrevBtn.Parent           = CC
Instance.new("UICorner",PrevBtn).CornerRadius = UDim.new(0,9)

local CIdxLbl = Instance.new("TextLabel")
CIdxLbl.Size               = UDim2.new(1,-120,0,36)
CIdxLbl.Position           = UDim2.new(0,62,0,60)
CIdxLbl.BackgroundTransparency = 1
CIdxLbl.Text               = "1 / "..#CONFIG.Colors
CIdxLbl.TextColor3         = Color3.fromRGB(80,90,150)
CIdxLbl.TextSize           = 11
CIdxLbl.Font               = Enum.Font.GothamSemibold
CIdxLbl.TextXAlignment     = Enum.TextXAlignment.Center
CIdxLbl.Parent             = CC

local NextBtn = Instance.new("TextButton")
NextBtn.Size             = UDim2.new(0,42,0,36)
NextBtn.Position         = UDim2.new(1,-56,0,60)
NextBtn.BackgroundColor3 = Color3.fromRGB(22,22,40)
NextBtn.Text             = "▶"
NextBtn.TextColor3       = Color3.fromRGB(80,130,255)
NextBtn.TextSize         = 14
NextBtn.Font             = Enum.Font.GothamBold
NextBtn.BorderSizePixel  = 0
NextBtn.Parent           = CC
Instance.new("UICorner",NextBtn).CornerRadius = UDim.new(0,9)

local RainbowBadge = Instance.new("TextLabel")
RainbowBadge.Size               = UDim2.new(0,76,0,18)
RainbowBadge.Position           = UDim2.new(0.5,-38,0,106)
RainbowBadge.BackgroundColor3   = Color3.fromRGB(22,22,40)
RainbowBadge.Text               = "✦ RAINBOW"
RainbowBadge.TextColor3         = Color3.fromRGB(255,200,255)
RainbowBadge.TextSize           = 8
RainbowBadge.Font               = Enum.Font.GothamBold
RainbowBadge.Visible            = false
RainbowBadge.Parent             = CC
Instance.new("UICorner",RainbowBadge).CornerRadius = UDim.new(0,5)

hookTip(PrevBtn,"PrevBtn")
hookTip(NextBtn,"NextBtn")

for _,b in ipairs({PrevBtn,NextBtn}) do
    local bg = b.BackgroundColor3
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=Color3.fromRGB(34,34,58)},0.14) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=bg},0.14) end)
end

-- ═══════════════════════════════════════════
--  SECTION 3 · FILL TRANSPARENCY
-- ═══════════════════════════════════════════
Section("ПРОЗРАЧНОСТЬ ЗАЛИВКИ", 6)
local FC = Card(64,7)
local FillLbl = Lbl(FC,"Заливка: "..math.floor((1-State.fillTrans)*100).."%",
    14,10,200,18,11,Color3.fromRGB(148,140,205),false)
local SW = math.floor(W*0.93) - 28
local SliderBg,SliderFill,SliderKnob = MkSlider(FC,14,40,SW,
    Color3.fromRGB(70,40,200), 1-State.fillTrans)
hookTip(SliderBg,"SliderBg")

-- ═══════════════════════════════════════════
--  SECTION 4 · OUTLINE TRANSPARENCY
-- ═══════════════════════════════════════════
Section("ПРОЗРАЧНОСТЬ ОБВОДКИ", 8)
local OC = Card(64,9)
local OutlineLbl = Lbl(OC,"Обводка: "..math.floor((1-State.outlineTrans)*100).."%",
    14,10,200,18,11,Color3.fromRGB(148,140,205),false)
local OSliderBg,OSliderFill,OSliderKnob = MkSlider(OC,14,40,SW,
    Color3.fromRGB(160,50,255), 1-State.outlineTrans)
hookTip(OSliderBg,"OSliderBg")

-- ═══════════════════════════════════════════
--  SECTION 5 · TAGS
-- ═══════════════════════════════════════════
Section("ТЕГИ НАД ИГРОКАМИ", 10)
local TC = Card(198,11)

local function TagRow(parent, labelTxt, tipKey, yOff, initState)
    Lbl(parent, labelTxt, 14, yOff+4, 180, 22, 12, Color3.fromRGB(148,142,205), false)
    local tr,kn,hi = MkToggle(parent, W*0.93-62, yOff+2)
    SetToggle(tr,kn,initState)
    hookTip(hi, tipKey)
    return tr,kn,hi
end

local NmTr,NmKn,NamesHit   = TagRow(TC,"Показывать ник",    "NamesHit",  4,  State.showNames)
local DsTr,DsKn,DistHit    = TagRow(TC,"Показывать дистанцию","DistHit", 42, State.showDistance)
local HpTr,HpKn,HealthHit  = TagRow(TC,"Показывать здоровье","HealthHit",80, State.showHealth)
local TlTr,TlKn,ToolHit    = TagRow(TC,"Показывать предмет","ToolHit",   118, State.showTool)

-- text size — ONE clean slider row
local TagSizeLbl = Lbl(TC,"Размер текста: "..State.nameTagSize,
    14,154,200,18,11,Color3.fromRGB(148,140,205),false)
local TSRatio = (State.nameTagSize-minTS)/(maxTS-minTS)
local TSBg,TSFill,TSKnob = MkSlider(TC,14,176,SW,Color3.fromRGB(230,130,50),TSRatio)
hookTip(TSBg,"TSBg")

-- ═══════════════════════════════════════════
--  SECTION 6 · KEYBINDS
-- ═══════════════════════════════════════════
Section("ГОРЯЧИЕ КЛАВИШИ", 12)
local KB = Card(80,13)

local function BindRow(parent, labelTxt, tipKey, yOff, keyCode)
    Lbl(parent, labelTxt, 14, yOff+4, 130, 22, 11, Color3.fromRGB(130,124,196), false)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0,90,0,26)
    b.Position         = UDim2.new(1,-104,0,yOff+2)
    b.BackgroundColor3 = Color3.fromRGB(22,22,40)
    b.Text             = keyCode.Name
    b.TextColor3       = Color3.fromRGB(80,140,255)
    b.TextSize         = 11
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.Parent           = parent
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,8)
    local st = Instance.new("UIStroke")
    st.Color     = Color3.fromRGB(45,50,110)
    st.Thickness = 1
    st.Parent    = b
    hookTip(b, tipKey)
    return b
end

local ESPBindBtn  = BindRow(KB,"Включение ESP:", "ESPBindBtn",  6,  State.espKey)
local MenuBindBtn = BindRow(KB,"Открытие меню:","MenuBindBtn", 44, State.menuKey)

-- ═══════════════════════════════════════════
--  SECTION 7 · EXCLUDE
-- ═══════════════════════════════════════════
Section("ИСКЛЮЧЕНИЯ", 14)
local ExC = Card(118,15)

local ExcInput = Instance.new("TextBox")
ExcInput.Size               = UDim2.new(1,-80,0,34)
ExcInput.Position           = UDim2.new(0,12,0,10)
ExcInput.BackgroundColor3   = Color3.fromRGB(20,20,36)
ExcInput.BorderSizePixel    = 0
ExcInput.Text               = ""
ExcInput.PlaceholderText    = "Введите ник..."
ExcInput.PlaceholderColor3  = Color3.fromRGB(60,60,106)
ExcInput.TextColor3         = Color3.fromRGB(195,185,255)
ExcInput.TextSize           = 12
ExcInput.Font               = Enum.Font.Gotham
ExcInput.ClearTextOnFocus   = false
ExcInput.Parent             = ExC
Instance.new("UICorner",ExcInput).CornerRadius = UDim.new(0,9)
local EIS = Instance.new("UIStroke")
EIS.Color     = Color3.fromRGB(50,44,96)
EIS.Thickness = 1
EIS.Parent    = ExcInput

local ExcAddBtn = Instance.new("TextButton")
ExcAddBtn.Size             = UDim2.new(0,56,0,34)
ExcAddBtn.Position         = UDim2.new(1,-68,0,10)
ExcAddBtn.BackgroundColor3 = Color3.fromRGB(50,30,155)
ExcAddBtn.Text             = "+ Добавить"
ExcAddBtn.TextColor3       = Color3.fromRGB(255,255,255)
ExcAddBtn.TextSize         = 9
ExcAddBtn.Font             = Enum.Font.GothamBold
ExcAddBtn.BorderSizePixel  = 0
ExcAddBtn.Parent           = ExC
Instance.new("UICorner",ExcAddBtn).CornerRadius = UDim.new(0,9)
hookTip(ExcAddBtn,"ExcAddBtn")

local ExcList = Instance.new("ScrollingFrame")
ExcList.Size                   = UDim2.new(1,-24,0,58)
ExcList.Position               = UDim2.new(0,12,0,52)
ExcList.BackgroundColor3       = Color3.fromRGB(12,12,22)
ExcList.BorderSizePixel        = 0
ExcList.ScrollBarThickness     = 2
ExcList.ScrollBarImageColor3   = Color3.fromRGB(55,50,150)
ExcList.CanvasSize             = UDim2.new(0,0,0,0)
ExcList.AutomaticCanvasSize    = Enum.AutomaticSize.Y
ExcList.Parent                 = ExC
Instance.new("UICorner",ExcList).CornerRadius = UDim.new(0,7)

local ELL = Instance.new("UIListLayout")
ELL.Padding   = UDim.new(0,2)
ELL.SortOrder = Enum.SortOrder.LayoutOrder
ELL.Parent    = ExcList
local ELP = Instance.new("UIPadding")
ELP.PaddingTop  = UDim.new(0,3)
ELP.PaddingLeft = UDim.new(0,4)
ELP.Parent      = ExcList

local ExcEmpty = Lbl(ExcList,"Список пуст",6,0,0,24,9,Color3.fromRGB(55,55,96),false)
ExcEmpty.Size = UDim2.new(1,-12,0,24)

-- ═══════════════════════════════════════════
--  SECTION 8 · GENERAL
-- ═══════════════════════════════════════════
Section("НАСТРОЙКИ", 16)
local GC = Card(52,17)
Lbl(GC,"Исключить себя из ESP",14,0,190,52,12,Color3.fromRGB(140,134,205),false)
local ESTr,ESKn,ExcSelfHit = MkToggle(GC, W*0.93-62, 14)
SetToggle(ESTr,ESKn,State.excludeSelf)
hookTip(ExcSelfHit,"ExcSelfHit")

-- ═══════════════════════════════════════════
--  SECTION 9 · INFO
-- ═══════════════════════════════════════════
Section("ИНФОРМАЦИЯ", 18)
local IC = Card(52,19)
local iL = Lbl(IC,
    "DERNOZ ESP v3.1  •  20 цветов\nНаведи курсор на кнопку — появится подсказка\nX — ESP  |  F2 — меню  (переназначаемые)",
    14,6,0,40,9,Color3.fromRGB(55,55,100),false)
iL.Size = UDim2.new(1,-28,0,40)

-- ═══════════════════════════════════════════
--  HIGHLIGHT LOGIC
-- ═══════════════════════════════════════════
local createHL, removeHL, applyColors

local function updCount()
    local n=0
    for _ in pairs(State.highlights) do n+=1 end
    CntLbl.Text  = "Подсвечено: "..n.." игр."
    CntBadge.Text = tostring(n)
end

function applyColors()
    local col = getColor()
    local rb  = isRainbow()
    RainbowBadge.Visible = rb
    for pl,hl in pairs(State.highlights) do
        if not rb then
            hl.FillColor    = col.fill
            hl.OutlineColor = col.outline
        end
        hl.FillTransparency    = State.fillTrans
        hl.OutlineTransparency = State.outlineTrans
        local bb = State.billboards[pl]
        if bb and not rb then
            local l = bb:FindFirstChildOfClass("TextLabel")
            if l then l.TextColor3 = col.fill end
        end
    end
    if not rb then
        CPrev.BackgroundColor3 = col.fill
        ColorNameLbl.Text      = col.name
    else
        ColorNameLbl.Text = "Rainbow"
    end
    CIdxLbl.Text = State.colorIndex.." / "..#CONFIG.Colors
end

function createHL(player)
    if State.highlights[player] then return end
    if isExcluded(player) then return end
    local char = player.Character
    if not char then return end

    local col = getColor()
    local rb  = isRainbow()

    local hl = Instance.new("Highlight")
    hl.FillColor           = rb and getRainbow() or col.fill
    hl.OutlineColor        = rb and getRainbow() or col.outline
    hl.FillTransparency    = State.fillTrans
    hl.OutlineTransparency = State.outlineTrans
    hl.Adornee             = char
    hl.Parent              = ScreenGui
    State.highlights[player] = hl

    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local need = hrp and (State.showNames or State.showDistance
        or State.showHealth or State.showTool)

    if need then
        local bb = Instance.new("BillboardGui")
        bb.Size        = UDim2.new(0,190,0,36)
        bb.StudsOffset = Vector3.new(0,4,0)
        bb.AlwaysOnTop = true
        bb.Adornee     = hrp
        bb.Parent      = ScreenGui

        local nl = Instance.new("TextLabel")
        nl.Size                   = UDim2.new(1,0,1,0)
        nl.BackgroundTransparency = 1
        nl.Text                   = buildTag(player)
        nl.TextColor3             = rb and getRainbow() or col.fill
        nl.TextSize               = State.nameTagSize
        nl.Font                   = Enum.Font.GothamBold
        nl.TextStrokeTransparency = 0.3
        nl.Parent                 = bb
        State.billboards[player]  = bb
    end
    updCount()
end

function removeHL(player)
    if State.highlights[player] then
        State.highlights[player]:Destroy()
        State.highlights[player] = nil
    end
    if State.billboards[player] then
        State.billboards[player]:Destroy()
        State.billboards[player] = nil
    end
    updCount()
end

local function refreshAll()
    for _,p in ipairs(Players:GetPlayers()) do
        removeHL(p)
        if State.enabled then createHL(p) end
    end
end

-- ═══════════════════════════════════════════
--  DRAG  — плавный lerp, без смещения вниз
-- ═══════════════════════════════════════════
local drag = {
    active    = false,
    startM    = Vector2.zero,
    startPos  = UDim2.new(),
    targetPos = CENTER,
    grabScale = 0,  -- визуальный эффект захвата
}

local LERP = 0.16

Header.InputBegan:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    drag.active   = true
    drag.startM   = Vector2.new(inp.Position.X, inp.Position.Y)
    drag.startPos = Main.Position
    drag.targetPos = Main.Position
    -- захват: лёгкое уменьшение
    tw(Main, {Size = UDim2.new(0, W-4, 0, Main.Size.Y.Offset)}, 0.12)
end)

Header.InputEnded:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    drag.active = false
    -- отпустить: вернуть размер
    tw(Main, {Size = UDim2.new(0, W, 0, Main.Size.Y.Offset)}, 0.18,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end)

-- ═══════════════════════════════════════════
--  SHOW / HIDE MENU
-- ═══════════════════════════════════════════
local function showMenu()
    State.menuVisible = true
    Main.Visible   = true          -- ← добавлено
    Shadow.Visible = true          -- ← добавлено
    local h = State.minimized and MINI_H or FULL_H
    Main.Position  = CENTER
    drag.targetPos = CENTER
    Main.BackgroundTransparency = 1
    Shadow.ImageTransparency    = 1
    Main.Size   = UDim2.new(0,W,0,0)
    Shadow.Size = UDim2.new(0,W+22,0,0)

    tw(Main,{
        Size=UDim2.new(0,W,0,h),
        BackgroundTransparency=0,
    },0.38,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    tw(Shadow,{
        Size=UDim2.new(0,W+22,0,h+22),
        ImageTransparency=0.5,
        Position=UDim2.new(0.5,0,0,54),
    },0.36)
end

local function hideMenu()
    State.menuVisible = false
    tw(Main,{
        Size=UDim2.new(0,W,0,0),
        BackgroundTransparency=1,
    },0.24,Enum.EasingStyle.Quart)
    tw(Shadow,{
        ImageTransparency=1,
        Size=UDim2.new(0,W+22,0,0),
    },0.22)
    task.delay(0.26, function()        -- ← добавлено: прячем полностью после анимации
        if not State.menuVisible then
            Main.Visible   = false
            Shadow.Visible = false
        end
    end)
end

-- ═══════════════════════════════════════════
--  RENDERSTEPPED
-- ═══════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local t = tick()

    -- анимация заголовка DERNOZ
    TitleAnimGrad.Offset = Vector2.new(math.sin(t*0.9)*0.35, 0)
    -- анимация подсказки
    TipGrad.Offset        = Vector2.new(math.sin(t*1.2)*0.4, 0)
    TipGradLabel.Offset   = Vector2.new(math.sin(t*1.0+1)*0.35, 0)

    -- rainbow
    if State.enabled and isRainbow() then
        local rc = getRainbow()
        for pl,hl in pairs(State.highlights) do
            hl.FillColor    = rc
            hl.OutlineColor = rc
            local bb = State.billboards[pl]
            if bb then
                local l = bb:FindFirstChildOfClass("TextLabel")
                if l then l.TextColor3 = rc end
            end
        end
        CPrev.BackgroundColor3 = rc
    end

    -- теги живые
    if State.enabled then
        for pl,bb in pairs(State.billboards) do
            local l = bb:FindFirstChildOfClass("TextLabel")
            if l then l.Text = buildTag(pl) end
        end
    end

    -- smooth drag
    if drag.active then
        local m = UserInputService:GetMouseLocation()
        local d = m - drag.startM
        drag.targetPos = UDim2.new(
            drag.startPos.X.Scale,
            drag.startPos.X.Offset + d.X,
            drag.startPos.Y.Scale,
            drag.startPos.Y.Offset + d.Y
        )
    end

    local cur = Main.Position
    local tgt = drag.targetPos
    local dx  = tgt.X.Offset - cur.X.Offset
    local dy  = tgt.Y.Offset - cur.Y.Offset
    if math.abs(dx)+math.abs(dy) > 0.3 then
        local np = UDim2.new(
            cur.X.Scale  + (tgt.X.Scale  - cur.X.Scale)  * LERP,
            cur.X.Offset + dx * LERP,
            cur.Y.Scale  + (tgt.Y.Scale  - cur.Y.Scale)  * LERP,
            cur.Y.Offset + dy * LERP
        )
        Main.Position   = np
        Shadow.Position = UDim2.new(np.X.Scale, np.X.Offset,
            np.Y.Scale, np.Y.Offset - 6)
    end
end)

-- ═══════════════════════════════════════════
--  SLIDERS LOGIC
-- ═══════════════════════════════════════════
local activeSlider = nil

local function bindSlider(bg, fill, knob, cb)
    bg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            activeSlider = {bg=bg,fill=fill,knob=knob,cb=cb}
            local r = math.clamp(
                (inp.Position.X - bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
            cb(r)
        end
    end)
end

bindSlider(SliderBg, SliderFill, SliderKnob, function(r)
    State.fillTrans      = 1-r
    SliderFill.Size      = UDim2.new(r,0,1,0)
    SliderKnob.Position  = UDim2.new(r,0,0.5,0)
    FillLbl.Text         = "Заливка: "..math.floor(r*100).."%"
    for _,hl in pairs(State.highlights) do hl.FillTransparency = State.fillTrans end
end)

bindSlider(OSliderBg, OSliderFill, OSliderKnob, function(r)
    State.outlineTrans   = 1-r
    OSliderFill.Size     = UDim2.new(r,0,1,0)
    OSliderKnob.Position = UDim2.new(r,0,0.5,0)
    OutlineLbl.Text      = "Обводка: "..math.floor(r*100).."%"
    for _,hl in pairs(State.highlights) do hl.OutlineTransparency = State.outlineTrans end
end)

bindSlider(TSBg, TSFill, TSKnob, function(r)
    State.nameTagSize    = math.floor(minTS + r*(maxTS-minTS))
    TSFill.Size          = UDim2.new(r,0,1,0)
    TSKnob.Position      = UDim2.new(r,0,0.5,0)
    TagSizeLbl.Text      = "Размер текста: "..State.nameTagSize
    for _,bb in pairs(State.billboards) do
        local l = bb:FindFirstChildOfClass("TextLabel")
        if l then l.TextSize = State.nameTagSize end
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        activeSlider = nil
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if not activeSlider then return end
    local bg = activeSlider.bg
    local r  = math.clamp(
        (inp.Position.X - bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
    activeSlider.cb(r)
end)

-- ═══════════════════════════════════════════
--  TOGGLE BUTTONS
-- ═══════════════════════════════════════════
local function setEnabled(on)
    State.enabled = on
    SetToggle(TrTrack,TrKnob,on)
    StatusDot.BackgroundColor3 = on
        and Color3.fromRGB(45,210,90) or Color3.fromRGB(200,45,45)
    StatusLbl.Text      = on and "ВКЛЮЧЁН" or "ВЫКЛЮЧЕН"
    StatusLbl.TextColor3 = on
        and Color3.fromRGB(45,210,90) or Color3.fromRGB(200,45,45)
    refreshAll()
end

ToggleHit.MouseButton1Click:Connect(function() setEnabled(not State.enabled) end)

NamesHit.MouseButton1Click:Connect(function()
    State.showNames = not State.showNames
    SetToggle(NmTr,NmKn,State.showNames)
    if State.enabled then refreshAll() end
end)

DistHit.MouseButton1Click:Connect(function()
    State.showDistance = not State.showDistance
    SetToggle(DsTr,DsKn,State.showDistance)
end)

HealthHit.MouseButton1Click:Connect(function()
    State.showHealth = not State.showHealth
    SetToggle(HpTr,HpKn,State.showHealth)
end)

ToolHit.MouseButton1Click:Connect(function()
    State.showTool = not State.showTool
    SetToggle(TlTr,TlKn,State.showTool)
end)

ExcSelfHit.MouseButton1Click:Connect(function()
    State.excludeSelf = not State.excludeSelf
    SetToggle(ESTr,ESKn,State.excludeSelf)
    if State.enabled then
        if State.excludeSelf then removeHL(LocalPlayer)
        else createHL(LocalPlayer) end
    end
end)

-- ═══════════════════════════════════════════
--  COLOR BUTTONS
-- ═══════════════════════════════════════════
local function chColor(dir)
    State.colorIndex = ((State.colorIndex-1+dir) % #CONFIG.Colors)+1
    applyColors()
end
PrevBtn.MouseButton1Click:Connect(function() chColor(-1) end)
NextBtn.MouseButton1Click:Connect(function() chColor(1)  end)

-- ═══════════════════════════════════════════
--  KEYBINDS
-- ═══════════════════════════════════════════
local function startBind(which)
    State.bindingKey = which
    local btn = which=="esp" and ESPBindBtn or MenuBindBtn
    btn.Text      = "[ нажми ]"
    btn.TextColor3 = Color3.fromRGB(255,210,60)
end

ESPBindBtn.MouseButton1Click:Connect(function()  startBind("esp")  end)
MenuBindBtn.MouseButton1Click:Connect(function() startBind("menu") end)

-- ═══════════════════════════════════════════
--  INPUT HANDLER
-- ═══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp or State.guiDestroyed then return end

    if State.bindingKey and inp.UserInputType == Enum.UserInputType.Keyboard then
        local kc = inp.KeyCode
        if kc == Enum.KeyCode.Escape then
            State.bindingKey     = nil
            ESPBindBtn.Text      = State.espKey.Name
            ESPBindBtn.TextColor3 = Color3.fromRGB(80,140,255)
            MenuBindBtn.Text      = State.menuKey.Name
            MenuBindBtn.TextColor3 = Color3.fromRGB(80,140,255)
            return
        end
        if State.bindingKey == "esp" then
            State.espKey         = kc
            ESPBindBtn.Text      = kc.Name
            ESPBindBtn.TextColor3 = Color3.fromRGB(80,140,255)
        else
            State.menuKey         = kc
            MenuBindBtn.Text      = kc.Name
            MenuBindBtn.TextColor3 = Color3.fromRGB(80,140,255)
        end
        State.bindingKey = nil
        return
    end

    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if inp.KeyCode == State.espKey then
        setEnabled(not State.enabled)
    elseif inp.KeyCode == State.menuKey then
        if State.menuVisible then hideMenu() else showMenu() end
    end
end)

-- ═══════════════════════════════════════════
--  MIN / CLOSE
-- ═══════════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
    State.minimized = not State.minimized
    MinBtn.Text = State.minimized and "+" or "−"
    local h = State.minimized and MINI_H or FULL_H
    tw(Main,   {Size=UDim2.new(0,W,0,h)}, 0.3, Enum.EasingStyle.Quart)
    tw(Shadow, {Size=UDim2.new(0,W+22,0,h+22)}, 0.3)
end)

CloseBtn.MouseButton1Click:Connect(function()
    State.guiDestroyed = true
    setEnabled(false)
    tw(Main,   {Size=UDim2.new(0,W,0,0), BackgroundTransparency=1}, 0.24)
    tw(Shadow, {ImageTransparency=1}, 0.22)
    task.delay(0.3, function() ScreenGui:Destroy() end)
end)

-- ═══════════════════════════════════════════
--  EXCLUDE LIST
-- ═══════════════════════════════════════════
local function rebuildExc()
    for _,ch in ipairs(ExcList:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    local n=0
    for name in pairs(State.excludedNames) do
        n+=1
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1,-6,0,20)
        row.BackgroundColor3 = Color3.fromRGB(20,20,36)
        row.BorderSizePixel  = 0
        row.Parent           = ExcList
        Instance.new("UICorner",row).CornerRadius = UDim.new(0,5)

        local nl = Lbl(row,name,6,0,0,20,10,Color3.fromRGB(170,155,255),false)
        nl.Size = UDim2.new(1,-30,1,0)

        local rb = Instance.new("TextButton")
        rb.Size               = UDim2.new(0,22,0,16)
        rb.Position           = UDim2.new(1,-24,0.5,-8)
        rb.BackgroundColor3   = Color3.fromRGB(130,25,25)
        rb.Text               = "✕"
        rb.TextColor3         = Color3.fromRGB(255,255,255)
        rb.TextSize           = 9
        rb.Font               = Enum.Font.GothamBold
        rb.BorderSizePixel    = 0
        rb.Parent             = row
        Instance.new("UICorner",rb).CornerRadius = UDim.new(0,4)

        local cap = name
        rb.MouseButton1Click:Connect(function()
            State.excludedNames[cap] = nil
            rebuildExc()
            if State.enabled then
                for _,pl in ipairs(Players:GetPlayers()) do
                    if pl.Name==cap then createHL(pl) end
                end
            end
        end)
    end
    ExcEmpty.Visible = (n==0)
end

ExcAddBtn.MouseButton1Click:Connect(function()
    local name = ExcInput.Text:match("^%s*(.-)%s*$")
    if name=="" then return end
    State.excludedNames[name] = true
    ExcInput.Text = ""
    rebuildExc()
    if State.enabled then
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl.Name==name then removeHL(pl) end
        end
    end
end)

rebuildExc()

-- ═══════════════════════════════════════════
--  PLAYER HOOKS
-- ═══════════════════════════════════════════
local function hookPlayer(player)
    if State.charConnections[player] then
        State.charConnections[player]:Disconnect()
    end
    State.charConnections[player] = player.CharacterAdded:Connect(function()
        removeHL(player)
        task.wait(0.18)
        if State.enabled then createHL(player) end
    end)
    if State.enabled and player.Character then createHL(player) end
end

Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(p)
    removeHL(p)
    if State.charConnections[p] then
        State.charConnections[p]:Disconnect()
        State.charConnections[p] = nil
    end
end)
for _,p in ipairs(Players:GetPlayers()) do hookPlayer(p) end

-- ═══════════════════════════════════════════
--  INITIAL ANIMATION
-- ═══════════════════════════════════════════
Main.Size                   = UDim2.new(0,W,0,0)
Main.Position               = CENTER
Main.BackgroundTransparency = 1
Shadow.ImageTransparency    = 1
Shadow.Size                 = UDim2.new(0,W+22,0,0)
drag.targetPos              = CENTER

task.delay(0.1, showMenu)
