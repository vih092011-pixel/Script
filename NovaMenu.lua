local Players = game:GetService("Players")
print("[NovaMenu] início do script")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

pcall(function()
    RunService:UnbindFromRenderStep("NovaMenuAim")
    RunService:UnbindFromRenderStep("NovaMenuSilent")
end)

local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.NovaMenuUnload then
    pcall(env.NovaMenuUnload)
end

local AX, AY = Enum.AutomaticSize.X, Enum.AutomaticSize.Y
local Left, Right, Center = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right, Enum.TextXAlignment.Center
local ByOrder = Enum.SortOrder.LayoutOrder
local AtEnd = Enum.TextTruncate.AtEnd

local Connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

local function RGB(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local PresetOrder = {"Preto Profundo", "Grafite", "Azul Noite", "Roxo Noturno", "Vinho Escuro", "Verde Escuro"}
local Presets = {
    ["Preto Profundo"] = {Background = RGB(5, 5, 7), BackgroundLight = RGB(38, 41, 50), Surface = RGB(14, 15, 19), Accent = RGB(235, 45, 62), Text = RGB(234, 237, 243), SubText = RGB(140, 147, 160), Stroke = RGB(42, 45, 54)},
    ["Grafite"] = {Background = RGB(10, 10, 11), BackgroundLight = RGB(56, 57, 62), Surface = RGB(21, 21, 23), Accent = RGB(160, 165, 178), Text = RGB(238, 238, 240), SubText = RGB(150, 150, 156), Stroke = RGB(60, 60, 66)},
    ["Azul Noite"] = {Background = RGB(4, 7, 14), BackgroundLight = RGB(30, 48, 82), Surface = RGB(11, 16, 28), Accent = RGB(74, 128, 220), Text = RGB(230, 236, 248), SubText = RGB(126, 142, 168), Stroke = RGB(34, 46, 70)},
    ["Roxo Noturno"] = {Background = RGB(7, 4, 12), BackgroundLight = RGB(50, 34, 80), Surface = RGB(16, 11, 26), Accent = RGB(140, 100, 220), Text = RGB(238, 232, 248), SubText = RGB(150, 138, 170), Stroke = RGB(46, 36, 68)},
    ["Vinho Escuro"] = {Background = RGB(10, 4, 5), BackgroundLight = RGB(64, 26, 32), Surface = RGB(22, 11, 13), Accent = RGB(200, 76, 92), Text = RGB(246, 232, 234), SubText = RGB(168, 138, 142), Stroke = RGB(62, 34, 38)},
    ["Verde Escuro"] = {Background = RGB(4, 9, 6), BackgroundLight = RGB(26, 56, 40), Surface = RGB(10, 20, 15), Accent = RGB(72, 176, 122), Text = RGB(228, 244, 236), SubText = RGB(132, 158, 142), Stroke = RGB(32, 56, 42)}
}

local SliderStyles = {"Barra", "Linha", "Pílula", "Bloco"}
local DropdownStyles = {"Lista", "Grade", "Pílula", "Minimalista"}
local KeybindList = {"RightShift", "RightControl", "Insert", "Delete", "K", "M", "V", "B", "N", "F1", "F2", "F3", "F4", "F5", "F6"}

local FontNames = {"GothamMedium", "Gotham", "GothamBold", "SourceSans", "SourceSansSemibold", "Ubuntu", "Nunito", "Roboto", "RobotoMono", "Code", "Arial", "Jura", "Michroma", "Oswald", "TitilliumWeb", "SciFi"}
local FontList = {}
for _, n in ipairs(FontNames) do
    local ok, f = pcall(function()
        return Enum.Font[n]
    end)
    if ok and f then
        table.insert(FontList, n)
    end
end

local Theme = {Keybind = "RightShift"}

local function loadPreset(name)
    for k, v in pairs(Presets[name]) do
        Theme[k] = v
    end
    Theme.Preset = name
end

local function applyDefaults()
    loadPreset("Preto Profundo")
    Theme.Radius = 14
    Theme.TextSize = 14
    Theme.Transparency = 0
    Theme.Scale = 1
    Theme.Font = FontList[1] or "GothamMedium"
    Theme.SliderStyle = "Barra"
    Theme.DropdownStyle = "Lista"
    Theme.Gradient = true
    Theme.StrokeOn = true
    Theme.TabStyle = "Pílula"
    Theme.TabPosition = "Lateral Esquerda"
end

local function luminance(c)
    return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

local function computeDerived()
    Theme.Element = Theme.Surface:Lerp(Color3.new(1, 1, 1), 0.07)
    Theme.ElementHover = Theme.Surface:Lerp(Color3.new(1, 1, 1), 0.13)
    Theme.OnAccent = luminance(Theme.Accent) > 0.62 and RGB(12, 12, 14) or RGB(255, 255, 255)
end

applyDefaults()
computeDerived()

local Refreshers = {}
local function reg(fn)
    table.insert(Refreshers, fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("[NovaMenu] atualização visual ignorada: " .. tostring(err))
    end
end

local function applyTheme()
    computeDerived()
    for _, fn in ipairs(Refreshers) do
        pcall(fn)
    end
end

local function themeFont()
    local ok, f = pcall(function()
        return Enum.Font[Theme.Font]
    end)
    if ok and f then
        return f
    end
    return Enum.Font.GothamMedium
end

local function new(class, props, parent)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            pcall(function()
                inst[k] = v
            end)
        end
    end
    if parent then
        pcall(function()
            inst.Parent = parent
        end)
    end
    return inst
end

local function tween(inst, props, t)
    TweenService:Create(inst, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function pad(inst, l, t, r, b)
    return new("UIPadding", {PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b)}, inst)
end

local function fill(inst, key, factor)
    reg(function()
        inst.BackgroundColor3 = Theme[key]
        inst.BackgroundTransparency = factor and (Theme.Transparency * factor) or 0
    end)
end

local function corner(inst, delta, full)
    local c = new("UICorner", nil, inst)
    if full then
        c.CornerRadius = UDim.new(1, 0)
        return c
    end
    reg(function()
        c.CornerRadius = UDim.new(0, math.max(0, Theme.Radius + (delta or 0)))
    end)
    return c
end

local function stroke(inst, key, thickness)
    local s = new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = thickness or 1}, inst)
    reg(function()
        s.Color = Theme[key or "Stroke"]
        s.Enabled = Theme.StrokeOn
    end)
    return s
end

local function styleText(inst, colorKey, sizeDelta)
    reg(function()
        inst.Font = themeFont()
        inst.TextSize = Theme.TextSize + (sizeDelta or 0)
        inst.TextColor3 = Theme[colorKey or "Text"]
        if inst:IsA("TextBox") then
            inst.PlaceholderColor3 = Theme.SubText
        end
    end)
end

local function hover(inst, baseKey, hoverKey)
    inst.MouseEnter:Connect(function()
        tween(inst, {BackgroundColor3 = Theme[hoverKey]}, 0.12)
    end)
    inst.MouseLeave:Connect(function()
        tween(inst, {BackgroundColor3 = Theme[baseKey]}, 0.12)
    end)
end

local function fire(cb, ...)
    if cb then
        task.spawn(function(...)
            local ok, err = pcall(cb, ...)
            if not ok then
                warn("[NovaMenu] " .. tostring(err))
            end
        end, ...)
    end
end

local function getGuiParent()
    if LocalPlayer then
        local ok, playerGui = pcall(function()
            return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
        if ok and playerGui then
            return playerGui
        end
    end
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then
            return ui
        end
    end
    local ok = pcall(function()
        return CoreGui:GetChildren()
    end)
    if ok then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local Gui = new("ScreenGui", {Name = "NovaMenu", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 9999, Enabled = true})
local guiParent
pcall(function()
    guiParent = getGuiParent()
end)
if not guiParent and LocalPlayer then
    guiParent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end
if guiParent then
    pcall(function()
        Gui.Parent = guiParent
    end)
end
if not Gui.Parent and LocalPlayer then
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
        Gui.Parent = playerGui
    end)
end
print("[NovaMenu] ScreenGui parent: " .. tostring(Gui.Parent))
local Main = new("Frame", {Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(520, 360), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = true}, Gui)
local MainScale = new("UIScale", {Scale = 1}, Main)
local MainGradient = new("UIGradient", {Rotation = 35}, Main)
corner(Main, 0)
stroke(Main)
reg(function()
    Main.BackgroundTransparency = Theme.Transparency
    MainScale.Scale = Theme.Scale
    if Theme.Gradient then
        MainGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Theme.Background), ColorSequenceKeypoint.new(1, Theme.BackgroundLight)})
    else
        MainGradient.Color = ColorSequence.new(Theme.Background)
    end
end)

local function makeDraggable(handle, target, onTap)
    local dragging, moved = false, false
    local dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local dx = input.Position.X - dragStart.X
            local dy = input.Position.Y - dragStart.Y
            if math.abs(dx) + math.abs(dy) > 6 then
                moved = true
            end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)
            end
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved and onTap then
                onTap()
            end
        end
    end)
end

local Topbar = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1}, Main)
makeDraggable(Topbar, Main)

local Title = new("TextLabel", {Text = "NOVA MENU", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(0, 130, 1, 0), TextXAlignment = Left, TextTruncate = AtEnd}, Topbar)
styleText(Title, "Text", 3)

-- Barrinha embaixo do NOVA MENU
local titleUnderline = new("Frame", {Size = UDim2.new(0, 110, 0, 2), Position = UDim2.fromOffset(16, 38), BorderSizePixel = 0, BackgroundTransparency = 0.3}, Topbar)
corner(titleUnderline, -12)
reg(function()
    titleUnderline.BackgroundColor3 = Theme.Accent
end)

local function topButton(text, xOffset)
    local b = new("TextButton", {Text = text, AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOffset, 0.5, 0), Size = UDim2.fromOffset(30, 30), BorderSizePixel = 0}, Topbar)
    fill(b, "Element")
    corner(b, -6)
    styleText(b, "Text", 1)
    hover(b, "Element", "ElementHover")
    return b
end

local CloseButton = topButton("X", -12)
local MinButton = topButton("-", -48)

local SearchBox = new("TextBox", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -88, 0.5, 0), Size = UDim2.new(0.34, 0, 0, 30), PlaceholderText = "Pesquisar opções...", Text = "", ClearTextOnFocus = false, BorderSizePixel = 0, TextXAlignment = Left}, Topbar)
new("UISizeConstraint", {MinSize = Vector2.new(110, 30), MaxSize = Vector2.new(250, 30)}, SearchBox)
fill(SearchBox, "Element")
corner(SearchBox, 0, true)
stroke(SearchBox)
pad(SearchBox, 10, 0, 10, 0)
styleText(SearchBox, "Text", -1)

local Divider = new("Frame", {Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0}, Main)
fill(Divider, "Stroke")

local TabBar = new("ScrollingFrame", {Position = UDim2.fromOffset(0, 47), Size = UDim2.new(0, 136, 1, -47), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = AX, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.X}, Main)
local TabLayout = new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = ByOrder}, TabBar)
pad(TabBar, 8, 4, 3, 0)

local Content = new("Frame", {Position = UDim2.new(0, 120, 0, 47), Size = UDim2.new(1, -120, 1, -47), BackgroundTransparency = 1}, Main)

local EmptyLabel = new("TextLabel", {Text = "Nenhuma opção encontrada", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false}, Content)
local Credits = new("TextLabel", {Text = "CRIADO POR  •  INOX777", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -5), Size = UDim2.fromOffset(190, 16), TextXAlignment = Right, ZIndex = 3}, Main)
styleText(Credits, "SubText", -2)
styleText(EmptyLabel, "SubText", 0)

local Pages = {}
local Registry = {}
local CurrentPage

local function selectPage(page)
    CurrentPage = page
    for _, p in ipairs(Pages) do
        p.scroll.Visible = p == page
        p.refresh()
    end
end

