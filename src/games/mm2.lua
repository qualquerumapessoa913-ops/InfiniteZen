-- ============================================================
-- INFINITE ZEN - MÓDULO MM2 v1.0 (ROLE-BASED)
-- Murder Mystery 2 (PlaceId 142823291)
-- ============================================================

local MM2 = {}

function MM2.Init(ctx)
    local Language = ctx.Language
    local gameName = ctx.gameName

    local GAME_VERSION = "1.0"
    local FULL_VERSION = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("[Infinite Zen] Inicializando " .. FULL_VERSION .. "...")

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInput = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local SoundService = game:GetService("SoundService")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    local UNLOADED = false
    local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local MOBILE_SCALE = 0.72

    local langRefresh = {}
    local function registerRefresh(fn)
        table.insert(langRefresh, fn)
        pcall(fn)
    end
    _G.IZ_RefreshLanguage = function()
        for _, fn in ipairs(langRefresh) do pcall(fn) end
    end

    local function getLabel(labelKey)
        local t = Language.get(labelKey)
        if t and t ~= labelKey then return t end
        local formatted = labelKey:gsub("_", " ")
        formatted = formatted:gsub("(%a)([%w']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
        return formatted
    end

    -- REMOTES
    local GE = ReplicatedStorage:FindFirstChild("GameEvents")
    local Remotes = {
        ChangeTarget = GE and GE:FindFirstChild("ChangeTarget"),
        KillEvent = GE and GE:FindFirstChild("KillEvent"),
        Hit = GE and GE:FindFirstChild("Hit"),
        Damage = GE and GE:FindFirstChild("Damage"),
        GunBeam = ReplicatedStorage:FindFirstChild("WeaponEvents") and ReplicatedStorage.WeaponEvents:FindFirstChild("GunBeam"),
    }
    print("[Infinite Zen] MM2 Remotes carregados")

    -- ROLE DETECTION
    local myRole = "Innocent"
    local roleCache = {}

    local function getPlayerRole(player)
        if not player or not player.Character then return "Unknown" end
        local char = player.Character
        local backpack = player:FindFirstChild("Backpack")
        local function checkContainer(container)
            if not container then return nil end
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local n = tool.Name:lower()
                    if n == "knife" or n:find("knife") then return "Murderer"
                    elseif n == "gun" or n:find("gun") then return "Sheriff" end
                end
            end
            return nil
        end
        local r = checkContainer(char)
        if r then return r end
        r = checkContainer(backpack)
        if r then return r end
        return "Innocent"
    end

    task.spawn(function()
        while not UNLOADED do
            myRole = getPlayerRole(LocalPlayer)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then roleCache[p] = getPlayerRole(p) end
            end
            task.wait(0.5)
        end
    end)

    local function isAlive(player)
        if not player or not player.Character then return false end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end

    local function isEnemy(player)
        if player == LocalPlayer then return false end
        if not isAlive(player) then return false end
        return true
    end

    -- STATE
    local State = {
        sheriffSilentAim = false, sheriffSilentFov = 100,
        sheriffTriggerbot = false, sheriffTriggerbotDelay = 5,
        sheriffAutoShoot = false, sheriffAutoShootFov = 100,
        sheriffAimbot = false, sheriffAimbotSmooth = 0.3,
        sheriffWallCheck = true,
        murdererSilentAim = false, murdererSilentFov = 100,
        killAura = false, killAuraRange = 30, killAuraDelay = 50,
        autoBackstab = false,
        esp = false, espMaxDistance = 2000,
        showMurderer = true, showSheriff = true, showInnocent = true,
        showWeaponESP = true, showDistanceESP = true, showTracerESP = false,
        murdererAlert = false, murdererAlertRange = 40,
        gunLocator = false, autoCoin = false,
        autoCoinSpeed = 45,          -- studs/segundo (fly suave anti-detecção)
        autoGrabGun = false,         -- NOVO
        autoGrabGunRange = 300,      -- NOVO
        speed = false, speedValue = 30,
        airJump = false, autoBhop = false, fullbright = false,
        lowGraphics = false, noShadows = false, noFog = false, noParticles = false,
        keybinds = {
            sheriffSilentAim = "X", sheriffTriggerbot = nil, sheriffAutoShoot = nil,
            murdererSilentAim = nil, killAura = "G", autoBackstab = nil,
            esp = "F", autoCoin = nil, autoGrabGun = nil, speed = nil, airJump = nil,
        }
    }

    local recordingKeyFor = nil

    local Theme = {
        Bg = Color3.fromRGB(8, 4, 6), Surface = Color3.fromRGB(18, 8, 12),
        Surface2 = Color3.fromRGB(35, 12, 18), Border = Color3.fromRGB(80, 15, 20),
        SidebarColor = Color3.fromRGB(15, 6, 10), ContentColor = Color3.fromRGB(25, 10, 15),
        Primary = Color3.fromRGB(255, 30, 40), TitleRed = Color3.fromRGB(255, 50, 50),
        Success = Color3.fromRGB(0, 220, 130), Danger = Color3.fromRGB(255, 40, 40),
        Warning = Color3.fromRGB(255, 150, 50), Text = Color3.fromRGB(255, 245, 245),
        TextDim = Color3.fromRGB(160, 120, 130), Discord = Color3.fromRGB(88, 101, 242),
        MurdererColor = Color3.fromRGB(255, 40, 40),
        SheriffColor = Color3.fromRGB(80, 150, 255),
        InnocentColor = Color3.fromRGB(0, 220, 130),
        Font = Enum.Font.GothamMedium, FontBold = Enum.Font.GothamBlack,
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
        titleL.Size = UDim2.new(1, -20, 0, 22); titleL.Position = UDim2.new(0, 12, 0, 8)
        titleL.BackgroundTransparency = 1; titleL.Font = Theme.FontBold; titleL.TextSize = 12
        titleL.TextColor3 = strokeColor; titleL.TextXAlignment = Enum.TextXAlignment.Left
        titleL.Text = title; titleL.ZIndex = 1000
        local contentL = Instance.new("TextLabel", notif)
        contentL.Size = UDim2.new(1, -20, 0, 30); contentL.Position = UDim2.new(0, 12, 0, 28)
        contentL.BackgroundTransparency = 1; contentL.Font = Theme.Font; contentL.TextSize = 11
        contentL.TextColor3 = Theme.Text; contentL.TextXAlignment = Enum.TextXAlignment.Left
        contentL.TextWrapped = true; contentL.Text = content; contentL.ZIndex = 1000
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

    -- FORWARD DECLARE
    local minimized = false
    local setMinimized

    -- MAIN WINDOW
    local MainFrame = Instance.new("Frame", GUI)
    MainFrame.Size = UDim2.new(0, 620, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -310, 0.5, -240)
    MainFrame.BackgroundColor3 = Theme.Bg
    MainFrame.BorderSizePixel = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local guiScale = Instance.new("UIScale")
    guiScale.Scale = IS_MOBILE and MOBILE_SCALE or 1
    guiScale.Parent = MainFrame
    if IS_MOBILE then
        local vp = Camera.ViewportSize
        MainFrame.Position = UDim2.new(0, (vp.X - 620 * MOBILE_SCALE) / 2, 0, (vp.Y - 480 * MOBILE_SCALE) / 2)
    end

    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Color = Theme.Primary; mainStroke.Thickness = 1.5; mainStroke.Transparency = 0.3

    -- HEADER
    local Header = Instance.new("Frame", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 48)
    Header.BackgroundColor3 = Theme.Surface
    Header.BorderSizePixel = 0
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

    local hg = Instance.new("UIGradient")
    hg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 10, 20)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 30, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 5, 15))
    })
    hg.Rotation = 15
    hg.Parent = Header

    local headerBar = Instance.new("Frame", Header)
    headerBar.Size = UDim2.new(1, 0, 0, 2)
    headerBar.BackgroundColor3 = Theme.Primary
    headerBar.BorderSizePixel = 0; headerBar.ZIndex = 2

    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(0, 250, 0, 22); Title.Position = UDim2.new(0, 20, 0, 6)
    Title.BackgroundTransparency = 1; Title.Font = Theme.FontBold
    Title.Text = "∞ INFINITE ZEN"; Title.TextColor3 = Theme.TitleRed; Title.TextSize = 17
    Title.TextXAlignment = Enum.TextXAlignment.Left; Title.ZIndex = 3

    local Subtitle = Instance.new("TextLabel", Header)
    Subtitle.Size = UDim2.new(0, 300, 0, 18); Subtitle.Position = UDim2.new(0, 20, 0, 25)
    Subtitle.BackgroundTransparency = 1; Subtitle.Font = Theme.Font
    Subtitle.Text = SHORT_VERSION; Subtitle.TextColor3 = Color3.fromRGB(220, 180, 185)
    Subtitle.TextSize = 11; Subtitle.TextXAlignment = Enum.TextXAlignment.Left; Subtitle.ZIndex = 3

    local RoleBadge = Instance.new("TextLabel", Header)
    RoleBadge.Size = UDim2.new(0, 100, 0, 22); RoleBadge.Position = UDim2.new(1, -220, 0.5, -11)
    RoleBadge.BackgroundColor3 = Theme.Surface2
    RoleBadge.Font = Theme.FontBold; RoleBadge.TextSize = 11
    RoleBadge.TextColor3 = Theme.InnocentColor
    RoleBadge.Text = "❓ Innocent"
    RoleBadge.ZIndex = 3
    Instance.new("UICorner", RoleBadge).CornerRadius = UDim.new(0, 6)

    task.spawn(function()
        while not UNLOADED do
            local role = myRole
            if role == "Murderer" then
                RoleBadge.Text = "🔪 Murderer"
                RoleBadge.TextColor3 = Theme.MurdererColor
            elseif role == "Sheriff" then
                RoleBadge.Text = "🔫 Sheriff"
                RoleBadge.TextColor3 = Theme.SheriffColor
            else
                RoleBadge.Text = "❓ Innocent"
                RoleBadge.TextColor3 = Theme.InnocentColor
            end
            task.wait(0.5)
        end
    end)

    -- LANG BUTTON
    local LangBtn = Instance.new("TextButton", Header)
    LangBtn.Size = UDim2.new(0, 60, 0, 26); LangBtn.Position = UDim2.new(1, -110, 0.5, -13)
    LangBtn.BackgroundColor3 = Theme.Surface2; LangBtn.Text = "US"
    LangBtn.Font = Theme.FontBold; LangBtn.TextSize = 12; LangBtn.TextColor3 = Theme.Text
    LangBtn.AutoButtonColor = false; LangBtn.ZIndex = 3
    Instance.new("UICorner", LangBtn).CornerRadius = UDim.new(0, 6)

    local LangDropdown = Instance.new("Frame", Header)
    LangDropdown.Size = UDim2.new(0, 140, 0, 0)
    LangDropdown.Position = UDim2.new(1, -110, 1, 4)
    LangDropdown.BackgroundColor3 = Theme.Surface2; LangDropdown.BorderSizePixel = 0
    LangDropdown.Visible = false; LangDropdown.ZIndex = 10; LangDropdown.ClipsDescendants = true
    Instance.new("UICorner", LangDropdown).CornerRadius = UDim.new(0, 8)
    local dStroke = Instance.new("UIStroke", LangDropdown)
    dStroke.Color = Theme.Primary; dStroke.Thickness = 1; dStroke.Transparency = 0.3
    local dLayout = Instance.new("UIListLayout", LangDropdown)
    dLayout.Padding = UDim.new(0, 2)
    for _, langData in ipairs(Language.getAvailable()) do
        local optBtn = Instance.new("TextButton", LangDropdown)
        optBtn.Size = UDim2.new(1, -8, 0, 30); optBtn.BackgroundColor3 = Theme.Surface
        optBtn.Text = "  [" .. langData.shortCode .. "]  " .. langData.displayName
        optBtn.Font = Theme.Font; optBtn.TextSize = 12; optBtn.TextColor3 = Theme.Text
        optBtn.TextXAlignment = Enum.TextXAlignment.Left; optBtn.AutoButtonColor = false; optBtn.ZIndex = 11
        Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 6)
        optBtn.MouseButton1Click:Connect(function()
            Language.setLanguage(langData.code)
            LangDropdown.Visible = false
        end)
    end
    LangDropdown.Size = UDim2.new(0, 140, 0, #Language.getAvailable() * 32 + 8)
    local ddOpen = false
    LangBtn.MouseButton1Click:Connect(function()
        ddOpen = not ddOpen
        LangDropdown.Visible = ddOpen
    end)
    registerRefresh(function()
        LangBtn.Text = "[" .. Language.getCurrentData().shortCode .. "]"
    end)

    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -40, 0.5, -15)
    MinBtn.BackgroundColor3 = Theme.Surface2; MinBtn.Text = "−"
    MinBtn.Font = Theme.FontBold; MinBtn.TextSize = 18; MinBtn.TextColor3 = Theme.Text; MinBtn.ZIndex = 3
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    -- SIDEBAR + CONTENT
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size = UDim2.new(0, 140, 1, -65); Sidebar.Position = UDim2.new(0, 10, 0, 58)
    Sidebar.BackgroundColor3 = Theme.SidebarColor; Sidebar.BorderSizePixel = 0
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

    local Content = Instance.new("Frame", MainFrame)
    Content.Size = UDim2.new(1, -170, 1, -70); Content.Position = UDim2.new(0, 160, 0, 58)
    Content.BackgroundColor3 = Theme.ContentColor; Content.BackgroundTransparency = 0.3
    Content.BorderSizePixel = 0
    Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 8)

    -- FLOATING REOPEN (MOBILE)
    local reopenBtn = nil
    if IS_MOBILE then
        reopenBtn = Instance.new("TextButton", GUI)
        reopenBtn.Size = UDim2.new(0, 55, 0, 55); reopenBtn.Position = UDim2.new(0, 20, 0, 100)
        reopenBtn.BackgroundColor3 = Theme.Primary; reopenBtn.Text = "∞"
        reopenBtn.Font = Theme.FontBold; reopenBtn.TextSize = 26; reopenBtn.TextColor3 = Theme.Text
        reopenBtn.AutoButtonColor = false; reopenBtn.Visible = false; reopenBtn.ZIndex = 500
        Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(1, 0)
        local rStroke = Instance.new("UIStroke", reopenBtn)
        rStroke.Color = Theme.TitleRed; rStroke.Thickness = 2; rStroke.Transparency = 0.3
        local rDragging, rDragStart, rStartPos, rMoved = false, nil, nil, false
        reopenBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                rDragging = true; rMoved = false
                rDragStart = input.Position; rStartPos = reopenBtn.Position
            end
        end)
        reopenBtn.InputChanged:Connect(function(input)
            if not rDragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - rDragStart
                if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then rMoved = true end
                reopenBtn.Position = UDim2.new(
                    rStartPos.X.Scale, rStartPos.X.Offset + delta.X,
                    rStartPos.Y.Scale, rStartPos.Y.Offset + delta.Y
                )
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if rDragging then rDragging = false; task.wait(0.1); rMoved = false end
            end
        end)
        reopenBtn.MouseButton1Click:Connect(function()
            if rMoved then return end
            if setMinimized then setMinimized(false) end
        end)
    end

    setMinimized = function(v)
        minimized = v
        Sidebar.Visible = not v
        Content.Visible = not v
        MainFrame.Size = v and UDim2.new(0, 620, 0, 48) or UDim2.new(0, 620, 0, 480)
        if reopenBtn and IS_MOBILE then reopenBtn.Visible = v end
    end
    MinBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)

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
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        element.InputChanged:Connect(function(input)
            if UNLOADED then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
    end
    UserInputService.InputChanged:Connect(function(input)
        if UNLOADED then return end
        if input == dragInput and dragging then updateDrag(input) end
    end)
    makeDraggable(Header); makeDraggable(Title); makeDraggable(Subtitle)

    -- TABS BUILDER
    local tabs, toggleHandles, sliderHandles = {}, {}, {}

    local function CreateTab(customLabel, icon)
        local tab = {}
        local btn = Instance.new("TextButton", Sidebar)
        btn.Size = UDim2.new(1, -16, 0, 38); btn.Position = UDim2.new(0, 8, 0, 8 + #tabs * 44)
        btn.BackgroundColor3 = Theme.Surface; btn.BorderSizePixel = 0
        btn.Text = "  " .. icon .. "   " .. customLabel
        btn.Font = Theme.Font; btn.TextColor3 = Theme.TextDim; btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left; btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseEnter:Connect(function()
            if btn.BackgroundColor3 == Theme.Surface then btn.BackgroundColor3 = Theme.Surface2 end
        end)
        btn.MouseLeave:Connect(function()
            if btn.BackgroundColor3 == Theme.Surface2 then btn.BackgroundColor3 = Theme.Surface end
        end)

        local container = Instance.new("ScrollingFrame", Content)
        container.Size = UDim2.new(1, -10, 1, -10); container.Position = UDim2.new(0, 5, 0, 5)
        container.BackgroundTransparency = 1; container.BorderSizePixel = 0
        container.CanvasSize = UDim2.new(0, 0, 0, 0); container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        container.ScrollBarThickness = 4; container.ScrollBarImageColor3 = Theme.Primary
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

        tab.CreateToggle = function(labelKey, featureId, callback)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 36)
            holder.BackgroundColor3 = Theme.Surface; holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", holder)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7

            local lbl = Instance.new("TextLabel", holder)
            lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.BackgroundTransparency = 1; lbl.Font = Theme.Font; lbl.TextSize = 12
            lbl.TextColor3 = Theme.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = ""
            registerRefresh(function() lbl.Text = getLabel(labelKey) end)

            local keyBtn = Instance.new("TextButton", holder)
            keyBtn.Size = UDim2.new(0, 50, 0, 22); keyBtn.Position = UDim2.new(0.55, 0, 0.5, -11)
            keyBtn.BackgroundColor3 = State.keybinds[featureId] and Theme.Primary or Theme.Surface2
            keyBtn.Text = State.keybinds[featureId] or "KEY"
            keyBtn.Font = Theme.FontBold; keyBtn.TextSize = 11
            keyBtn.TextColor3 = State.keybinds[featureId] and Theme.Text or Theme.TextDim
            keyBtn.AutoButtonColor = false
            Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)

            local toggleBtn = Instance.new("TextButton", holder)
            toggleBtn.Size = UDim2.new(0, 50, 0, 22); toggleBtn.Position = UDim2.new(1, -58, 0.5, -11)
            toggleBtn.BackgroundColor3 = State[featureId] and Theme.Success or Theme.Surface2
            toggleBtn.Font = Theme.FontBold; toggleBtn.TextSize = 11; toggleBtn.TextColor3 = Theme.Text
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
                SetState = setState, Toggle = toggle,
                SetKeybind = function(key)
                    State.keybinds[featureId] = key
                    if key then
                        keyBtn.Text = key; keyBtn.BackgroundColor3 = Theme.Primary; keyBtn.TextColor3 = Theme.Text
                    else
                        keyBtn.Text = "KEY"; keyBtn.BackgroundColor3 = Theme.Surface2; keyBtn.TextColor3 = Theme.TextDim
                    end
                end,
                keyBtn = keyBtn,
            }
            toggleHandles[featureId] = handle
            return handle
        end

        tab.CreateSlider = function(labelKey, min, max, defaultValue, featureId, callback)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 44)
            holder.BackgroundColor3 = Theme.Surface; holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", holder)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7

            local lbl = Instance.new("TextLabel", holder)
            lbl.Size = UDim2.new(0.6, 0, 0, 18); lbl.Position = UDim2.new(0, 12, 0, 4)
            lbl.BackgroundTransparency = 1; lbl.Font = Theme.Font; lbl.TextSize = 11
            lbl.TextColor3 = Theme.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = ""
            registerRefresh(function() lbl.Text = getLabel(labelKey) end)

            local valLbl = Instance.new("TextLabel", holder)
            valLbl.Size = UDim2.new(0.35, 0, 0, 18); valLbl.Position = UDim2.new(0.6, 0, 0, 4)
            valLbl.BackgroundTransparency = 1; valLbl.Font = Theme.FontBold; valLbl.TextSize = 11
            valLbl.TextColor3 = Theme.Primary; valLbl.Text = tostring(defaultValue or min)
            valLbl.TextXAlignment = Enum.TextXAlignment.Right

            local barBg = Instance.new("Frame", holder)
            barBg.Size = UDim2.new(1, -24, 0, 5); barBg.Position = UDim2.new(0, 12, 0, 30)
            barBg.BackgroundColor3 = Theme.Surface2; barBg.BorderSizePixel = 0
            Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

            local cur = defaultValue or min
            local rel = (cur - min) / (max - min)
            local fill = Instance.new("Frame", barBg)
            fill.Size = UDim2.new(rel, 0, 1, 0); fill.BackgroundColor3 = Theme.Primary
            fill.BorderSizePixel = 0
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local click = Instance.new("TextButton", holder)
            click.Size = UDim2.new(1, -24, 0, 22); click.Position = UDim2.new(0, 12, 0, 22)
            click.BackgroundTransparency = 1; click.Text = ""; click.AutoButtonColor = false; click.ZIndex = 5

            local activeInput = nil
            local function update(posX)
                local p = barBg.AbsolutePosition
                local s = barBg.AbsoluteSize
                if s.X <= 0 then return end
                local rx = math.clamp((posX - p.X) / s.X, 0, 1)
                local v = math.floor(min + (max - min) * rx)
                cur = v
                fill.Size = UDim2.new(rx, 0, 1, 0)
                valLbl.Text = tostring(v)
                State[featureId] = v
                if callback then callback(v) end
            end
            click.InputBegan:Connect(function(input)
                if UNLOADED or activeInput then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    activeInput = input
                    update(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if UNLOADED or activeInput ~= input then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    update(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if UNLOADED then return end
                if input == activeInput then activeInput = nil end
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

        tab.CreateButton = function(labelKey, callback, style)
            local btn = Instance.new("TextButton", container)
            btn.Size = UDim2.new(1, -10, 0, 34)
            btn.BackgroundColor3 = style == "danger" and Color3.fromRGB(60, 15, 20) or Theme.Surface
            btn.BorderSizePixel = 0; btn.Text = ""
            btn.Font = Theme.Font; btn.TextColor3 = style == "danger" and Theme.Danger or Theme.Text
            btn.TextSize = 12; btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            local bs = Instance.new("UIStroke", btn)
            bs.Color = Theme.Border; bs.Thickness = 1; bs.Transparency = 0.7
            registerRefresh(function() btn.Text = getLabel(labelKey) end)
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = style == "danger" and Color3.fromRGB(80, 20, 25) or Theme.Primary
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = style == "danger" and Color3.fromRGB(60, 15, 20) or Theme.Surface
            end)
            btn.MouseButton1Click:Connect(function() if callback then callback() end end)
            return btn
        end

        tab.CreateLabel = function(textKey, color)
            local lbl = Instance.new("TextLabel", container)
            lbl.Size = UDim2.new(1, -10, 0, 18)
            lbl.BackgroundTransparency = 1; lbl.Font = Theme.Font; lbl.TextSize = 11
            lbl.TextColor3 = color or Theme.TextDim; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = ""
            registerRefresh(function() lbl.Text = getLabel(textKey) end)
            return lbl
        end

        tab.CreateTextBox = function(placeholder, callback)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 36)
            holder.BackgroundColor3 = Theme.Surface; holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", holder)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7
            local box = Instance.new("TextBox", holder)
            box.Size = UDim2.new(1, -20, 1, -10); box.Position = UDim2.new(0, 10, 0, 5)
            box.BackgroundTransparency = 1; box.Font = Theme.Font; box.TextSize = 12
            box.TextColor3 = Theme.Text; box.PlaceholderText = placeholder or "Type..."
            box.PlaceholderColor3 = Theme.TextDim; box.Text = ""
            box.ClearTextOnFocus = false; box.TextXAlignment = Enum.TextXAlignment.Left
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
            holder.BackgroundColor3 = Theme.Surface; holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", holder)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7
            local roleLbl = Instance.new("TextLabel", holder)
            roleLbl.Size = UDim2.new(1, -20, 0, 16); roleLbl.Position = UDim2.new(0, 12, 0, 6)
            roleLbl.BackgroundTransparency = 1; roleLbl.Font = Theme.Font; roleLbl.TextSize = 10
            roleLbl.TextColor3 = Theme.TextDim; roleLbl.Text = role
            roleLbl.TextXAlignment = Enum.TextXAlignment.Left
            local nameLbl = Instance.new("TextLabel", holder)
            nameLbl.Size = UDim2.new(1, -20, 0, 20); nameLbl.Position = UDim2.new(0, 12, 0, 22)
            nameLbl.BackgroundTransparency = 1; nameLbl.Font = Theme.FontBold; nameLbl.TextSize = 14
            nameLbl.TextColor3 = color or Theme.TitleRed; nameLbl.Text = name
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            return holder
        end

        return tab
    end

    -- HELPERS
    local function getBasePart(parent, ...)
        if not parent then return nil end
        for _, name in ipairs({...}) do
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == name and child:IsA("BasePart") then return child end
            end
        end
        return nil
    end

    local function hasLineOfSight(fromPos, targetPart)
        if not targetPart or not targetPart.Parent then return false end
        if not targetPart:IsA("BasePart") then return false end
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
        return workspace:Raycast(origin, unitDir * rayLength, params) == nil
    end

    local function getClosestEnemyInFov(fovRange, filterRole)
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, fovRange
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local ok = true
                if filterRole then
                    local r = roleCache[p] or getPlayerRole(p)
                    if r ~= filterRole then ok = false end
                end
                if ok then
                    local head = getBasePart(p.Character, "Head")
                    if head then
                        local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                        if onScreen and depth and depth > 0 then
                            local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                            if d and d < minDist then
                                if not State.sheriffWallCheck or hasLineOfSight(Camera.CFrame.Position, head) then
                                    minDist = d; closest = p
                                end
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    local function fireWeapon()
        local char = LocalPlayer.Character
        if not char then return false end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return false end
        if mouse1click then
            local ok = pcall(mouse1click)
            if ok then return true end
        end
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
        pcall(function() tool:Activate() end)
        return true
    end

    -- ESP
    local ESP = {data = {}}
    local function createESP(p)
        if ESP.data[p] or not p.Character then return end
        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Theme.Primary; chams.FillTransparency = 0.6
        chams.OutlineColor = Color3.fromRGB(255, 255, 255); chams.OutlineTransparency = 0.3
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
        data.role = newDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        data.distance = newDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Theme.TitleRed})
        data.weapon = newDrawing("Text", {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 200, 100)})
        data.tracer = newDrawing("Line", {Thickness = 1.2, Color = Theme.Primary})
        data.headDot = newDrawing("Circle", {Radius = 4, NumSides = 20, Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255)})
        ESP.data[p] = data
    end

    local function removeESP(p)
        local d = ESP.data[p]
        if not d then return end
        if d.chams then d.chams:Destroy() end
        for _, key in ipairs({"box", "name", "role", "distance", "weapon", "tracer", "headDot"}) do
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
            for _, key in ipairs({"box", "name", "role", "distance", "weapon", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            for _, key in ipairs({"box", "name", "role", "distance", "weapon", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end

        local role = roleCache[p] or "Innocent"
        if role == "Murderer" and not State.showMurderer then
            for _, key in ipairs({"box", "name", "role", "distance", "weapon", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        if role == "Sheriff" and not State.showSheriff then
            for _, key in ipairs({"box", "name", "role", "distance", "weapon", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        if role == "Innocent" and not State.showInnocent then
            for _, key in ipairs({"box", "name", "role", "distance", "weapon", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end

        local color = Theme.InnocentColor
        if role == "Murderer" then color = Theme.MurdererColor
        elseif role == "Sheriff" then color = Theme.SheriffColor end

        if d.chams then
            d.chams.Enabled = true
            d.chams.FillColor = color
            d.chams.OutlineColor = color
        end

        local head = getBasePart(char, "Head")
        local hrp = getBasePart(char, "HumanoidRootPart")
        if not head or not hrp then return end

        local headSp, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpSp, hrpOn = Camera:WorldToViewportPoint(hrp.Position)
        local footPos = hrp.Position - Vector3.new(0, 3, 0)
        local footSp, footOn = Camera:WorldToViewportPoint(footPos)

        local myHRP = getBasePart(LocalPlayer.Character, "HumanoidRootPart")
        if not myHRP then return end
        local dist = math.floor((head.Position - myHRP.Position).Magnitude)

        if dist > State.espMaxDistance then
            for _, key in ipairs({"box", "name", "role", "distance", "weapon", "tracer", "headDot"}) do
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
            d.box.Color = color
            d.box.Visible = true
        else d.box.Visible = false end

        if headOn then
            d.name.Position = Vector2.new(headSp.X, headSp.Y - 44)
            d.name.Text = p.Name
            d.name.Visible = true
            d.role.Position = Vector2.new(headSp.X, headSp.Y - 30)
            d.role.Text = "[" .. role .. "]"
            d.role.Color = color
            d.role.Visible = true
            if State.showDistanceESP then
                d.distance.Position = Vector2.new(headSp.X, headSp.Y - 16)
                d.distance.Text = dist .. "m"
                d.distance.Visible = true
            else d.distance.Visible = false end

            if State.showWeaponESP then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    d.weapon.Position = Vector2.new(headSp.X, headSp.Y - 58)
                    d.weapon.Text = "[" .. tool.Name .. "]"
                    d.weapon.Visible = true
                else d.weapon.Visible = false end
            else d.weapon.Visible = false end

            d.headDot.Position = Vector2.new(headSp.X, headSp.Y)
            d.headDot.Color = color
            d.headDot.Visible = true
        else
            d.name.Visible = false
            d.role.Visible = false
            d.distance.Visible = false
            d.weapon.Visible = false
            d.headDot.Visible = false
        end

        if State.showTracerESP and hrpOn then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To = Vector2.new(hrpSp.X, hrpSp.Y)
            d.tracer.Color = color
            d.tracer.Visible = true
        else d.tracer.Visible = false end
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.esp then return end
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    if not ESP.data[p] then createESP(p) end
                    updateESP(p, p.Character)
                end
            end
        end)
    end)
    Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

    -- ============================================================
    -- SHERIFF TAB
    -- ============================================================
    local SheriffTab = CreateTab("Sheriff", "🔫")

    local sheriffSilentTarget = nil
    local sheriffSilentHolding = false
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not sheriffSilentHolding then return end
        if not sheriffSilentTarget or not sheriffSilentTarget.Character then sheriffSilentHolding = false; return end
        local head = getBasePart(sheriffSilentTarget.Character, "Head")
        if not head then sheriffSilentHolding = false; return end
        local newCF = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
        Camera.CFrame = newCF
        if Remotes.ChangeTarget then pcall(function() Remotes.ChangeTarget:FireServer(newCF) end) end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.sheriffSilentAim then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local target = getClosestEnemyInFov(State.sheriffSilentFov, "Murderer")
        if target and target.Character then
            sheriffSilentTarget = target
            sheriffSilentHolding = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if sheriffSilentHolding then
            sheriffSilentHolding = false
            sheriffSilentTarget = nil
        end
    end)

    local sheriffTriggerLast = 0
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.sheriffTriggerbot then return end
        if tick() - sheriffTriggerLast < (State.sheriffTriggerbotDelay / 1000) then return end
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local role = roleCache[p]
                if role == "Murderer" then
                    local head = getBasePart(p.Character, "Head")
                    if head then
                        local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                        if onScreen and depth and depth > 0 then
                            local d = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
                            if d and d < 20 and hasLineOfSight(Camera.CFrame.Position, head) then
                                sheriffTriggerLast = tick()
                                pcall(function() mouse1click() end)
                                pcall(function()
                                    VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                    task.wait(0.005)
                                    VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                                end)
                                break
                            end
                        end
                    end
                end
            end
        end
    end)

    local sheriffAutoLast = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.sheriffAutoShoot then return end
        if tick() - sheriffAutoLast < 0.05 then return end
        local target = getClosestEnemyInFov(State.sheriffAutoShootFov, "Murderer")
        if target and target.Character then
            local head = getBasePart(target.Character, "Head")
            if head and hasLineOfSight(Camera.CFrame.Position, head) then
                sheriffAutoLast = tick()
                fireWeapon()
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.sheriffAimbot then return end
        local target = getClosestEnemyInFov(State.sheriffSilentFov, "Murderer")
        if target and target.Character then
            local head = getBasePart(target.Character, "Head")
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local mouse = UserInputService:GetMouseLocation()
                    local dx = sp.X - mouse.X
                    local dy = sp.Y - mouse.Y
                    local s = State.sheriffAimbotSmooth
                    if mousemoverel then pcall(function() mousemoverel(dx * s, dy * s) end) end
                end
            end
        end
    end)

    SheriffTab.CreateLabel("── Requires Sheriff Role ──", Theme.Warning)
    SheriffTab.CreateToggle("sheriff_silent_aim", "sheriffSilentAim")
    SheriffTab.CreateSlider("sheriff_silent_fov", 30, 300, 100, "sheriffSilentFov")
    SheriffTab.CreateToggle("sheriff_wallcheck", "sheriffWallCheck")
    SheriffTab.CreateToggle("sheriff_triggerbot", "sheriffTriggerbot")
    SheriffTab.CreateSlider("sheriff_triggerbot_delay", 1, 100, 5, "sheriffTriggerbotDelay")
    SheriffTab.CreateToggle("sheriff_auto_shoot", "sheriffAutoShoot")
    SheriffTab.CreateSlider("sheriff_auto_shoot_fov", 30, 300, 100, "sheriffAutoShootFov")
    SheriffTab.CreateToggle("sheriff_aimbot", "sheriffAimbot")
    SheriffTab.CreateSlider("sheriff_aimbot_smooth", 5, 100, 30, "sheriffAimbotSmooth", function(v)
        State.sheriffAimbotSmooth = v / 100
    end)

    -- ============================================================
    -- MURDERER TAB
    -- ============================================================
    local MurdererTab = CreateTab("Murderer", "🔪")

    local murdererSilentTarget = nil
    local murdererSilentHolding = false
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not murdererSilentHolding then return end
        if not murdererSilentTarget or not murdererSilentTarget.Character then murdererSilentHolding = false; return end
        local head = getBasePart(murdererSilentTarget.Character, "Head")
        if not head then murdererSilentHolding = false; return end
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
    end)
    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.murdererSilentAim then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local target = getClosestEnemyInFov(State.murdererSilentFov, nil)
        if target and target.Character then
            murdererSilentTarget = target
            murdererSilentHolding = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if murdererSilentHolding then
            murdererSilentHolding = false
            murdererSilentTarget = nil
        end
    end)

    -- KILL AURA
    local killAuraActive = false
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.killAura then return end
        if killAuraActive then return end
        local char = LocalPlayer.Character
        if not char then return end
        local myHRP = getBasePart(char, "HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not myHRP or not hum then return end

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local knife = char:FindFirstChild("Knife") or char:FindFirstChild("KnifeTool")
            or (backpack and (backpack:FindFirstChild("Knife") or backpack:FindFirstChild("KnifeTool")))
        if not knife then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("knife") then knife = t break end
            end
            if not knife and backpack then
                for _, t in ipairs(backpack:GetChildren()) do
                    if t:IsA("Tool") and t.Name:lower():find("knife") then knife = t break end
                end
            end
        end
        if not knife then return end

        killAuraActive = true
        local originalCF = myHRP.CFrame
        task.spawn(function()
            pcall(function()
                if knife.Parent ~= char then
                    hum:EquipTool(knife)
                    task.wait(0.05)
                end
            end)
            for _, p in ipairs(Players:GetPlayers()) do
                if UNLOADED then break end
                if isEnemy(p) and p.Character then
                    local tHRP = getBasePart(p.Character, "HumanoidRootPart")
                    if tHRP then
                        local dist = (tHRP.Position - originalCF.Position).Magnitude
                        if dist <= State.killAuraRange then
                            myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2)
                            task.wait(0.02)
                            pcall(function() knife:Activate() end)
                            pcall(function() mouse1click() end)
                            pcall(function()
                                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                task.wait(0.005)
                                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                            end)
                            task.wait(State.killAuraDelay / 1000)
                        end
                    end
                end
            end
            if myHRP and myHRP.Parent then myHRP.CFrame = originalCF end
            killAuraActive = false
        end)
    end)

    -- AUTO BACKSTAB
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoBackstab then return end
        local char = LocalPlayer.Character
        if not char then return end
        local myHRP = getBasePart(char, "HumanoidRootPart")
        if not myHRP then return end
        local knife = char:FindFirstChildOfClass("Tool")
        if not knife then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local tHRP = getBasePart(p.Character, "HumanoidRootPart")
                if tHRP then
                    local dist = (tHRP.Position - myHRP.Position).Magnitude
                    if dist < 10 then
                        local relative = myHRP.CFrame:PointToObjectSpace(tHRP.Position)
                        if relative.Z > 0 then
                            pcall(function() knife:Activate() end)
                            pcall(function() mouse1click() end)
                            task.wait(0.1)
                            break
                        end
                    end
                end
            end
        end
    end)

    MurdererTab.CreateLabel("── Requires Murderer Role ──", Theme.Warning)
    MurdererTab.CreateToggle("murderer_silent_aim", "murdererSilentAim")
    MurdererTab.CreateSlider("murderer_silent_fov", 30, 300, 100, "murdererSilentFov")
    MurdererTab.CreateToggle("kill_aura", "killAura")
    MurdererTab.CreateSlider("kill_aura_range", 5, 500, 30, "killAuraRange")
    MurdererTab.CreateSlider("kill_aura_delay", 10, 500, 50, "killAuraDelay")
    MurdererTab.CreateToggle("auto_backstab", "autoBackstab")

    -- ============================================================
    -- INNOCENT TAB
    -- ============================================================
    local InnocentTab = CreateTab("Innocent", "❓")

    -- Murderer Alert
    local lastAlertTime = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.murdererAlert then return end
        if myRole == "Murderer" then return end
        if tick() - lastAlertTime < 3 then return end
        local myHRP = getBasePart(LocalPlayer.Character, "HumanoidRootPart")
        if not myHRP then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local role = roleCache[p]
                if role == "Murderer" then
                    local tHRP = getBasePart(p.Character, "HumanoidRootPart")
                    if tHRP then
                        local dist = (tHRP.Position - myHRP.Position).Magnitude
                        if dist <= State.murdererAlertRange then
                            lastAlertTime = tick()
                            Notify("⚠️ MURDERER PERTO!", "Distância: " .. math.floor(dist) .. "m", 3, true)
                            pcall(function()
                                local sound = Instance.new("Sound")
                                sound.SoundId = "rbxassetid://131961136"
                                sound.Volume = 2
                                sound.Parent = SoundService
                                sound:Play()
                                task.delay(2, function() if sound then sound:Destroy() end end)
                            end)
                            break
                        end
                    end
                end
            end
        end
    end)

    -- Gun Locator
    local gunDrawing, gunTextDrawing, gunDistDrawing = nil, nil, nil
    local gunScanTick = 0
    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        if not State.gunLocator then
            if gunDrawing then gunDrawing.Visible = false end
            if gunTextDrawing then gunTextDrawing.Visible = false end
            if gunDistDrawing then gunDistDrawing.Visible = false end
            return
        end

        gunScanTick = gunScanTick + 1
        if gunScanTick % 10 ~= 0 then
            return
        end

        local gunPart = nil
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Tool") and (obj.Name:lower() == "gun" or obj.Name:lower():find("gun")) then
                local handle = obj:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then gunPart = handle; break end
            end
        end

        if not gunPart then
            if gunDrawing then gunDrawing.Visible = false end
            if gunTextDrawing then gunTextDrawing.Visible = false end
            if gunDistDrawing then gunDistDrawing.Visible = false end
            return
        end

        if not gunDrawing then
            gunDrawing = Drawing.new("Circle")
            gunDrawing.Radius = 20; gunDrawing.NumSides = 30
            gunDrawing.Thickness = 2; gunDrawing.Filled = false
            gunDrawing.Color = Theme.SheriffColor
            gunTextDrawing = Drawing.new("Text")
            gunTextDrawing.Size = 14; gunTextDrawing.Center = true
            gunTextDrawing.Outline = true; gunTextDrawing.Color = Theme.SheriffColor
            gunTextDrawing.Text = "🔫 GUN"
            gunDistDrawing = Drawing.new("Text")
            gunDistDrawing.Size = 12; gunDistDrawing.Center = true
            gunDistDrawing.Outline = true; gunDistDrawing.Color = Color3.fromRGB(200, 220, 255)
        end

        local sp, onScreen = Camera:WorldToViewportPoint(gunPart.Position)
        if onScreen then
            gunDrawing.Position = Vector2.new(sp.X, sp.Y)
            gunDrawing.Visible = true
            gunTextDrawing.Position = Vector2.new(sp.X, sp.Y - 30)
            gunTextDrawing.Visible = true
            local myHRP = getBasePart(LocalPlayer.Character, "HumanoidRootPart")
            if myHRP then
                local dist = math.floor((gunPart.Position - myHRP.Position).Magnitude)
                gunDistDrawing.Position = Vector2.new(sp.X, sp.Y + 26)
                gunDistDrawing.Text = dist .. "m"
                gunDistDrawing.Visible = true
            end
        else
            gunDrawing.Visible = false
            gunTextDrawing.Visible = false
            gunDistDrawing.Visible = false
        end
    end)

    -- ============================================================
    -- AUTO COIN FARM (FLY SUAVE - anti-detecção)
    -- ============================================================
    local coinDrawings = {}
    local coinCache = {}
    local coinCacheTimer = 0

    local function findCoins()
        local coins = {}
        local function scan(parent, depth)
            if depth > 3 then return end
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    if n:find("coin") or n:find("gem") or n:find("token") or n:find("candy") then
                        table.insert(coins, obj)
                    end
                elseif obj:IsA("Folder") or obj:IsA("Model") then
                    scan(obj, depth + 1)
                end
            end
        end
        if workspace then scan(workspace, 0) end
        local rsCoins = ReplicatedStorage:FindFirstChild("Coins")
        if rsCoins then
            for _, sub in ipairs(rsCoins:GetChildren()) do
                if sub:IsA("Folder") then scan(sub, 0) end
            end
        end
        return coins
    end

    RunService.Heartbeat:Connect(function(dt)
        if UNLOADED then return end

        -- Cleanup se desligado
        if not State.autoCoin then
            for _, d in pairs(coinDrawings) do
                if d.box then d.box:Remove() end
                if d.text then d.text:Remove() end
            end
            coinDrawings = {}
            coinCache = {}
            return
        end

        local char = LocalPlayer.Character
        if not char then return end
        local hrp = getBasePart(char, "HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        -- Cache de coins (rescan a cada ~0.4s para performance)
        coinCacheTimer = coinCacheTimer + dt
        if coinCacheTimer >= 0.4 or #coinCache == 0 then
            coinCacheTimer = 0
            coinCache = findCoins()
        end

        -- Achar moeda mais próxima (ainda existente)
        local nearest, minDist = nil, math.huge
        for _, c in ipairs(coinCache) do
            if c and c.Parent then
                local d = (c.Position - hrp.Position).Magnitude
                if d < minDist then minDist = d; nearest = c end
            end
        end

        -- Desenha TODAS as coins visíveis
        local activeSet = {}
        for _, coin in ipairs(coinCache) do
            if coin and coin.Parent then
                activeSet[coin] = true
                if not coinDrawings[coin] then
                    local box = Drawing.new("Circle")
                    box.Radius = 10; box.NumSides = 20; box.Thickness = 1.5
                    box.Filled = false; box.Color = Color3.fromRGB(255, 220, 100)
                    local text = Drawing.new("Text")
                    text.Size = 10; text.Center = true; text.Outline = true
                    text.Color = Color3.fromRGB(255, 220, 100)
                    coinDrawings[coin] = {box = box, text = text}
                end
                local d = coinDrawings[coin]
                local sp, onScreen = Camera:WorldToViewportPoint(coin.Position)
                if onScreen then
                    d.box.Position = Vector2.new(sp.X, sp.Y)
                    d.box.Visible = true
                    d.text.Position = Vector2.new(sp.X, sp.Y - 18)
                    local dist2 = (coin.Position - hrp.Position).Magnitude
                    d.text.Text = math.floor(dist2) .. "m"
                    d.text.Visible = true
                    -- destaca a moeda alvo
                    if coin == nearest then
                        d.box.Color = Color3.fromRGB(0, 255, 130)
                        d.box.Radius = 14
                    else
                        d.box.Color = Color3.fromRGB(255, 220, 100)
                        d.box.Radius = 10
                    end
                else
                    d.box.Visible = false
                    d.text.Visible = false
                end
            end
        end
        for coin, d in pairs(coinDrawings) do
            if not activeSet[coin] then
                if d.box then d.box:Remove() end
                if d.text then d.text:Remove() end
                coinDrawings[coin] = nil
            end
        end

        if not nearest then return end

        -- Movimento FLY suave (não teleporta!)
        local targetPos = nearest.Position + Vector3.new(0, 2.2, 0)
        local dir = targetPos - hrp.Position
        local dist = dir.Magnitude

        -- Desliga gravidade enquanto voa
        hum.PlatformStand = true

        if dist <= 3 then
            -- Coleta por toque
            pcall(function()
                firetouchinterest(hrp, nearest, 0)
                task.wait()
                firetouchinterest(hrp, nearest, 1)
            end)
        else
            local speed = tonumber(State.autoCoinSpeed) or 45
            local step = math.min(speed * dt, dist)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(hrp.Position + dir.Unit * step)
        end

        -- Se ficar muito tempo parado, cancela o PlatformStand
        if dist <= 3 then
            task.wait(0.05)
            if hum and hum.Parent then hum.PlatformStand = false end
        end
    end)

    -- ============================================================
    -- AUTO GRAB GUN (Innocent) - pega gun do sheriff morto
    -- ============================================================
    local function playerHasGun()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("gun") then return true end
            end
        end
        if backpack then
            for _, t in ipairs(backpack:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("gun") then return true end
            end
        end
        return false
    end

    local function findDroppedGun()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Tool") then
                local n = obj.Name:lower()
                if n == "gun" or n:find("gun") then
                    local handle = obj:FindFirstChild("Handle")
                    if handle and handle:IsA("BasePart") then
                        return obj, handle
                    end
                end
            end
        end
        return nil
    end

    local autoGrabCooldown = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoGrabGun then return end
        if tick() < autoGrabCooldown then return end
        if playerHasGun() then return end -- já tenho

        local gun, handle = findDroppedGun()
        if not gun or not handle then return end

        local char = LocalPlayer.Character
        if not char then return end
        local hrp = getBasePart(char, "HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local dist = (handle.Position - hrp.Position).Magnitude
        if dist > (tonumber(State.autoGrabGunRange) or 300) then return end

        autoGrabCooldown = tick() + 1.5 -- evita spam
        local originalCF = hrp.CFrame

        task.spawn(function()
            local pulled = pcall(function()
                gun.Parent = char
            end)
            task.wait(0.03)

            if pulled and gun.Parent == char then
                Notify("🔫 Auto Grab Gun", "Gun puxada pra mão!", 3)
                return
            end

            -- Fallback: teleporta pra gun por 0.05s, pega e volta
            if not hrp or not hrp.Parent then return end
            hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0, 1.5, 0))
            task.wait(0.05)

            pcall(function()
                firetouchinterest(hrp, handle, 0)
                task.wait()
                firetouchinterest(hrp, handle, 1)
            end)
            task.wait(0.05)

            if hrp and hrp.Parent then
                hrp.CFrame = originalCF
            end

            if playerHasGun() then
                Notify("🔫 Auto Grab Gun", "Gun pega com sucesso!", 3)
            end
        end)
    end)

    InnocentTab.CreateLabel("── ESP ──", Theme.Text)
    InnocentTab.CreateToggle("esp", "esp", function(v)
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then createESP(p) end
            end
        else clearAllESP() end
    end)
    InnocentTab.CreateSlider("max_distance", 100, 5000, 2000, "espMaxDistance")
    InnocentTab.CreateToggle("show_murderer", "showMurderer")
    InnocentTab.CreateToggle("show_sheriff", "showSheriff")
    InnocentTab.CreateToggle("show_innocent", "showInnocent")
    InnocentTab.CreateToggle("weapon_esp", "showWeaponESP")
    InnocentTab.CreateToggle("distance_esp", "showDistanceESP")
    InnocentTab.CreateToggle("tracer_esp", "showTracerESP")
    InnocentTab.CreateLabel(" ")
    InnocentTab.CreateLabel("── Alert ──", Theme.Text)
    InnocentTab.CreateToggle("murderer_alert", "murdererAlert")
    InnocentTab.CreateSlider("murderer_alert_range", 10, 200, 40, "murdererAlertRange")
    InnocentTab.CreateLabel(" ")
    InnocentTab.CreateLabel("── Utility ──", Theme.Text)
    InnocentTab.CreateToggle("gun_locator", "gunLocator")
    InnocentTab.CreateToggle("auto_coin_farm", "autoCoin")
    InnocentTab.CreateSlider("auto_coin_speed", 15, 200, 45, "autoCoinSpeed")
    InnocentTab.CreateLabel(" ")
    InnocentTab.CreateLabel("── Auto Grab ──", Theme.Text)
    InnocentTab.CreateToggle("auto_grab_gun", "autoGrabGun")
    InnocentTab.CreateSlider("auto_grab_gun_range", 50, 1000, 300, "autoGrabGunRange")

    -- ============================================================
    -- UTILS TAB
    -- ============================================================
    local UtilsTab = CreateTab("Utils", "🌑")

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
                if c:IsA("Atmosphere") then c.Density = 0; c.Haze = 0; c.Glare = 0 end
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

    local function applyLowGraphics(v)
        if v then
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        else
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        end
    end
    local function applyNoShadows(v)
        pcall(function() Lighting.GlobalShadows = not v end)
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                pcall(function() d.CastShadow = not v end)
            end
        end
    end
    local function applyNoFog(v)
        if v then
            Lighting.FogEnd = 100000; Lighting.FogStart = 0
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Atmosphere") then c.Density = 0; c.Haze = 0; c.Glare = 0 end
            end
        end
    end
    local function applyNoParticles(v)
        if v then
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Trail") then
                    pcall(function() d.Enabled = false end)
                end
            end
        end
    end

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.noParticles then return end
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
                pcall(function() d.Enabled = false end)
            end
        end
    end)

    local airJumpConn = nil
    local function startAirJump()
        if airJumpConn then airJumpConn:Disconnect() end
        airJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = getBasePart(char, "HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end
            if hum:GetState() == Enum.HumanoidStateType.Dead then return end
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 55, hrp.Velocity.Z)
        end)
    end
    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.speed then return end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoBhop then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Landed or st == Enum.HumanoidStateType.Running then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then hum.Jump = true end
        end
    end)

    UtilsTab.CreateLabel("── Movement ──", Theme.Text)
    UtilsTab.CreateToggle("speed", "speed")
    UtilsTab.CreateSlider("speed_value", 16, 200, 30, "speedValue")
    UtilsTab.CreateToggle("air_jump", "airJump", function(v)
        if v then startAirJump() else stopAirJump() end
    end)
    UtilsTab.CreateToggle("auto_bhop", "autoBhop")
    UtilsTab.CreateLabel(" ")
    UtilsTab.CreateLabel("── Visuals ──", Theme.Text)
    UtilsTab.CreateToggle("fullbright", "fullbright", function(v)
        if not v then disableFullbright() end
    end)
    UtilsTab.CreateLabel(" ")
    UtilsTab.CreateLabel("── Performance ──", Theme.Text)
    UtilsTab.CreateToggle("low_graphics", "lowGraphics", function(v) applyLowGraphics(v) end)
    UtilsTab.CreateToggle("no_shadows", "noShadows", function(v) applyNoShadows(v) end)
    UtilsTab.CreateToggle("no_fog", "noFog", function(v) applyNoFog(v) end)
    UtilsTab.CreateToggle("no_particles", "noParticles", function(v) applyNoParticles(v) end)
    UtilsTab.CreateLabel(" ")
    UtilsTab.CreateButton("⚡ Max FPS Boost", function()
        toggleHandles.lowGraphics.SetState(true)
        toggleHandles.noShadows.SetState(true)
        toggleHandles.noFog.SetState(true)
        toggleHandles.noParticles.SetState(true)
        Notify("⚡ Boost", "All optimizations ON", 3)
    end)
    UtilsTab.CreateButton("🔄 Reset Optimizations", function()
        toggleHandles.lowGraphics.SetState(false)
        toggleHandles.noShadows.SetState(false)
        toggleHandles.noFog.SetState(false)
        toggleHandles.noParticles.SetState(false)
    end)

    -- ============================================================
    -- SETTINGS TAB
    -- ============================================================
    local SettingsTab = CreateTab("Settings", "⚙️")

    local BASE_FOLDER = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/MM2"
    local AUTOLOAD_FILE = "InfiniteZen_MM2_Autoload.txt"

    local function ensureFolder()
        if makefolder then
            if not isfolder(BASE_FOLDER) then pcall(function() makefolder(BASE_FOLDER) end) end
            if not isfolder(CONFIG_FOLDER) then pcall(function() makefolder(CONFIG_FOLDER) end) end
        end
    end
    local function getConfigPath(name) return CONFIG_FOLDER .. "/" .. name .. ".json" end
    local function getAutoloadPath() return AUTOLOAD_FILE end

    local function saveConfigNamed(name)
        ensureFolder()
        local data = {version = GAME_VERSION, language = Language.getCurrent(), state = {}, keybinds = State.keybinds}
        for k, v in pairs(State) do
            if k ~= "keybinds" then data.state[k] = v end
        end
        local json = HttpService:JSONEncode(data)
        local ok, err = pcall(function() writefile(getConfigPath(name), json) end)
        if ok then Notify("💾 Config", "Saved: " .. name, 3); return true
        else Notify("⚠️ Error", "Failed: " .. tostring(err), 4, true); return false end
    end

    local function loadConfigNamed(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then Notify("⚠️ Error", "Config not found", 4, true); return false end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data then Notify("⚠️ Error", "Corrupted", 4, true); return false end
        if data.language then Language.setLanguage(data.language) end
        if data.state then for k, v in pairs(data.state) do State[k] = v end end
        if data.keybinds then for k, v in pairs(data.keybinds) do State.keybinds[k] = v end end
        for featId, handle in pairs(toggleHandles) do
            if State[featId] ~= nil then handle.SetState(State[featId], true) end
            handle.SetKeybind(State.keybinds[featId])
        end
        for featId, handle in pairs(sliderHandles) do
            if State[featId] ~= nil then handle.SetValue(State[featId]) end
        end
        if State.fullbright == false then disableFullbright() end
        if State.airJump then startAirJump() end
        Notify("📂 Load", "Loaded: " .. name, 3)
        return true
    end

    local function deleteConfigNamed(name)
        local path = getConfigPath(name)
        if isfile and isfile(path) then
            pcall(function() delfile(path) end)
            Notify("🗑️ Delete", "Deleted", 3); return true
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
        if ok then Notify("⚡ Autoload", "Set: " .. name, 3) end
    end
    local function clearAutoload()
        pcall(function() if isfile(getAutoloadPath()) then delfile(getAutoloadPath()) end end)
        Notify("🚫 Autoload", "Disabled", 3)
    end
    local function getAutoload()
        local ok, content = pcall(function() return readfile(getAutoloadPath()) end)
        if ok and content and content ~= "" then return content end
        return nil
    end

    SettingsTab.CreateLabel("── Configs ──", Theme.Text)
    SettingsTab.CreateLabel("Type name and press Enter", Theme.TextDim)
    local refreshConfigListRef = nil
    SettingsTab.CreateTextBox("Config name...", function(name)
        if saveConfigNamed(name) and refreshConfigListRef then refreshConfigListRef() end
    end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateLabel("── Loaded Configs ──", Theme.Text)
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
                loadConfigNamed(configName); refreshConfigList()
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
                deleteConfigNamed(configName); refreshConfigList()
            end)
        end
    end
    refreshConfigListRef = refreshConfigList
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
    SettingsTab.CreateButton("Unload Script", function()
        UNLOADED = true
        _G.IZ_RefreshLanguage = nil
        clearAllESP()
        stopAirJump()
        for _, d in pairs(coinDrawings) do
            if d.box then d.box:Remove() end
            if d.text then d.text:Remove() end
        end
        if gunDrawing then gunDrawing:Remove() end
        if gunTextDrawing then gunTextDrawing:Remove() end
        if gunDistDrawing then gunDistDrawing:Remove() end
        GUI:Destroy()
    end, "danger")

    -- ============================================================
    -- CREDITS TAB
    -- ============================================================
    local CreditsTab = CreateTab("Credits", "➕")
    CreditsTab.CreateCredit("FOUNDER & DEVELOPER", "Sr Red", Theme.TitleRed)
    CreditsTab.CreateLabel(" ")
    CreditsTab.CreateLabel("── Join our Discord ──", Theme.Text)
    CreditsTab.CreateLabel("https://discord.gg/ScZfU2mAGm", Theme.TextDim)
    local discordBtn = CreditsTab.CreateButton("Join Discord Server", function()
        if setclipboard then setclipboard("https://discord.gg/ScZfU2mAGm"); Notify("📋 Copied", "Discord link copied!", 3) end
    end)
    discordBtn.BackgroundColor3 = Theme.Discord
    CreditsTab.CreateLabel(" ")
    CreditsTab.CreateLabel(FULL_VERSION, Theme.TextDim)
    CreditsTab.CreateLabel("MM2 Role-Based Edition", Theme.Warning)
    CreditsTab.CreateLabel("© 2026 Sr Red", Theme.TextDim)

    local versionLabel = Instance.new("TextLabel", MainFrame)
    versionLabel.Size = UDim2.new(1, -20, 0, 16)
    versionLabel.Position = UDim2.new(0, 10, 1, -20)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Font = Theme.Font
    versionLabel.TextSize = 10
    versionLabel.TextColor3 = Theme.TextDim
    versionLabel.TextXAlignment = Enum.TextXAlignment.Right
    versionLabel.Text = FULL_VERSION

    task.defer(function()
        local autoloadName = getAutoload()
        if autoloadName then task.wait(1); loadConfigNamed(autoloadName) end
    end)

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
            State.keybinds[featId] = newKey
            recordingKeyFor = nil
            local handle = toggleHandles[featId]
            if handle then handle.SetKeybind(State.keybinds[featId]) end
            return
        end

        if input.KeyCode == MINIMIZE_KEY then
            setMinimized(not minimized); return
        end

        local keyName = input.KeyCode.Name
        for featId, key in pairs(State.keybinds) do
            if key and key == keyName then
                local handle = toggleHandles[featId]
                if handle then handle.Toggle() end
            end
        end
    end)

    task.wait(0.5)
    Notify("🎯 " .. SHORT_VERSION, "MM2 carregado!", 4)

    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
    print("[Infinite Zen] Tabs: Sheriff | Murderer | Innocent | Utils | Settings | Credits")
end

return MM2