-- ============================================================
-- INFINITE ZEN - MÓDULO JAILBIRD v1.0
-- Jailbird (PlaceId 14939963714)
-- ============================================================

local Jailbird = {}

function Jailbird.Init(ctx)
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
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    local UNLOADED = false
    local IS_JAILBIRD = game.PlaceId == 14939963714
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
    local GameEvents = ReplicatedStorage:FindFirstChild("GameEvents")
    local Remotes = {
        LookRotation = GameEvents and GameEvents:FindFirstChild("LookRotation"),
        Shoot = GameEvents and GameEvents:FindFirstChild("Shoot"),
        Reload = GameEvents and GameEvents:FindFirstChild("Reload"),
        Hit = GameEvents and GameEvents:FindFirstChild("Hit"),
        Damage = GameEvents and GameEvents:FindFirstChild("Damage"),
        ChangeMovement = GameEvents and GameEvents:FindFirstChild("ChangeMovement"),
        VoteKick = GameEvents and GameEvents:FindFirstChild("VoteKick"),
        SwitchTeam = GameEvents and GameEvents:FindFirstChild("SwitchTeam"),
        Stance = GameEvents and GameEvents:FindFirstChild("Stance"),
        HitFromServer = GameEvents and GameEvents:FindFirstChild("HitFromServer"),
    }
    print("[Infinite Zen] Remotes carregados")

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

    local State = {
        silentHeadshot = false, silentFov = 120,
        aimbot = false, aimbotFov = 100, aimbotSmoothness = 0.3,
        aimbotMaxDist = 500, aimbotHitbox = 1, aimbotWallCheck = true,
        triggerbot = false, triggerbotDelay = 5,
        headExpander = false, headExpanderSize = 3,
        backstab = false,
        noRecoil = false, rapidFire = false, fastReload = false,
        instaReload = false, noSpread = false, infiniteAmmo = false,
        autoShoot = false, autoShootFov = 100, autoShootDelay = 0.05,
        speed = false, speedValue = 50, airJump = false,
        autoBhop = false, fullbright = false,
        esp = false, espMaxDistance = 500,
        espWeapon = true, espArmor = true, espGrenades = false,
        damageIndicator = false, antiFlash = false, antiVK = false,
        lowGraphics = false, noShadows = false, noFog = false, noParticles = false,
        keybinds = {
            silentHeadshot = "X", aimbot = nil, triggerbot = nil,
            headExpander = nil, backstab = "E", noRecoil = nil,
            rapidFire = nil, fastReload = nil, instaReload = nil,
            noSpread = nil, infiniteAmmo = nil, autoShoot = nil,
            speed = nil, airJump = nil, autoBhop = nil, esp = nil,
            fullbright = nil,
        }
    }

    local recordingKeyFor = nil
    local FeatureLabels = {
        silentHeadshot = "Silent Headshot", aimbot = "Aimbot",
        triggerbot = "Triggerbot", headExpander = "Head Expander",
        backstab = "Backstab", noRecoil = "No-Recoil", rapidFire = "Rapid Fire",
        fastReload = "Fast Reload", instaReload = "Insta-Reload",
        noSpread = "No Spread", infiniteAmmo = "Infinite Ammo",
        autoShoot = "Auto Shoot", speed = "Speed", airJump = "Air Jump",
        autoBhop = "Auto Bhop", esp = "ESP", fullbright = "Fullbright",
        lowGraphics = "Low Graphics", noShadows = "No Shadows",
        noFog = "No Fog", noParticles = "No Particles",
        antiFlash = "Anti-Flash", antiVK = "Anti-VoteKick",
        damageIndicator = "Damage Indicator", espWeapon = "Weapon ESP",
        espArmor = "Armor ESP", espGrenades = "Grenade ESP",
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

    local Theme = {
        Bg = Color3.fromRGB(8, 4, 6), Surface = Color3.fromRGB(18, 8, 12),
        Surface2 = Color3.fromRGB(35, 12, 18), Border = Color3.fromRGB(80, 15, 20),
        SidebarColor = Color3.fromRGB(15, 6, 10), ContentColor = Color3.fromRGB(25, 10, 15),
        Primary = Color3.fromRGB(255, 30, 40), TitleRed = Color3.fromRGB(255, 50, 50),
        Success = Color3.fromRGB(0, 220, 130), Danger = Color3.fromRGB(255, 40, 40),
        Warning = Color3.fromRGB(255, 150, 50), Text = Color3.fromRGB(255, 245, 245),
        TextDim = Color3.fromRGB(160, 120, 130), Discord = Color3.fromRGB(88, 101, 242),
        Font = Enum.Font.GothamMedium, FontBold = Enum.Font.GothamBlack,
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
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, 0, notif.Position.Y.Offset)
            }):Play()
            task.wait(0.35)
            if notif and notif.Parent then notif:Destroy() end
        end)
    end

    local function findFeatureWithKeybind(key)
        for featId, boundKey in pairs(State.keybinds) do
            if boundKey == key then return featId end
        end
        return nil
    end

    -- HELPERS
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
        return workspace:Raycast(origin, unitDir * rayLength, params) == nil
    end

    local function getTargetPart(p)
        if not p.Character then return nil end
        local mode = State.aimbotHitbox
        if mode == 1 then return p.Character:FindFirstChild("Head")
        elseif mode == 2 then return p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("UpperTorso")
        else
            local head = p.Character:FindFirstChild("Head")
            local torso = p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("UpperTorso")
            if head and torso then
                local camPos = Camera.CFrame.Position
                local dHead = (head.Position - camPos).Magnitude
                local dTorso = (torso.Position - camPos).Magnitude
                return dHead <= dTorso and head or torso
            end
            return head or torso
        end
    end

    -- MAIN WINDOW
    local MainFrame = Instance.new("Frame", GUI)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 620, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -310, 0.5, -240)
    MainFrame.BackgroundColor3 = Theme.Bg
    MainFrame.BorderSizePixel = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local guiScale = Instance.new("UIScale")
    guiScale.Scale = IS_MOBILE and MOBILE_SCALE or 1
    guiScale.Parent = MainFrame

    if IS_MOBILE then
        local vp = workspace.CurrentCamera.ViewportSize
        local w = 620 * MOBILE_SCALE
        local h = 480 * MOBILE_SCALE
        MainFrame.Position = UDim2.new(0, (vp.X - w) / 2, 0, (vp.Y - h) / 2)
    end

    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Color = Theme.Primary; mainStroke.Thickness = 1.5; mainStroke.Transparency = 0.3

    -- HEADER FLAT
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
    headerGradient.Rotation = 15
    headerGradient.Parent = Header

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
    Subtitle.Size = UDim2.new(0, 250, 0, 18); Subtitle.Position = UDim2.new(0, 20, 0, 25)
    Subtitle.BackgroundTransparency = 1; Subtitle.Font = Theme.Font
    Subtitle.Text = SHORT_VERSION; Subtitle.TextColor3 = Color3.fromRGB(220, 180, 185)
    Subtitle.TextSize = 11; Subtitle.TextXAlignment = Enum.TextXAlignment.Left; Subtitle.ZIndex = 3

    -- BOTÃO DE IDIOMA
    local LangBtn = Instance.new("TextButton", Header)
    LangBtn.Size = UDim2.new(0, 60, 0, 26); LangBtn.Position = UDim2.new(1, -110, 0.5, -13)
    LangBtn.BackgroundColor3 = Theme.Surface2; LangBtn.Text = "US"
    LangBtn.Font = Theme.FontBold; LangBtn.TextSize = 12; LangBtn.TextColor3 = Theme.Text
    LangBtn.AutoButtonColor = false; LangBtn.ZIndex = 3
    Instance.new("UICorner", LangBtn).CornerRadius = UDim.new(0, 6)

    local LangDropdown = Instance.new("Frame", Header)
    LangDropdown.Size = UDim2.new(0, 140, 0, 0); LangDropdown.Position = UDim2.new(1, -110, 1, 4)
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
    MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -40, 0.5, -15)
    MinBtn.BackgroundColor3 = Theme.Surface2; MinBtn.Text = "−"
    MinBtn.Font = Theme.FontBold; MinBtn.TextSize = 18; MinBtn.TextColor3 = Theme.Text; MinBtn.ZIndex = 3
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    local reopenBtn = nil
    local reopenDragging = false
    local reopenDragStart = nil
    local reopenStartPos = nil
    local reopenMoved = false

    if IS_MOBILE then
        reopenBtn = Instance.new("TextButton", GUI)
        reopenBtn.Size = UDim2.new(0, 55, 0, 55); reopenBtn.Position = UDim2.new(0, 20, 0, 100)
        reopenBtn.BackgroundColor3 = Theme.Primary; reopenBtn.Text = "∞"
        reopenBtn.Font = Theme.FontBold; reopenBtn.TextSize = 26; reopenBtn.TextColor3 = Theme.Text
        reopenBtn.AutoButtonColor = false; reopenBtn.Visible = false; reopenBtn.ZIndex = 500
        Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(1, 0)
        local reopenStroke = Instance.new("UIStroke", reopenBtn)
        reopenStroke.Color = Theme.TitleRed; reopenStroke.Thickness = 2; reopenStroke.Transparency = 0.3

        reopenBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                reopenDragging = true; reopenMoved = false
                reopenDragStart = input.Position; reopenStartPos = reopenBtn.Position
            end
        end)
        reopenBtn.InputChanged:Connect(function(input)
            if not reopenDragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - reopenDragStart
                if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then reopenMoved = true end
                reopenBtn.Position = UDim2.new(
                    reopenStartPos.X.Scale, reopenStartPos.X.Offset + delta.X,
                    reopenStartPos.Y.Scale, reopenStartPos.Y.Offset + delta.Y
                )
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if reopenDragging then reopenDragging = false; task.wait(0.1); reopenMoved = false end
            end
        end)
        reopenBtn.MouseButton1Click:Connect(function()
            if reopenMoved then return end
            setMinimized(false)
        end)
    end

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

    -- SIDEBAR + CONTENT FLAT
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size = UDim2.new(0, 140, 1, -65); Sidebar.Position = UDim2.new(0, 10, 0, 58)
    Sidebar.BackgroundColor3 = Theme.SidebarColor; Sidebar.BorderSizePixel = 0
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

    local Content = Instance.new("Frame", MainFrame)
    Content.Size = UDim2.new(1, -170, 1, -70); Content.Position = UDim2.new(0, 160, 0, 58)
    Content.BackgroundColor3 = Theme.ContentColor; Content.BackgroundTransparency = 0.3
    Content.BorderSizePixel = 0
    Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 8)

    local minimized = false
    local function setMinimized(v)
        minimized = v
        Sidebar.Visible = not v
        Content.Visible = not v
        MainFrame.Size = v and UDim2.new(0, 620, 0, 48) or UDim2.new(0, 620, 0, 480)
        if reopenBtn and IS_MOBILE then reopenBtn.Visible = v end
    end
    MinBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)

    -- TABS BUILDER
    local tabs, toggleHandles, sliderHandles = {}, {}, {}

    local function CreateTab(nameKey, icon)
        local tab = {}
        local btn = Instance.new("TextButton", Sidebar)
        btn.Size = UDim2.new(1, -16, 0, 38); btn.Position = UDim2.new(0, 8, 0, 8 + #tabs * 44)
        btn.BackgroundColor3 = Theme.Surface; btn.BorderSizePixel = 0
        btn.Text = "  " .. icon .. "   "; btn.Font = Theme.Font
        btn.TextColor3 = Theme.TextDim; btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left; btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        registerRefresh(function()
            btn.Text = "  " .. icon .. "   " .. getLabel(nameKey)
        end)

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
            fill.Size = UDim2.new(rel, 0, 1, 0)
            fill.BackgroundColor3 = Theme.Primary; fill.BorderSizePixel = 0
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

    -- FOV CIRCLE
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Theme.Primary; fovCircle.Thickness = 1.5
    fovCircle.Filled = false; fovCircle.NumSides = 100; fovCircle.Transparency = 1
    fovCircle.Radius = 25; fovCircle.Visible = false

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        local mouse = UserInputService:GetMouseLocation()
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
        if State.silentHeadshot then
            fovCircle.Visible = true; fovCircle.Radius = State.silentFov / 6
        elseif State.autoShoot then
            fovCircle.Visible = true; fovCircle.Radius = State.autoShootFov / 6
        elseif State.triggerbot then
            fovCircle.Visible = true; fovCircle.Radius = 15
        elseif State.aimbot then
            fovCircle.Visible = true; fovCircle.Radius = State.aimbotFov / 6
        else
            fovCircle.Visible = false
        end
    end)

    -- TARGETING
    local function getClosestEnemyInFov(fovRange)
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, fovRange
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d < minDist then
                            if not State.aimbotWallCheck or hasLineOfSight(Camera.CFrame.Position, part) then
                                minDist = d; closest = p
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    -- FIRE WEAPON
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
        if Remotes.Shoot then pcall(function() Remotes.Shoot:FireServer() end) end
        return true
    end

    -- SILENT HEADSHOT
    local silentHolding, silentTarget, silentOriginalCF = false, nil, nil
    local function fireLookRemote(newCF)
        if not Remotes.LookRotation then return end
        pcall(function() Remotes.LookRotation:FireServer(newCF) end)
        pcall(function() Remotes.LookRotation:FireServer(newCF.LookVector) end)
        pcall(function() Remotes.LookRotation:FireServer(newCF.lookVector) end)
    end
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then silentHolding = false; return end
        local head = silentTarget.Character:FindFirstChild("Head")
        if not head then silentHolding = false; return end
        local newCF = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
        Camera.CFrame = newCF
        fireLookRemote(newCF)
    end)
    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.silentHeadshot then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        silentOriginalCF = Camera.CFrame
        local target = getClosestEnemyInFov(State.silentFov)
        if not target or not target.Character then return end
        silentTarget = target
        silentHolding = true
        local head = target.Character:FindFirstChild("Head")
        if head then
            local newCF = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
            Camera.CFrame = newCF
            fireLookRemote(newCF)
        end
    end)
    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if silentHolding then
            silentHolding = false
            silentTarget = nil
            if silentOriginalCF then
                Camera.CFrame = silentOriginalCF
                fireLookRemote(silentOriginalCF)
                silentOriginalCF = nil
            end
        end
    end)

    -- AIMBOT
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.aimbot then return end
        local target = getClosestEnemyInFov(State.aimbotFov)
        if target and target.Character then
            local part = getTargetPart(target)
            if part then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local dist3D = (part.Position - myRoot.Position).Magnitude
                    if dist3D <= State.aimbotMaxDist then
                        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local mouse = UserInputService:GetMouseLocation()
                            local dx = sp.X - mouse.X
                            local dy = sp.Y - mouse.Y
                            local s = State.aimbotSmoothness
                            if mousemoverel then pcall(function() mousemoverel(dx * s, dy * s) end) end
                        end
                    end
                end
            end
        end
    end)

    -- TRIGGERBOT
    local triggerLastFire = 0
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.triggerbot then return end
        if tick() - triggerLastFire < (State.triggerbotDelay / 1000) then return end
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
                        if d < 20 and hasLineOfSight(Camera.CFrame.Position, part) then
                            triggerLastFire = tick()
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
    end)

    -- AUTO SHOOT
    local lastAutoShoot = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoShoot then return end
        if tick() - lastAutoShoot < State.autoShootDelay then return end
        local target = getClosestEnemyInFov(State.autoShootFov)
        if target and target.Character then
            local part = getTargetPart(target)
            if part and hasLineOfSight(Camera.CFrame.Position, part) then
                lastAutoShoot = tick()
                fireWeapon()
            end
        end
    end)

    -- BACKSTAB
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
            if tHRP and mHRP then Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position) end
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
        backstabLock.active = true; backstabLock.target = target; backstabLock.endTime = tick() + 0.5
        Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
        task.wait(0.08)
        Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
        task.wait(0.02)
        for _ = 1, 3 do
            fireWeapon()
            task.wait(0.05)
        end
    end

    -- HEAD EXPANDER
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
            head.Transparency = 0.7; head.CanCollide = false; head.Massless = true
        end
        local torso = p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("UpperTorso")
        if torso then
            saveOriginal(p, torso)
            local base = hitboxSaved[p][torso]
            local tMult = math.min(size * 0.7, 3)
            torso.Size = Vector3.new(base.X * tMult, base.Y * tMult, base.Z * tMult)
            torso.Transparency = 0.7; torso.CanCollide = false; torso.Massless = true
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

    -- WEAPON HACKS
    local reloadOriginals = {}
    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if not (State.rapidFire or State.noRecoil or State.fastReload or State.instaReload or State.noSpread or State.infiniteAmmo) then return end
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
                            for _, name in ipairs({"FireRate", "BFireRate", "RateOfFire", "ShootCooldown", "FireDelay", "Cooldown", "EquipTime"}) do
                                local f = tool:FindFirstChild(name)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then f.Value = 0.01
                                elseif typeof(tool[name]) == "number" then tool[name] = 0.01 end
                            end
                        end)
                    end
                    if State.noRecoil or State.noSpread then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if State.noRecoil and (n:find("recoil") or n:find("kick") or n:find("camera")) then d.Value = 0 end
                                    if State.noSpread and (n:find("spread") or n:find("accuracy")) then d.Value = 0 end
                                end
                            end
                        end)
                    end
                    if State.infiniteAmmo then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("ammo") or n:find("magazine") or n == "mag" then
                                        if not reloadOriginals["ammo_" .. tostring(d)] then
                                            reloadOriginals["ammo_" .. tostring(d)] = d.Value
                                        end
                                        d.Value = 9999
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
                                        d.Value = reloadOriginals[d] * 0.1
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
                        if Remotes.Reload then pcall(function() Remotes.Reload:FireServer() end) end
                    end
                end
            end
        end
    end)

    coroutine.wrap(function()
        while not UNLOADED do
            if State.rapidFire or State.noRecoil or State.fastReload or State.instaReload or State.noSpread then
                pcall(function()
                    if ReplicatedStorage:FindFirstChild("Weapons") then
                        for _, d in ipairs(ReplicatedStorage.Weapons:GetDescendants()) do
                            if d:IsA("NumberValue") or d:IsA("IntValue") then
                                local n = d.Name:lower()
                                if State.rapidFire and (n == "firerate" or n == "bfirerate" or n == "rateoffire" or n == "firedelay") then d.Value = 0.01
                                elseif State.noRecoil and n:find("recoil") then d.Value = 0
                                elseif State.noSpread and (n:find("spread") or n:find("accuracy")) then d.Value = 0
                                elseif State.fastReload and not State.instaReload and n:find("reload") and not n:find("reloading") then
                                    if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                    d.Value = reloadOriginals[d] * 0.1
                                elseif State.instaReload and n:find("reload") and not n:find("reloading") then
                                    if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
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

    -- AUTO BHOP
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoBhop then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then hum.Jump = true end
        end
    end)

    -- ANTI-FLASH
    local flashKeywords = {"flash", "blind", "whiteout", "whitescreen", "flashbang"}
    local function isFlashName(name)
        local lower = name:lower()
        for _, kw in ipairs(flashKeywords) do if lower:find(kw) then return true end end
        return false
    end
    local function checkFlash()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, child in ipairs(pg:GetChildren()) do
                if child:IsA("ScreenGui") or child:IsA("Frame") then
                    if isFlashName(child.Name) then pcall(function() child:Destroy() end) end
                end
            end
        end
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("ColorCorrectionEffect") or child:IsA("BlurEffect") then
                if isFlashName(child.Name) then pcall(function() child:Destroy() end) end
            end
        end
    end
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.antiFlash then return end
        checkFlash()
    end)
    PlayerGui.ChildAdded:Connect(function(child)
        if UNLOADED or not State.antiFlash then return end
        if isFlashName(child.Name) then
            task.wait(0.05)
            pcall(function() child:Destroy() end)
        end
    end)

    -- ANTI-VOTEKICK
    local vkKeywords = {"votekick", "voting", "vote_kick", "kickvote"}
    local function blockVoteKickGui(child)
        if not child then return end
        local lower = child.Name:lower()
        for _, kw in ipairs(vkKeywords) do
            if lower:find(kw) then
                pcall(function() child:Destroy() end)
                return true
            end
        end
        return false
    end
    PlayerGui.ChildAdded:Connect(function(child)
        if UNLOADED or not State.antiVK then return end
        if blockVoteKickGui(child) then
            Notify("🛡️ Anti-VK", "Votekick bloqueado", 3)
        end
    end)
    if Remotes.VoteKick then
        Remotes.VoteKick.OnClientEvent:Connect(function(...)
            if UNLOADED or not State.antiVK then return end
            local args = {...}
            for _, v in ipairs(args) do
                if typeof(v) == "Instance" and v:IsA("Player") and v == LocalPlayer then
                    pcall(function() Remotes.VoteKick:FireServer(LocalPlayer, false) end)
                end
            end
        end)
    end

    -- DAMAGE INDICATOR
    local dmgArrow = Drawing.new("Triangle")
    dmgArrow.Filled = true
    dmgArrow.Color = Color3.fromRGB(255, 40, 40)
    dmgArrow.Transparency = 0.85
    dmgArrow.Visible = false

    local lastDamageTime = 0
    local lastAttacker = nil

    if Remotes.HitFromServer then
        Remotes.HitFromServer.OnClientEvent:Connect(function(...)
            local args = {...}
            for _, v in ipairs(args) do
                if typeof(v) == "Instance" and v:IsA("Player") then
                    lastAttacker = v
                    return
                end
            end
        end)
    end

    task.spawn(function()
        while not UNLOADED do
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local lastHealth = hum.Health
                    local conn
                    conn = hum.HealthChanged:Connect(function(newHealth)
                        if newHealth < lastHealth and newHealth > 0 then
                            lastDamageTime = tick()
                        end
                        lastHealth = newHealth
                    end)
                    hum.AncestryChanged:Wait()
                    if conn then conn:Disconnect() end
                end
            end
            task.wait(0.5)
        end
    end)

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.damageIndicator then dmgArrow.Visible = false; return end
        local now = tick()
        if now - lastDamageTime > 1.5 then dmgArrow.Visible = false; return end
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then dmgArrow.Visible = false; return end
        local attackerPos = nil
        if lastAttacker and lastAttacker.Character then
            local hrp = lastAttacker.Character:FindFirstChild("HumanoidRootPart")
            if hrp then attackerPos = hrp.Position end
        end
        if not attackerPos then dmgArrow.Visible = false; return end
        local direction = (attackerPos - myHRP.Position)
        local lookVector = Camera.CFrame.LookVector
        local rightVector = Camera.CFrame.RightVector
        local forward = direction:Dot(lookVector)
        local right = direction:Dot(rightVector)
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local angle = math.atan2(right, forward)
        local radius = 120
        local px = center.X + math.sin(angle) * radius
        local py = center.Y - math.cos(angle) * radius
        local size = 14
        local dirX = math.sin(angle)
        local dirY = -math.cos(angle)
        local perpX = -dirY
        local perpY = dirX
        dmgArrow.PointA = Vector2.new(px + dirX * size, py + dirY * size)
        dmgArrow.PointB = Vector2.new(px + perpX * size * 0.7, py + perpY * size * 0.7)
        dmgArrow.PointC = Vector2.new(px - perpX * size * 0.7, py - perpY * size * 0.7)
        local alpha = math.clamp((1.5 - (now - lastDamageTime)) / 1.5, 0, 1)
        dmgArrow.Transparency = 0.15 + (1 - alpha) * 0.7
        dmgArrow.Visible = true
    end)

    -- GRENADE ESP
    local grenadeKeywords = {"grenade", "frag", "flashbang", "smoke", "molotov", "impact", "sticky", "decoy"}
    local grenadeDrawings = {}
    local function isGrenade(obj)
        if not obj or not obj.Parent then return false end
        if not obj:IsA("BasePart") then return false end
        local lower = obj.Name:lower()
        for _, kw in ipairs(grenadeKeywords) do if lower:find(kw) then return true end end
        return false
    end
    local function clearGrenadeDrawings()
        for obj, d in pairs(grenadeDrawings) do
            if d.box then d.box:Remove() end
            if d.name then d.name:Remove() end
        end
        grenadeDrawings = {}
    end
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.espGrenades then clearGrenadeDrawings(); return end
        local activeObjects = {}
        for _, obj in ipairs(workspace:GetChildren()) do
            if isGrenade(obj) then
                activeObjects[obj] = true
                if not grenadeDrawings[obj] then
                    local box = Drawing.new("Square")
                    box.Thickness = 1.5
                    box.Color = Color3.fromRGB(255, 150, 50)
                    box.Filled = false
                    box.Transparency = 1
                    local name = Drawing.new("Text")
                    name.Size = 12; name.Center = true; name.Outline = true
                    name.Color = Color3.fromRGB(255, 200, 100)
                    name.Text = obj.Name
                    grenadeDrawings[obj] = {box = box, name = name}
                end
                local data = grenadeDrawings[obj]
                local sp, onScreen = Camera:WorldToViewportPoint(obj.Position)
                if onScreen then
                    local size = math.clamp(300 / math.max((Camera.CFrame.Position - obj.Position).Magnitude, 1), 8, 100)
                    data.box.Size = Vector2.new(size, size)
                    data.box.Position = Vector2.new(sp.X - size / 2, sp.Y - size / 2)
                    data.box.Visible = true
                    data.name.Position = Vector2.new(sp.X, sp.Y - size / 2 - 12)
                    data.name.Visible = true
                else
                    data.box.Visible = false
                    data.name.Visible = false
                end
            end
        end
        for obj, data in pairs(grenadeDrawings) do
            if not activeObjects[obj] then
                if data.box then data.box:Remove() end
                if data.name then data.name:Remove() end
                grenadeDrawings[obj] = nil
            end
        end
    end)

    -- ESP
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
        data.weapon = newDrawing("Text", {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 200, 100)})
        data.armor = newDrawing("Text", {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(100, 200, 255)})
        ESP.data[p] = data
    end
    local function removeESP(p)
        local d = ESP.data[p]
        if not d then return end
        if d.chams then d.chams:Destroy() end
        for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon", "armor"}) do
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
            for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon", "armor"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon", "armor"}) do
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
            for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon", "armor"}) do
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
            if State.espWeapon then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    d.weapon.Position = Vector2.new(headSp.X, headSp.Y - 34)
                    d.weapon.Text = "[" .. tool.Name .. "]"
                    d.weapon.Visible = true
                else d.weapon.Visible = false end
            else d.weapon.Visible = false end
            if State.espArmor then
                if hum.MaxHealth > 100 then
                    local armorVal = math.floor(hum.MaxHealth - 100)
                    d.armor.Position = Vector2.new(headSp.X, headSp.Y + 8)
                    d.armor.Text = "🛡 " .. armorVal
                    d.armor.Color = Color3.fromRGB(100, 200, 255)
                    d.armor.Visible = true
                else d.armor.Visible = false end
            else d.armor.Visible = false end
        else
            d.name.Visible = false
            d.distance.Visible = false
            d.headDot.Visible = false
            d.weapon.Visible = false
            d.armor.Visible = false
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

    -- SPEED
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.speed then return end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
        end
    end)

    -- AIR JUMP
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
            hrp.Velocity = Vector3.new(hrp.Velocity.X, AIR_JUMP_POWER, hrp.Velocity.Z)
        end)
    end
    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    -- FULLBRIGHT
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

    -- OPTIMIZATIONS
    local optBackup = {
        fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart,
        globalShadows = Lighting.GlobalShadows, qualityLevel = nil,
        atmosphereData = {}, particles = {},
    }
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then
            table.insert(optBackup.atmosphereData, {obj = c, D = c.Density, H = c.Haze, G = c.Glare})
        end
    end
    pcall(function() optBackup.qualityLevel = settings().Rendering.QualityLevel end)

    local function applyLowGraphics(v)
        if v then
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        else
            if optBackup.qualityLevel then
                pcall(function() settings().Rendering.QualityLevel = optBackup.qualityLevel end)
            end
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
        else
            Lighting.FogEnd = optBackup.fogEnd; Lighting.FogStart = optBackup.fogStart
            for _, data in ipairs(optBackup.atmosphereData) do
                if data.obj and data.obj.Parent then
                    pcall(function()
                        data.obj.Density = data.D; data.obj.Haze = data.H; data.obj.Glare = data.G
                    end)
                end
            end
        end
    end
    local function applyNoParticles(v)
        if v then
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Trail") then
                    if optBackup.particles[d] == nil then optBackup.particles[d] = d.Enabled end
                    pcall(function() d.Enabled = false end)
                end
            end
        else
            for obj, orig in pairs(optBackup.particles) do
                if obj and obj.Parent then pcall(function() obj.Enabled = orig end) end
            end
            optBackup.particles = {}
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

    -- CONFIG SYSTEM
    local BASE_FOLDER = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/Jailbird"
    local AUTOLOAD_FILE = "InfiniteZen_Jailbird_Autoload.txt"
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
        if State.lowGraphics then applyLowGraphics(true) end
        if State.noShadows then applyNoShadows(true) end
        if State.noFog then applyNoFog(true) end
        if State.noParticles then applyNoParticles(true) end
        if State.airJump then startAirJump() else stopAirJump() end
        if not State.fullbright then disableFullbright() end
        if not State.headExpander then restoreAllHitboxes() end
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

    -- CRIAR ABAS
    local CombatTab = CreateTab("tab_combat", "⚔️")
    CombatTab.CreateToggle("silent_headshot", "silentHeadshot")
    CombatTab.CreateSlider("silent_fov", 30, 300, 120, "silentFov")
    CombatTab.CreateToggle("aimbot", "aimbot")
    CombatTab.CreateSlider("aimbot_fov", 30, 300, 100, "aimbotFov")
    CombatTab.CreateSlider("aimbot_smooth", 5, 100, 30, "aimbotSmoothness", function(v)
        State.aimbotSmoothness = v / 100
    end)
    CombatTab.CreateToggle("aimbot_wallcheck", "aimbotWallCheck")
    CombatTab.CreateToggle("triggerbot", "triggerbot")
    CombatTab.CreateSlider("triggerbot_delay", 1, 100, 5, "triggerbotDelay")
    CombatTab.CreateToggle("head_expander", "headExpander", function(v)
        if not v then restoreAllHitboxes() end
    end)
    CombatTab.CreateSlider("head_size", 1, 8, 3, "headExpanderSize")
    CombatTab.CreateToggle("backstab", "backstab")

    local WeaponTab = CreateTab("tab_weapon", "🔫")
    WeaponTab.CreateToggle("no_recoil", "noRecoil")
    WeaponTab.CreateToggle("no_spread", "noSpread")
    WeaponTab.CreateToggle("rapid_fire", "rapidFire")
    WeaponTab.CreateToggle("fast_reload", "fastReload", function(v)
        if not v then
            for value, original in pairs(reloadOriginals) do
                if typeof(value) == "Instance" then
                    pcall(function() value.Value = original end)
                end
            end
            reloadOriginals = {}
        end
    end)
    WeaponTab.CreateToggle("insta_reload", "instaReload")
    WeaponTab.CreateToggle("infinite_ammo", "infiniteAmmo")
    WeaponTab.CreateToggle("auto_shoot", "autoShoot")
    WeaponTab.CreateSlider("auto_shoot_fov", 30, 300, 100, "autoShootFov")

    local MovementTab = CreateTab("tab_movement", "🏃")
    MovementTab.CreateToggle("speed", "speed")
    MovementTab.CreateSlider("speed_value", 12, 300, 50, "speedValue")
    MovementTab.CreateToggle("air_jump", "airJump", function(v)
        if v then startAirJump() else stopAirJump() end
    end)
    MovementTab.CreateToggle("auto_bhop", "autoBhop")
    MovementTab.CreateToggle("fullbright", "fullbright", function(v)
        if not v then disableFullbright() end
    end)

    local VisualsTab = CreateTab("tab_visuals", "👁️")
    VisualsTab.CreateToggle("esp", "esp", function(v)
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then createESP(p) end
            end
        else clearAllESP() end
    end)
    VisualsTab.CreateSlider("max_distance", 100, 5000, 500, "espMaxDistance")
    VisualsTab.CreateToggle("weapon_esp", "espWeapon")
    VisualsTab.CreateToggle("armor_esp", "espArmor")
    VisualsTab.CreateToggle("grenade_esp", "espGrenades")
    VisualsTab.CreateToggle("damage_indicator", "damageIndicator")

    local SettingsTab = CreateTab("tab_settings", "⚙️")
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
    SettingsTab.CreateLabel("── Optimizations ──", Theme.Text)
    SettingsTab.CreateLabel("Boost FPS / Reduce lag", Theme.TextDim)
    SettingsTab.CreateToggle("low_graphics", "lowGraphics", function(v) applyLowGraphics(v) end)
    SettingsTab.CreateToggle("no_shadows", "noShadows", function(v) applyNoShadows(v) end)
    SettingsTab.CreateToggle("no_fog", "noFog", function(v) applyNoFog(v) end)
    SettingsTab.CreateToggle("no_particles", "noParticles", function(v) applyNoParticles(v) end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateButton("⚡ Max FPS Boost", function()
        toggleHandles.lowGraphics.SetState(true)
        toggleHandles.noShadows.SetState(true)
        toggleHandles.noFog.SetState(true)
        toggleHandles.noParticles.SetState(true)
        Notify("⚡ Boost", "Otimizações ativadas", 3)
    end)
    SettingsTab.CreateButton("🔄 Reset Optimizations", function()
        toggleHandles.lowGraphics.SetState(false)
        toggleHandles.noShadows.SetState(false)
        toggleHandles.noFog.SetState(false)
        toggleHandles.noParticles.SetState(false)
        Notify("🔄 Reset", "Otimizações desativadas", 3)
    end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateLabel("── Security ──", Theme.Text)
    SettingsTab.CreateLabel("Anti-detection", Theme.TextDim)
    SettingsTab.CreateToggle("anti_flash", "antiFlash")
    SettingsTab.CreateToggle("anti_votekick", "antiVK")
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateButton("unload_script", function()
        UNLOADED = true
        _G.IZ_RefreshLanguage = nil
        clearAllESP()
        clearGrenadeDrawings()
        stopAirJump()
        restoreAllHitboxes()
        disableFullbright()
        applyLowGraphics(false)
        applyNoShadows(false)
        applyNoFog(false)
        applyNoParticles(false)
        if fovCircle then fovCircle:Remove() end
        if dmgArrow then dmgArrow:Remove() end
        GUI:Destroy()
    end, "danger")

    local CreditsTab = CreateTab("tab_credits", "➕")
    CreditsTab.CreateCredit("FOUNDER & DEVELOPER", "Sr Red", Theme.TitleRed)
    CreditsTab.CreateLabel(" ")
    CreditsTab.CreateLabel("── Join our Discord ──", Theme.Text)
    CreditsTab.CreateLabel("https://discord.gg/ScZfU2mAGm", Theme.TextDim)
    local discordBtn = CreditsTab.CreateButton("💬 Join Discord Server", function()
        if setclipboard then setclipboard("https://discord.gg/ScZfU2mAGm"); Notify("📋 Copied", "Discord link copied!", 3) end
    end)
    discordBtn.BackgroundColor3 = Theme.Discord
    CreditsTab.CreateLabel(" ")
    CreditsTab.CreateLabel(FULL_VERSION, Theme.TextDim)
    CreditsTab.CreateLabel("Jailbird Edition", Theme.Warning)
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
                Notify("🚫 Blocked", "K reserved", 4, true)
                recordingKeyFor = nil
                local handle = toggleHandles[featId]
                if handle then handle.SetKeybind(State.keybinds[featId]) end
                return
            end
            local conflictFeat = findFeatureWithKeybind(newKey)
            if conflictFeat and conflictFeat ~= featId then
                Notify("🚫 In Use", newKey .. " → " .. (FeatureLabels[conflictFeat] or conflictFeat), 4, true)
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
        if input.KeyCode == MINIMIZE_KEY then setMinimized(not minimized); return end
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

    task.wait(0.5)
    if IS_JAILBIRD then
        Notify("🎯 " .. SHORT_VERSION, "Carregado!", 4)
    end

    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
    print("[Infinite Zen] Configs em: InfiniteZen_Configs/Jailbird")
end

return Jailbird