local function applyTabStyle()
    local style = Theme.TabStyle
    local position = Theme.TabPosition
    local isVertical = position == "Lateral Esquerda" or position == "Lateral Direita"
    for _, p in ipairs(Pages) do
        local tab = p.tab
        tab.TextSize = Theme.TextSize - 1
        tab.Font = themeFont()
        if isVertical then
            tab.Size = UDim2.new(1, 0, 0, 32)
            tab.AutomaticSize = Enum.AutomaticSize.None
        else
            tab.AutomaticSize = AX
            tab.Size = UDim2.fromOffset(0, 28)
        end
        local cr = tab:FindFirstChildOfClass("UICorner")
        if cr then
            if style == "Redondo" then
                cr.CornerRadius = UDim.new(1, 0)
            elseif style == "Quadrado" then
                cr.CornerRadius = UDim.new(0, 0)
            elseif style == "Arredondado" then
                cr.CornerRadius = UDim.new(0, 8)
            else
                cr.CornerRadius = UDim.new(0, math.max(0, Theme.Radius - 6))
            end
        end
    end
    if isVertical then
        TabLayout.FillDirection = Enum.FillDirection.Vertical
        TabBar.ScrollingDirection = Enum.ScrollingDirection.Y
        TabBar.AutomaticCanvasSize = AY
        TabBar.Size = UDim2.new(0, 136, 1, -47)
        TabBar.Position = UDim2.fromOffset(0, 47)
        TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
        Content.Position = UDim2.new(0, 136, 0, 47)
        Content.Size = UDim2.new(1, -136, 1, -69)
        if position == "Lateral Direita" then
            TabBar.Position = UDim2.new(1, -136, 0, 47)
            Content.Position = UDim2.fromOffset(0, 47)
            Content.Size = UDim2.new(1, -136, 1, -69)
        end
    else
        TabLayout.FillDirection = Enum.FillDirection.Horizontal
        TabBar.ScrollingDirection = Enum.ScrollingDirection.X
        TabBar.AutomaticCanvasSize = AX
        TabBar.Size = UDim2.new(1, 0, 0, 38)
        TabBar.Position = UDim2.fromOffset(0, 47)
        TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
        Content.Position = UDim2.fromOffset(0, 86)
        Content.Size = UDim2.new(1, 0, 1, -108)
    end
end

local function makeSlider(scroll, name, min, max, default, step, suffix, callback)
    step = step or 1
    suffix = suffix or ""
    local decimals = 0
    local probe = step
    while probe < 1 and decimals < 3 do
        probe = probe * 10
        decimals = decimals + 1
    end
    local fmt = "%." .. decimals .. "f"
    local value = math.clamp(default, min, max)

    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1})
    local label = new("TextLabel", {Text = name, BackgroundTransparency = 1, Size = UDim2.new(1, -74, 0, 18), TextXAlignment = Left, TextTruncate = AtEnd}, row)
    local valueLabel = new("TextLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(74, 18), TextXAlignment = Right}, row)
    styleText(label, "Text", 0)
    styleText(valueLabel, "SubText", -1)

    local hit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 26)}, row)
    local track = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 8), BorderSizePixel = 0}, hit)
    local trackCorner = new("UICorner", nil, track)
    local bar = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0}, track)
    local barCorner = new("UICorner", nil, bar)
    local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(0, 0), BorderSizePixel = 0, ZIndex = 2}, track)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    local knobStroke = new("UIStroke", {Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, knob)

    local function render()
        local style = Theme.SliderStyle
        local frac = (max == min) and 0 or (value - min) / (max - min)
        local h, kn = 8, 0
        if style == "Linha" then
            h, kn = 3, 14
        elseif style == "Pílula" then
            h, kn = 12, 22
        elseif style == "Bloco" then
            h = 20
        end
        local cr = (style == "Bloco") and UDim.new(0, math.max(3, math.floor(Theme.Radius / 2))) or UDim.new(1, 0)
        track.Size = UDim2.new(1, 0, 0, h)
        track.BackgroundColor3 = Theme.Stroke
        trackCorner.CornerRadius = cr
        barCorner.CornerRadius = cr
        bar.BackgroundColor3 = Theme.Accent
        bar.Size = UDim2.new(frac, 0, 1, 0)
        knob.Visible = kn > 0
        knob.Size = UDim2.fromOffset(kn, kn)
        knob.Position = UDim2.new(frac, 0, 0.5, 0)
        knob.BackgroundColor3 = (style == "Linha") and Theme.Accent or Theme.Text
        knobStroke.Color = (style == "Linha") and Theme.Surface or Theme.Accent
        valueLabel.Text = string.format(fmt, value) .. suffix
    end
    reg(render)

    local obj = {}
    local function setValue(v, silent)
        v = math.clamp(v, min, max)
        v = math.floor((v - min) / step + 0.5) * step + min
        v = math.clamp(tonumber(string.format("%.4f", v)), min, max)
        local changed = v ~= value
        value = v
        render()
        if changed and not silent then
            fire(callback, value)
        end
    end
    obj.Set = setValue
    function obj.Get()
        return value
    end

    local function fromInput(input)
        local w = track.AbsoluteSize.X
        if w <= 0 then
            return
        end
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / w, 0, 1)
        setValue(min + (max - min) * rel)
    end

    local dragging = false
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            scroll.ScrollingEnabled = false
            fromInput(input)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            scroll.ScrollingEnabled = true
        end
    end)

    return row, obj
end

