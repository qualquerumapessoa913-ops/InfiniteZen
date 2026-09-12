-- ============================================================
-- INFINITE ZEN - MÓDULO ARSENAL v1.0
-- ============================================================

local Arsenal = {}

function Arsenal.Init(ctx)
    local Language = ctx.Language
    local gameName = ctx.gameName

    print("[Infinite Zen] Inicializando Arsenal...")

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInput = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    local UNLOADED = false

    -- ============================================================
    -- SISTEMA DE TRADUÇÃO (via função global)
    -- ============================================================
    local langRefresh = {}

    local function registerRefresh(fn)
        table.insert(langRefresh, fn)
        pcall(fn)
    end

    -- Função GLOBAL que o language.lua chama quando o idioma muda
    _G.IZ_RefreshLanguage = function()
        for _, fn in ipairs(langRefresh) do
            pcall(fn)
        end
    end

    local function isEnemy(player)
        if player == LocalPlayer then return false end
        if not player.Character then return false end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        local myTeam = LocalPlayer.Team
        if myTeam == nil then return true end
        if player.Team == nil then return false end
        return player.Team ~= myTeam
    end

    local State = {
        silentHeadshot = false,
        aimbot = false,
        headExpander = false,
        headExpanderSize = 3,
        silentFov = 120,
        backstab = false,
        noRecoil = false,
        rapidFire = false,
        fastReload = false,
        instaReload = false,
        autoShoot = false,
        autoShootFov = 100,
        speed = false,
        airJump = false,
        esp = false,
        espMaxDistance = 500,
        keybinds = {
            silentHeadshot = "X",
            aimbot = nil,
            headExpander = nil,
            backstab = "E",
            noRecoil = nil,
            rapidFire = nil,
            fastReload = nil,
            instaReload = nil,
            autoShoot = nil,
            speed = nil,
            airJump = nil,
            esp = nil,
        },
    }

    local recordingKeyFor = nil

    local FeatureLabels = {
        silentHeadshot = "Silent Headshot",
        aimbot = "Aimbot",
        headExpander = "Head Expander",
        backstab = "Backstab",
        noRecoil = "No-Recoil",
        rapidFire = "Rapid Fire",
        fastReload = "Fast Reload",
        instaReload = "Insta-Reload",
        autoShoot = "Auto Shoot",
        speed = "Speed",
        airJump = "Air Jump",
        esp = "ESP",
    }

    local oldMenu = PlayerGui:FindFirstChild("InfiniteZen")
    if oldMenu then oldMenu:Destroy() end

    local GUI = Instance.new("ScreenGui")
    GUI.Name = "InfiniteZen"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = PlayerGui

    local Theme = {
        Bg = Color3.fromRGB(14, 14, 18),
        Surface = Color3.fromRGB(22, 22, 28),
        Surface2 = Color3.fromRGB(32, 32, 40),
        Border = Color3.fromRGB(45, 45, 55),
        SidebarColor = Color3.fromRGB(40, 40, 45),
        ContentColor = Color3.fromRGB(20, 60, 80),
        TitleRed = Color3.fromRGB(255, 60, 60),
        Primary = Color3.fromRGB(0, 180, 255),
        Gradient1 = Color3.fromRGB(100, 80, 220),
        Gradient2 = Color3.fromRGB(0, 180, 255),
        Success = Color3.fromRGB(0, 220, 130),
        Danger = Color3.fromRGB(255, 70, 70),
        Warning = Color3.fromRGB(255, 180, 60),
        Text = Color3.fromRGB(240, 240, 250),
        TextDim = Color3.fromRGB(150, 155, 170),
        Font = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold,
    }

    local activeNotifs = {}

    local function Notify(title, content, duration, isError)
        duration = duration or 4
        local stackIndex = #activeNotifs

        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 260, 0, 62)
        notif.Position = UDim2.new(1, 20, 0, 80 + stackIndex * 72)
        notif.BackgroundColor3 = Theme.Surface
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        notif.ZIndex = 999

        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)

        local strokeColor = isError and Theme.Danger or Theme.Warning

        local s = Instance.new("UIStroke", notif)
        s.Color = strokeColor
        s.Thickness = 1.5
        s.Transparency = 0.2

        local titleL = Instance.new("TextLabel", notif)
        titleL.Size = UDim2.new(1, -20, 0, 22)
        titleL.Position = UDim2.new(0, 12, 0, 8)
        titleL.BackgroundTransparency = 1
        titleL.Font = Theme.FontBold
        titleL.TextSize = 12
        titleL.TextColor3 = strokeColor
        titleL.TextXAlignment = Enum.TextXAlignment.Left
        titleL.Text = title
        titleL.ZIndex = 1000

        local contentL = Instance.new("TextLabel", notif)
        contentL.Size = UDim2.new(1, -20, 0, 30)
        contentL.Position = UDim2.new(0, 12, 0, 28)
        contentL.BackgroundTransparency = 1
        contentL.Font = Theme.Font
        contentL.TextSize = 11
        contentL.TextColor3 = Theme.Text
        contentL.TextXAlignment = Enum.TextXAlignment.Left
        contentL.TextWrapped = true
        contentL.Text = content
        contentL.ZIndex = 1000

        table.insert(activeNotifs, notif)

        TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -280, 0, 80 + stackIndex * 72)
        }):Play()

        task.delay(duration, function()
            for i, n in ipairs(activeNotifs) do
                if n == notif then
                    table.remove(activeNotifs, i)
                    break
                end
            end
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, 0, notif.Position.Y.Offset)
            }):Play()
            task.wait(0.35)
            if notif and notif.Parent then notif:Destroy() end
        end)
    end

    local function findFeatureWithKeybind(key)
        for featId, boundKey in pairs(State.keybinds) do
            if boundKey == key then
                return featId
            end
        end
        return nil
    end

    -- ============================================================
    -- MAIN WINDOW
    -- ============================================================
    local MainFrame = Instance.new("Frame", GUI)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 620, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -310, 0.5, -240)
    MainFrame.BackgroundColor3 = Theme.Bg
    MainFrame.BorderSizePixel = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Color = Theme.Border
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.4

    local shadow = Instance.new("ImageLabel", MainFrame)
    shadow.Image = "rbxassetid://1316045217"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.55
    shadow.ZIndex = 0

    -- HEADER
    local Header = Instance.new("Frame", MainFrame)
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 48)
    Header.BackgroundColor3 = Theme.Surface
    Header.BorderSizePixel = 0
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Gradient1),
        ColorSequenceKeypoint.new(1, Theme.Gradient2)
    })
    headerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.85),
        NumberSequenceKeypoint.new(0.5, 0.95),
        NumberSequenceKeypoint.new(1, 1)
    })
    headerGradient.Parent = Header

    local headerFix = Instance.new("Frame", Header)
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = Theme.Surface
    headerFix.BorderSizePixel = 0

    local headerBar = Instance.new("Frame", Header)
    headerBar.Size = UDim2.new(1, 0, 0, 2)
    headerBar.Position = UDim2.new(0, 0, 0, 0)
    headerBar.BackgroundColor3 = Theme.Primary
    headerBar.BorderSizePixel = 0
    headerBar.ZIndex = 2

    local headerBarGradient = Instance.new("UIGradient")
    headerBarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Gradient1),
        ColorSequenceKeypoint.new(1, Theme.Gradient2)
    })
    headerBarGradient.Parent = headerBar

    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(0, 200, 0, 22)
    Title.Position = UDim2.new(0, 20, 0, 6)
    Title.BackgroundTransparency = 1
    Title.Font = Theme.FontBold
    Title.Text = "INFINITE ZEN"
    Title.TextColor3 = Theme.TitleRed
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 3

    local Subtitle = Instance.new("TextLabel", Header)
    Subtitle.Size = UDim2.new(0, 200, 0, 18)
    Subtitle.Position = UDim2.new(0, 20, 0, 25)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Font = Theme.Font
    Subtitle.Text = "Arsenal Edition"
    Subtitle.TextColor3 = Color3.fromRGB(200, 205, 220)
    Subtitle.TextSize = 11
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.ZIndex = 3

    local LangBtn = Instance.new("TextButton", Header)
    LangBtn.Size = UDim2.new(0, 60, 0, 26)
    LangBtn.Position = UDim2.new(1, -110, 0.5, -13)
    LangBtn.BackgroundColor3 = Theme.Surface2
    LangBtn.Text = "US"
    LangBtn.Font = Theme.FontBold
    LangBtn.TextSize = 12
    LangBtn.TextColor3 = Theme.Text
    LangBtn.AutoButtonColor = false
    LangBtn.ZIndex = 3
    Instance.new("UICorner", LangBtn).CornerRadius = UDim.new(0, 6)

    local LangDropdown = Instance.new("Frame", Header)
    LangDropdown.Size = UDim2.new(0, 140, 0, 0)
    LangDropdown.Position = UDim2.new(1, -110, 1, 4)
    LangDropdown.BackgroundColor3 = Theme.Surface2
    LangDropdown.BorderSizePixel = 0
    LangDropdown.Visible = false
    LangDropdown.ZIndex = 10
    LangDropdown.ClipsDescendants = true
    Instance.new("UICorner", LangDropdown).CornerRadius = UDim.new(0, 8)

    local dropdownStroke = Instance.new("UIStroke", LangDropdown)
    dropdownStroke.Color = Theme.Primary
    dropdownStroke.Thickness = 1
    dropdownStroke.Transparency = 0.3

    local dropdownLayout = Instance.new("UIListLayout", LangDropdown)
    dropdownLayout.Padding = UDim.new(0, 2)
    dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local availableLangs = Language.getAvailable()

    for i, langData in ipairs(availableLangs) do
        local optBtn = Instance.new("TextButton", LangDropdown)
        optBtn.Size = UDim2.new(1, -8, 0, 30)
        optBtn.BackgroundColor3 = Theme.Surface
        optBtn.Text = "  [" .. langData.shortCode .. "]  " .. langData.displayName
        optBtn.Font = Theme.Font
        optBtn.TextSize = 12
        optBtn.TextColor3 = Theme.Text
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.ZIndex = 11
        Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 6)

        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundColor3 = Theme.Surface2
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundColor3 = Theme.Surface
        end)

        optBtn.MouseButton1Click:Connect(function()
            Language.setLanguage(langData.code)
            LangDropdown.Visible = false
        end)
    end

    local totalDropdownHeight = #availableLangs * 32 + 8
    LangDropdown.Size = UDim2.new(0, 140, 0, totalDropdownHeight)

    local dropdownOpen = false
    LangBtn.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        LangDropdown.Visible = dropdownOpen
    end)

    registerRefresh(function()
        local data = Language.getCurrentData()
        LangBtn.Text = "[" .. data.shortCode .. "]"
    end)

    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -40, 0.5, -15)
    MinBtn.BackgroundColor3 = Theme.Surface2
    MinBtn.Text = "−"
    MinBtn.Font = Theme.FontBold
    MinBtn.TextSize = 18
    MinBtn.TextColor3 = Theme.Text
    MinBtn.ZIndex = 3
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    -- ============================================================
    -- DRAG SYSTEM
    -- ============================================================
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function updateDrag(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    local function makeDraggable(element)
        element.InputBegan:Connect(function(input)
            if UNLOADED then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        element.InputChanged:Connect(function(input)
            if UNLOADED then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
    end

    UserInputService.InputChanged:Connect(function(input)
        if UNLOADED then return end
        if input == dragInput and dragging then
            updateDrag(input)
        end
    end)

    makeDraggable(Header)
    makeDraggable(Title)
    makeDraggable(Subtitle)

    -- SIDEBAR
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size = UDim2.new(0, 140, 1, -65)
    Sidebar.Position = UDim2.new(0, 10, 0, 58)
    Sidebar.BackgroundColor3 = Theme.SidebarColor
    Sidebar.BorderSizePixel = 0
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

    -- CONTENT
    local Content = Instance.new("Frame", MainFrame)
    Content.Size = UDim2.new(1, -170, 1, -70)
    Content.Position = UDim2.new(0, 160, 0, 58)
    Content.BackgroundColor3 = Theme.ContentColor
    Content.BackgroundTransparency = 0.3
    Content.BorderSizePixel = 0
    Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 10)

    -- MINIMIZE
    local minimized = false
    local function setMinimized(v)
        minimized = v
        Sidebar.Visible = not v
        Content.Visible = not v
        MainFrame.Size = v and UDim2.new(0, 620, 0, 48) or UDim2.new(0, 620, 0, 480)
    end

    MinBtn.MouseButton1Click:Connect(function()
        setMinimized(not minimized)
    end)

    -- ============================================================
    -- TABS
    -- ============================================================
    local tabs = {}
    local toggleHandles = {}
    local sliderHandles = {}

    local function CreateTab(nameKey, icon)
        local tab = {}

        local btn = Instance.new("TextButton", Sidebar)
        btn.Size = UDim2.new(1, -16, 0, 38)
        btn.Position = UDim2.new(0, 8, 0, 8 + #tabs * 44)
        btn.BackgroundColor3 = Theme.Surface
        btn.BorderSizePixel = 0
        btn.Text = "  " .. icon .. "   "
        btn.Font = Theme.Font
        btn.TextColor3 = Theme.TextDim
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        registerRefresh(function()
            btn.Text = "  " .. icon .. "   " .. Language.get(nameKey)
        end)

        btn.MouseEnter:Connect(function()
            if btn.BackgroundColor3 == Theme.Surface then
                btn.BackgroundColor3 = Theme.Surface2
            end
        end)
        btn.MouseLeave:Connect(function()
            if btn.BackgroundColor3 == Theme.Surface2 then
                btn.BackgroundColor3 = Theme.Surface
            end
        end)

        local container = Instance.new("ScrollingFrame", Content)
        container.Size = UDim2.new(1, -10, 1, -10)
        container.Position = UDim2.new(0, 5, 0, 5)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        container.ScrollBarThickness = 4
        container.ScrollBarImageColor3 = Theme.Primary
        container.ScrollBarImageTransparency = 0.4
        container.Visible = false

        local layout = Instance.new("UIListLayout", container)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.Padding = UDim.new(0, 6)

        local bottomPad = Instance.new("Frame", container)
        bottomPad.Size = UDim2.new(1, 0, 0, 10)
        bottomPad.BackgroundTransparency = 1

        tab.container = container
        tab.btn = btn

        local function activate()
            for _, t in ipairs(tabs) do
                t.container.Visible = false
                t.btn.BackgroundColor3 = Theme.Surface
                t.btn.TextColor3 = Theme.TextDim
            end
            tab.container.Visible = true
            btn.BackgroundColor3 = Theme.Primary
            btn.TextColor3 = Theme.Text
        end

        btn.MouseButton1Click:Connect(activate)
        table.insert(tabs, tab)
        if #tabs == 1 then task.defer(activate) end

        -- TOGGLE
        tab.CreateToggle = function(labelKey, featureId, callback)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 36)
            holder.BackgroundColor3 = Theme.Surface
            holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

            local lbl = Instance.new("TextLabel", holder)
            lbl.Size = UDim2.new(0.5, 0, 1, 0)
            lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.Font
            lbl.TextSize = 12
            lbl.TextColor3 = Theme.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = ""

            registerRefresh(function()
                lbl.Text = Language.get(labelKey)
            end)

            local keyBtn = Instance.new("TextButton", holder)
            keyBtn.Size = UDim2.new(0, 50, 0, 22)
            keyBtn.Position = UDim2.new(0.55, 0, 0.5, -11)
            keyBtn.BackgroundColor3 = State.keybinds[featureId] and Theme.Primary or Theme.Surface2
            keyBtn.Text = State.keybinds[featureId] or Language.get("key")
            keyBtn.Font = Theme.FontBold
            keyBtn.TextSize = 11
            keyBtn.TextColor3 = State.keybinds[featureId] and Theme.Text or Theme.TextDim
            keyBtn.AutoButtonColor = false
            Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)

            registerRefresh(function()
                if State.keybinds[featureId] then
                    keyBtn.Text = State.keybinds[featureId]
                else
                    keyBtn.Text = Language.get("key")
                end
            end)

            local toggleBtn = Instance.new("TextButton", holder)
            toggleBtn.Size = UDim2.new(0, 50, 0, 22)
            toggleBtn.Position = UDim2.new(1, -58, 0.5, -11)
            toggleBtn.BackgroundColor3 = State[featureId] and Theme.Success or Theme.Surface2
            toggleBtn.Font = Theme.FontBold
            toggleBtn.TextSize = 11
            toggleBtn.TextColor3 = Theme.Text
            toggleBtn.AutoButtonColor = false
            Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

            -- Função que atualiza o texto do toggle
            local function refreshToggleText()
                if State[featureId] then
                    toggleBtn.Text = Language.get("on")
                else
                    toggleBtn.Text = Language.get("off")
                end
            end

            -- Registra o refresh
            registerRefresh(refreshToggleText)

            local function setState(v, silent)
                State[featureId] = v
                refreshToggleText()
                toggleBtn.BackgroundColor3 = v and Theme.Success or Theme.Surface2
                if not silent and callback then callback(v) end
            end

            local function toggle()
                setState(not State[featureId])
            end

            toggleBtn.MouseButton1Click:Connect(toggle)

            keyBtn.MouseButton1Click:Connect(function()
                if recordingKeyFor then return end
                recordingKeyFor = featureId
                keyBtn.Text = "..."
                keyBtn.BackgroundColor3 = Theme.Warning
                keyBtn.TextColor3 = Theme.Text
            end)

            local handle = {
                SetState = setState,
                Toggle = toggle,
                SetKeybind = function(key)
                    State.keybinds[featureId] = key
                    if key then
                        keyBtn.Text = key
                        keyBtn.BackgroundColor3 = Theme.Primary
                        keyBtn.TextColor3 = Theme.Text
                    else
                        keyBtn.Text = Language.get("key")
                        keyBtn.BackgroundColor3 = Theme.Surface2
                        keyBtn.TextColor3 = Theme.TextDim
                    end
                end,
                keyBtn = keyBtn,
            }

            toggleHandles[featureId] = handle
            return handle
        end

        -- SLIDER
        tab.CreateSlider = function(labelKey, min, max, defaultValue, featureId, callback)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 44)
            holder.BackgroundColor3 = Theme.Surface
            holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

            local lbl = Instance.new("TextLabel", holder)
            lbl.Size = UDim2.new(0.6, 0, 0, 18)
            lbl.Position = UDim2.new(0, 12, 0, 4)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.Font
            lbl.TextSize = 11
            lbl.TextColor3 = Theme.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = ""

            registerRefresh(function()
                lbl.Text = Language.get(labelKey)
            end)

            local valLbl = Instance.new("TextLabel", holder)
            valLbl.Size = UDim2.new(0.35, 0, 0, 18)
            valLbl.Position = UDim2.new(0.6, 0, 0, 4)
            valLbl.BackgroundTransparency = 1
            valLbl.Font = Theme.FontBold
            valLbl.TextSize = 11
            valLbl.TextColor3 = Theme.Primary
            valLbl.Text = tostring(defaultValue or min)
            valLbl.TextXAlignment = Enum.TextXAlignment.Right

            local barBg = Instance.new("Frame", holder)
            barBg.Size = UDim2.new(1, -24, 0, 5)
            barBg.Position = UDim2.new(0, 12, 0, 30)
            barBg.BackgroundColor3 = Theme.Surface2
            barBg.BorderSizePixel = 0
            Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

            local cur = defaultValue or min
            local rel = (cur - min) / (max - min)
            local fill = Instance.new("Frame", barBg)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            fill.BackgroundColor3 = Theme.Primary
            fill.BorderSizePixel = 0
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local click = Instance.new("TextButton", holder)
            click.Size = UDim2.new(1, 0, 1, 0)
            click.BackgroundTransparency = 1
            click.Text = ""

            local draggingSlider = false
            local function update(mouse)
                local p = barBg.AbsolutePosition
                local s = barBg.AbsoluteSize
                local rx = math.clamp((mouse.X - p.X) / s.X, 0, 1)
                local v = math.floor(min + (max - min) * rx)
                cur = v
                fill.Size = UDim2.new(rx, 0, 1, 0)
                valLbl.Text = tostring(v)
                State[featureId] = v
                if callback then callback(v) end
            end

            click.MouseButton1Down:Connect(function()
                draggingSlider = true
                update(UserInputService:GetMouseLocation())
            end)
            UserInputService.InputEnded:Connect(function(i)
                if UNLOADED then return end
                if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
            end)
            RunService.RenderStepped:Connect(function()
                if UNLOADED then return end
                if draggingSlider then update(UserInputService:GetMouseLocation()) end
            end)

            local handle = {
                SetValue = function(v)
                    cur = math.clamp(v, min, max)
                    local r = (cur - min) / (max - min)
                    fill.Size = UDim2.new(r, 0, 1, 0)
                    valLbl.Text = tostring(cur)
                    State[featureId] = cur
                    if callback then callback(cur) end
                end
            }
            sliderHandles[featureId] = handle
            return handle
        end

        -- BUTTON
        tab.CreateButton = function(labelKey, callback, style)
            local btn = Instance.new("TextButton", container)
            btn.Size = UDim2.new(1, -10, 0, 34)
            btn.BackgroundColor3 = style == "danger" and Color3.fromRGB(60, 25, 25) or Theme.Surface
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.Font = Theme.Font
            btn.TextColor3 = style == "danger" and Theme.Danger or Theme.Text
            btn.TextSize = 12
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            registerRefresh(function()
                btn.Text = Language.get(labelKey)
            end)

            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = style == "danger" and Color3.fromRGB(80, 30, 30) or Theme.Primary
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = style == "danger" and Color3.fromRGB(60, 25, 25) or Theme.Surface
            end)
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            return btn
        end

        -- LABEL
        tab.CreateLabel = function(textKey, color)
            local lbl = Instance.new("TextLabel", container)
            lbl.Size = UDim2.new(1, -10, 0, 18)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.Font
            lbl.TextSize = 11
            lbl.TextColor3 = color or Theme.TextDim
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = ""

            registerRefresh(function()
                lbl.Text = Language.get(textKey)
            end)

            return lbl
        end

        return tab
    end

    -- ============================================================
    -- FEATURES
    -- ============================================================

    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(0, 200, 255)
    fovCircle.Thickness = 1.5
    fovCircle.Filled = false
    fovCircle.NumSides = 100
    fovCircle.Transparency = 1
    fovCircle.Radius = 25
    fovCircle.Visible = false

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        local mouse = UserInputService:GetMouseLocation()
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
        if State.silentHeadshot then
            fovCircle.Visible = true
            fovCircle.Radius = State.silentFov / 6
        elseif State.autoShoot then
            fovCircle.Visible = true
            fovCircle.Radius = State.autoShootFov / 6
        elseif State.aimbot then
            fovCircle.Visible = true
            fovCircle.Radius = 25
        else
            fovCircle.Visible = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.aimbot then return end
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, 25
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d < minDist then minDist = d; closest = p end
                    end
                end
            end
        end
        if closest and closest.Character then
            local head = closest.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end)

    local silentHolding = false
    local silentTarget = nil
    local silentOriginalCam = nil

    local function getClosestHeadInFov()
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, State.silentFov
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d < minDist then
                            minDist = d
                            closest = p
                        end
                    end
                end
            end
        end
        return closest
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then
            silentHolding = false
            return
        end
        local head = silentTarget.Character:FindFirstChild("Head")
        if not head then
            silentHolding = false
            return
        end
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if not State.silentHeadshot then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        silentOriginalCam = Camera.CFrame
        local target = getClosestHeadInFov()
        if not target or not target.Character then return end
        silentTarget = target
        silentHolding = true
        local head = target.Character:FindFirstChild("Head")
        if head then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if silentHolding then
            silentHolding = false
            silentTarget = nil
            if silentOriginalCam then
                Camera.CFrame = silentOriginalCam
                silentOriginalCam = nil
            end
        end
    end)

    local function hasLineOfSight(fromPos, targetPart)
        if not targetPart or not targetPart.Parent then return false end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true

        local exclusions = {}
        if LocalPlayer.Character then
            table.insert(exclusions, LocalPlayer.Character)
        end
        table.insert(exclusions, targetPart.Parent)
        params.FilterDescendantsInstances = exclusions

        local direction = targetPart.Position - fromPos
        local distance = direction.Magnitude
        if distance < 0.1 then return true end

        local unitDir = direction.Unit
        local origin = fromPos + unitDir * 2
        local rayLength = distance - 2

        if rayLength <= 0 then return true end

        local result = workspace:Raycast(origin, unitDir * rayLength, params)
        return result == nil
    end

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoShoot then return end
        local mouse = UserInputService:GetMouseLocation()
        local targetInFov = false

        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d < State.autoShootFov then
                            if hasLineOfSight(Camera.CFrame.Position, head) then
                                targetInFov = true
                                break
                            end
                        end
                    end
                end
            end
        end

        if targetInFov then
            pcall(function()
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.01)
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            pcall(function() mouse1click() end)
        end
    end)

    local hitboxSaved = {}

    local function saveOriginal(player, part)
        if not player or not part then return end
        if not hitboxSaved[player] then hitboxSaved[player] = {} end
        if not hitboxSaved[player][part] then
            hitboxSaved[player][part] = part.Size
        end
    end

    local function restorePlayer(player)
        if not hitboxSaved[player] then return end
        for part, size in pairs(hitboxSaved[player]) do
            if part and part.Parent then
                pcall(function() part.Size = size end)
            end
        end
        hitboxSaved[player] = nil
    end

    local function restoreAll()
        for player, _ in pairs(hitboxSaved) do
            restorePlayer(player)
        end
        hitboxSaved = {}
    end

    local function expandPlayer(p, size)
        if not p.Character then return end
        local head = p.Character:FindFirstChild("Head")
        if head then
            saveOriginal(p, head)
            local baseSize = hitboxSaved[p][head]
            head.Size = Vector3.new(
                baseSize.X * size,
                baseSize.Y * math.min(size, 4),
                baseSize.Z * size
            )
            head.Transparency = 0.7
            head.CanCollide = false
            head.Massless = true
        end
        local headHB = p.Character:FindFirstChild("HeadHB")
        if headHB and headHB:IsA("BasePart") then
            saveOriginal(p, headHB)
            local baseHB = hitboxSaved[p][headHB]
            local hbMult = math.min(size * 1.5, 12)
            headHB.Size = Vector3.new(baseHB.X * hbMult, baseHB.Y * hbMult, baseHB.Z * hbMult)
            headHB.Transparency = 1
            headHB.CanCollide = false
            headHB.Massless = true
        end
        local torso = p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("UpperTorso")
        if torso then
            saveOriginal(p, torso)
            local baseT = hitboxSaved[p][torso]
            local tMult = math.min(size * 0.8, 4)
            torso.Size = Vector3.new(baseT.X * tMult, baseT.Y * tMult, baseT.Z * tMult)
            torso.CanCollide = false
            torso.Massless = true
        end
    end

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.headExpander then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then
            elseif isEnemy(p) then
                if p.Character then expandPlayer(p, State.headExpanderSize) end
            else
                if hitboxSaved[p] then restorePlayer(p) end
            end
        end
    end)

    local ESP = {data = {}}

    local function createESP(p)
        if ESP.data[p] then return end
        if not p.Character then return end
        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Color3.fromRGB(255, 60, 60)
        chams.FillTransparency = 0.6
        chams.OutlineColor = Color3.fromRGB(255, 255, 255)
        chams.OutlineTransparency = 0.3
        chams.Parent = p.Character

        local data = {chams = chams}

        local function newDrawing(class, props)
            local d = Drawing.new(class)
            for k, v in pairs(props) do d[k] = v end
            d.Visible = false
            return d
        end

        data.box = newDrawing("Square", {Thickness = 1.5, Color = Color3.fromRGB(0, 200, 255), Filled = false, Transparency = 1})
        data.name = newDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        data.distance = newDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(0, 200, 255)})
        data.health = newDrawing("Line", {Thickness = 3, Color = Color3.fromRGB(0, 255, 0)})
        data.tracer = newDrawing("Line", {Thickness = 1.2, Color = Color3.fromRGB(0, 200, 255)})
        data.headDot = newDrawing("Circle", {Radius = 4, NumSides = 20, Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255)})

        ESP.data[p] = data
    end

    local function removeESP(p)
        local d = ESP.data[p]
        if not d then return end
        if d.chams then d.chams:Destroy() end
        for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot"}) do
            if d[key] and d[key].Remove then d[key]:Remove() end
        end
        ESP.data[p] = nil
    end

    local function clearAllESP()
        for p, _ in pairs(ESP.data) do
            removeESP(p)
        end
    end

    local function updateESP(p, char)
        local d = ESP.data[p]
        if not d then return end
        if not State.esp or not isEnemy(p) then
            for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then return end
        if d.chams then d.chams.Enabled = true end

        local headSp, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpSp, hrpOn = Camera:WorldToViewportPoint(hrp.Position)
        local footPos = hrp.Position - Vector3.new(0, 3, 0)
        local footSp, footOn = Camera:WorldToViewportPoint(footPos)

        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local dist = math.floor((head.Position - myHRP.Position).Magnitude)

        if dist > State.espMaxDistance then
            for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            return
        end

        if headOn and footOn then
            local h = math.abs(footSp.Y - headSp.Y)
            local w = h * 0.6
            local cx = (headSp.X + footSp.X) / 2
            local cy = (headSp.Y + footSp.Y) / 2
            d.box.Position = Vector2.new(cx - w / 2, cy - h / 2)
            d.box.Size = Vector2.new(w, h)
            d.box.Color = Color3.fromRGB(0, 200, 255)
            d.box.Visible = true
        else
            d.box.Visible = false
        end

        if headOn then
            d.name.Position = Vector2.new(headSp.X, headSp.Y - 20)
            d.name.Text = p.Name
            d.name.Visible = true
            d.distance.Position = Vector2.new(headSp.X, headSp.Y - 6)
            d.distance.Text = dist .. "m"
            d.distance.Visible = true
        else
            d.name.Visible = false
            d.distance.Visible = false
        end

        if headOn and footOn then
            local h = math.abs(footSp.Y - headSp.Y)
            local hr = hum.Health / hum.MaxHealth
            local bx = headSp.X + (h * 0.6) / 2 + 5
            local by = headSp.Y + h
            local fy = by - (h * hr)
            d.health.From = Vector2.new(bx, fy)
            d.health.To = Vector2.new(bx, by)
            if hr > 0.6 then d.health.Color = Color3.fromRGB(0, 255, 0)
            elseif hr > 0.3 then d.health.Color = Color3.fromRGB(255, 200, 0)
            else d.health.Color = Color3.fromRGB(255, 40, 40) end
            d.health.Visible = true
        else
            d.health.Visible = false
        end

        if hrpOn then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To = Vector2.new(hrpSp.X, hrpSp.Y)
            d.tracer.Visible = true
        else
            d.tracer.Visible = false
        end

        if headOn then
            d.headDot.Position = Vector2.new(headSp.X, headSp.Y)
            d.headDot.Visible = true
        else
            d.headDot.Visible = false
        end
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.esp then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if not ESP.data[p] then createESP(p) end
                updateESP(p, p.Character)
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(p)
        removeESP(p)
    end)

    local reloadOriginals = {}

    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if not (State.rapidFire or State.noRecoil or State.fastReload or State.instaReload) then return end
        local char = LocalPlayer.Character
        if not char then return end

        local containers = {char}
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then table.insert(containers, backpack) end

        for _, container in ipairs(containers) do
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    if State.rapidFire then
                        pcall(function()
                            for _, name in ipairs({"FireRate", "BFireRate", "RateOfFire"}) do
                                local f = tool:FindFirstChild(name)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then
                                    f.Value = 0.03
                                elseif typeof(tool[name]) == "number" then
                                    tool[name] = 0.03
                                end
                            end
                            for _, name in ipairs({"Cooldown", "EquipTime", "EquipCooldown", "SwapCooldown", "NextFire"}) do
                                local f = tool:FindFirstChild(name)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then
                                    f.Value = 0
                                elseif typeof(tool[name]) == "number" then
                                    tool[name] = 0
                                end
                            end
                        end)
                    end

                    if State.noRecoil then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("recoil") or n:find("kick") or n:find("spread") then
                                        d.Value = 0
                                    end
                                end
                            end
                        end)
                    end

                    if State.fastReload and not State.instaReload then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    if d.Name:lower():find("reload") then
                                        if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                        d.Value = reloadOriginals[d] * 0.3
                                    end
                                end
                            end
                        end)
                    end

                    if State.instaReload then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    if d.Name:lower():find("reload") then
                                        d.Value = 0
                                    end
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)

    coroutine.wrap(function()
        while true do
            if UNLOADED then return end
            if State.rapidFire or State.noRecoil or State.fastReload or State.instaReload then
                pcall(function()
                    if ReplicatedStorage:FindFirstChild("Weapons") then
                        for _, d in ipairs(ReplicatedStorage.Weapons:GetDescendants()) do
                            if d:IsA("NumberValue") or d:IsA("IntValue") then
                                local n = d.Name:lower()
                                if State.rapidFire and (n == "firerate" or n == "bfirerate" or n == "rateoffire") then
                                    d.Value = 0.03
                                elseif State.rapidFire and (n:find("cooldown") or n:find("equip") or n:find("swap")) then
                                    d.Value = 0
                                elseif State.noRecoil and (n == "recoilcontrol" or n:find("recoil")) then
                                    d.Value = 0
                                elseif State.fastReload and not State.instaReload and n:find("reload") then
                                    if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                    d.Value = reloadOriginals[d] * 0.3
                                elseif State.instaReload and n:find("reload") then
                                    d.Value = 0
                                end
                            end
                        end
                    end
                end)
            end
            task.wait(1)
        end
    end)()

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.speed then return end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= 50 then hum.WalkSpeed = 50 end
        end
    end)

    local airJumpConn = nil

    local function startAirJump()
        if airJumpConn then airJumpConn:Disconnect() end
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid")
        hum.JumpPower = 70
        airJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED then return end
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end

    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    local backstabLock = {active = false, target = nil, endTime = 0}

    local function getClosestEnemyAnywhere()
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local closest, closestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d < closestDist then closestDist = d; closest = p end
                end
            end
        end
        return closest
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not backstabLock.active then return end
        if tick() >= backstabLock.endTime then
            backstabLock.active = false; backstabLock.target = nil; return
        end
        local target = backstabLock.target
        if target and target.Character then
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and myHRP then
                Camera.CFrame = CFrame.new(myHRP.Position, targetHRP.Position)
            end
        end
    end)

    local function doBackstab()
        if UNLOADED then return end
        local target = getClosestEnemyAnywhere()
        if not target or not target.Character then
            print("[Infinite Zen] " .. Language.get("no_enemy")); return
        end
        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP or not myHRP then return end

        print("[Infinite Zen] " .. Language.get("backstab_target") .. target.Name)
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
        backstabLock.active = true
        backstabLock.target = target
        backstabLock.endTime = tick() + 0.5
        Camera.CFrame = CFrame.new(myHRP.Position, targetHRP.Position)
        task.wait(0.08)
        Camera.CFrame = CFrame.new(myHRP.Position, targetHRP.Position)
        task.wait(0.02)

        for _ = 1, 3 do
            pcall(function()
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.02)
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            pcall(function() mouse1click() end)
            task.wait(0.05)
        end
    end

    -- ============================================================
    -- CRIAR ABAS
    -- ============================================================
    local CombatTab = CreateTab("tab_combat", "⚔️")
    CombatTab.CreateToggle("silent_headshot", "silentHeadshot")
    CombatTab.CreateSlider("silent_fov", 30, 300, 120, "silentFov")
    CombatTab.CreateToggle("aimbot", "aimbot")
    CombatTab.CreateToggle("head_expander", "headExpander", function(v)
        if not v then restoreAll() end
    end)
    CombatTab.CreateSlider("head_size", 1, 8, 3, "headExpanderSize")
    CombatTab.CreateToggle("backstab", "backstab")

    local WeaponTab = CreateTab("tab_weapon", "🔫")
    WeaponTab.CreateToggle("no_recoil", "noRecoil")
    WeaponTab.CreateToggle("rapid_fire", "rapidFire")
    WeaponTab.CreateToggle("fast_reload", "fastReload", function(v)
        if not v then
            for value, original in pairs(reloadOriginals) do
                pcall(function() value.Value = original end)
            end
            reloadOriginals = {}
        end
    end)
    WeaponTab.CreateToggle("insta_reload", "instaReload")
    WeaponTab.CreateToggle("auto_shoot", "autoShoot")
    WeaponTab.CreateSlider("auto_shoot_fov", 30, 300, 100, "autoShootFov")

    local MovementTab = CreateTab("tab_movement", "🏃")
    MovementTab.CreateToggle("speed", "speed", function(v)
        if not v then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end)
    MovementTab.CreateToggle("air_jump", "airJump", function(v)
        if v then startAirJump() else stopAirJump() end
    end)

    local VisualsTab = CreateTab("tab_visuals", "👁️")
    VisualsTab.CreateToggle("esp", "esp", function(v)
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then createESP(p) end
            end
        else
            clearAllESP()
        end
    end)
    VisualsTab.CreateSlider("max_distance", 100, 10000, 500, "espMaxDistance")

    local SettingsTab = CreateTab("tab_settings", "⚙️")

    local function saveConfig()
        local data = {}
        for k, v in pairs(State) do
            if k ~= "keybinds" then data[k] = v end
        end
        data.keybinds = State.keybinds
        local json = HttpService:JSONEncode(data)
        local ok = pcall(function()
            writefile("InfiniteZen_Config.json", json)
        end)
        if ok then
            Notify("💾 " .. Language.get("config_title"), Language.get("config_saved"), 3)
        else
            Notify("⚠️ " .. Language.get("error_title"), Language.get("config_error_save"), 3, true)
        end
    end

    local function loadConfig()
        local ok, content = pcall(function()
            return readfile("InfiniteZen_Config.json")
        end)
        if ok and content then
            local success, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if success and data then
                for k, v in pairs(data) do
                    if k == "keybinds" then
                        for feat, key in pairs(v) do
                            State.keybinds[feat] = key
                        end
                    else
                        State[k] = v
                    end
                end
                for featId, handle in pairs(toggleHandles) do
                    if State[featId] ~= nil then handle.SetState(State[featId], true) end
                    handle.SetKeybind(State.keybinds[featId])
                end
                for featId, handle in pairs(sliderHandles) do
                    if State[featId] ~= nil then handle.SetValue(State[featId]) end
                end
                Notify("📂 " .. Language.get("load_title"), Language.get("config_loaded"), 3)
            else
                Notify("⚠️ " .. Language.get("error_title"), Language.get("config_error_corrupt"), 3, true)
            end
        else
            Notify("⚠️ " .. Language.get("error_title"), Language.get("config_error_load"), 3, true)
        end
    end

    local function unloadScript()
        UNLOADED = true
        _G.IZ_RefreshLanguage = nil
        restoreAll()
        clearAllESP()
        if airJumpConn then airJumpConn:Disconnect() end
        if fovCircle then fovCircle:Remove() end
        GUI:Destroy()
        print("[Infinite Zen] Script descarregado")
    end

    SettingsTab.CreateLabel("interface_label")
    SettingsTab.CreateButton("save_config", saveConfig)
    SettingsTab.CreateButton("load_config", loadConfig)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateLabel("info_label")
    SettingsTab.CreateLabel("key_minimize")
    SettingsTab.CreateLabel("keybind_help1")
    SettingsTab.CreateLabel("keybind_help2")
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateButton("unload_script", unloadScript, "danger")

    local versionLabel = Instance.new("TextLabel", MainFrame)
    versionLabel.Size = UDim2.new(1, -20, 0, 16)
    versionLabel.Position = UDim2.new(0, 10, 1, -20)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Font = Theme.Font
    versionLabel.TextSize = 10
    versionLabel.TextColor3 = Theme.TextDim
    versionLabel.TextXAlignment = Enum.TextXAlignment.Right
    versionLabel.Text = Language.get("version_text")

    registerRefresh(function()
        versionLabel.Text = Language.get("version_text")
    end)

    registerRefresh(function()
        Subtitle.Text = Language.get("hub_subtitle") .. " • v1.0"
    end)

    local MINIMIZE_KEY = Enum.KeyCode.K

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

        if recordingKeyFor then
            local featId = recordingKeyFor

            if input.KeyCode == Enum.KeyCode.Escape then
                recordingKeyFor = nil
                local handle = toggleHandles[featId]
                if handle then handle.SetKeybind(State.keybinds[featId]) end
                return
            end

            local newKey = input.KeyCode.Name

            if newKey == "K" then
                Notify("🚫 " .. Language.get("keybind_locked"),
                    Language.get("keybind_locked_desc"),
                    4, true)
                recordingKeyFor = nil
                local handle = toggleHandles[featId]
                if handle then handle.SetKeybind(State.keybinds[featId]) end
                return
            end

            local conflictFeat = findFeatureWithKeybind(newKey)
            if conflictFeat and conflictFeat ~= featId then
                local conflictLabel = FeatureLabels[conflictFeat] or conflictFeat
                Notify("🚫 " .. Language.get("keybind_inuse"),
                    newKey .. Language.get("keybind_inuse_desc") .. conflictLabel,
                    4, true)
                recordingKeyFor = nil
                local handle = toggleHandles[featId]
                if handle then handle.SetKeybind(State.keybinds[featId]) end
                return
            end

            State.keybinds[featId] = newKey
            recordingKeyFor = nil
            local handle = toggleHandles[featId]
            if handle then handle.SetKeybind(State.keybinds[featId]) end
            return
        end

        if input.KeyCode == MINIMIZE_KEY then
            setMinimized(not minimized)
            return
        end

        local keyName = input.KeyCode.Name
        for featId, key in pairs(State.keybinds) do
            if key and key == keyName then
                if featId == "backstab" then
                    if State.backstab then doBackstab() end
                else
                    local handle = toggleHandles[featId]
                    if handle then handle.Toggle() end
                end
            end
        end
    end)

    print("[Infinite Zen] ✅ Arsenal carregado!")
    print("[Infinite Zen] K = Minimize | E = Backstab | X = Silent Headshot")
end

return Arsenal