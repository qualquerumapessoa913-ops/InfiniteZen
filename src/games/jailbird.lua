-- ============================================================
-- INFINITE ZEN - MÓDULO JAILBIRD v1.3 (FIXED)
-- Jailbird (PlaceId 14939963714)
-- ============================================================

local Jailbird = {}

function Jailbird.Init(ctx)
    local Language = ctx.Language
    local gameName = ctx.gameName

    print("[Infinite Zen] Inicializando Jailbird v1.3 FIXED...")

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInput = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    local UNLOADED = false
    local AUTOLOAD_FILE = "InfiniteZen_Jailbird_Autoload.txt"
    local CONFIG_FOLDER = "InfiniteZen_Configs"
    local IS_JAILBIRD = game.PlaceId == 14939963714

    -- ============================================================
    -- TRADUÇÃO
    -- ============================================================
    local langRefresh = {}
    local function registerRefresh(fn)
        table.insert(langRefresh, fn)
        pcall(fn)
    end
    _G.IZ_RefreshLanguage = function()
        for _, fn in ipairs(langRefresh) do pcall(fn) end
    end

    -- ============================================================
    -- THEME
    -- ============================================================
    local Theme = {
        Bg = Color3.fromRGB(8, 4, 6),
        Surface = Color3.fromRGB(18, 8, 12),
        Surface2 = Color3.fromRGB(35, 12, 18),
        Border = Color3.fromRGB(80, 15, 20),
        SidebarColor = Color3.fromRGB(15, 6, 10),
        ContentColor = Color3.fromRGB(25, 10, 15),
        Primary = Color3.fromRGB(255, 30, 40),
        TitleRed = Color3.fromRGB(255, 50, 50),
        Success = Color3.fromRGB(0, 220, 130),
        Danger = Color3.fromRGB(255, 40, 40),
        Warning = Color3.fromRGB(255, 150, 50),
        Text = Color3.fromRGB(255, 245, 245),
        TextDim = Color3.fromRGB(160, 120, 130),
        Discord = Color3.fromRGB(88, 101, 242),
        Font = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBlack,
    }

    -- ============================================================
    -- ESTADO
    -- ============================================================
    local State = {
        silentHeadshot = false,
        silentFov = 120,
        aimbot = false,
        aimbotFov = 100,
        aimbotSmoothness = 0.3,
        aimbotMaxDist = 500,
        headExpander = false,
        headExpanderSize = 3,
        backstab = false,
        noRecoil = false,
        rapidFire = false,
        fastReload = false,
        instaReload = false,
        autoShoot = false,
        autoShootFov = 100,
        autoShootDelay = 0.05,
        speed = false,
        speedValue = 50,
        airJump = false,
        esp = false,
        espMaxDistance = 500,
        fullbright = false,
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
            fullbright = nil,
        }
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
        fullbright = "Fullbright",
    }

    local oldMenu = PlayerGui:FindFirstChild("InfiniteZen")
    if oldMenu then oldMenu:Destroy() end

    local GUI = Instance.new("ScreenGui")
    GUI.Name = "InfiniteZen"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if gethui then
        local ok = pcall(function() GUI.Parent = gethui() end)
        if not ok then GUI.Parent = PlayerGui end
    else
        GUI.Parent = PlayerGui
    end

    -- ============================================================
    -- NOTIFICAÇÕES
    -- ============================================================
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
        s.Color = strokeColor; s.Thickness = 1.5; s.Transparency = 0.2

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
                if n == notif then table.remove(activeNotifs, i); break end
            end
            if notif and notif.Parent then
                TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, 20, 0, notif.Position.Y.Offset)
                }):Play()
                task.wait(0.35)
                if notif.Parent then notif:Destroy() end
            end
        end)
    end

    local function findFeatureWithKeybind(key)
        for featId, boundKey in pairs(State.keybinds) do
            if boundKey == key then return featId end
        end
        return nil
    end

    -- ============================================================
    -- HELPERS
    -- ============================================================
    local function isEnemy(player)
        if player == LocalPlayer then return false end
        if not player.Character then return false end
        if player.Team then
            local tname = player.Team.Name
            if tname == "Spectator" or tname == "Spectators" or tname == "Neutral" then
                return false
            end
        end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        local myTeam = LocalPlayer.Team
        if myTeam == nil then return true end
        if player.Team == nil then return false end
        return player.Team ~= myTeam
    end

    local function hasLineOfSight(fromPos, targetPart)
        if not targetPart or not targetPart.Parent then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local exclusions = {}
        if LocalPlayer.Character then table.insert(exclusions, LocalPlayer.Character) end
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

    -- Tenta pegar remote de look (Jailbird específico)
    local lookRemote = nil
    pcall(function()
        if ReplicatedStorage:FindFirstChild("GameEvents") then
            lookRemote = ReplicatedStorage.GameEvents:FindFirstChild("LookRotation")
        end
    end)

    -- ============================================================
    -- MAIN WINDOW
    -- ============================================================
    local MainFrame = Instance.new("Frame", GUI)
    MainFrame.Size = UDim2.new(0, 620, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -310, 0.5, -240)
    MainFrame.BackgroundColor3 = Theme.Bg
    MainFrame.BorderSizePixel = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Color = Theme.Primary; mainStroke.Thickness = 1.5; mainStroke.Transparency = 0.3

    local shadow = Instance.new("ImageLabel", MainFrame)
    shadow.Image = "rbxassetid://1316045217"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.55
    shadow.ZIndex = 0

    local Header = Instance.new("Frame", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 48)
    Header.BackgroundColor3 = Theme.Surface
    Header.BorderSizePixel = 0
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 10, 20)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 30, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 5, 15))
    })
    headerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.75),
        NumberSequenceKeypoint.new(0.5, 0.9),
        NumberSequenceKeypoint.new(1, 0.95)
    })
    headerGradient.Rotation = 15
    headerGradient.Parent = Header

    local headerFix = Instance.new("Frame", Header)
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = Theme.Surface
    headerFix.BorderSizePixel = 0

    local headerBar = Instance.new("Frame", Header)
    headerBar.Size = UDim2.new(1, 0, 0, 2)
    headerBar.BackgroundColor3 = Theme.Primary
    headerBar.BorderSizePixel = 0
    headerBar.ZIndex = 2
    local hbg = Instance.new("UIGradient")
    hbg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 5, 15)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 50, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 5, 15))
    })
    hbg.Parent = headerBar

    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(0, 250, 0, 22)
    Title.Position = UDim2.new(0, 20, 0, 6)
    Title.BackgroundTransparency = 1
    Title.Font = Theme.FontBold
    Title.Text = "∞ INFINITE ZEN"
    Title.TextColor3 = Theme.TitleRed
    Title.TextSize = 17
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 3
    local titleStroke = Instance.new("UIStroke", Title)
    titleStroke.Color = Color3.fromRGB(255, 100, 100); titleStroke.Thickness = 1; titleStroke.Transparency = 0.7

    local Subtitle = Instance.new("TextLabel", Header)
    Subtitle.Size = UDim2.new(0, 250, 0, 18)
    Subtitle.Position = UDim2.new(0, 20, 0, 25)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Font = Theme.Font
    Subtitle.Text = "Jailbird v1.3 FIXED"
    Subtitle.TextColor3 = Color3.fromRGB(220, 180, 185)
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
    local dStroke = Instance.new("UIStroke", LangDropdown)
    dStroke.Color = Theme.Primary; dStroke.Thickness = 1; dStroke.Transparency = 0.3
    local dLayout = Instance.new("UIListLayout", LangDropdown)
    dLayout.Padding = UDim.new(0, 2)

    for _, langData in ipairs(Language.getAvailable()) do
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
        optBtn.MouseEnter:Connect(function() optBtn.BackgroundColor3 = Theme.Surface2 end)
        optBtn.MouseLeave:Connect(function() optBtn.BackgroundColor3 = Theme.Surface end)
        optBtn.MouseButton1Click:Connect(function()
            Language.setLanguage(langData.code)
            LangDropdown.Visible = false
        end)
    end
    LangDropdown.Size = UDim2.new(0, 140, 0, #Language.getAvailable() * 32 + 8)

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

    -- DRAG
    local dragging, dragInput, dragStart, startPos
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
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        element.InputChanged:Connect(function(input)
            if UNLOADED then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
        end)
    end
    UserInputService.InputChanged:Connect(function(input)
        if UNLOADED then return end
        if input == dragInput and dragging then updateDrag(input) end
    end)
    makeDraggable(Header); makeDraggable(Title); makeDraggable(Subtitle)

    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size = UDim2.new(0, 140, 1, -65)
    Sidebar.Position = UDim2.new(0, 10, 0, 58)
    Sidebar.BackgroundColor3 = Theme.SidebarColor
    Sidebar.BorderSizePixel = 0
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)
    local sbStroke = Instance.new("UIStroke", Sidebar)
    sbStroke.Color = Theme.Border; sbStroke.Thickness = 1; sbStroke.Transparency = 0.5

    local Content = Instance.new("Frame", MainFrame)
    Content.Size = UDim2.new(1, -170, 1, -70)
    Content.Position = UDim2.new(0, 160, 0, 58)
    Content.BackgroundColor3 = Theme.ContentColor
    Content.BackgroundTransparency = 0.3
    Content.BorderSizePixel = 0
    Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 8)
    local cStroke = Instance.new("UIStroke", Content)
    cStroke.Color = Theme.Border; cStroke.Thickness = 1; cStroke.Transparency = 0.5

    local minimized = false
    local function setMinimized(v)
        minimized = v
        Sidebar.Visible = not v
        Content.Visible = not v
        MainFrame.Size = v and UDim2.new(0, 620, 0, 48) or UDim2.new(0, 620, 0, 480)
    end
    MinBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)

    -- ============================================================
    -- TABS BUILDER
    -- ============================================================
    local tabs, toggleHandles, sliderHandles = {}, {}, {}

    local function CreateTab(name, icon)
        local tab = {}
        local btn = Instance.new("TextButton", Sidebar)
        btn.Size = UDim2.new(1, -16, 0, 38)
        btn.Position = UDim2.new(0, 8, 0, 8 + #tabs * 44)
        btn.BackgroundColor3 = Theme.Surface
        btn.BorderSizePixel = 0
        btn.Text = "  " .. icon .. "   " .. name
        btn.Font = Theme.Font
        btn.TextColor3 = Theme.TextDim
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseEnter:Connect(function()
            if btn.BackgroundColor3 == Theme.Surface then btn.BackgroundColor3 = Theme.Surface2 end
        end)
        btn.MouseLeave:Connect(function()
            if btn.BackgroundColor3 == Theme.Surface2 then btn.BackgroundColor3 = Theme.Surface end
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
        layout.Padding = UDim.new(0, 6)
        local bp = Instance.new("Frame", container)
        bp.Size = UDim2.new(1, 0, 0, 10); bp.BackgroundTransparency = 1

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

        tab.CreateToggle = function(label, featureId, callback)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 36)
            holder.BackgroundColor3 = Theme.Surface
            holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", holder)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7

            local lbl = Instance.new("TextLabel", holder)
            lbl.Size = UDim2.new(0.5, 0, 1, 0)
            lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.Font
            lbl.TextSize = 12
            lbl.TextColor3 = Theme.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = label

            local keyBtn = Instance.new("TextButton", holder)
            keyBtn.Size = UDim2.new(0, 50, 0, 22)
            keyBtn.Position = UDim2.new(0.55, 0, 0.5, -11)
            keyBtn.BackgroundColor3 = State.keybinds[featureId] and Theme.Primary or Theme.Surface2
            keyBtn.Text = State.keybinds[featureId] or "KEY"
            keyBtn.Font = Theme.FontBold
            keyBtn.TextSize = 11
            keyBtn.TextColor3 = State.keybinds[featureId] and Theme.Text or Theme.TextDim
            keyBtn.AutoButtonColor = false
            Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)

            local toggleBtn = Instance.new("TextButton", holder)
            toggleBtn.Size = UDim2.new(0, 50, 0, 22)
            toggleBtn.Position = UDim2.new(1, -58, 0.5, -11)
            toggleBtn.BackgroundColor3 = State[featureId] and Theme.Success or Theme.Surface2
            toggleBtn.Font = Theme.FontBold
            toggleBtn.TextSize = 11
            toggleBtn.TextColor3 = Theme.Text
            toggleBtn.Text = State[featureId] and "ON" or "OFF"
            toggleBtn.AutoButtonColor = false
            Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

            local function setState(v, silent)
                State[featureId] = v
                toggleBtn.Text = v and "ON" or "OFF"
                toggleBtn.BackgroundColor3 = v and Theme.Success or Theme.Surface2
                if not silent and callback then callback(v) end
            end
            local function toggle() setState(not State[featureId]) end
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
                        keyBtn.Text = "KEY"
                        keyBtn.BackgroundColor3 = Theme.Surface2
                        keyBtn.TextColor3 = Theme.TextDim
                    end
                end,
                keyBtn = keyBtn,
            }
            toggleHandles[featureId] = handle
            return handle
        end

        tab.CreateSlider = function(label, min, max, def, featureId, callback)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 44)
            holder.BackgroundColor3 = Theme.Surface
            holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", holder)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7

            local lbl = Instance.new("TextLabel", holder)
            lbl.Size = UDim2.new(0.6, 0, 0, 18)
            lbl.Position = UDim2.new(0, 12, 0, 4)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.Font
            lbl.TextSize = 11
            lbl.TextColor3 = Theme.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = label

            local valLbl = Instance.new("TextLabel", holder)
            valLbl.Size = UDim2.new(0.35, 0, 0, 18)
            valLbl.Position = UDim2.new(0.6, 0, 0, 4)
            valLbl.BackgroundTransparency = 1
            valLbl.Font = Theme.FontBold
            valLbl.TextSize = 11
            valLbl.TextColor3 = Theme.Primary
            valLbl.Text = tostring(def or min)
            valLbl.TextXAlignment = Enum.TextXAlignment.Right

            local barBg = Instance.new("Frame", holder)
            barBg.Size = UDim2.new(1, -24, 0, 5)
            barBg.Position = UDim2.new(0, 12, 0, 30)
            barBg.BackgroundColor3 = Theme.Surface2
            barBg.BorderSizePixel = 0
            Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

            local cur = def or min
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

        tab.CreateButton = function(label, callback, style)
            local btn = Instance.new("TextButton", container)
            btn.Size = UDim2.new(1, -10, 0, 34)
            btn.BackgroundColor3 = style == "danger" and Color3.fromRGB(60, 15, 20) or Theme.Surface
            btn.BorderSizePixel = 0
            btn.Text = label
            btn.Font = Theme.Font
            btn.TextColor3 = style == "danger" and Theme.Danger or Theme.Text
            btn.TextSize = 12
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            local bs = Instance.new("UIStroke", btn)
            bs.Color = Theme.Border; bs.Thickness = 1; bs.Transparency = 0.7

            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = style == "danger" and Color3.fromRGB(80, 20, 25) or Theme.Primary
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = style == "danger" and Color3.fromRGB(60, 15, 20) or Theme.Surface
            end)
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            return btn
        end

        tab.CreateLabel = function(text, color)
            local lbl = Instance.new("TextLabel", container)
            lbl.Size = UDim2.new(1, -10, 0, 18)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.Font
            lbl.TextSize = 11
            lbl.TextColor3 = color or Theme.TextDim
            lbl.Text = text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            return lbl
        end

        tab.CreateTextBox = function(placeholder, callback)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 36)
            holder.BackgroundColor3 = Theme.Surface
            holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", holder)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7

            local box = Instance.new("TextBox", holder)
            box.Size = UDim2.new(1, -20, 1, -10)
            box.Position = UDim2.new(0, 10, 0, 5)
            box.BackgroundTransparency = 1
            box.Font = Theme.Font
            box.TextSize = 12
            box.TextColor3 = Theme.Text
            box.PlaceholderText = placeholder or "Type..."
            box.PlaceholderColor3 = Theme.TextDim
            box.Text = ""
            box.ClearTextOnFocus = false
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.FocusLost:Connect(function(enterPressed)
                if enterPressed and box.Text ~= "" then
                    local text = box.Text
                    box.Text = ""
                    if callback then callback(text) end
                end
            end)
            return box
        end

        tab.CreateCredit = function(role, name, color)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 50)
            holder.BackgroundColor3 = Theme.Surface
            holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", holder)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7

            local roleLbl = Instance.new("TextLabel", holder)
            roleLbl.Size = UDim2.new(1, -20, 0, 16)
            roleLbl.Position = UDim2.new(0, 12, 0, 6)
            roleLbl.BackgroundTransparency = 1
            roleLbl.Font = Theme.Font
            roleLbl.TextSize = 10
            roleLbl.TextColor3 = Theme.TextDim
            roleLbl.Text = role
            roleLbl.TextXAlignment = Enum.TextXAlignment.Left

            local nameLbl = Instance.new("TextLabel", holder)
            nameLbl.Size = UDim2.new(1, -20, 0, 20)
            nameLbl.Position = UDim2.new(0, 12, 0, 22)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Theme.FontBold
            nameLbl.TextSize = 14
            nameLbl.TextColor3 = color or Theme.TitleRed
            nameLbl.Text = name
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            return holder
        end

        return tab
    end

    -- ============================================================
    -- FOV CIRCLE
    -- ============================================================
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Theme.Primary
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
            fovCircle.Radius = State.aimbotFov / 6
        else
            fovCircle.Visible = false
        end
    end)

    -- ============================================================
    -- TARGETING HELPERS
    -- ============================================================
    local function getClosestHeadInFov(fovRange)
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, fovRange
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

    -- ============================================================
    -- SILENT HEADSHOT (FIX)
    -- ============================================================
    local silentHolding = false
    local silentTarget = nil
    local silentOriginalCF = nil

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then silentHolding = false; return end
        local head = silentTarget.Character:FindFirstChild("Head")
        if not head then silentHolding = false; return end
        -- FIX: usa CFrame + remote se disponível
        local newCF = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
        Camera.CFrame = newCF
        if lookRemote then
            pcall(function() lookRemote:FireServer(newCF) end)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if not State.silentHeadshot then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        silentOriginalCF = Camera.CFrame
        local target = getClosestHeadInFov(State.silentFov)
        if not target or not target.Character then return end
        silentTarget = target
        silentHolding = true
        local head = target.Character:FindFirstChild("Head")
        if head then
            local newCF = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
            Camera.CFrame = newCF
            if lookRemote then
                pcall(function() lookRemote:FireServer(newCF) end)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if silentHolding then
            silentHolding = false
            silentTarget = nil
            if silentOriginalCF then
                Camera.CFrame = silentOriginalCF
                if lookRemote then
                    pcall(function() lookRemote:FireServer(silentOriginalCF) end)
                end
                silentOriginalCF = nil
            end
        end
    end)

    -- ============================================================
    -- AIMBOT (FIX: mousemoverel)
    -- ============================================================
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.aimbot then return end
        local target = getClosestHeadInFov(State.aimbotFov)
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local dist3D = (head.Position - myRoot.Position).Magnitude
                    if dist3D <= State.aimbotMaxDist and hasLineOfSight(Camera.CFrame.Position, head) then
                        local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local mouse = UserInputService:GetMouseLocation()
                            local dx = sp.X - mouse.X
                            local dy = sp.Y - mouse.Y
                            local s = State.aimbotSmoothness
                            if mousemoverel then
                                pcall(function() mousemoverel(dx * s, dy * s) end)
                            end
                        end
                    end
                end
            end
        end
    end)

    -- ============================================================
    -- AUTO SHOOT (FIX: tool:Activate + VirtualInput + mouse1click)
    -- ============================================================
    local lastAutoShoot = 0

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoShoot then return end
        if tick() - lastAutoShoot < State.autoShootDelay then return end
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end

        local mouse = UserInputService:GetMouseLocation()
        local targetFound = false
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d < State.autoShootFov and hasLineOfSight(Camera.CFrame.Position, head) then
                            targetFound = true
                            break
                        end
                    end
                end
            end
        end

        if targetFound then
            lastAutoShoot = tick()
            -- 3 métodos em sequência (fallback)
            pcall(function() tool:Activate() end)
            pcall(function()
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.01)
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            pcall(function() mouse1click() end)
        end
    end)

    -- ============================================================
    -- BACKSTAB
    -- ============================================================
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
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            local mHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and mHRP then
                Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
            end
        end
    end)

    local function doBackstab()
        if UNLOADED then return end
        local target = getClosestEnemyAnywhere()
        if not target or not target.Character then
            Notify("⚔️ Backstab", "Nenhum inimigo próximo", 3, true)
            return
        end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local mHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP or not mHRP then return end

        Notify("⚔️ Backstab", "Alvo: " .. target.Name, 2)
        mHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2)
        backstabLock.active = true
        backstabLock.target = target
        backstabLock.endTime = tick() + 0.5
        Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
        task.wait(0.08)
        Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
        task.wait(0.02)
        for _ = 1, 3 do
            pcall(function() mouse1click() end)
            pcall(function()
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.02)
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            task.wait(0.05)
        end
    end

    -- ============================================================
    -- HEAD EXPANDER
    -- ============================================================
    local hitboxSaved = {}

    local function saveOriginal(player, part)
        if not player or not part then return end
        if not hitboxSaved[player] then hitboxSaved[player] = {} end
        if not hitboxSaved[player][part] then hitboxSaved[player][part] = part.Size end
    end
    local function restorePlayer(player)
        if not hitboxSaved[player] then return end
        for part, size in pairs(hitboxSaved[player]) do
            if part and part.Parent then pcall(function() part.Size = size end) end
        end
        hitboxSaved[player] = nil
    end
    local function restoreAllHitboxes()
        for player, _ in pairs(hitboxSaved) do restorePlayer(player) end
        hitboxSaved = {}
    end

    local function expandPlayer(p, size)
        if not p.Character then return end
        local head = p.Character:FindFirstChild("Head")
        if head then
            saveOriginal(p, head)
            local base = hitboxSaved[p][head]
            head.Size = Vector3.new(base.X * size, base.Y * math.min(size, 4), base.Z * size)
            head.Transparency = 0.7
            head.CanCollide = false
            head.Massless = true
        end
        local torso = p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("UpperTorso")
        if torso then
            saveOriginal(p, torso)
            local base = hitboxSaved[p][torso]
            local tMult = math.min(size * 0.7, 3)
            torso.Size = Vector3.new(base.X * tMult, base.Y * tMult, base.Z * tMult)
            torso.Transparency = 0.7
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

    -- ============================================================
    -- WEAPON HACKS
    -- ============================================================
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
                            for _, name in ipairs({"FireRate", "BFireRate", "RateOfFire", "ShootCooldown", "FireDelay"}) do
                                local f = tool:FindFirstChild(name)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then
                                    f.Value = 0.01
                                elseif typeof(tool[name]) == "number" then
                                    tool[name] = 0.01
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
                                    if n:find("recoil") or n:find("kick") or n:find("spread") or n:find("camera") then
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
                                    local n = d.Name:lower()
                                    if n:find("reload") and not n:find("reloading") then
                                        if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                        d.Value = reloadOriginals[d] * 0.15
                                    end
                                end
                            end
                        end)
                    end
                    if State.instaReload then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("reload") and not n:find("reloading") then
                                        if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
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

    -- Loop em ReplicatedStorage.Weapons + Modules.Constants
    coroutine.wrap(function()
        while true do
            if UNLOADED then return end
            if State.rapidFire or State.noRecoil or State.fastReload or State.instaReload then
                pcall(function()
                    if ReplicatedStorage:FindFirstChild("Weapons") then
                        for _, d in ipairs(ReplicatedStorage.Weapons:GetDescendants()) do
                            if d:IsA("NumberValue") or d:IsA("IntValue") then
                                local n = d.Name:lower()
                                if State.rapidFire and (n == "firerate" or n == "bfirerate" or n == "rateoffire" or n == "firedelay") then
                                    d.Value = 0.01
                                elseif State.rapidFire and (n:find("cooldown") or n:find("equip") or n:find("swap")) then
                                    d.Value = 0
                                elseif State.noRecoil and (n == "recoilcontrol" or n:find("recoil")) then
                                    d.Value = 0
                                elseif State.fastReload and not State.instaReload and n:find("reload") and not n:find("reloading") then
                                    if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                    d.Value = reloadOriginals[d] * 0.15
                                elseif State.instaReload and n:find("reload") and not n:find("reloading") then
                                    if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                    d.Value = 0
                                end
                            end
                        end
                    end
                    if ReplicatedStorage:FindFirstChild("Modules") then
                        local constants = ReplicatedStorage.Modules:FindFirstChild("Constants")
                        if constants and constants:IsA("ModuleScript") then
                            -- Não consegue editar ModuleScript direto, mas tenta via require
                            local ok, mod = pcall(require, constants)
                            if ok and type(mod) == "table" then
                                if State.noRecoil then
                                    for k, v in pairs(mod) do
                                        if type(k) == "string" and (k:lower():find("recoil") or k:lower():find("spread")) then
                                            pcall(function() mod[k] = 0 end)
                                        end
                                    end
                                end
                                if State.rapidFire then
                                    for k, v in pairs(mod) do
                                        if type(k) == "string" and (k:lower():find("firerate") or k:lower():find("firedelay")) then
                                            pcall(function() mod[k] = 0.01 end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            task.wait(1)
        end
    end)()

    -- ============================================================
    -- ESP
    -- ============================================================
    local ESP = {data = {}}

    local function createESP(p)
        if ESP.data[p] then return end
        if not p.Character then return end
        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Theme.Primary
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
        data.box = newDrawing("Square", {Thickness = 1.5, Color = Theme.Primary, Filled = false, Transparency = 1})
        data.name = newDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        data.distance = newDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Theme.TitleRed})
        data.health = newDrawing("Line", {Thickness = 3, Color = Color3.fromRGB(0, 255, 0)})
        data.tracer = newDrawing("Line", {Thickness = 1.2, Color = Theme.Primary})
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
        for p, _ in pairs(ESP.data) do removeESP(p) end
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
            d.box.Visible = true
        else d.box.Visible = false end

        if headOn then
            d.name.Position = Vector2.new(headSp.X, headSp.Y - 20)
            d.name.Text = p.Name
            d.name.Visible = true
            d.distance.Position = Vector2.new(headSp.X, headSp.Y - 6)
            d.distance.Text = dist .. "m"
            d.distance.Visible = true
            d.headDot.Position = Vector2.new(headSp.X, headSp.Y)
            d.headDot.Visible = true
        else
            d.name.Visible = false
            d.distance.Visible = false
            d.headDot.Visible = false
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
        else d.health.Visible = false end

        if hrpOn then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To = Vector2.new(hrpSp.X, hrpSp.Y)
            d.tracer.Visible = true
        else d.tracer.Visible = false end
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
    Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

    -- ============================================================
    -- SPEED
    -- ============================================================
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.speed then return end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= State.speedValue then
                hum.WalkSpeed = State.speedValue
            end
        end
    end)

    -- ============================================================
    -- AIR JUMP (FIX: velocity direto no HRP)
    -- ============================================================
    local airJumpConn = nil
    local AIR_JUMP_POWER = 55

    local function startAirJump()
        if airJumpConn then airJumpConn:Disconnect() end
        airJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end
            if hum:GetState() == Enum.HumanoidStateType.Dead then return end
            -- Aplica velocity vertical direto (funciona no ar)
            hrp.Velocity = Vector3.new(hrp.Velocity.X, AIR_JUMP_POWER, hrp.Velocity.Z)
        end)
    end
    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    -- ============================================================
    -- FULLBRIGHT
    -- ============================================================
    local origBrightness = Lighting.Brightness
    local origAmbient = Lighting.Ambient
    local origOutdoorAmbient = Lighting.OutdoorAmbient
    local origClockTime = Lighting.ClockTime
    local origGlobalShadows = Lighting.GlobalShadows
    local origAtmosphere = {}
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then
            table.insert(origAtmosphere, {obj = c, D = c.Density, H = c.Haze, G = c.Glare})
        end
    end

    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if State.fullbright then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Atmosphere") then
                    c.Density = 0; c.Haze = 0; c.Glare = 0
                end
            end
        end
    end)

    local function disableFullbright()
        Lighting.Brightness = origBrightness
        Lighting.Ambient = origAmbient
        Lighting.OutdoorAmbient = origOutdoorAmbient
        Lighting.ClockTime = origClockTime
        Lighting.GlobalShadows = origGlobalShadows
        for _, data in ipairs(origAtmosphere) do
            if data.obj and data.obj.Parent then
                pcall(function()
                    data.obj.Density = data.D; data.obj.Haze = data.H; data.obj.Glare = data.G
                end)
            end
        end
    end

    -- ============================================================
    -- CONFIG SYSTEM
    -- ============================================================
    local function ensureFolder()
        if makefolder and not isfolder(CONFIG_FOLDER) then
            pcall(function() makefolder(CONFIG_FOLDER) end)
        end
    end
    local function getConfigPath(name) return CONFIG_FOLDER .. "/" .. name .. ".json" end
    local function getAutoloadPath() return AUTOLOAD_FILE end

    local function saveConfig(name)
        ensureFolder()
        local data = {version = "1.3", language = Language.getCurrent(), state = {}, keybinds = State.keybinds}
        for k, v in pairs(State) do
            if k ~= "keybinds" then data.state[k] = v end
        end
        local json = HttpService:JSONEncode(data)
        local ok, err = pcall(function() writefile(getConfigPath(name), json) end)
        if ok then Notify("💾 Config", "Saved: " .. name, 3); return true
        else Notify("⚠️ Error", "Failed: " .. tostring(err), 4, true); return false end
    end

    local function loadConfig(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then
            Notify("⚠️ Error", "Config not found: " .. name, 4, true); return false
        end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data then
            Notify("⚠️ Error", "Corrupted: " .. name, 4, true); return false
        end
        if data.language then Language.setLanguage(data.language) end
        if data.state then
            for k, v in pairs(data.state) do State[k] = v end
        end
        if data.keybinds then
            for k, v in pairs(data.keybinds) do State.keybinds[k] = v end
        end
        for featId, handle in pairs(toggleHandles) do
            if State[featId] ~= nil then handle.SetState(State[featId], true) end
            handle.SetKeybind(State.keybinds[featId])
        end
        for featId, handle in pairs(sliderHandles) do
            if State[featId] ~= nil then handle.SetValue(State[featId]) end
        end
        if State.airJump then startAirJump() else stopAirJump() end
        if not State.fullbright then disableFullbright() end
        if not State.headExpander then restoreAllHitboxes() end
        Notify("📂 Load", "Loaded: " .. name, 3)
        return true
    end

    local function deleteConfig(name)
        local path = getConfigPath(name)
        if isfile and isfile(path) then
            pcall(function() delfile(path) end)
            Notify("🗑️ Delete", "Deleted: " .. name, 3)
            return true
        end
        return false
    end

    local function listConfigs()
        local list = {}
        if listfiles and isfolder and isfolder(CONFIG_FOLDER) then
            for _, file in ipairs(listfiles(CONFIG_FOLDER)) do
                if file:sub(-5) == ".json" then
                    local name = file:match("([^/\\]+)%.json$")
                    if name then table.insert(list, name) end
                end
            end
        end
        return list
    end

    local function setAutoload(name)
        ensureFolder()
        local ok = pcall(function() writefile(getAutoloadPath(), name) end)
        if ok then Notify("⚡ Autoload", "Set: " .. name, 3)
        else Notify("⚠️ Error", "Failed autoload", 4, true) end
    end

    local function clearAutoload()
        local ok = pcall(function()
            if isfile(getAutoloadPath()) then delfile(getAutoloadPath()) end
        end)
        if ok then Notify("🚫 Autoload", "Disabled", 3) end
    end

    local function getAutoload()
        local ok, content = pcall(function() return readfile(getAutoloadPath()) end)
        if ok and content and content ~= "" then return content end
        return nil
    end

    -- ============================================================
    -- ABAS
    -- ============================================================
    local CombatTab = CreateTab("COMBAT", "⚔️")
    CombatTab.CreateToggle("Silent Headshot", "silentHeadshot")
    CombatTab.CreateSlider("Silent FOV", 30, 300, 120, "silentFov")
    CombatTab.CreateToggle("Aimbot (Legit)", "aimbot")
    CombatTab.CreateSlider("Aimbot FOV", 30, 300, 100, "aimbotFov")
    CombatTab.CreateSlider("Aimbot Smoothness", 5, 100, 30, "aimbotSmoothness", function(v)
        State.aimbotSmoothness = v / 100
    end)
    CombatTab.CreateSlider("Aimbot Max Dist", 100, 2000, 500, "aimbotMaxDist")
    CombatTab.CreateToggle("Head Expander", "headExpander", function(v)
        if not v then restoreAllHitboxes() end
    end)
    CombatTab.CreateSlider("Head Size", 1, 8, 3, "headExpanderSize")
    CombatTab.CreateToggle("Backstab", "backstab")

    local WeaponTab = CreateTab("WEAPON", "🔫")
    WeaponTab.CreateToggle("No-Recoil", "noRecoil")
    WeaponTab.CreateToggle("Rapid Fire", "rapidFire")
    WeaponTab.CreateToggle("Fast Reload", "fastReload", function(v)
        if not v then
            for value, original in pairs(reloadOriginals) do
                pcall(function() value.Value = original end)
            end
            reloadOriginals = {}
        end
    end)
    WeaponTab.CreateToggle("Insta-Reload", "instaReload")
    WeaponTab.CreateToggle("Auto Shoot", "autoShoot")
    WeaponTab.CreateSlider("Auto Shoot FOV", 30, 300, 100, "autoShootFov")
    WeaponTab.CreateSlider("Auto Shoot Delay (ms)", 10, 500, 50, "autoShootDelay", function(v)
        State.autoShootDelay = v / 1000
    end)

    local MovementTab = CreateTab("MOVEMENT", "🏃")
    MovementTab.CreateToggle("Speedhack", "speed")
    MovementTab.CreateSlider("Speed Value", 12, 300, 50, "speedValue")
    MovementTab.CreateToggle("Air Jump", "airJump", function(v)
        if v then startAirJump() else stopAirJump() end
    end)
    MovementTab.CreateToggle("Fullbright", "fullbright", function(v)
        if not v then disableFullbright() end
    end)

    local VisualsTab = CreateTab("VISUALS", "👁️")
    VisualsTab.CreateToggle("ESP", "esp", function(v)
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then createESP(p) end
            end
        else clearAllESP() end
    end)
    VisualsTab.CreateSlider("ESP Max Dist", 100, 5000, 500, "espMaxDistance")

    local SettingsTab = CreateTab("SETTINGS", "⚙️")
    SettingsTab.CreateLabel("── Save Config ──", Theme.Text)
    SettingsTab.CreateLabel("Type name and press Enter", Theme.TextDim)
    SettingsTab.CreateTextBox("Config name...", function(name) saveConfig(name) end)
    SettingsTab.CreateLabel("── Configs ──", Theme.Text)
    SettingsTab.CreateLabel("Load • ⚡ Autoload • × Delete", Theme.TextDim)

    local configListFrame = Instance.new("Frame", SettingsTab.container)
    configListFrame.Size = UDim2.new(1, -10, 0, 140)
    configListFrame.BackgroundColor3 = Theme.Surface
    configListFrame.BorderSizePixel = 0
    Instance.new("UICorner", configListFrame).CornerRadius = UDim.new(0, 6)
    local cfs = Instance.new("UIStroke", configListFrame)
    cfs.Color = Theme.Border; cfs.Thickness = 1; cfs.Transparency = 0.7

    local configScroll = Instance.new("ScrollingFrame", configListFrame)
    configScroll.Size = UDim2.new(1, -10, 1, -10)
    configScroll.Position = UDim2.new(0, 5, 0, 5)
    configScroll.BackgroundTransparency = 1
    configScroll.BorderSizePixel = 0
    configScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    configScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    configScroll.ScrollBarThickness = 4
    configScroll.ScrollBarImageColor3 = Theme.Primary
    local cl = Instance.new("UIListLayout", configScroll)
    cl.Padding = UDim.new(0, 4)

    local function refreshConfigList()
        for _, child in ipairs(configScroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
        end
        local configs = listConfigs()
        local currentAutoload = getAutoload()
        if #configs == 0 then
            local emptyLbl = Instance.new("TextLabel", configScroll)
            emptyLbl.Size = UDim2.new(1, 0, 0, 30)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Font = Theme.Font
            emptyLbl.TextSize = 11
            emptyLbl.TextColor3 = Theme.TextDim
            emptyLbl.Text = "No configs saved yet."
            return
        end
        for _, configName in ipairs(configs) do
            local entry = Instance.new("Frame", configScroll)
            entry.Size = UDim2.new(1, -4, 0, 30)
            entry.BackgroundColor3 = Theme.Surface2
            entry.BorderSizePixel = 0
            Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 4)

            local nameLbl = Instance.new("TextLabel", entry)
            nameLbl.Size = UDim2.new(0.5, 0, 1, 0)
            nameLbl.Position = UDim2.new(0, 8, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Theme.Font
            nameLbl.TextSize = 11
            nameLbl.TextColor3 = Theme.Text
            nameLbl.Text = configName
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            if currentAutoload == configName then
                nameLbl.Text = "⚡ " .. configName
                nameLbl.TextColor3 = Theme.Warning
            end

            local loadBtn = Instance.new("TextButton", entry)
            loadBtn.Size = UDim2.new(0, 50, 0, 22)
            loadBtn.Position = UDim2.new(1, -110, 0.5, -11)
            loadBtn.BackgroundColor3 = Theme.Primary
            loadBtn.Text = "Load"
            loadBtn.Font = Theme.FontBold
            loadBtn.TextSize = 10
            loadBtn.TextColor3 = Theme.Text
            loadBtn.AutoButtonColor = false
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
            loadBtn.MouseButton1Click:Connect(function()
                loadConfig(configName); refreshConfigList()
            end)

            local autoBtn = Instance.new("TextButton", entry)
            autoBtn.Size = UDim2.new(0, 22, 0, 22)
            autoBtn.Position = UDim2.new(1, -55, 0.5, -11)
            autoBtn.BackgroundColor3 = currentAutoload == configName and Theme.Warning or Theme.Surface
            autoBtn.Text = "⚡"
            autoBtn.Font = Theme.FontBold
            autoBtn.TextSize = 12
            autoBtn.TextColor3 = Theme.Text
            autoBtn.AutoButtonColor = false
            Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 4)
            autoBtn.MouseButton1Click:Connect(function()
                if currentAutoload == configName then clearAutoload()
                else setAutoload(configName) end
                refreshConfigList()
            end)

            local delBtn = Instance.new("TextButton", entry)
            delBtn.Size = UDim2.new(0, 22, 0, 22)
            delBtn.Position = UDim2.new(1, -28, 0.5, -11)
            delBtn.BackgroundColor3 = Color3.fromRGB(60, 15, 20)
            delBtn.Text = "×"
            delBtn.Font = Theme.FontBold
            delBtn.TextSize = 14
            delBtn.TextColor3 = Theme.Danger
            delBtn.AutoButtonColor = false
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
            delBtn.MouseButton1Click:Connect(function()
                deleteConfig(configName); refreshConfigList()
            end)
        end
    end
    refreshConfigList()

    SettingsTab.CreateButton("🔄 Refresh List", function()
        refreshConfigList()
        Notify("🔄 Refresh", "Config list updated", 2)
    end)

    SettingsTab.CreateLabel(" ")
    local autoloadLabel = SettingsTab.CreateLabel("", Theme.Text)
    registerRefresh(function()
        local ca = getAutoload()
        if ca then
            autoloadLabel.Text = "⚡ Autoload: " .. ca
            autoloadLabel.TextColor3 = Theme.Warning
        else
            autoloadLabel.Text = "🚫 Autoload: disabled"
            autoloadLabel.TextColor3 = Theme.TextDim
        end
    end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateButton("🚫 Disable Autoload", function()
        clearAutoload(); refreshConfigList()
    end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateButton("🗑️ Unload Script", function()
        UNLOADED = true
        _G.IZ_RefreshLanguage = nil
        clearAllESP()
        stopAirJump()
        restoreAllHitboxes()
        disableFullbright()
        if fovCircle then fovCircle:Remove() end
        GUI:Destroy()
        print("[Infinite Zen] Jailbird v1.3 unloaded")
    end, "danger")

    local CreditsTab = CreateTab("CREDITS", "➕")
    CreditsTab.CreateCredit("FOUNDER", "Sr Red", Theme.TitleRed)
    CreditsTab.CreateCredit("DEVELOPER", "Eclipse Dev", Theme.Primary)
    CreditsTab.CreateLabel(" ")
    CreditsTab.CreateLabel("── Discord ──", Theme.Text)
    CreditsTab.CreateLabel("https://discord.gg/ScZfU2mAGm", Theme.TextDim)
    local discordBtn = CreditsTab.CreateButton("💬 Join Discord", function()
        if setclipboard then
            setclipboard("https://discord.gg/ScZfU2mAGm")
            Notify("📋 Copied", "Discord link copied!", 3)
        else Notify("ℹ️ Discord", "discord.gg/ScZfU2mAGm", 5) end
    end)
    discordBtn.BackgroundColor3 = Theme.Discord
    CreditsTab.CreateLabel(" ")
    CreditsTab.CreateLabel("Infinite Zen v1.3", Theme.TextDim)
    CreditsTab.CreateLabel("Jailbird FIXED", Theme.Warning)
    CreditsTab.CreateLabel("© 2026 Eclipse Dev", Theme.TextDim)

    -- ============================================================
    -- KEYBIND SYSTEM
    -- ============================================================
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
                Notify("🚫 Blocked", "K reserved for Minimize", 4, true)
                recordingKeyFor = nil
                local handle = toggleHandles[featId]
                if handle then handle.SetKeybind(State.keybinds[featId]) end
                return
            end
            local conflictFeat = findFeatureWithKeybind(newKey)
            if conflictFeat and conflictFeat ~= featId then
                Notify("🚫 In Use", newKey .. " used by: " .. (FeatureLabels[conflictFeat] or conflictFeat), 4, true)
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

    task.defer(function()
        local autoloadName = getAutoload()
        if autoloadName then
            task.wait(1)
            loadConfig(autoloadName)
        end
    end)

    task.wait(0.5)
    if IS_JAILBIRD then
        Notify("🎯 Jailbird v1.3", "FIXED Edition carregado!", 5)
    end

    print("[Infinite Zen] ✅ Jailbird v1.3 FIXED carregado!")
    print("[Infinite Zen] Fixes: Aimbot mousemoverel | Air Jump velocity | Auto Shoot tool:Activate | Silent Headshot remote")
end

return Jailbird