local function makeTabIcon(parent, name)
    local root = new("Frame", {Name = "TabIcon", BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(16, 16), Active = false}, parent)
    local tint = Theme.SubText
    local function shape(x, y, w, h, round, outlined)
        local f = new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = tint, BackgroundTransparency = outlined and 1 or 0, BorderSizePixel = 0, Active = false}, root)
        if round then new("UICorner", {CornerRadius = UDim.new(1, 0)}, f) end
        if outlined then new("UIStroke", {Color = tint, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, f) end
        return f
    end
    if name == "Perfil" then
        shape(5, 0, 6, 6, true, false); shape(2, 8, 12, 7, true, false)
    elseif name == "Principal" then
        -- Telhado em duas linhas inclinadas, corpo e porta: ícone de casa feito em UI.
        shape(1, 5, 9, 2, true, false).Rotation = -38
        shape(7, 5, 9, 2, true, false).Rotation = 38
        shape(3, 8, 10, 7, true, false)
        local door = shape(7, 10, 3, 5, true, false)
        door.BackgroundColor3 = Theme.Element
    elseif name == "Visual" then
        shape(0, 3, 16, 10, true, true); shape(6, 6, 4, 4, true, false)
    elseif name == "Aim" then
        shape(2, 2, 12, 12, true, true); shape(7, 0, 2, 5, false, false)
        shape(7, 11, 2, 5, false, false); shape(0, 7, 5, 2, false, false); shape(11, 7, 5, 2, false, false)
    elseif name == "Componentes" then
        shape(1, 1, 6, 6, true, false); shape(9, 1, 6, 6, true, false)
        shape(1, 9, 6, 6, true, false); shape(9, 9, 6, 6, true, false)
    elseif name == "Personalizar" then
        shape(1, 3, 14, 2, true, false); shape(1, 11, 14, 2, true, false)
        shape(4, 1, 4, 6, true, false); shape(10, 9, 4, 6, true, false)
    else
        shape(1, 1, 14, 14, true, true)
    end
    return root
end
local function addTab(name)
    local page = {name = name, children = {}}

    local tab = new("TextButton", {Text = "", AutoButtonColor = false, AutomaticSize = Enum.AutomaticSize.None, Size = UDim2.new(1, 0, 0, 32), BorderSizePixel = 0, LayoutOrder = #Pages + 1}, TabBar)
    local icon = makeTabIcon(tab, name)
    page.icon = icon
    local tabLabel = new("TextLabel", {Name = "TabLabel", Text = name, BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -33, 1, 0), TextXAlignment = Left, TextTruncate = AtEnd, Active = false}, tab)
    page.label = tabLabel
    styleText(tabLabel, "Text", -1)
    corner(tab, -6)
    page.tab = tab

    local scroll = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = AY, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false}, Content)
    reg(function()
        scroll.ScrollBarImageColor3 = Theme.Accent
    end)
    pad(scroll, 12, 4, 12, 14)
    new("UIListLayout", {SortOrder = ByOrder}, scroll)
    page.scroll = scroll

    local holder = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1}, scroll)
    local holderLayout = new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = ByOrder}, holder)
    local colLeft = new("Frame", {BackgroundTransparency = 1, AutomaticSize = AY, Size = UDim2.new(0.5, -4, 0, 0), LayoutOrder = 1}, holder)
    local colRight = new("Frame", {BackgroundTransparency = 1, AutomaticSize = AY, Size = UDim2.new(0.5, -4, 0, 0), LayoutOrder = 2}, holder)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = ByOrder}, colLeft)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = ByOrder}, colRight)

    function page.setStack(stack)
        holderLayout.FillDirection = stack and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
        local size = stack and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -4, 0, 0)
        colLeft.Size = size
        colRight.Size = size
    end

    page.refresh = function()
        local active = CurrentPage == page
        tab.BackgroundColor3 = active and Theme.Accent or Theme.Element
        tab.BackgroundTransparency = 0
        tab.Font = themeFont()
        tab.TextSize = Theme.TextSize - 1
        tab.TextColor3 = active and Theme.OnAccent or Theme.Text
        if page.icon then
            local tint = active and Theme.OnAccent or Theme.SubText
            for _, part in ipairs(page.icon:GetDescendants()) do
                if part:IsA("Frame") then part.BackgroundColor3 = tint end
                if part:IsA("UIStroke") then part.Color = tint end
            end
        end
    end
    reg(page.refresh)

    tab.MouseButton1Click:Connect(function()
        selectPage(page)
    end)

    function page.BeginChild(title, side)
        local column = (side == "right") and colRight or colLeft
        local child = {title = title, titleLower = string.lower(title), page = page, scroll = scroll, collapsed = false}

        local frame = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BorderSizePixel = 0}, column)
        fill(frame, "Surface", 0.6)
        corner(frame, -2)
        stroke(frame)
        pad(frame, 10, 10, 10, 10)
        new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = ByOrder}, frame)
        child.frame = frame

        -- Barra de destaque lateral no child
        local accentBar = new("Frame", {Size = UDim2.new(0, 3, 0, 18), Position = UDim2.fromOffset(-10, 10), BorderSizePixel = 0}, frame)
        corner(accentBar, -14)
        reg(function()
            accentBar.BackgroundColor3 = Theme.Accent
        end)

        local header = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 0}, frame)
        local titleLabel = new("TextLabel", {Text = title, BackgroundTransparency = 1, Size = UDim2.new(1, -26, 1, 0), TextXAlignment = Left}, header)
        styleText(titleLabel, "Accent", 1)
        local line = new("Frame", {Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, LayoutOrder = 1}, frame)
        fill(line, "Stroke")

        local order = 2
        local collapsed = false
        local function addRow(row, searchText)
            order = order + 1
            row.LayoutOrder = order
            row.Parent = frame
            row.Visible = not collapsed
            table.insert(Registry, {name = string.lower(searchText or ""), row = row, child = child, page = page})
        end

        function child.Custom(height, searchText)
            local row = new("Frame", {Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1})
            addRow(row, searchText)
            return row
        end

        function child.Label(text, subtle)
            local l = new("TextLabel", {Text = text, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextXAlignment = Left, TextYAlignment = Enum.TextYAlignment.Top})
            styleText(l, subtle and "SubText" or "Text", -1)
            addRow(l, text)
            return {Set = function(t)
                l.Text = t
            end}
        end

        function child.Info(key, value)
            local row = new("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1})
            local k = new("TextLabel", {Text = key, BackgroundTransparency = 1, Size = UDim2.new(0.45, 0, 1, 0), TextXAlignment = Left, TextTruncate = AtEnd}, row)
            local v = new("TextLabel", {Text = tostring(value), BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0), TextXAlignment = Right, TextTruncate = AtEnd}, row)
            styleText(k, "SubText", -1)
            styleText(v, "Text", -1)
            addRow(row, key)
            return {Set = function(t)
                v.Text = tostring(t)
            end}
        end

        function child.Button(text, callback)
            local b = new("TextButton", {Text = text, AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 30), BorderSizePixel = 0})
            fill(b, "Element")
            corner(b, -6)
            stroke(b)
            styleText(b, "Text", 0)
            hover(b, "Element", "ElementHover")
            b.MouseButton1Click:Connect(function()
                b.BackgroundColor3 = Theme.Accent
                tween(b, {BackgroundColor3 = Theme.Element}, 0.3)
                fire(callback)
            end)
            addRow(b, text)
            return b
        end

        function child.Toggle(text, default, callback)
            local state = default and true or false
            local row = new("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1})
            local label = new("TextLabel", {Text = text, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 1, 0), TextXAlignment = Left, TextTruncate = AtEnd}, row)
            styleText(label, "Text", 0)
            local track = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(42, 24), BorderSizePixel = 0}, row)
            corner(track, 0, true)
            local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(18, 18), BorderSizePixel = 0}, track)
            corner(knob, 0, true)
            local function render(animate)
                local pos = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                local col = state and Theme.Accent or Theme.Stroke
                local kcol = state and Theme.OnAccent or Theme.SubText
                if animate then
                    tween(track, {BackgroundColor3 = col})
                    tween(knob, {Position = pos, BackgroundColor3 = kcol})
                else
                    track.BackgroundColor3 = col
                    knob.Position = pos
                    knob.BackgroundColor3 = kcol
                end
            end
            reg(function()
                render(false)
            end)
            local obj = {}
            function obj.Set(v, silent)
                state = v and true or false
                render(true)
                if not silent then
                    fire(callback, state)
                end
            end
            function obj.Get()
                return state
            end
            row.MouseButton1Click:Connect(function()
                obj.Set(not state)
            end)
            addRow(row, text)
            return obj
        end

        function child.Slider(text, min, max, default, step, suffix, callback)
            local row, obj = makeSlider(scroll, text, min, max, default, step, suffix, callback)
            addRow(row, text)
            return obj
        end

        function child.TextBox(text, default, placeholder, callback)
            local row = new("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1})
            local label = new("TextLabel", {Text = text, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Left, TextTruncate = AtEnd}, row)
            styleText(label, "Text", 0)
            local box = new("TextBox", {Text = default or "", PlaceholderText = placeholder or "", ClearTextOnFocus = false, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 28), TextXAlignment = Left}, row)
            fill(box, "Element")
            corner(box, -6)
            stroke(box)
            pad(box, 10, 0, 10, 0)
            styleText(box, "Text", -1)
            box.FocusLost:Connect(function(enter)
                fire(callback, box.Text, enter)
            end)
            addRow(row, text)
            return {
                Get = function()
                    return box.Text
                end,
                Set = function(t)
                    box.Text = t
                end
            }
        end

        function child.ColorPicker(text, default, callback)
            local color = default
            local rgb = {math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5)}
            local row = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1})
            new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = ByOrder}, row)
            local head = new("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 1}, row)
            local label = new("TextLabel", {Text = text, BackgroundTransparency = 1, Size = UDim2.new(1, -52, 1, 0), TextXAlignment = Left, TextTruncate = AtEnd}, head)
            styleText(label, "Text", 0)
            local swatch = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(40, 20), BorderSizePixel = 0, BackgroundColor3 = color}, head)
            corner(swatch, -8)
            stroke(swatch)
            local panel = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BorderSizePixel = 0, Visible = false, LayoutOrder = 2}, row)
            fill(panel, "Element")
            corner(panel, -6)
            pad(panel, 8, 8, 8, 6)
            new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = ByOrder}, panel)

            local sliderObjs = {}
            local function commit(silent)
                color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
                swatch.BackgroundColor3 = color
                if not silent then
                    fire(callback, color)
                end
            end
            local names = {"Vermelho", "Verde", "Azul"}
            for i = 1, 3 do
                local r2, s = makeSlider(scroll, names[i], 0, 255, rgb[i], 1, "", function(v)
                    rgb[i] = v
                    commit(false)
                end)
                r2.LayoutOrder = i
                r2.Parent = panel
                sliderObjs[i] = s
            end

            head.MouseButton1Click:Connect(function()
                panel.Visible = not panel.Visible
            end)

            local obj = {}
            function obj.Set(c, silent)
                rgb = {math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)}
                for i = 1, 3 do
                    sliderObjs[i].Set(rgb[i], true)
                end
                commit(silent)
            end
            function obj.Get()
                return color
            end
            addRow(row, text)
            return obj
        end

        function child.Dropdown(text, options, default, multi, callback)
            local single = nil
            local selected = {}
            if multi then
                if type(default) == "table" then
                    for _, v in ipairs(default) do
                        selected[v] = true
                    end
                end
            else
                single = default or options[1]
            end

            local row = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1})
            new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = ByOrder}, row)
            local head = new("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 30), BorderSizePixel = 0, LayoutOrder = 1}, row)
            fill(head, "Element")
            corner(head, -6)
            stroke(head)
            hover(head, "Element", "ElementHover")
            local nameLabel = new("TextLabel", {Text = text, BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.5, -10, 1, 0), TextXAlignment = Left, TextTruncate = AtEnd}, head)
            styleText(nameLabel, "SubText", -1)
            local valueLabel = new("TextLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -26, 0, 0), Size = UDim2.new(0.5, -26, 1, 0), TextXAlignment = Right, TextTruncate = AtEnd}, head)
            styleText(valueLabel, "Text", -1)
            local arrow = new("TextLabel", {Text = ">", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(18, 18), Rotation = 90}, head)
            styleText(arrow, "SubText", -1)

            local list = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BorderSizePixel = 0, Visible = false, LayoutOrder = 2}, row)
            fill(list, "Element")
            corner(list, -6)
            pad(list, 6, 6, 6, 6)

            local open = false
            local buttons = {}
            local builtStyle = nil

            local function isOn(opt)
                if multi then
                    return selected[opt] == true
                end
                return single == opt
            end

            local function getValue()
                if multi then
                    local out = {}
                    for _, o in ipairs(options) do
                        if selected[o] then
                            table.insert(out, o)
                        end
                    end
                    return out
                end
                return single
            end

            local function updateHeader()
                if multi then
                    local picked = getValue()
                    if #picked == 0 then
                        valueLabel.Text = "Nenhum"
                    elseif #picked <= 2 then
                        valueLabel.Text = table.concat(picked, ", ")
                    else
                        valueLabel.Text = #picked .. " selecionados"
                    end
                else
                    valueLabel.Text = tostring(single or "")
                end
            end

            local function setOpen(v)
                open = v
                list.Visible = v
                arrow.Rotation = v and 270 or 90
            end
            head.MouseButton1Click:Connect(function()
                setOpen(not open)
            end)

            local function paintButtons()
                local style = Theme.DropdownStyle
                for opt, b in pairs(buttons) do
                    local on = isOn(opt)
                    b.Font = themeFont()
                    b.TextSize = Theme.TextSize - 1
                    if style == "Minimalista" then
                        b.BackgroundColor3 = Theme.Accent
                        b.BackgroundTransparency = on and 0.82 or 1
                        b.TextColor3 = on and Theme.Accent or Theme.SubText
                    else
                        b.BackgroundColor3 = on and Theme.Accent or Theme.Surface
                        b.BackgroundTransparency = 0
                        b.TextColor3 = on and Theme.OnAccent or Theme.Text
                    end
                    local cr = b:FindFirstChildOfClass("UICorner")
                    if cr then
                        cr.CornerRadius = (style == "Pílula") and UDim.new(1, 0) or UDim.new(0, math.max(2, Theme.Radius - 8))
                    end
                end
            end

            local function rebuild()
                for _, c in ipairs(list:GetChildren()) do
                    if c:IsA("TextButton") or c:IsA("UIListLayout") or c:IsA("UIGridLayout") then
                        c:Destroy()
                    end
                end
                buttons = {}
                local style = Theme.DropdownStyle
                if style == "Grade" then
                    new("UIGridLayout", {CellSize = UDim2.new(0.5, -3, 0, 28), CellPadding = UDim2.fromOffset(6, 6), SortOrder = ByOrder}, list)
                elseif style == "Pílula" then
                    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = ByOrder}, list)
                else
                    new("UIListLayout", {Padding = UDim.new(0, style == "Minimalista" and 1 or 4), SortOrder = ByOrder}, list)
                end
                for i, opt in ipairs(options) do
                    local b = new("TextButton", {Text = tostring(opt), AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i, TextTruncate = AtEnd}, list)
                    new("UICorner", nil, b)
                    if style == "Pílula" then
                        b.AutomaticSize = AX
                        b.Size = UDim2.fromOffset(0, 26)
                        pad(b, 12, 0, 12, 0)
                        b.TextXAlignment = Center
                    elseif style == "Grade" then
                        b.TextXAlignment = Center
                    elseif style == "Minimalista" then
                        b.Size = UDim2.new(1, 0, 0, 26)
                        pad(b, 10, 0, 10, 0)
                        b.TextXAlignment = Left
                    else
                        b.Size = UDim2.new(1, 0, 0, 26)
                        b.TextXAlignment = Center
                    end
                    buttons[opt] = b
                    b.MouseButton1Click:Connect(function()
                        if multi then
                            selected[opt] = not selected[opt]
                            updateHeader()
                            paintButtons()
                            fire(callback, getValue())
                        else
                            single = opt
                            updateHeader()
                            paintButtons()
                            setOpen(false)
                            fire(callback, single)
                        end
                    end)
                end
                paintButtons()
            end

            reg(function()
                if builtStyle ~= Theme.DropdownStyle then
                    builtStyle = Theme.DropdownStyle
                    rebuild()
                end
                paintButtons()
            end)
            updateHeader()

            local obj = {}
            function obj.Get()
                return getValue()
            end
            function obj.Set(v, silent)
                if multi then
                    selected = {}
                    if type(v) == "table" then
                        for _, o in ipairs(v) do
                            selected[o] = true
                        end
                    end
                else
                    single = v
                end
                updateHeader()
                paintButtons()
                if not silent then
                    fire(callback, getValue())
                end
            end
            addRow(row, text .. " " .. table.concat(options, " "))
            return obj
        end

        table.insert(page.children, child)
        return child
    end

    table.insert(Pages, page)
    return page
end

local Toasts = new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(290, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 10}, Gui)
new("UIListLayout", {Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = ByOrder}, Toasts)

local function notify(title, body, duration)
    local t = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BorderSizePixel = 0, BackgroundColor3 = Theme.Surface, ZIndex = 10}, Toasts)
    new("UICorner", {CornerRadius = UDim.new(0, math.max(6, Theme.Radius - 3))}, t)
    new("UIStroke", {Color = Theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, t)
    new("Frame", {Position = UDim2.fromOffset(0, 13), Size = UDim2.new(0, 4, 1, -26), BorderSizePixel = 0, BackgroundColor3 = Theme.Accent, ZIndex = 11}, t)
    local content = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10}, t)
    pad(content, 16, 9, 12, 9)
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = ByOrder}, content)
    new("TextLabel", {Text = title, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 17), TextXAlignment = Left, Font = themeFont(), TextSize = math.max(12, Theme.TextSize - 1), TextColor3 = Theme.Accent, LayoutOrder = 1, ZIndex = 10}, content)
    new("TextLabel", {Text = body, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Left, TextYAlignment = Enum.TextYAlignment.Top, Font = themeFont(), TextSize = math.max(11, Theme.TextSize - 2), TextColor3 = Theme.Text, LayoutOrder = 2, ZIndex = 10}, content)
    task.delay(duration or 3, function()
        if t and t.Parent then
            t:Destroy()
        end
    end)
end

local function copy(text)
    local fn = setclipboard or toclipboard
    if fn then
        fn(text)
        notify("Copiado", text)
    else
        notify("Indisponível", "O executor não suporta área de transferência.")
    end
end

