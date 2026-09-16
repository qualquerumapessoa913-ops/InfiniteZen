-- ============================================================
-- INFINITE ZEN - UI LIBRARY v1.1
-- Estilo PHANTOM + Suporte a Tradução
-- ============================================================

local Library = {}
Library.Version = "1.1"

Library.Theme = {
    Bg          = Color3.fromRGB(10, 10, 15),
    Sidebar     = Color3.fromRGB(13, 13, 18),
    Surface     = Color3.fromRGB(18, 18, 24),
    Surface2    = Color3.fromRGB(24, 24, 32),
    Border      = Color3.fromRGB(35, 35, 45),
    HeaderBg    = Color3.fromRGB(13, 13, 18),
    Primary     = Color3.fromRGB(230, 40, 40),
    PrimaryDark = Color3.fromRGB(160, 20, 20),
    PrimaryGlow = Color3.fromRGB(255, 60, 60),
    Text        = Color3.fromRGB(240, 240, 245),
    TextDim     = Color3.fromRGB(140, 140, 155),
    TextMuted   = Color3.fromRGB(90, 90, 105),
    Success     = Color3.fromRGB(50, 200, 120),
    Warning     = Color3.fromRGB(255, 180, 50),
    Danger      = Color3.fromRGB(230, 40, 40),
    Font        = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
    FontBlack   = Enum.Font.GothamBlack,
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function corner(obj, r)
    local c = Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function stroke(obj, color, thickness)
    local s = Instance.new("UIStroke", obj)
    s.Color = color or Library.Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = 0.3
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function padding(obj, t, r, b, l)
    local p = Instance.new("UIPadding", obj)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    return p
end

-- ═══ SISTEMA DE TRADUÇÃO ═══
Library._translator = nil
Library._translatable = setmetatable({}, {__mode = "k"}) -- weak keys

local function registerTranslatable(el, meta)
    if el then
        Library._translatable[el] = meta
    end
end

-- Função global de tradução (definida pelo consumidor da lib)
function Library:SetTranslator(fn)
    Library._translator = fn
    self:RefreshTranslations()
end

-- Reaplica as traduções em TODOS os elementos registrados
function Library:RefreshTranslations()
    if not Library._translator then return end
    for el, meta in pairs(Library._translatable) do
        if meta.nameLabel and meta.nameKey then
            local t = Library._translator(meta.nameKey)
            if t then meta.nameLabel.Text = t end
        end
        if meta.descLabel and meta.descKey then
            local t = Library._translator(meta.descKey)
            if t then meta.descLabel.Text = t end
        end
        if meta.sectionLabel and meta.nameKey then
            local t = Library._translator(meta.nameKey)
            if t then meta.sectionLabel.Text = string.upper(t) end
        end
        if meta.labelObj and meta.nameKey then
            local t = Library._translator(meta.nameKey)
            if t then meta.labelObj.Text = t end
        end
        if meta.buttonObj and meta.nameKey then
            local t = Library._translator(meta.nameKey)
            if t then meta.buttonObj.Text = t end
        end
        if meta.dropdownBtn and meta.placeholderKey then
            local t = Library._translator(meta.placeholderKey)
            if t and meta.currentText == meta.placeholderOriginal then
                meta.dropdownBtn.Text = t
                meta.currentText = t
            end
        end
    end
end

-- ═══ NOTIFICAÇÕES ═══
local activeNotifs = {}

local function Notify(GUI, title, content, duration, kind)
    duration = duration or 4
    kind = kind or "info"
    local colors = {
        info = Library.Theme.Primary,
        success = Library.Theme.Success,
        warning = Library.Theme.Warning,
        error = Library.Theme.Danger,
    }
    local accent = colors[kind] or Library.Theme.Primary
    local idx = #activeNotifs
    local n = Instance.new("Frame")
    n.Size = UDim2.new(0, 300, 0, 70)
    n.Position = UDim2.new(1, 20, 0, 20 + idx * 80)
    n.BackgroundColor3 = Library.Theme.Surface
    n.BorderSizePixel = 0
    n.Parent = GUI
    n.ZIndex = 9999
    corner(n, 10)
    local s = stroke(n, accent, 1.5)
    s.Transparency = 0.2

    local bar = Instance.new("Frame", n)
    bar.Size = UDim2.new(0, 3, 1, -16)
    bar.Position = UDim2.new(0, 8, 0, 8)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel = 0
    corner(bar, 2)

    local titleL = Instance.new("TextLabel", n)
    titleL.Size = UDim2.new(1, -30, 0, 22)
    titleL.Position = UDim2.new(0, 20, 0, 10)
    titleL.BackgroundTransparency = 1
    titleL.Font = Library.Theme.FontBold
    titleL.TextSize = 13
    titleL.TextColor3 = accent
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.Text = title

    local contentL = Instance.new("TextLabel", n)
    contentL.Size = UDim2.new(1, -30, 0, 30)
    contentL.Position = UDim2.new(0, 20, 0, 32)
    contentL.BackgroundTransparency = 1
    contentL.Font = Library.Theme.Font
    contentL.TextSize = 11
    contentL.TextColor3 = Library.Theme.TextDim
    contentL.TextXAlignment = Enum.TextXAlignment.Left
    contentL.TextWrapped = true
    contentL.Text = content

    table.insert(activeNotifs, n)
    TweenService:Create(n, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -320, 0, 20 + idx * 80)
    }):Play()

    task.delay(duration, function()
        for i, nn in ipairs(activeNotifs) do
            if nn == n then table.remove(activeNotifs, i); break end
        end
        if n and n.Parent then
            TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, 0, n.Position.Y.Offset)
            }):Play()
            task.wait(0.35)
            if n.Parent then n:Destroy() end
        end
    end)