local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ============================================================
-- TEAM CHECK MELHORADO (combina todas as abordagens)
-- ============================================================
local function getTeamSignature(player)
    if not player then return nil end
    local sigs = {}

    -- 1. Team object
    if player.Team ~= nil then
        table.insert(sigs, "team:" .. player.Team.Name)
    end

    -- 2. TeamColor
    if player.TeamColor ~= nil then
        table.insert(sigs, "color:" .. tostring(player.TeamColor))
    end

    -- 3. Neutral
    if player.Neutral ~= nil then
        table.insert(sigs, "neutral:" .. tostring(player.Neutral))
    end

    -- 4. Atributos no Player
    local attrs = {"Team", "TeamId", "team", "teamId", "TeamColor", "teamColor", "TeamName", "teamName", "TeamID", "team_id", "Faction", "faction", "Alignment", "alignment", "Side", "side", "Group", "group"}
    for _, a in ipairs(attrs) do
        local v = player:GetAttribute(a)
        if v ~= nil then
            table.insert(sigs, "attr:" .. a .. ":" .. tostring(v))
        end
    end

    -- 5. Atributos no Character
    local char = player.Character
    if char then
        for _, a in ipairs(attrs) do
            local v = char:GetAttribute(a)
            if v ~= nil then
                table.insert(sigs, "cattr:" .. a .. ":" .. tostring(v))
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, a in ipairs(attrs) do
                local v = hum:GetAttribute(a)
                if v ~= nil then
                    table.insert(sigs, "hattr:" .. a .. ":" .. tostring(v))
                end
            end
        end
    end

    if #sigs == 0 then return nil end
    return sigs
end

local function isSameTeam(player)
    if not player or not LocalPlayer or player == LocalPlayer then return false end
    -- Neutral/FFA nunca deve classificar dois jogadores como aliados apenas por valores padrão.
    if LocalPlayer.Neutral == true or player.Neutral == true then return false end
    if LocalPlayer.Team ~= nil and player.Team ~= nil then
        return LocalPlayer.Team == player.Team or LocalPlayer.Team.Name == player.Team.Name
    end
    if LocalPlayer.TeamColor ~= nil and player.TeamColor ~= nil
        and tostring(LocalPlayer.TeamColor) ~= "Medium stone grey" then
        return LocalPlayer.TeamColor == player.TeamColor
    end
    -- Metadados só são comparados pela mesma chave e mesma origem; evita falsos positivos
    -- por valores coincidentes em atributos sem relação (ex.: Side="Blue" vs Faction="Blue").
    local keys = {"Team", "TeamId", "team", "teamId", "TeamColor", "teamColor", "TeamName", "teamName", "TeamID", "team_id", "Faction", "faction", "Alignment", "alignment", "Side", "side", "Group", "group"}
    local function matchingAttributes(a, b, names)
        for _, key in ipairs(names) do
            local av, bv = a:GetAttribute(key), b:GetAttribute(key)
            if av ~= nil and bv ~= nil and typeof(av) == typeof(bv) and av == bv then return true end
        end
        return false
    end
    if matchingAttributes(LocalPlayer, player, keys) then return true end
    local a, b = LocalPlayer.Character, player.Character
    if a and b and matchingAttributes(a, b, keys) then return true end
    local ah = a and a:FindFirstChildOfClass("Humanoid")
    local bh = b and b:FindFirstChildOfClass("Humanoid")
    if ah and bh and matchingAttributes(ah, bh, keys) then return true end
    return false
end
-- ============================================================
-- TABS COM ÍCONES
-- ============================================================
local pPerfil = addTab("Perfil")
local pPrincipal = addTab("Principal")
local pVisual = addTab("Visual")
local pAim = addTab("Aim")
local pSilent = pAim -- controles Silent ficam agrupados na aba Aim
local pComponentes = addTab("Componentes")
local pPersonalizar = addTab("Personalizar")

local fpsHud, pingHud
do
local membership = LocalPlayer.MembershipType.Name
if membership == "None" then
    membership = "Nenhuma"
end

local profile = pPerfil.BeginChild("Perfil do Roblox", "left")
local card = profile.Custom(70, "perfil avatar nome usuario")
local avatar = new("ImageLabel", {Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(0, 3), BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop}, card)
fill(avatar, "Element")
corner(avatar, 0, true)
stroke(avatar, "Accent", 2)
local cardName = new("TextLabel", {Text = LocalPlayer.DisplayName, BackgroundTransparency = 1, Position = UDim2.fromOffset(76, 6), Size = UDim2.new(1, -76, 0, 24), TextXAlignment = Left, TextTruncate = AtEnd}, card)
styleText(cardName, "Text", 4)
local cardUser = new("TextLabel", {Text = "@" .. LocalPlayer.Name, BackgroundTransparency = 1, Position = UDim2.fromOffset(76, 32), Size = UDim2.new(1, -76, 0, 16), TextXAlignment = Left, TextTruncate = AtEnd}, card)
styleText(cardUser, "SubText", -1)
local cardId = new("TextLabel", {Text = "ID " .. tostring(LocalPlayer.UserId), BackgroundTransparency = 1, Position = UDim2.fromOffset(76, 48), Size = UDim2.new(1, -76, 0, 16), TextXAlignment = Left, TextTruncate = AtEnd}, card)
styleText(cardId, "SubText", -1)

task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)
    if ok and img then
        avatar.Image = img
    end
end)

profile.Info("Usuário", LocalPlayer.Name)
profile.Info("Nome de exibição", LocalPlayer.DisplayName)
profile.Info("ID do usuário", tostring(LocalPlayer.UserId))
profile.Info("Idade da conta", LocalPlayer.AccountAge .. " dias")
profile.Info("Conta criada em", os.date("%d/%m/%Y", os.time() - LocalPlayer.AccountAge * 86400))
profile.Info("Assinatura", membership)
profile.Info("Idioma", LocalPlayer.LocaleId)
profile.Button("Copiar ID do usuário", function()
    copy(tostring(LocalPlayer.UserId))
end)
profile.Button("Copiar nome de usuário", function()
    copy(LocalPlayer.Name)
end)

local execName = "Desconhecido"
pcall(function()
    if identifyexecutor then
        local n, v = identifyexecutor()
        execName = tostring(n) .. (v and (" " .. tostring(v)) or "")
    end
end)

local session = pPerfil.BeginChild("Sessão", "right")
local infoExec = session.Info("Executor", execName)
local infoGame = session.Info("Jogo", "Carregando...")
session.Info("Place ID", tostring(game.PlaceId))
session.Info("Servidor", game.JobId ~= "" and (string.sub(game.JobId, 1, 8) .. "...") or "Local")
local infoPlayers = session.Info("Jogadores", "-")
local infoPing = session.Info("Ping", "-")
local infoFps = session.Info("FPS", "-")
local infoTime = session.Info("Tempo na sessão", "00:00:00")
session.Button("Copiar Job ID", function()
    copy(game.JobId)
end)

local charInfo = pPerfil.BeginChild("Personagem", "right")
local infoHealth = charInfo.Info("Vida", "-")
local infoPos = charInfo.Info("Posição", "-")

task.spawn(function()
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    infoGame.Set(ok and info and info.Name or "Desconhecido")
end)

local function formatTime(s)
    return string.format("%02d:%02d:%02d", math.floor(s / 3600), math.floor((s % 3600) / 60), math.floor(s % 60))
end

local startClock = os.clock()
local frames, acc = 0, 0
connect(RunService.Heartbeat, function(dt)
    frames = frames + 1
    acc = acc + dt
    if acc < 1 then
        return
    end
    local fps = math.floor(frames / acc + 0.5)
    frames, acc = 0, 0
    infoFps.Set(fps .. " FPS")
    if fpsHud then
        fpsHud.Text = "FPS: " .. tostring(fps)
    end
    local pingText = "N/D"
    pcall(function()
        pingText = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) .. " ms"
    end)
    infoPing.Set(pingText)
    if pingHud then
        pingHud.Text = "MS: " .. tostring(pingText)
    end
    infoPlayers.Set(#Players:GetPlayers() .. "/" .. Players.MaxPlayers)
    infoTime.Set(formatTime(os.clock() - startClock))
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    infoHealth.Set(hum and (math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) or "N/D")
    if root then
        infoPos.Set(math.floor(root.Position.X) .. ", " .. math.floor(root.Position.Y) .. ", " .. math.floor(root.Position.Z))
    else
        infoPos.Set("N/D")
    end
end)
end

local modEnabled = false
local walkValue, jumpValue = 16, 50

local player = pPrincipal.BeginChild("Jogador", "left")
player.Toggle("Aplicar modificações", false, function(v)
    modEnabled = v
    if not v then
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = 16
            hum.UseJumpPower = true
            hum.JumpPower = 50
        end
    end
end)
player.Slider("Velocidade de caminhada", 16, 250, 16, 1, "", function(v)
    walkValue = v
end)
player.Slider("Força do pulo", 50, 300, 50, 1, "", function(v)
    jumpValue = v
end)

local modAcc = 0
connect(RunService.Heartbeat, function(dt)
    modAcc = modAcc + dt
    if modAcc < 0.2 then
        return
    end
    modAcc = 0
    if modEnabled then
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = walkValue
            hum.UseJumpPower = true
            hum.JumpPower = jumpValue
        end
    end
end)

local cameraChild = pPrincipal.BeginChild("Câmera", "right")
local initialCamera = workspace.CurrentCamera
local initialFov = initialCamera and math.floor(initialCamera.FieldOfView + 0.5) or 70
local fovSlider = cameraChild.Slider("Campo de visão", 30, 120, initialFov, 1, "°", function(v)
    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = v
    end
end)
local zoomSlider = cameraChild.Slider("Zoom máximo", 10, 1000, math.clamp(math.floor(LocalPlayer.CameraMaxZoomDistance), 10, 1000), 10, "", function(v)
    LocalPlayer.CameraMaxZoomDistance = v
end)
cameraChild.Button("Resetar câmera", function()
    fovSlider.Set(70)
    zoomSlider.Set(128)
end)

local statsFloat = new("Frame", {Name = "PerformanceFloat", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(148, 30), BorderSizePixel = 0, Visible = false, ZIndex = 4}, Gui)
fill(statsFloat, "Surface")
corner(statsFloat, 0, true)
stroke(statsFloat, "Accent")
pad(statsFloat, 10, 5, 10, 5)
fpsHud = new("TextLabel", {Text = "FPS: -", BackgroundTransparency = 1, Size = UDim2.new(0.5, -8, 1, 0), TextXAlignment = Center, ZIndex = 4}, statsFloat)
new("Frame", {Position = UDim2.new(0.5, -1, 0, 6), Size = UDim2.new(0, 2, 1, -12), BorderSizePixel = 0, BackgroundColor3 = Theme.Stroke, ZIndex = 5}, statsFloat)
pingHud = new("TextLabel", {Text = "MS: -", BackgroundTransparency = 1, Position = UDim2.new(0.5, 8, 0, 0), Size = UDim2.new(0.5, -8, 1, 0), TextXAlignment = Center, ZIndex = 4}, statsFloat)
styleText(fpsHud, "Accent", -1)
styleText(pingHud, "SubText", -1)
makeDraggable(statsFloat, statsFloat)

local crosshair = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Visible = false, ZIndex = 4}, Gui)
local crosshairH = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 2), BorderSizePixel = 0, ZIndex = 4}, crosshair)
local crosshairV = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(2, 18), BorderSizePixel = 0, ZIndex = 4}, crosshair)
reg(function()
    crosshairH.BackgroundColor3 = Theme.Accent
    crosshairV.BackgroundColor3 = Theme.Accent
end)

local performanceEnabled = false
local terrain = workspace:FindFirstChildOfClass("Terrain")
local terrainDecoration
if terrain then
    pcall(function()
        terrainDecoration = terrain.Decoration
    end)
end
local performanceOriginal = {
    GlobalShadows = Lighting.GlobalShadows,
    Decoration = terrainDecoration,
    Effects = {}
}
for _, effect in ipairs(Lighting:GetChildren()) do
    if effect:IsA("PostEffect") then
        performanceOriginal.Effects[effect] = effect.Enabled
    end
end
local function setPerformanceMode(enabled)
    performanceEnabled = enabled
    pcall(function()
        Lighting.GlobalShadows = (not enabled) and performanceOriginal.GlobalShadows
    end)
    if terrain and performanceOriginal.Decoration ~= nil then
        pcall(function()
            terrain.Decoration = (not enabled) and performanceOriginal.Decoration
        end)
    end
    for effect, wasEnabled in pairs(performanceOriginal.Effects) do
        if effect and effect.Parent then
            pcall(function()
                effect.Enabled = (not enabled) and wasEnabled
            end)
        end
    end
    if enabled then
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                pcall(function()
                    effect.Enabled = false
                end)
            end
        end
    end
end

local fpsPerformance = pVisual.BeginChild("Desempenho", "left")
fpsPerformance.Label("Opções visuais para melhorar a fluidez em jogos de FPS.", true)
fpsPerformance.Toggle("Modo desempenho", false, function(v)
    setPerformanceMode(v)
    notify(v and "Modo desempenho ativado" or "Modo desempenho desativado", v and "Sombras e efeitos visuais reduzidos." or "Configurações visuais originais restauradas.")
end)
fpsPerformance.Button("Restaurar configurações visuais", function()
    setPerformanceMode(false)
    notify("Configurações restauradas", "Sombras e efeitos visuais originais restaurados.")
end)

local fpsVisuals = pVisual.BeginChild("Interface", "right")
fpsVisuals.Toggle("Contador de FPS na tela", false, function(v)
    statsFloat.Visible = v
    notify(v and "Painel de desempenho ativado" or "Painel de desempenho desativado", v and "FPS e ms serão mostrados no painel flutuante." or "O painel flutuante foi ocultado.")
end)
fpsVisuals.Toggle("Mira na tela", false, function(v)
    crosshair.Visible = v
    notify(v and "Mira ativada" or "Mira desativada", v and "A mira foi exibida no centro da tela." or "A mira foi ocultada.")
end)

do
    local espEnabled = false
    local espBoxEnabled = false
    local espLineEnabled = false
    local espHealthEnabled = false
    local espNameEnabled = false
    local espDistanceEnabled = false
    local espFillEnabled = false
    -- Aliados ficam ocultos por padrão na ESP.
    local espHideAllies = true
    local espBoxColor = Theme.Accent
    local espLineColor = Theme.Accent
    local espHealthColor = RGB(80, 210, 110)
    local espTextColor = Theme.Text
    local espLineOrigin = "Baixo compacto"
    local espBoxStyle = "Borda"
    local espWidthFactor = 55
    local espThickness = 1
    local espFillOpacity = 15
    local espMaxDistance = 5000
    local espEntries = {}
    local espFont = themeFont()
    local espOverlay = new("Frame", {Name = "NovaMenuVisual", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = true, ZIndex = 0}, Gui)

    local function getCharacterRoot(character)
        return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
    end

    local function newPill(parent, anchorY, textSize)
        local label = new("TextLabel", {BackgroundColor3 = RGB(8, 8, 10), BackgroundTransparency = 0.3, BorderSizePixel = 0, AutomaticSize = AX, Size = UDim2.fromOffset(0, textSize + 5), AnchorPoint = Vector2.new(0.5, anchorY), Visible = false, ZIndex = 4, Font = espFont, TextSize = textSize, TextColor3 = espTextColor}, parent)
        new("UICorner", {CornerRadius = UDim.new(1, 0)}, label)
        pad(label, 7, 0, 7, 0)
        local labelStroke = new("UIStroke", {Thickness = 1, Transparency = 0.45, Color = espBoxColor, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, label)
        return label, labelStroke
    end

    local function destroyEspEntry(player)
        local entry = espEntries[player]
        if not entry then
            return
        end
        entry.holder:Destroy()
        entry.line:Destroy()
        entry.dot:Destroy()
        espEntries[player] = nil
    end

    local function createEspEntry(player)
        if player == LocalPlayer or espEntries[player] then
            return
        end
        local holder = new("Frame", {Name = "Player", BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 2}, espOverlay)
        local shadow = new("Frame", {Name = "Shadow", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(-1, -1), Size = UDim2.new(1, 2, 1, 2), Visible = false, ZIndex = 2}, holder)
        new("UICorner", {CornerRadius = UDim.new(0, 4)}, shadow)
        local shadowStroke = new("UIStroke", {Thickness = 3, Transparency = 0.45, Color = RGB(0, 0, 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, shadow)
        local box = new("Frame", {Name = "Box", BackgroundColor3 = espBoxColor, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 3}, holder)
        new("UICorner", {CornerRadius = UDim.new(0, 3)}, box)
        local boxStroke = new("UIStroke", {Thickness = 1, Color = espBoxColor, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, box)
        local corners = {}
        for i = 1, 8 do
            local piece = new("Frame", {Name = "Corner" .. i, BorderSizePixel = 0, BackgroundColor3 = espBoxColor, Visible = false, ZIndex = 4}, holder)
            new("UIStroke", {Thickness = 1, Transparency = 0.5, Color = RGB(0, 0, 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, piece)
            corners[i] = piece
        end
        local hpBack = new("Frame", {Name = "HealthBack", BackgroundColor3 = RGB(12, 12, 14), BackgroundTransparency = 0.2, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0, -5, 0, 0), Size = UDim2.new(0, 4, 1, 0), Visible = false, ZIndex = 3}, holder)
        new("UICorner", {CornerRadius = UDim.new(1, 0)}, hpBack)
        new("UIStroke", {Thickness = 1, Transparency = 0.35, Color = RGB(0, 0, 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, hpBack)
        -- O preenchimento cresce de baixo para cima e sua altura é atualizada pela vida atual.
        local hpFill = new("Frame", {Name = "Fill", BorderSizePixel = 0, BackgroundColor3 = espHealthColor, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 1), ZIndex = 4}, hpBack)
        new("UICorner", {CornerRadius = UDim.new(1, 0)}, hpFill)
        local hpText = new("TextLabel", {Name = "HealthText", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0, -12, 0, 0), Size = UDim2.fromOffset(30, 12), TextXAlignment = Right, TextStrokeTransparency = 0.35, TextStrokeColor3 = RGB(0, 0, 0), Visible = false, ZIndex = 4, Font = espFont, TextSize = 10, TextColor3 = espHealthColor}, holder)
        local nameLabel, nameStroke = newPill(holder, 1, 12)
        nameLabel.Name = "Name"
        nameLabel.Position = UDim2.new(0.5, 0, 0, -6)
        local distLabel, distStroke = newPill(holder, 0, 11)
        distLabel.Name = "Distance"
        distLabel.Position = UDim2.new(0.5, 0, 1, 6)
        local line = new("Frame", {Name = "Line", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = espLineColor, BorderSizePixel = 0, Visible = false, ZIndex = 2}, espOverlay)
        new("UIStroke", {Thickness = 1, Transparency = 0.7, Color = RGB(0, 0, 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, line)
        new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(1, 0)})}, line)
        local dot = new("Frame", {Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = espLineColor, BorderSizePixel = 0, Size = UDim2.fromOffset(7, 7), Visible = false, ZIndex = 3}, espOverlay)
        new("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
        new("UIStroke", {Thickness = 1, Transparency = 0.35, Color = RGB(0, 0, 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, dot)
        espEntries[player] = {shown = false, holder = holder, shadow = shadow, shadowStroke = shadowStroke, box = box, boxStroke = boxStroke, corners = corners, hpBack = hpBack, hpFill = hpFill, hpText = hpText, name = nameLabel, nameStroke = nameStroke, dist = distLabel, distStroke = distStroke, line = line, dot = dot}
    end

    local function hideEspEntry(entry)
        if entry.shown then
            entry.shown = false
            entry.holder.Visible = false
            entry.line.Visible = false
            entry.dot.Visible = false
        end
    end

    local function setLine(line, from, to, thickness)
        local delta = to - from
        local midpoint = (from + to) / 2
        line.Position = UDim2.fromOffset(midpoint.X, midpoint.Y)
        line.Size = UDim2.fromOffset(math.max(1, delta.Magnitude), math.max(1, thickness))
        line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    end

    local function placePiece(piece, x, y, w, h)
        piece.Position = UDim2.fromOffset(x, y)
        piece.Size = UDim2.fromOffset(w, h)
    end

    local function layoutCorners(entry, width, height, thickness)
        -- Comprimento fixo/limitado: evita que a box pareça uma borda arredondada
        -- quando o personagem muda de escala pela distância da câmera.
        local length = math.clamp(math.floor(math.min(width, height) * 0.12), 7, 14)
        local c = entry.corners
        placePiece(c[1], 0, 0, length, thickness)
        placePiece(c[2], 0, 0, thickness, length)
        placePiece(c[3], width - length, 0, length, thickness)
        placePiece(c[4], width - thickness, 0, thickness, length)
        placePiece(c[5], 0, height - thickness, length, thickness)
        placePiece(c[6], 0, height - length, thickness, length)
        placePiece(c[7], width - length, height - thickness, length, thickness)
        placePiece(c[8], width - thickness, height - length, thickness, length)
    end

    local function getEspBounds(camera, character, root, humanoid)
        local head = character:FindFirstChild("Head")
        local topWorld, bottomWorld
        if head and head:IsA("BasePart") then
            topWorld = head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.2, 0)
            bottomWorld = root.Position - Vector3.new(0, root.Size.Y * 0.5 + math.max(humanoid.HipHeight, 2), 0)
        else
            local ok, cf, size = pcall(function()
                return character:GetBoundingBox()
            end)
            if not ok or not cf or not size then
                return nil
            end
            topWorld = cf.Position + Vector3.new(0, size.Y * 0.5, 0)
            bottomWorld = cf.Position - Vector3.new(0, size.Y * 0.5, 0)
        end
        local top, topVisible = camera:WorldToViewportPoint(topWorld)
        local bottom, bottomVisible = camera:WorldToViewportPoint(bottomWorld)
        local _, rootVisible = camera:WorldToViewportPoint(root.Position)
        if top.Z <= 0 or bottom.Z <= 0 then
            return nil
        end
        if not (topVisible or bottomVisible or rootVisible) then
            return nil
        end
        local height = math.max(12, math.abs(bottom.Y - top.Y))
        local width = math.max(8, height * (espWidthFactor / 100))
        return (top.X + bottom.X) * 0.5, math.min(top.Y, bottom.Y), width, height
    end

    local function updateEspEntry(player, entry, camera, viewport)
        local character = player.Character
        local root = getCharacterRoot(character)
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not (espEnabled and camera and viewport and root and humanoid and humanoid.Health > 0) then
            hideEspEntry(entry)
            return
        end
        if espHideAllies and isSameTeam(player) then
            hideEspEntry(entry)
            return
        end
        local distance = (camera.CFrame.Position - root.Position).Magnitude
        if distance > espMaxDistance then
            hideEspEntry(entry)
            return
        end
        local centerX, top, width, height = getEspBounds(camera, character, root, humanoid)
        if not centerX then
            hideEspEntry(entry)
            return
        end
        entry.shown = true
        local left = centerX - width * 0.5
        local thickness = math.max(1, espThickness)
        entry.holder.Position = UDim2.fromOffset(left, top)
        entry.holder.Size = UDim2.fromOffset(width, height)
        entry.holder.Visible = true

        local bordered = espBoxStyle == "Borda"
        entry.box.Visible = espBoxEnabled
        entry.box.BackgroundColor3 = espBoxColor
        entry.box.BackgroundTransparency = espFillEnabled and (1 - espFillOpacity / 100) or 1
        entry.boxStroke.Enabled = bordered
        entry.boxStroke.Color = espBoxColor
        entry.boxStroke.Thickness = thickness
        entry.shadow.Visible = espBoxEnabled and bordered
        entry.shadowStroke.Thickness = thickness + 2
        local cornersOn = espBoxEnabled and not bordered
        for _, piece in ipairs(entry.corners) do
            piece.Visible = cornersOn
            piece.BackgroundColor3 = espBoxColor
        end
        if cornersOn then
            layoutCorners(entry, width, height, thickness)
        end

        entry.hpBack.Visible = espHealthEnabled
        entry.hpText.Visible = espHealthEnabled and height >= 34
        if espHealthEnabled then
            -- A proporção da barra é sempre a vida atual dividida pela vida máxima.
            -- O AnchorPoint/Position do hpFill fazem a barra diminuir de cima para baixo.
            local maxHealth = math.max(tonumber(humanoid.MaxHealth) or 0, 1)
            local currentHealth = math.clamp(tonumber(humanoid.Health) or 0, 0, maxHealth)
            local ratio = math.clamp(currentHealth / maxHealth, 0, 1)
            local hpColor = espHealthColor:Lerp(RGB(220, 75, 75), 1 - ratio)

            entry.hpFill.AnchorPoint = Vector2.new(0, 1)
            entry.hpFill.Position = UDim2.fromScale(0, 1)
            entry.hpFill.Size = UDim2.fromScale(1, ratio)
            entry.hpFill.BackgroundColor3 = hpColor
            entry.hpText.Position = UDim2.new(0, -12, 1 - ratio, 0)
            entry.hpText.Text = tostring(math.ceil(currentHealth))
            entry.hpText.TextColor3 = hpColor
        end

        entry.name.Visible = espNameEnabled
        if espNameEnabled then
            entry.name.Text = player.DisplayName
            entry.name.TextColor3 = espTextColor
            entry.nameStroke.Color = espBoxColor
        end
        entry.dist.Visible = espDistanceEnabled
        if espDistanceEnabled then
            entry.dist.Text = string.format("%d m", math.floor(distance + 0.5))
            entry.dist.TextColor3 = espTextColor
            entry.distStroke.Color = espBoxColor
        end

        if espLineEnabled then
            local centerY = top + height * 0.5
            local origin, target
            -- A linha termina bem próxima da box e a bolinha fica no ponto de
            -- encaixe. A margem impede que a linha fique colada no limite da tela.
            local lineGap = math.max(1, math.min(3, thickness))
            local screenMargin = 12
            if espLineOrigin == "Topo" then
                origin = Vector2.new(viewport.X * 0.5, screenMargin)
                target = Vector2.new(centerX, top - lineGap)
            elseif espLineOrigin == "Centro" then
                origin = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
                target = Vector2.new(centerX, centerY)
            elseif espLineOrigin == "Esquerda" then
                origin = Vector2.new(screenMargin, viewport.Y * 0.5)
                target = Vector2.new(left - lineGap, centerY)
            elseif espLineOrigin == "Direita" then
                origin = Vector2.new(viewport.X - screenMargin, viewport.Y * 0.5)
                target = Vector2.new(left + width + lineGap, centerY)
            else
                origin = Vector2.new(viewport.X * 0.5, viewport.Y - screenMargin)
                target = Vector2.new(centerX, top + height + lineGap)
            end
            local offset = espOverlay.AbsolutePosition
            setLine(entry.line, origin - offset, target - offset, thickness)
            entry.line.BackgroundColor3 = espLineColor
            entry.line.Visible = true
            entry.dot.Position = UDim2.fromOffset(target.X - offset.X, target.Y - offset.Y)
            entry.dot.BackgroundColor3 = espLineColor
            entry.dot.Visible = true
        else
            entry.line.Visible = false
            entry.dot.Visible = false
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        createEspEntry(player)
    end
    connect(Players.PlayerAdded, createEspEntry)
    connect(Players.PlayerRemoving, destroyEspEntry)
    connect(RunService.RenderStepped, function()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize
        local font = themeFont()
        local fontChanged = font ~= espFont
        if fontChanged then
            espFont = font
        end
        for player, entry in pairs(espEntries) do
            if espEnabled or entry.shown then
                updateEspEntry(player, entry, camera, viewport)
            end
            if fontChanged then
                entry.name.Font = font
                entry.dist.Font = font
                entry.hpText.Font = font
            end
        end
    end)

    local espChild = pVisual.BeginChild("Visual", "left")
    espChild.Toggle("Ativar visual", false, function(v)
        espEnabled = v
        notify(v and "Visual ativado" or "Visual desativado", v and "As opções selecionadas serão exibidas nos jogadores." or "Box, vida, nome e distância foram ocultados.")
    end)
    espChild.Toggle("Box", false, function(v)
        espBoxEnabled = v
        notify(v and "Box ativado" or "Box desativado", v and "A box dos jogadores foi ativada." or "A box foi ocultada.")
    end)
    espChild.Toggle("Line", false, function(v)
        espLineEnabled = v
        notify(v and "Line ativado" or "Line desativado", v and "A linha até os jogadores foi ativada." or "As linhas foram ocultadas.")
    end)
    espChild.Toggle("Health", false, function(v)
        espHealthEnabled = v
        notify(v and "Health ativado" or "Health desativado", v and "A barra de vida foi ativada." or "A barra de vida foi ocultada.")
    end)
    espChild.Toggle("Name", false, function(v)
        espNameEnabled = v
        notify(v and "Name ativado" or "Name desativado", v and "Os nomes dos jogadores foram exibidos." or "Os nomes dos jogadores foram ocultados.")
    end)
    espChild.Toggle("Distance", false, function(v)
        espDistanceEnabled = v
        notify(v and "Distance ativado" or "Distance desativado", v and "A distância dos jogadores foi exibida." or "As distâncias foram ocultadas.")
    end)
    espChild.Toggle("Preenchimento da box", false, function(v)
        espFillEnabled = v
        notify(v and "Preenchimento ativado" or "Preenchimento desativado", v and "A box agora tem preenchimento translúcido." or "O preenchimento da box foi removido.")
    end)
    espChild.Toggle("Ocultar aliados", true, function(v)
        espHideAllies = v
        notify(v and "Aliados ocultos" or "Aliados visíveis", v and "Jogadores do mesmo time não serão exibidos." or "Todos os jogadores serão exibidos.")
    end)

    local espSettings = pVisual.BeginChild("Personalizar ESP", "right")
    espSettings.ColorPicker("Cor da box", espBoxColor, function(c)
        espBoxColor = c
        notify("Cor da box alterada", "A cor da box foi atualizada.")
    end)
    espSettings.ColorPicker("Cor da line", espLineColor, function(c)
        espLineColor = c
        notify("Cor da line alterada", "A cor das linhas foi atualizada.")
    end)
    espSettings.ColorPicker("Cor da health", espHealthColor, function(c)
        espHealthColor = c
        notify("Cor da health alterada", "A cor da barra de vida foi atualizada.")
    end)
    espSettings.ColorPicker("Cor dos textos", espTextColor, function(c)
        espTextColor = c
        notify("Cor dos textos alterada", "A cor de nome, vida e distância foi atualizada.")
    end)
    espSettings.Dropdown("Local da ESP Line", {"Baixo compacto", "Centro", "Topo", "Esquerda", "Direita"}, espLineOrigin, false, function(v)
        espLineOrigin = v
        notify("Origem da line alterada", "Origem selecionada: " .. tostring(v) .. ".")
    end)
    espSettings.Dropdown("Estilo da box", {"Borda", "Cantos"}, espBoxStyle, false, function(v)
        espBoxStyle = v
        notify("Estilo da box alterado", "Estilo selecionado: " .. tostring(v) .. ".")
    end)
    espSettings.Slider("Largura da box", 30, 100, espWidthFactor, 1, "%", function(v)
        espWidthFactor = v
    end)
    espSettings.Slider("Espessura", 1, 4, espThickness, 1, " px", function(v)
        espThickness = v
    end)
    espSettings.Slider("Opacidade do preenchimento", 5, 60, espFillOpacity, 1, "%", function(v)
        espFillOpacity = v
    end)
    espSettings.Slider("Distância máxima", 100, 5000, espMaxDistance, 100, " m", function(v)
        espMaxDistance = v
    end)
end

-- ============================================================
-- AIMBOT
-- ============================================================
local aimEnabled = false
local aimHolding = false
local aimFov = 150
local aimSmooth = 0.35
local aimPart = "Head"
local aimTeamCheck = true
local aimMode = "Sempre ativo"
local aimKeyHolding = false
local aimUniversalEnabled = true
local aimPriority = "FOV"
local aimVisibleCheck = false
local aimPredictionEnabled = false
local aimPrediction = 0.08
local aimDrawFov = true
local aimFovIndicator = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(aimFov * 2, aimFov * 2), BackgroundTransparency = 1, Visible = false, ZIndex = 3}, Gui)
local aimFovCorner = new("UICorner", {CornerRadius = UDim.new(1, 0)}, aimFovIndicator)
local aimFovStroke = new("UIStroke", {Thickness = 1.5}, aimFovIndicator)
reg(function()
    aimFovStroke.Color = Theme.Accent
end)

local function getAimPart(character)
    local candidates
    if aimPart == "Head" then
        candidates = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso"}
    elseif aimPart == "HumanoidRootPart" then
        candidates = {"HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Head"}
    elseif aimPart == "UpperTorso" then
        candidates = {"UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso", "Head"}
    else
        candidates = {"Torso", "UpperTorso", "HumanoidRootPart", "LowerTorso", "Head"}
    end
    for _, name in ipairs(candidates) do
        local part = character and character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local universalModels = {}
local function registerUniversalModel(instance)
    local model = instance and (instance:IsA("Model") and instance or instance:FindFirstAncestorOfClass("Model"))
    if model and model:FindFirstChildOfClass("Humanoid") then
        universalModels[model] = true
    end
end
task.spawn(function()
    local ok, descendants = pcall(function()
        return workspace:GetDescendants()
    end)
    if ok and descendants then
        for _, instance in ipairs(descendants) do
            if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
                universalModels[instance] = true
            end
        end
    end
end)
connect(workspace.DescendantAdded, registerUniversalModel)
connect(workspace.DescendantRemoving, function(instance)
    if instance:IsA("Model") then
        universalModels[instance] = nil
    end
end)

local function getAimTarget()
    local camera = workspace.CurrentCamera
    if not camera then
        return nil
    end
    local center = camera.ViewportSize / 2
    local closest, closestScore = nil, math.huge
    local seen = {}
    local rayParams = RaycastParams.new()
    local filterOk = pcall(function()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
    end)
    if not filterOk then
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    end
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local function isVisible(model, part)
        if not aimVisibleCheck then
            return true
        end
        local direction = part.Position - camera.CFrame.Position
        local result = workspace:Raycast(camera.CFrame.Position, direction, rayParams)
        return not result or result.Instance:IsDescendantOf(model)
    end
    local function consider(model, player)
        if not model or seen[model] or model == LocalPlayer.Character then
            return
        end
        seen[model] = true
        if player and aimTeamCheck and isSameTeam(player) then
            return
        end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local part = getAimPart(model)
        if humanoid and humanoid.Health > 0 and part then
            local point, visible = camera:WorldToViewportPoint(part.Position)
            if visible and point.Z > 0 and isVisible(model, part) then
                local screenDistance = (Vector2.new(point.X, point.Y) - center).Magnitude
                local score = aimPriority == "Distância" and (camera.CFrame.Position - part.Position).Magnitude or (aimPriority == "Vida" and humanoid.Health or screenDistance)
                if screenDistance <= aimFov and (closest == nil or score < closestScore) then
                    closest = part
                    closestScore = score
                end
            end
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        consider(player.Character, player)
    end
    if aimUniversalEnabled then
        for model in pairs(universalModels) do
            consider(model, Players:GetPlayerFromCharacter(model))
        end
    end
    return closest
end

local function isSelectedAimKey(input)
    if aimMode == "Segurar Shift" then
        return input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift
    elseif aimMode == "Segurar Alt" then
        return input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt
    elseif aimMode == "Segurar Ctrl" then
        return input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl
    end
    return false
end

connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimHolding = true
    elseif isSelectedAimKey(input) then
        aimKeyHolding = true
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimHolding = false
    elseif isSelectedAimKey(input) then
        aimKeyHolding = false
    end
end)
local function isAimActivationHeld()
    if aimMode == "Sempre ativo" then
        return true
    elseif aimMode == "Segurar botão direito" then
        return aimHolding
    else
        return aimKeyHolding
    end
end

RunService:BindToRenderStep("NovaMenuAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    -- Main.Visible não bloqueia o aim; apenas um TextBox em edição pausa a mira.
    if not aimEnabled or UserInputService:GetFocusedTextBox() ~= nil
        or not isAimActivationHeld() then
        return
    end
    local camera = workspace.CurrentCamera
    local target = getAimTarget()
    if camera and target then
        local targetPosition = target.Position
        if aimPredictionEnabled then
            local velocity = target.AssemblyLinearVelocity
            targetPosition = targetPosition + velocity * aimPrediction
        end
        local look = CFrame.lookAt(camera.CFrame.Position, targetPosition)
        local alpha = math.clamp(aimSmooth, 0.01, 1)
        camera.CFrame = camera.CFrame:Lerp(look, math.clamp(alpha, 0.01, 1))
    end
end)

local aimChild = pAim.BeginChild("Aim", "left")
aimChild.Label("Aimbot baseado em câmera. Funciona na maioria dos jogos que usam a mira padrão do Roblox.", true)
aimChild.Toggle("Aim assist", false, function(v)
    aimEnabled = v
    aimFovIndicator.Visible = v and aimDrawFov
    notify(v and "Aim assist ativado" or "Aim assist desativado", v and (aimMode == "Sempre ativo" and "A mira acompanhará o alvo dentro do FOV." or "Use a tecla ou botão definido no modo de ativação para mirar.") or "A assistência de mira foi desativada.")
end)
aimChild.Toggle("Aimbot universal", true, function(v)
    aimUniversalEnabled = v
    notify(v and "Aimbot universal ativado" or "Aimbot universal desativado", v and "Modelos com Humanoid e NPCs também serão considerados." or "A mira voltou a considerar apenas personagens de jogadores.")
end)
aimChild.Dropdown("Modo de ativação", {"Sempre ativo", "Segurar botão direito", "Segurar Shift", "Segurar Alt", "Segurar Ctrl"}, aimMode, false, function(v)
    aimMode = v
    aimHolding = false
    aimKeyHolding = false
    notify("Modo do aim alterado", "Modo selecionado: " .. tostring(v) .. ".")
end)
aimChild.Dropdown("Parte do alvo", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, aimPart, false, function(v)
    aimPart = v
    notify("Parte do alvo alterada", "Alvo selecionado: " .. tostring(v) .. ".")
end)
-- O aim começa ignorando jogadores do mesmo time.
aimChild.Toggle("Team check", true, function(v)
    aimTeamCheck = v
    notify(v and "Team check ativado" or "Team check desativado", v and "Jogadores do mesmo time serão ignorados." or "Jogadores do mesmo time poderão ser selecionados.")
end)
aimChild.Toggle("Verificação de visibilidade", false, function(v)
    aimVisibleCheck = v
    notify(v and "Visibilidade ativada" or "Visibilidade desativada", v and "O alvo precisa estar visível para ser selecionado." or "A mira poderá selecionar alvos atrás de obstáculos.")
end)
aimChild.Toggle("Predição de movimento", false, function(v)
    aimPredictionEnabled = v
    notify(v and "Predição ativada" or "Predição desativada", v and "A mira compensará o deslocamento do alvo." or "A compensação de movimento foi desativada.")
end)
aimChild.Toggle("Indicador de FOV", true, function(v)
    aimDrawFov = v
    aimFovIndicator.Visible = v and aimEnabled
    notify(v and "Indicador de FOV ativado" or "Indicador de FOV desativado", v and "O círculo de alcance foi exibido." or "O círculo de alcance foi ocultado.")
end)
aimChild.Dropdown("Prioridade do alvo", {"FOV", "Distância", "Vida"}, aimPriority, false, function(v)
    aimPriority = v
    notify("Prioridade alterada", "Prioridade selecionada: " .. tostring(v) .. ".")
end)
aimChild.Slider("FOV da mira", 50, 500, aimFov, 10, " px", function(v)
    aimFov = v
    aimFovIndicator.Size = UDim2.fromOffset(v * 2, v * 2)
end)
aimChild.Slider("Suavidade", 0.05, 1, aimSmooth, 0.05, "", function(v)
    aimSmooth = v
end)
aimChild.Slider("Força da predição", 0, 0.35, aimPrediction, 0.01, " s", function(v)
    aimPrediction = v
end)

-- ============================================================
-- OPÇÕES SILENT NA ABA AIM
-- ============================================================
local silentEnabled = false
local silentFov = 200
local silentTeamCheck = true
local silentPart = "Head"
local silentHitChance = 100
local silentPrediction = 0.08
local silentUsePrediction = true
local silentTarget = nil
local silentFovCircle = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(silentFov * 2, silentFov * 2), BackgroundTransparency = 1, Visible = false, ZIndex = 3}, Gui)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, silentFovCircle)
local silentFovStroke = new("UIStroke", {Thickness = 1.5, Color = RGB(255, 100, 100)}, silentFovCircle)
reg(function()
    silentFovStroke.Color = Theme.Accent
end)