end

-- ═══ CREATE WINDOW ═══
function Library:CreateWindow(config)
    config = config or {}
    local Window = {}
    local T = Library.Theme

    local title = config.Title or "INFINITE ZEN"
    local subtitle = config.Subtitle or "v1.0"
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    local windowSize = config.Size or UDim2.new(0, 720, 0, 480)
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local old = PlayerGui:FindFirstChild("InfiniteZen")
    if old then old:Destroy() end

    local GUI = Instance.new("ScreenGui")
    GUI.Name = "InfiniteZen"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local pok = false
    if gethui then pok = pcall(function() GUI.Parent = gethui() end) end
    if not pok then GUI.Parent = PlayerGui end

    local Main = Instance.new("Frame", GUI)
    Main.Size = windowSize
    Main.Position = UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2)
    Main.BackgroundColor3 = T.Bg
    Main.BorderSizePixel = 0
    corner(Main, 12)
    local mainStroke = stroke(Main, T.Primary, 1.5)
    mainStroke.Transparency = 0.3

    local scale = Instance.new("UIScale", Main)
    scale.Scale = isMobile and 0.8 or 1

    local Header = Instance.new("Frame", Main)
    Header.Size = UDim2.new(1, 0, 0, 52)
    Header.BackgroundColor3 = T.HeaderBg
    Header.BorderSizePixel = 0
    corner(Header, 12)

    local headerBar = Instance.new("Frame", Header)
    headerBar.Size = UDim2.new(1, -20, 0, 1)
    headerBar.Position = UDim2.new(0, 10, 1, -1)
    headerBar.BackgroundColor3 = T.Border
    headerBar.BorderSizePixel = 0

    local Logo = Instance.new("TextLabel", Header)
    Logo.Size = UDim2.new(0, 200, 0, 24)
    Logo.Position = UDim2.new(0, 20, 0, 8)
    Logo.BackgroundTransparency = 1
    Logo.Font = T.FontBlack
    Logo.Text = title:upper()
    Logo.TextColor3 = T.Text
    Logo.TextSize = 18
    Logo.TextXAlignment = Enum.TextXAlignment.Left

    local Sub = Instance.new("TextLabel", Header)
    Sub.Size = UDim2.new(0, 200, 0, 16)
    Sub.Position = UDim2.new(0, 20, 0, 28)
    Sub.BackgroundTransparency = 1
    Sub.Font = T.Font
    Sub.Text = subtitle
    Sub.TextColor3 = T.TextMuted
    Sub.TextSize = 11
    Sub.TextXAlignment = Enum.TextXAlignment.Left

    local SearchBg = Instance.new("Frame", Header)
    SearchBg.Size = UDim2.new(0, 260, 0, 32)
    SearchBg.Position = UDim2.new(0.5, -130, 0.5, -16)
    SearchBg.BackgroundColor3 = T.Surface
    SearchBg.BorderSizePixel = 0
    corner(SearchBg, 16)
    stroke(SearchBg, T.Border, 1)

    local SearchIcon = Instance.new("TextLabel", SearchBg)
    SearchIcon.Size = UDim2.new(0, 20, 1, 0)
    SearchIcon.Position = UDim2.new(0, 10, 0, 0)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Font = T.Font
    SearchIcon.Text = "🔍"
    SearchIcon.TextColor3 = T.TextMuted
    SearchIcon.TextSize = 12

    local SearchBox = Instance.new("TextBox", SearchBg)
    SearchBox.Size = UDim2.new(1, -40, 1, 0)
    SearchBox.Position = UDim2.new(0, 32, 0, 0)
    SearchBox.BackgroundTransparency = 1
    SearchBox.Font = T.Font
    SearchBox.TextSize = 12
    SearchBox.TextColor3 = T.Text
    SearchBox.PlaceholderText = "Search features..."
    SearchBox.PlaceholderColor3 = T.TextMuted
    SearchBox.Text = ""
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -42, 0.5, -15)
    CloseBtn.BackgroundColor3 = T.Primary
    CloseBtn.Text = "✕"
    CloseBtn.Font = T.FontBold
    CloseBtn.TextSize = 14
    CloseBtn.TextColor3 = T.Text
    CloseBtn.AutoButtonColor = false
    corner(CloseBtn, 15)

    local MinimizeBtn = Instance.new("TextButton", Header)
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -78, 0.5, -15)
    MinimizeBtn.BackgroundColor3 = T.Surface
    MinimizeBtn.Text = "−"
    MinimizeBtn.Font = T.FontBold
    MinimizeBtn.TextSize = 16
    MinimizeBtn.TextColor3 = T.Text
    MinimizeBtn.AutoButtonColor = false
    corner(MinimizeBtn, 15)
    stroke(MinimizeBtn, T.Border, 1)

    local Sidebar = Instance.new("Frame", Main)
    Sidebar.Size = UDim2.new(0, 64, 1, -64)
    Sidebar.Position = UDim2.new(0, 8, 0, 58)
    Sidebar.BackgroundColor3 = T.Sidebar
    Sidebar.BorderSizePixel = 0
    corner(Sidebar, 10)

    local SidebarList = Instance.new("UIListLayout", Sidebar)
    SidebarList.Padding = UDim.new(0, 4)
    SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    padding(Sidebar, 8, 0, 8, 0)

    local Content = Instance.new("Frame", Main)
    Content.Size = UDim2.new(1, -80, 1, -64)
    Content.Position = UDim2.new(0, 72, 0, 58)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0

    local ReopenBtn = nil
    if isMobile then
        ReopenBtn = Instance.new("TextButton", GUI)
        ReopenBtn.Size = UDim2.new(0, 55, 0, 55)
        ReopenBtn.Position = UDim2.new(0, 20, 0, 100)
        ReopenBtn.BackgroundColor3 = T.Primary
        ReopenBtn.Text = "∞"
        ReopenBtn.Font = T.FontBlack
        ReopenBtn.TextSize = 24
        ReopenBtn.TextColor3 = T.Text
        ReopenBtn.AutoButtonColor = false
        ReopenBtn.Visible = false
        ReopenBtn.ZIndex = 500
        corner(ReopenBtn, 27)
        stroke(ReopenBtn, T.PrimaryGlow, 2)
    end

    local dragging, dragInput, dragStart, startPos
    local function makeDraggable(el)
        el.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        el.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
    end
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    makeDraggable(Header)
    makeDraggable(Logo)

    local minimized = false
    local function setMinimized(v)
        minimized = v
        Sidebar.Visible = not v
        Content.Visible = not v
        Main.Size = v and UDim2.new(0, 720, 0, 52) or windowSize
        if ReopenBtn then ReopenBtn.Visible = v end
    end
    MinimizeBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)
    if ReopenBtn then
        ReopenBtn.MouseButton1Click:Connect(function() setMinimized(false) end)
    end

    CloseBtn.MouseButton1Click:Connect(function()
        GUI:Destroy()
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == toggleKey then
            setMinimized(not minimized)
        end
    end)

    function Window:Notify(t, c, d, k)
        Notify(GUI, t, c, d, k)
    end

    local searchableElements = {}
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchBox.Text:lower()
        for _, data in ipairs(searchableElements) do
            if data.frame and data.frame.Parent then
                if query == "" then
                    data.frame.Visible = true
                else
                    local nameMatch = data.name:lower():find(query, 1, true) ~= nil
                    local descMatch = data.desc and data.desc:lower():find(query, 1, true) ~= nil
                    data.frame.Visible = nameMatch or descMatch
                end
            end
        end
    end)

    local tabs = {}

    function Window:CreateTab(name, icon)
        local tab = {}

        local btn = Instance.new("TextButton", Sidebar)
        btn.Size = UDim2.new(0, 48, 0, 48)
        btn.BackgroundColor3 = T.Surface
        btn.BackgroundTransparency = 1
        btn.Text = icon or "●"
        btn.Font = T.FontBold
        btn.TextSize = 20
        btn.TextColor3 = T.TextDim
        btn.AutoButtonColor = false
        corner(btn, 10)

        btn.MouseEnter:Connect(function()
            if not tab.active then btn.BackgroundTransparency = 0.5 end
        end)
        btn.MouseLeave:Connect(function()
            if not tab.active then btn.BackgroundTransparency = 1 end
        end)

        local container = Instance.new("ScrollingFrame", Content)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = T.Primary
        container.ScrollBarImageTransparency = 0.5
        container.Visible = false
        padding(container, 0, 8, 12, 8)

        local list = Instance.new("UIListLayout", container)
        list.Padding = UDim.new(0, 8)
        list.SortOrder = Enum.SortOrder.LayoutOrder

        tab.container = container
        tab.btn = btn

        local function activate()
            for _, t in ipairs(tabs) do
                t.container.Visible = false
                t.btn.BackgroundTransparency = 1
                t.btn.TextColor3 = T.TextDim
                t.active = false
            end
            tab.container.Visible = true
            btn.BackgroundTransparency = 0
            btn.BackgroundColor3 = T.Primary
            btn.TextColor3 = T.Text
            tab.active = true
        end
        btn.MouseButton1Click:Connect(activate)

        table.insert(tabs, tab)
        if #tabs == 1 then task.defer(activate) end

        -- Retorna row + titleLbl + descLbl pra podermos registrar tradução
        local function createRow(cfg)
            local row = Instance.new("Frame", container)
            row.Size = UDim2.new(1, 0, 0, 58)
            row.BackgroundColor3 = T.Surface
            row.BorderSizePixel = 0
            row.LayoutOrder = #container:GetChildren()
            corner(row, 8)
            local rs = stroke(row, T.Border, 1)
            rs.Transparency = 0.5

            row.MouseEnter:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = T.Surface2 }):Play()
                rs.Transparency = 0.3
            end)
            row.MouseLeave:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = T.Surface }):Play()
                rs.Transparency = 0.5
            end)

            local iconFrame = Instance.new("Frame", row)
            iconFrame.Size = UDim2.new(0, 32, 0, 32)
            iconFrame.Position = UDim2.new(0, 14, 0.5, -16)
            iconFrame.BackgroundColor3 = T.Bg
            iconFrame.BorderSizePixel = 0
            corner(iconFrame, 8)
            stroke(iconFrame, T.Border, 1)

            local iconLbl = Instance.new("TextLabel", iconFrame)
            iconLbl.Size = UDim2.new(1, 0, 1, 0)
            iconLbl.BackgroundTransparency = 1
            iconLbl.Font = T.FontBold
            iconLbl.Text = cfg.Icon or "●"
            iconLbl.TextColor3 = T.Primary
            iconLbl.TextSize = 14

            local titleLbl = Instance.new("TextLabel", row)
            titleLbl.Size = UDim2.new(0.5, 0, 0, 18)
            titleLbl.Position = UDim2.new(0, 58, 0, 10)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Font = T.FontBold
            titleLbl.Text = cfg.Name or "Feature"
            titleLbl.TextColor3 = T.Text
            titleLbl.TextSize = 13
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left

            local descLbl = Instance.new("TextLabel", row)
            descLbl.Size = UDim2.new(0.5, 0, 0, 16)
            descLbl.Position = UDim2.new(0, 58, 0, 28)
            descLbl.BackgroundTransparency = 1
            descLbl.Font = T.Font
            descLbl.Text = cfg.Description or ""
            descLbl.TextColor3 = T.TextDim
            descLbl.TextSize = 11
            descLbl.TextXAlignment = Enum.TextXAlignment.Left

            table.insert(searchableElements, {
                frame = row,
                name = cfg.Name or "",
                desc = cfg.Description or "",
            })

            return row, titleLbl, descLbl
        end

        function tab:CreateSection(name, nameKey)
            local sec = Instance.new("Frame", container)
            sec.Size = UDim2.new(1, 0, 0, 24)
            sec.BackgroundTransparency = 1
            sec.LayoutOrder = #container:GetChildren()
            local lbl = Instance.new("TextLabel", sec)
            lbl.Size = UDim2.new(1, -8, 1, 0)
            lbl.Position = UDim2.new(0, 4, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = T.FontBold
            lbl.Text = name:upper()
            lbl.TextColor3 = T.TextMuted
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left

            if nameKey then
                registerTranslatable(sec, {
                    sectionLabel = lbl,
                    nameKey = nameKey,
                })
            end
        end

        function tab:CreateToggle(cfg)
            local row, titleLbl, descLbl = createRow(cfg)
            local state = cfg.Default or false

            local toggleBg = Instance.new("Frame", row)
            toggleBg.Size = UDim2.new(0, 44, 0, 22)
            toggleBg.Position = UDim2.new(1, -58, 0.5, -11)
            toggleBg.BackgroundColor3 = state and T.Primary or T.Border
            toggleBg.BorderSizePixel = 0
            corner(toggleBg, 11)

            local knob = Instance.new("Frame", toggleBg)
            knob.Size = UDim2.new(0, 18, 0, 18)
            knob.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            knob.BackgroundColor3 = T.Text
            knob.BorderSizePixel = 0
            corner(knob, 9)

            local keybind = Instance.new("TextButton", row)
            keybind.Size = UDim2.new(0, 46, 0, 22)
            keybind.Position = UDim2.new(1, -112, 0.5, -11)
            keybind.BackgroundColor3 = T.Bg
            keybind.Text = cfg.Keybind or "—"
            keybind.Font = T.FontBold
            keybind.TextSize = 10
            keybind.TextColor3 = T.TextDim
            keybind.AutoButtonColor = false
            corner(keybind, 6)
            stroke(keybind, T.Border, 1)

            local function setState(v, silent)
                state = v
                TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                    BackgroundColor3 = v and T.Primary or T.Border
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                    Position = v and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                }):Play()
                if not silent and cfg.Callback then pcall(cfg.Callback, v) end
            end

            toggleBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    setState(not state)
                end
            end)

            local recording = false
            keybind.MouseButton1Click:Connect(function()
                if recording then return end
                recording = true
                keybind.Text = "..."
                keybind.TextColor3 = T.Primary
                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                            keybind.Text = "—"
                        else
                            keybind.Text = input.KeyCode.Name
                            keybind.TextColor3 = T.Text
                        end
                        recording = false
                        conn:Disconnect()
                    end
                end)
            end)

            if cfg.NameKey or cfg.DescKey then
                registerTranslatable(row, {
                    nameLabel = titleLbl,
                    descLabel = descLbl,
                    nameKey = cfg.NameKey,
                    descKey = cfg.DescKey,
                })
            end

            return { SetState = setState, GetState = function() return state end }
        end

        function tab:CreateSlider(cfg)
            local row, titleLbl, descLbl = createRow(cfg)
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local value = cfg.Default or min

            local valLbl = Instance.new("TextLabel", row)
            valLbl.Size = UDim2.new(0, 50, 0, 18)
            valLbl.Position = UDim2.new(1, -60, 0, 12)
            valLbl.BackgroundTransparency = 1
            valLbl.Font = T.FontBold
            valLbl.Text = tostring(value)
            valLbl.TextColor3 = T.Primary
            valLbl.TextSize = 12
            valLbl.TextXAlignment = Enum.TextXAlignment.Right

            local barBg = Instance.new("Frame", row)
            barBg.Size = UDim2.new(0, 120, 0, 4)
            barBg.Position = UDim2.new(1, -190, 0.5, 8)
            barBg.BackgroundColor3 = T.Border
            barBg.BorderSizePixel = 0
            corner(barBg, 2)

            local rel = (value - min) / (max - min)
            local fill = Instance.new("Frame", barBg)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            fill.BackgroundColor3 = T.Primary
            fill.BorderSizePixel = 0
            corner(fill, 2)

            local click = Instance.new("TextButton", row)
            click.Size = UDim2.new(0, 120, 0, 20)
            click.Position = UDim2.new(1, -190, 0.5, 0)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.AutoButtonColor = false

            local activeInput = nil
            local function update(posX)
                local p = barBg.AbsolutePosition
                local s = barBg.AbsoluteSize
                if s.X <= 0 then return end
                local rx = math.clamp((posX - p.X) / s.X, 0, 1)
                local v = math.floor(min + (max - min) * rx)
                value = v
                fill.Size = UDim2.new(rx, 0, 1, 0)
                valLbl.Text = tostring(v)
                if cfg.Callback then pcall(cfg.Callback, v) end
            end

            click.InputBegan:Connect(function(input)
                if activeInput then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    activeInput = input
                    update(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if activeInput ~= input then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    update(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input == activeInput then activeInput = nil end
            end)

            if cfg.NameKey or cfg.DescKey then
                registerTranslatable(row, {
                    nameLabel = titleLbl,
                    descLabel = descLbl,
                    nameKey = cfg.NameKey,
                    descKey = cfg.DescKey,
                })
            end

            return {
                SetValue = function(v)
                    value = math.clamp(v, min, max)
                    local r = (value - min) / (max - min)
                    fill.Size = UDim2.new(r, 0, 1, 0)
                    valLbl.Text = tostring(value)
                    if cfg.Callback then pcall(cfg.Callback, value) end
                end,
                GetValue = function() return value end,
            }
        end

        function tab:CreateDropdown(cfg)
            local row, titleLbl, descLbl = createRow(cfg)
            local options = cfg.Options or {}
            local curIdx = cfg.Default or 1
            local open = false

            local selBtn = Instance.new("TextButton", row)
            selBtn.Size = UDim2.new(0, 130, 0, 26)
            selBtn.Position = UDim2.new(1, -144, 0.5, -13)
            selBtn.BackgroundColor3 = T.Bg
            selBtn.Text = options[curIdx] or "Select..."
            selBtn.Font = T.FontBold
            selBtn.TextSize = 11
            selBtn.TextColor3 = T.Text
            selBtn.AutoButtonColor = false
            corner(selBtn, 6)
            stroke(selBtn, T.Border, 1)

            local dropFrame = Instance.new("Frame", GUI)
            dropFrame.Size = UDim2.new(0, 130, 0, #options * 26 + 8)
            dropFrame.BackgroundColor3 = T.Surface
            dropFrame.BorderSizePixel = 0
            dropFrame.Visible = false
            dropFrame.ZIndex = 100
            corner(dropFrame, 8)
            stroke(dropFrame, T.Primary, 1)

            local dl = Instance.new("UIListLayout", dropFrame)
            dl.Padding = UDim.new(0, 0)
            padding(dropFrame, 4, 0, 4, 0)

            for i, opt in ipairs(options) do
                local ob = Instance.new("TextButton", dropFrame)
                ob.Size = UDim2.new(1, -8, 0, 26)
                ob.BackgroundColor3 = T.Surface
                ob.BackgroundTransparency = 1
                ob.Text = tostring(opt)
                ob.Font = T.Font
                ob.TextSize = 11
                ob.TextColor3 = T.TextDim
                ob.AutoButtonColor = false
                ob.ZIndex = 101
                corner(ob, 4)

                ob.MouseEnter:Connect(function()
                    ob.BackgroundTransparency = 0
                    ob.BackgroundColor3 = T.Surface2
                    ob.TextColor3 = T.Text
                end)
                ob.MouseLeave:Connect(function()
                    ob.BackgroundTransparency = 1
                    ob.TextColor3 = T.TextDim
                end)

                ob.MouseButton1Click:Connect(function()
                    curIdx = i
                    selBtn.Text = tostring(opt)
                    dropFrame.Visible = false
                    open = false
                    if cfg.Callback then pcall(cfg.Callback, opt, i) end
                end)
            end

            selBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    local absPos = selBtn.AbsolutePosition
                    dropFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + 30)
                    dropFrame.Visible = true
                else
                    dropFrame.Visible = false
                end
            end)

            if cfg.NameKey or cfg.DescKey then
                registerTranslatable(row, {
                    nameLabel = titleLbl,
                    descLabel = descLbl,
                    nameKey = cfg.NameKey,
                    descKey = cfg.DescKey,
                })
            end

            return {
                SetValue = function(i)
                    curIdx = math.clamp(i, 1, #options)
                    selBtn.Text = tostring(options[curIdx])
                    if cfg.Callback then pcall(cfg.Callback, options[curIdx], curIdx) end
                end,
                GetValue = function() return options[curIdx], curIdx end,
            }
        end

        function tab:CreateButton(cfg)
            local row = Instance.new("TextButton", container)
            row.Size = UDim2.new(1, 0, 0, 40)
            row.BackgroundColor3 = cfg.Danger and T.Danger or T.Primary
            row.Text = cfg.Name or "Button"
            row.Font = T.FontBold
            row.TextSize = 13
            row.TextColor3 = T.Text
            row.AutoButtonColor = false
            row.LayoutOrder = #container:GetChildren()
            corner(row, 8)

            row.MouseEnter:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.15), {
                    BackgroundColor3 = cfg.Danger and Color3.fromRGB(255, 60, 60) or T.PrimaryGlow
                }):Play()
            end)
            row.MouseLeave:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.15), {
                    BackgroundColor3 = cfg.Danger and T.Danger or T.Primary
                }):Play()
            end)
            row.MouseButton1Click:Connect(function()
                if cfg.Callback then pcall(cfg.Callback) end
            end)

            if cfg.NameKey then
                registerTranslatable(row, {
                    buttonObj = row,
                    nameKey = cfg.NameKey,
                })
            end

            return row
        end

        function tab:CreateLabel(text, color, nameKey)
            local lbl = Instance.new("TextLabel", container)
            lbl.Size = UDim2.new(1, -8, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Font = T.Font
            lbl.Text = text
            lbl.TextColor3 = color or T.TextDim
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.LayoutOrder = #container:GetChildren()
            if nameKey then
                registerTranslatable(lbl, {
                    labelObj = lbl,
                    nameKey = nameKey,
                })
            end
            return lbl
        end

        return tab
    end

    function Window:Destroy()
        if GUI and GUI.Parent then GUI:Destroy() end
    end

    return Window
end

return Library