local mouse = LocalPlayer:GetMouse()

local function getSilentTarget()
    local camera = workspace.CurrentCamera
    if not camera then
        return nil
    end
    local center = camera.ViewportSize / 2
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                if humanoid and humanoid.Health > 0 and root then
                    if silentTeamCheck and isSameTeam(player) then
                        continue
                    end
                    local part = char:FindFirstChild(silentPart) or root
                    if part and part:IsA("BasePart") then
                        local worldPos = part.Position
                        if silentUsePrediction then
                            worldPos = worldPos + part.AssemblyLinearVelocity * silentPrediction
                        end
                        local point, visible = camera:WorldToViewportPoint(worldPos)
                        if visible and point.Z > 0 then
                            local screenDist = (Vector2.new(point.X, point.Y) - center).Magnitude
                            if screenDist <= silentFov and screenDist < closestDist then
                                closest = part
                                closestDist = screenDist
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService:BindToRenderStep("NovaMenuSilent", Enum.RenderPriority.Camera.Value - 1, function(dt)
    if not silentEnabled then
        silentTarget = nil
        return
    end
    silentTarget = getSilentTarget()
end)

connect(UserInputService.InputBegan, function(input, processed)
    if processed or not silentEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if silentTarget then
            if math.random(1, 100) <= silentHitChance then
                pcall(function()
                    local camera = workspace.CurrentCamera
                    if camera then
                        local targetPos = silentTarget.Position
                        if silentUsePrediction then
                            targetPos = targetPos + silentTarget.AssemblyLinearVelocity * silentPrediction
                        end
                        local look = CFrame.lookAt(camera.CFrame.Position, targetPos)
                        camera.CFrame = look
                    end
                end)
            end
        end
    end
end)

local silentChild = pSilent.BeginChild("Silent Aim", "left")
silentChild.Label("Silent aim global: redireciona o alvo sem mover a câmera visivelmente. Funciona em PC, mobile e emulador.", true)
silentChild.Toggle("Ativar silent aim", false, function(v)
    silentEnabled = v
    silentFovCircle.Visible = v
    notify(v and "Silent aim ativado" or "Silent aim desativado", v and "Os tiros serão redirecionados para o alvo mais próximo dentro do FOV." or "O silent aim foi desativado.")
end)
-- O silent aim começa ignorando jogadores do mesmo time.
silentChild.Toggle("Team check", true, function(v)
    silentTeamCheck = v
    notify(v and "Team check ativado" or "Team check desativado", v and "Jogadores do mesmo time serão ignorados." or "Jogadores do mesmo time poderão ser alvos.")
end)
silentChild.Toggle("Predição de movimento", true, function(v)
    silentUsePrediction = v
    notify(v and "Predição ativada" or "Predição desativada", v and "O silent aim compensará o movimento do alvo." or "A predição foi desativada.")
end)
silentChild.Dropdown("Parte do alvo", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, silentPart, false, function(v)
    silentPart = v
    notify("Parte do alvo alterada", "Alvo: " .. tostring(v) .. ".")
end)
silentChild.Slider("FOV do silent", 50, 600, silentFov, 10, " px", function(v)
    silentFov = v
    silentFovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
end)
silentChild.Slider("Chance de acerto", 0, 100, silentHitChance, 1, "%", function(v)
    silentHitChance = v
end)
silentChild.Slider("Força da predição", 0, 0.35, silentPrediction, 0.01, " s", function(v)
    silentPrediction = v
end)
silentChild.Toggle("Mostrar círculo do FOV", true, function(v)
    silentFovCircle.Visible = v and silentEnabled
    notify(v and "Círculo do FOV exibido" or "Círculo do FOV ocultado", "")
end)

-- ============================================================
-- TRIGGER BOT GLOBAL
-- ============================================================
local triggerBotEnabled = false
local triggerDelay = 0.05
local triggerFov = 30
local triggerTeamCheck = true
local lastTrigger = 0

local function simulateClick()
    local ok1 = pcall(function()
        VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.01)
        VirtualUser:Button1Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
    if ok1 then return end
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

connect(RunService.RenderStepped, function()
    if not triggerBotEnabled then return end
    local now = tick()
    if now - lastTrigger < triggerDelay then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local center = camera.ViewportSize / 2
    if not mouse then return end
    local target = mouse.Target
    if target then
        local model = target:FindFirstAncestorOfClass("Model")
        if model then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local player = Players:GetPlayerFromCharacter(model)
            if humanoid and humanoid.Health > 0 then
                if triggerTeamCheck and player and isSameTeam(player) then
                    return
                end
                local point = camera:WorldToViewportPoint(target.Position)
                if point.Z > 0 then
                    local screenDist = (Vector2.new(point.X, point.Y) - center).Magnitude
                    if screenDist <= triggerFov then
                        lastTrigger = now
                        simulateClick()
                    end
                end
            end
        end
    end
end)

local triggerChild = pSilent.BeginChild("Trigger Bot", "right")
triggerChild.Label("Dispara automaticamente quando a mira passa sobre um inimigo. Funciona em PC, mobile e emulador.", true)
triggerChild.Toggle("Ativar trigger bot", false, function(v)
    triggerBotEnabled = v
    notify(v and "Trigger bot ativado" or "Trigger bot desativado", v and "O bot disparará ao mirar em inimigos." or "O trigger bot foi desativado.")
end)
-- O trigger bot começa ignorando jogadores do mesmo time.
triggerChild.Toggle("Team check", true, function(v)
    triggerTeamCheck = v
    notify(v and "Team check ativado" or "Team check desativado", "")
end)
triggerChild.Slider("FOV do trigger", 5, 200, triggerFov, 5, " px", function(v)
    triggerFov = v
end)
triggerChild.Slider("Delay entre tiros", 0.01, 0.5, triggerDelay, 0.01, " s", function(v)
    triggerDelay = v
end)

-- ============================================================
-- COMPONENTES
-- ============================================================
local selection = pComponentes.BeginChild("Seleção", "left")
selection.Label("Use estes componentes como base para adicionar suas próprias funções.", true)
selection.Dropdown("Modo", {"Automático", "Manual", "Seguro", "Rápido"}, "Automático", false, function(v)
    print("[NovaMenu] Modo:", v)
end)
selection.Dropdown("Alvos", {"Jogadores", "NPCs", "Itens", "Baús", "Portas"}, {"Jogadores"}, true, function(v)
    print("[NovaMenu] Alvos:", table.concat(v, ", "))
end)
selection.TextBox("Nome do perfil", "", "Digite aqui", function(text)
    print("[NovaMenu] Texto:", text)
end)

local actions = pComponentes.BeginChild("Ações", "right")
actions.Button("Enviar notificação", function()
    notify("Nova notificação", "Este é um exemplo de aviso do menu.", 3)
end)
actions.Toggle("Exemplo de toggle", false, function(v)
    print("[NovaMenu] Toggle:", v)
end)
actions.Slider("Intensidade", 0, 100, 50, 1, "%", function(v)
    print("[NovaMenu] Intensidade:", v)
end)
actions.Slider("Precisão decimal", 0, 1, 0.5, 0.05, "", function(v)
    print("[NovaMenu] Decimal:", v)
end)
actions.ColorPicker("Cor de exemplo", Color3.fromRGB(96, 128, 170), function(c)
    print("[NovaMenu] Cor:", c)
end)

-- ============================================================
-- PERSONALIZAÇÃO
-- ============================================================
local Controls = {}
local Pickers = {}

local function syncControls()
    for _, fn in ipairs(Controls) do
        pcall(fn)
    end
end

local themeChild = pPersonalizar.BeginChild("Tema e cores", "left")
local presetDD = themeChild.Dropdown("Predefinição", PresetOrder, Theme.Preset, false, function(v)
    loadPreset(v)
    applyTheme()
    for key, picker in pairs(Pickers) do
        picker.Set(Theme[key], true)
    end
end)
table.insert(Controls, function()
    presetDD.Set(Theme.Preset, true)
    for key, picker in pairs(Pickers) do
        picker.Set(Theme[key], true)
    end
end)

local function themeColor(label, key)
    Pickers[key] = themeChild.ColorPicker(label, Theme[key], function(c)
        Theme[key] = c
        applyTheme()
    end)
end
themeColor("Fundo escuro", "Background")
themeColor("Fundo claro", "BackgroundLight")
themeColor("Superfície dos blocos", "Surface")
themeColor("Cor de destaque", "Accent")
themeColor("Cor do texto", "Text")
themeColor("Cor do texto secundário", "SubText")
themeColor("Cor do contorno", "Stroke")

local gradToggle = themeChild.Toggle("Mistura de fundo (gradiente)", Theme.Gradient, function(v)
    Theme.Gradient = v
    applyTheme()
end)
local strokeToggle = themeChild.Toggle("Contornos", Theme.StrokeOn, function(v)
    Theme.StrokeOn = v
    applyTheme()
end)
table.insert(Controls, function()
    gradToggle.Set(Theme.Gradient, true)
    strokeToggle.Set(Theme.StrokeOn, true)
end)

local styleChild = pPersonalizar.BeginChild("Estilo do menu", "right")
local fontDD = styleChild.Dropdown("Fonte", FontList, Theme.Font, false, function(v)
    Theme.Font = v
    applyTheme()
end)
local sizeSl = styleChild.Slider("Tamanho do texto", 11, 17, Theme.TextSize, 1, "", function(v)
    Theme.TextSize = v
    applyTheme()
end)
local radiusSl = styleChild.Slider("Cantos arredondados", 0, 30, Theme.Radius, 1, "", function(v)
    Theme.Radius = v
    applyTheme()
end)
local transSl = styleChild.Slider("Transparência do menu", 0, 70, Theme.Transparency * 100, 1, "%", function(v)
    Theme.Transparency = v / 100
    applyTheme()
end)
local scaleSl = styleChild.Slider("Escala do menu", 70, 130, Theme.Scale * 100, 5, "%", function(v)
    Theme.Scale = v / 100
    applyTheme()
end)
local sliderDD = styleChild.Dropdown("Estilo do slider", SliderStyles, Theme.SliderStyle, false, function(v)
    Theme.SliderStyle = v
    applyTheme()
end)
local dropDD = styleChild.Dropdown("Estilo do dropdown", DropdownStyles, Theme.DropdownStyle, false, function(v)
    Theme.DropdownStyle = v
    applyTheme()
end)
table.insert(Controls, function()
    fontDD.Set(Theme.Font, true)
    sizeSl.Set(Theme.TextSize, true)
    radiusSl.Set(Theme.Radius, true)
    transSl.Set(Theme.Transparency * 100, true)
    scaleSl.Set(Theme.Scale * 100, true)
    sliderDD.Set(Theme.SliderStyle, true)
    dropDD.Set(Theme.DropdownStyle, true)
end)

local tabStyleChild = pPersonalizar.BeginChild("Estilo das abas", "left")
local tabStyleDD = tabStyleChild.Dropdown("Formato das abas", {"Pílula", "Redondo", "Quadrado", "Arredondado"}, Theme.TabStyle, false, function(v)
    Theme.TabStyle = v
    applyTabStyle()
    notify("Formato das abas alterado", "Formato: " .. tostring(v) .. ".")
end)
local tabPositionDD = tabStyleChild.Dropdown("Posição das abas", {"Topo", "Lateral Esquerda", "Lateral Direita"}, Theme.TabPosition, false, function(v)
    Theme.TabPosition = v
    applyTabStyle()
    notify("Posição das abas alterada", "Posição: " .. tostring(v) .. ".")
end)
table.insert(Controls, function()
    tabStyleDD.Set(Theme.TabStyle, true)
    tabPositionDD.Set(Theme.TabPosition, true)
end)

local SaveColors = {"Background", "BackgroundLight", "Surface", "Accent", "Text", "SubText", "Stroke"}
local SaveNumbers = {"Radius", "TextSize", "Transparency", "Scale"}
local SaveBools = {"Gradient", "StrokeOn"}
local FileName = "NovaMenu_tema.json"

local function saveTheme()
    local data = {Font = Theme.Font, SliderStyle = Theme.SliderStyle, DropdownStyle = Theme.DropdownStyle, Preset = Theme.Preset, Keybind = Theme.Keybind, TabStyle = Theme.TabStyle, TabPosition = Theme.TabPosition}
    for _, k in ipairs(SaveColors) do
        local c = Theme[k]
        data[k] = {math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)}
    end
    for _, k in ipairs(SaveNumbers) do
        data[k] = Theme[k]
    end
    for _, k in ipairs(SaveBools) do
        data[k] = Theme[k]
    end
    local ok = pcall(function()
        writefile(FileName, HttpService:JSONEncode(data))
    end)
    if ok then
        notify("Tema salvo", "Arquivo: " .. FileName)
    else
        notify("Erro", "Não foi possível salvar o tema.")
    end
end

local function loadTheme()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(FileName))
    end)
    if not ok or type(data) ~= "table" then
        notify("Erro", "Nenhum tema salvo foi encontrado.")
        return
    end
    for _, k in ipairs(SaveColors) do
        local v = data[k]
        if type(v) == "table" and #v == 3 then
            Theme[k] = Color3.fromRGB(v[1], v[2], v[3])
        end
    end
    for _, k in ipairs(SaveNumbers) do
        if type(data[k]) == "number" then
            Theme[k] = data[k]
        end
    end
    for _, k in ipairs(SaveBools) do
        if type(data[k]) == "boolean" then
            Theme[k] = data[k]
        end
    end
    if type(data.Font) == "string" and table.find(FontList, data.Font) then
        Theme.Font = data.Font
    end
    if type(data.SliderStyle) == "string" and table.find(SliderStyles, data.SliderStyle) then
        Theme.SliderStyle = data.SliderStyle
    end
    if type(data.DropdownStyle) == "string" and table.find(DropdownStyles, data.DropdownStyle) then
        Theme.DropdownStyle = data.DropdownStyle
    end
    if type(data.Preset) == "string" and Presets[data.Preset] then
        Theme.Preset = data.Preset
    end
    if type(data.Keybind) == "string" and table.find(KeybindList, data.Keybind) then
        Theme.Keybind = data.Keybind
    end
    if type(data.TabStyle) == "string" then
        Theme.TabStyle = data.TabStyle
    end
    if type(data.TabPosition) == "string" then
        Theme.TabPosition = data.TabPosition
    end
    applyTheme()
    applyTabStyle()
    syncControls()
    notify("Tema carregado", "Configuração aplicada.")
end

local configChild = pPersonalizar.BeginChild("Configuração", "right")
configChild.Button("Salvar tema", saveTheme)
configChild.Button("Carregar tema", loadTheme)
configChild.Button("Restaurar padrão", function()
    applyDefaults()
    applyTheme()
    applyTabStyle()
    syncControls()
    notify("Padrão restaurado", "Tema original aplicado.")
end)

local Float = new("TextButton", {Text = "NOVA  •  MENU", AutoButtonColor = false, Size = UDim2.fromOffset(148, 30), Position = UDim2.new(0, 14, 0.5, -15), BorderSizePixel = 0, Visible = true, ZIndex = 5}, Gui)
fill(Float, "Surface")
local floatCorner = corner(Float, 0, true)
stroke(Float, "Accent", 2)
styleText(Float, "Accent", 1)
makeDraggable(Float, Float, function()
    Main.Visible = not Main.Visible
end)

configChild.Toggle("Botão flutuante", true, function(v)
    Float.Visible = v
end)
local keyDD = configChild.Dropdown("Tecla para abrir/fechar", KeybindList, Theme.Keybind, false, function(v)
    Theme.Keybind = v
end)
table.insert(Controls, function()
    keyDD.Set(Theme.Keybind, true)
end)
local floatSize = 148
local floatShape = "Redondo"
configChild.Slider("Tamanho do ícone", 30, 80, floatSize, 2, " px", function(v)
    floatSize = v
    Float.Size = UDim2.fromOffset(148, math.clamp(v * 30 / 44, 24, 48))
    Float.Position = UDim2.new(Float.Position.X.Scale, Float.Position.X.Offset, 0.5, -Float.Size.Y.Offset / 2)
    notify("Tamanho do ícone alterado", "Tamanho: " .. tostring(v) .. " px.")
end)
configChild.Dropdown("Formato do ícone", {"Redondo", "Quadrado", "Arredondado"}, floatShape, false, function(v)
    floatShape = v
    if v == "Redondo" then
        floatCorner.CornerRadius = UDim.new(1, 0)
    elseif v == "Quadrado" then
        floatCorner.CornerRadius = UDim.new(1, 0)
    else
        floatCorner.CornerRadius = UDim.new(1, 0)
    end
    notify("Formato do ícone alterado", "Formato selecionado: " .. tostring(v) .. ".")
end)
local function runSearch()
    local q = string.lower(SearchBox.Text)
    q = (q:gsub("^%s+", "")):gsub("%s+$", "")
    local counts = {}
    local childVisible = {}
    for _, e in ipairs(Registry) do
        local match = q == "" or e.child.titleLower:find(q, 1, true) ~= nil or e.name:find(q, 1, true) ~= nil
        e.row.Visible = match and not e.child.collapsed
        if match then
            counts[e.page] = (counts[e.page] or 0) + 1
            childVisible[e.child] = true
        end
    end
    for _, p in ipairs(Pages) do
        for _, c in ipairs(p.children) do
            c.frame.Visible = q == "" or childVisible[c] == true
        end
        p.tab.Visible = q == "" or (counts[p] or 0) > 0
    end
    if q ~= "" and not counts[CurrentPage] then
        for _, p in ipairs(Pages) do
            if counts[p] then
                selectPage(p)
                break
            end
        end
    end
    EmptyLabel.Visible = q ~= "" and next(counts) == nil
end
connect(SearchBox:GetPropertyChangedSignal("Text"), runSearch)

local function layoutMain()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local vp = camera.ViewportSize
    local s = Theme.Scale
    local w = math.clamp(vp.X / s - 40, 300, 720)
    local h = math.clamp(vp.Y / s - 40, 240, 440)
    Main.Size = UDim2.fromOffset(w, h)
    local stack = w < 540
    for _, p in ipairs(Pages) do
        p.setStack(stack)
    end
end
reg(layoutMain)
if workspace.CurrentCamera then
    connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), layoutMain)
end
connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    local camera = workspace.CurrentCamera
    if camera then
        layoutMain()
        connect(camera:GetPropertyChangedSignal("ViewportSize"), layoutMain)
    end
end)

MinButton.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

connect(UserInputService.InputBegan, function(input, processed)
    if processed then
        return
    end
    local ok, kc = pcall(function()
        return Enum.KeyCode[Theme.Keybind]
    end)
    if ok and input.KeyCode == kc then
        Main.Visible = not Main.Visible
    end
end)

local function unload()
    pcall(function()
        RunService:UnbindFromRenderStep("NovaMenuAim")
        RunService:UnbindFromRenderStep("NovaMenuSilent")
    end)
    if performanceEnabled then
        setPerformanceMode(false)
    end
    if modEnabled then
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = 16
            hum.UseJumpPower = true
            hum.JumpPower = 50
        end
    end
    for _, c in ipairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    Gui:Destroy()
    env.NovaMenuUnload = nil
end
env.NovaMenuUnload = unload

CloseButton.MouseButton1Click:Connect(unload)
configChild.Button("Destruir menu", unload)

applyTabStyle()
selectPage(Pages[1])
applyTheme()
pcall(function()
    Gui.Enabled = true
    Main.Visible = true
    if not Gui.Parent and LocalPlayer then
        Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)
notify("Nova Menu", "Bem-vindo, " .. LocalPlayer.DisplayName .. ".", 4)
