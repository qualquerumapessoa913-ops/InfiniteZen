-- ============================================================
-- INFINITE ZEN - MÓDULO ARSENAL v2.0 (LAYERED TEST)
-- Sem Skin System, sem Ghost/Rainbow
-- ============================================================

local Arsenal = {}

function Arsenal.Init(ctx)
    ctx = ctx or {}
    local Language = ctx.Language
    local gameName = ctx.gameName or "Arsenal"

    local GAME_VERSION = "2.0"
    local FULL_VERSION = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    local function STEP(n, msg) pcall(function() print("[IZ Step " .. n .. "] " .. msg) end) end
    STEP(1, "Init começou")

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
    local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    STEP(2, "Services OK")

    local function langGet(key)
        if not Language or type(Language.get) ~= "function" then return key end
        local ok, res = pcall(Language.get, key)
        if ok and res then return res end
        return key
    end
    local function langSet(code)
        if Language and type(Language.setLanguage) == "function" then pcall(Language.setLanguage, code) end
    end
    local function langGetAvailable()
        if not Language or type(Language.getAvailable) ~= "function" then return {} end
        local ok, res = pcall(Language.getAvailable)
        if ok and type(res) == "table" then return res end
        return {}
    end
    local function langGetCurrentData()
        if not Language or type(Language.getCurrentData) ~= "function" then
            return { shortCode = "US", displayName = "English" }
        end
        local ok, res = pcall(Language.getCurrentData)
        if ok and type(res) == "table" then return res end
        return { shortCode = "US", displayName = "English" }
    end

    local langRefresh = {}
    local function registerRefresh(fn)
        table.insert(langRefresh, fn)
        pcall(fn)
    end
    _G.IZ_RefreshLanguage = function()
        for _, fn in ipairs(langRefresh) do pcall(fn) end
    end

    local function getLabel(k)
        if type(k) ~= "string" then return tostring(k) end
        local t = langGet(k)
        if t and t ~= k then return t end
        local f = k:gsub("_", " ")
        f = f:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b:lower() end)
        return f
    end

    STEP(3, "Language wrappers OK")

    -- REMOTES
    local Events = ReplicatedStorage:FindFirstChild("Events")
    local function sfind(p, ...)
        if not p then return nil end
        local c = p
        for _, n in ipairs({...}) do
            if not c then return nil end
            local ok, nx = pcall(function() return c:FindFirstChild(n) end)
            if not ok or not nx then return nil end
            c = nx
        end
        return c
    end
    local Remotes = {
        Look = sfind(Events, "Look"),
        ReloadInstant = sfind(Events, "ReloadInstant"),
        AmmoMod = sfind(Events, "AmmoMod"),
    }
    STEP(4, "Remotes OK")

    -- TEAM
    local function isEnemy(p)
        if p == LocalPlayer then return false end
        if not p.Character then return false end
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        local mt = LocalPlayer.Team
        if mt == nil then return true end
        if p.Team == nil then return false end
        return p.Team ~= mt
    end

    STEP(5, "Team check OK")

    -- STATE
    local State = {
        -- Combat
        killAll = false, killAllDelay = 100,
        killAura = false, killAuraRange = 30, killAuraDelay = 50,
        silentAim = false, silentFov = 120,
        lockBot = false, lockBotFov = 200,
        triggerbot = false, triggerbotDelay = 5,
        autoShot = false, autoShotFov = 100, autoShotDelay = 50,
        aimbot = false, aimbotFov = 100, aimbotSmoothness = 0.3,
        aimbotMaxDist = 500, aimbotHitbox = 1, aimbotWallCheck = true,
        antiAim = false, antiAimMode = 1,
        expanderEnabled = false, hitboxSize = 2,
        fovCircle = false,

        -- Weapon
        noRecoil = false, noSpread = false,
        rapidFire = false, rapidFireValue = 0.03,
        fastReload = false, instaReload = false, autoReload = false,
        infiniteAmmo = false,
        damageMult = false, damageMultValue = 2,
        rangeExtender = false, rangeValue = 5000,
        bulletSpeed = false, bulletSpeedValue = 9999,
        noGravity = false, piercing = false, noMuzzleFlash = false,

        -- Movement
        speed = false, speedValue = 50,
        fly = false, flySpeed = 60,
        infJump = false, jumpPower = 50,
        autoBhop = false, noclip = false, teleportCursor = false,

        -- Visuals
        esp = false, espMaxDistance = 1000,
        espBox = true, espName = true, espHealth = true,
        espDistance = true, espWeapon = true, espTracer = false, espChams = true,
        grenadeEsp = false, damageIndicator = false, fullbright = false,
        thirdPerson = false, cameraFov = false, cameraFovValue = 90,

        -- Extra
        antiFlash = false, antiVK = false, antiAFK = false,
        lowGraphics = false, noShadows = false, noFog = false, noParticles = false,

        keybinds = {
            killAll = nil, killAura = "G", silentAim = "X",
            lockBot = nil, triggerbot = nil, autoShot = nil,
            aimbot = "C", antiAim = nil,
            speed = nil, fly = "F", infJump = nil, autoBhop = nil,
            esp = "V", fullbright = nil, thirdPerson = nil,
        },
    }

    local recordingKeyFor = nil
    local FeatureLabels = {
        killAll = "Kill All", killAura = "Kill Aura", silentAim = "Silent Aim",
        lockBot = "Lock Bot", triggerbot = "Triggerbot", autoShot = "Auto Shot",
        aimbot = "Aimbot", antiAim = "Anti Aim", expanderEnabled = "Head Expander",
        noRecoil = "No-Recoil", noSpread = "No Spread", rapidFire = "Rapid Fire",
        fastReload = "Fast Reload", instaReload = "Insta-Reload",
        infiniteAmmo = "Infinite Ammo", autoReload = "Auto Reload",
        damageMult = "Damage Multiplier", rangeExtender = "Range Extender",
        bulletSpeed = "Bullet Speed", noGravity = "No Gravity",
        piercing = "Piercing", noMuzzleFlash = "No Muzzle Flash",
        speed = "Speed", fly = "Fly", infJump = "Infinite Jump",
        jumpPower = "Jump Power", autoBhop = "Auto Bhop", noclip = "Noclip",
        teleportCursor = "Teleport to Cursor",
        esp = "ESP", grenadeEsp = "Grenade ESP", damageIndicator = "Damage Indicator",
        fullbright = "Fullbright", thirdPerson = "Third Person",
        cameraFov = "Camera FOV", antiFlash = "Anti-Flash", antiVK = "Anti-VoteKick",
        antiAFK = "Anti-AFK", lowGraphics = "Low Graphics", noShadows = "No Shadows",
        noFog = "No Fog", noParticles = "No Particles", fovCircle = "FOV Circle",
        espBox = "Box", espName = "Name", espHealth = "Health",
        espDistance = "Distance", espWeapon = "Weapon", espTracer = "Tracer",
        espChams = "Chams",
    }

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

    STEP(6, "State + Theme OK")

    -- GUI
    local oldMenu = PlayerGui:FindFirstChild("InfiniteZen")
    if oldMenu then oldMenu:Destroy() end

    local GUI = Instance.new("ScreenGui")
    GUI.Name = "InfiniteZen"
    GUI.ResetOnSpawn = false
    local pok = false
    if gethui then pok = pcall(function() GUI.Parent = gethui() end) end
    if not pok then GUI.Parent = PlayerGui end

    STEP(7, "GUI criada")

    -- NOTIFICAÇÕES
    local activeNotifs = {}
    local function Notify(title, content, duration, isError)
        duration = duration or 4
        local idx = #activeNotifs
        local n = Instance.new("Frame")
        n.Size = UDim2.new(0, 260, 0, 62)
        n.Position = UDim2.new(1, 20, 0, 80 + idx * 72)
        n.BackgroundColor3 = Theme.Surface
        n.BorderSizePixel = 0
        n.Parent = GUI
        n.ZIndex = 999
        Instance.new("UICorner", n).CornerRadius = UDim.new(0, 10)
        local col = isError and Theme.Danger or Theme.Warning
        local s = Instance.new("UIStroke", n)
        s.Color = col; s.Thickness = 1.5; s.Transparency = 0.2
        local tl = Instance.new("TextLabel", n)
        tl.Size = UDim2.new(1, -20, 0, 22); tl.Position = UDim2.new(0, 12, 0, 8)
        tl.BackgroundTransparency = 1; tl.Font = Theme.FontBold; tl.TextSize = 12
        tl.TextColor3 = col; tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Text = title; tl.ZIndex = 1000
        local cl = Instance.new("TextLabel", n)
        cl.Size = UDim2.new(1, -20, 0, 30); cl.Position = UDim2.new(0, 12, 0, 28)
        cl.BackgroundTransparency = 1; cl.Font = Theme.Font; cl.TextSize = 11
        cl.TextColor3 = Theme.Text; cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.TextWrapped = true; cl.Text = content; cl.ZIndex = 1000
        table.insert(activeNotifs, n)
        TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -280, 0, 80 + idx * 72)
        }):Play()
        task.delay(duration, function()
            for i, nn in ipairs(activeNotifs) do
                if nn == n then table.remove(activeNotifs, i); break end
            end
            if n and n.Parent then n:Destroy() end
        end)
    end

    local function findFeatureWithKeybind(k)
        for id, kk in pairs(State.keybinds) do
            if kk == k then return id end
        end
        return nil
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
        if not targetPart or not targetPart.Parent or not targetPart:IsA("BasePart") then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local excl = {}
        if LocalPlayer.Character then table.insert(excl, LocalPlayer.Character) end
        table.insert(excl, targetPart.Parent)
        params.FilterDescendantsInstances = excl
        local dir = targetPart.Position - fromPos
        local dist = dir.Magnitude
        if dist < 0.1 then return true end
        local rl = dist - 2
        if rl <= 0 then return true end
        return workspace:Raycast(fromPos + dir.Unit * 2, dir.Unit * rl, params) == nil
    end

    local function getTargetPart(p)
        if not p.Character then return nil end
        local mode = State.aimbotHitbox
        if mode == 1 then return getBasePart(p.Character, "HeadHB", "Head")
        elseif mode == 2 then return getBasePart(p.Character, "Hitbox", "UpperTorso", "Torso")
        elseif mode == 3 then
            for _, n in ipairs({"Hitbox", "HeadHB", "Head", "UpperTorso", "Torso", "HumanoidRootPart"}) do
                local bp = getBasePart(p.Character, n)
                if bp then return bp end
            end
        else
            local h = getBasePart(p.Character, "HeadHB", "Head")
            local t = getBasePart(p.Character, "Hitbox", "UpperTorso", "Torso")
            if h and t then
                local cp = Camera.CFrame.Position
                return (h.Position - cp).Magnitude <= (t.Position - cp).Magnitude and h or t
            end
            return h or t
        end
    end

    local function getMyTool()
        local c = LocalPlayer.Character
        if not c then return nil end
        return c:FindFirstChildOfClass("Tool")
    end

    local function fireWeapon()
        local t = getMyTool()
        if not t then return false end
        if mouse1click then
            local ok = pcall(mouse1click)
            if ok then return true end
        end
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.005)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
        pcall(function() t:Activate() end)
        return true
    end

    STEP(8, "Helpers OK")

    -- MAIN WINDOW
    local MainFrame = Instance.new("Frame", GUI)
    MainFrame.Size = UDim2.new(0, 620, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -310, 0.5, -240)
    MainFrame.BackgroundColor3 = Theme.Bg
    MainFrame.BorderSizePixel = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local guiScale = Instance.new("UIScale")
    guiScale.Scale = IS_MOBILE and 0.72 or 1
    guiScale.Parent = MainFrame

    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Color = Theme.Primary; mainStroke.Thickness = 1.5; mainStroke.Transparency = 0.3

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

    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -40, 0.5, -15)
    MinBtn.BackgroundColor3 = Theme.Surface2; MinBtn.Text = "−"
    MinBtn.Font = Theme.FontBold; MinBtn.TextSize = 18; MinBtn.TextColor3 = Theme.Text; MinBtn.ZIndex = 3
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

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
    end
    MinBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)

    local dragging, dragInput, dragStart, startPos
    local function updateDrag(input)
        local d = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
    local function makeDraggable(el)
        el.InputBegan:Connect(function(input)
            if UNLOADED then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        el.InputChanged:Connect(function(input)
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

    STEP(9, "Window OK")

    -- TABS
    local tabs, toggleHandles, sliderHandles, dropdownHandles = {}, {}, {}, {}

    local function CreateTab(label, icon)
        local tab = {}
        local btn = Instance.new("TextButton", Sidebar)
        btn.Size = UDim2.new(1, -16, 0, 38); btn.Position = UDim2.new(0, 8, 0, 8 + #tabs * 44)
        btn.BackgroundColor3 = Theme.Surface; btn.BorderSizePixel = 0
        btn.Text = "  " .. icon .. "   " .. label
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
        local lay = Instance.new("UIListLayout", container)
        lay.Padding = UDim.new(0, 6)
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
            local h = Instance.new("Frame", container)
            h.Size = UDim2.new(1, -10, 0, 36)
            h.BackgroundColor3 = Theme.Surface; h.BorderSizePixel = 0
            Instance.new("UICorner", h).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", h)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7
            local lbl = Instance.new("TextLabel", h)
            lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.BackgroundTransparency = 1; lbl.Font = Theme.Font; lbl.TextSize = 12
            lbl.TextColor3 = Theme.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = ""
            registerRefresh(function() lbl.Text = getLabel(labelKey) end)
            local kb = Instance.new("TextButton", h)
            kb.Size = UDim2.new(0, 50, 0, 22); kb.Position = UDim2.new(0.55, 0, 0.5, -11)
            kb.BackgroundColor3 = State.keybinds[featureId] and Theme.Primary or Theme.Surface2
            kb.Text = State.keybinds[featureId] or "KEY"
            kb.Font = Theme.FontBold; kb.TextSize = 11
            kb.TextColor3 = State.keybinds[featureId] and Theme.Text or Theme.TextDim
            kb.AutoButtonColor = false
            Instance.new("UICorner", kb).CornerRadius = UDim.new(0, 6)
            local tb = Instance.new("TextButton", h)
            tb.Size = UDim2.new(0, 50, 0, 22); tb.Position = UDim2.new(1, -58, 0.5, -11)
            tb.BackgroundColor3 = State[featureId] and Theme.Success or Theme.Surface2
            tb.Font = Theme.FontBold; tb.TextSize = 11; tb.TextColor3 = Theme.Text
            tb.Text = State[featureId] and "ON" or "OFF"
            tb.AutoButtonColor = false
            Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
            local function setState(v, silent)
                State[featureId] = v
                tb.Text = v and "ON" or "OFF"
                tb.BackgroundColor3 = v and Theme.Success or Theme.Surface2
                if not silent and callback then pcall(callback, v) end
            end
            local function tog() setState(not State[featureId]) end
            tb.MouseButton1Click:Connect(tog)
            kb.MouseButton1Click:Connect(function()
                if recordingKeyFor then return end
                recordingKeyFor = featureId
                kb.Text = "..."
                kb.BackgroundColor3 = Theme.Warning
                kb.TextColor3 = Theme.Text
            end)
            local handle = {
                SetState = setState, Toggle = tog,
                SetKeybind = function(key)
                    State.keybinds[featureId] = key
                    if key then
                        kb.Text = key; kb.BackgroundColor3 = Theme.Primary; kb.TextColor3 = Theme.Text
                    else
                        kb.Text = "KEY"; kb.BackgroundColor3 = Theme.Surface2; kb.TextColor3 = Theme.TextDim
                    end
                end,
            }
            toggleHandles[featureId] = handle
            return handle
        end

        tab.CreateSlider = function(labelKey, min, max, defaultValue, featureId, callback)
            local h = Instance.new("Frame", container)
            h.Size = UDim2.new(1, -10, 0, 44)
            h.BackgroundColor3 = Theme.Surface; h.BorderSizePixel = 0
            Instance.new("UICorner", h).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", h)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7
            local lbl = Instance.new("TextLabel", h)
            lbl.Size = UDim2.new(0.6, 0, 0, 18); lbl.Position = UDim2.new(0, 12, 0, 4)
            lbl.BackgroundTransparency = 1; lbl.Font = Theme.Font; lbl.TextSize = 11
            lbl.TextColor3 = Theme.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = ""
            registerRefresh(function() lbl.Text = getLabel(labelKey) end)
            local vl = Instance.new("TextLabel", h)
            vl.Size = UDim2.new(0.35, 0, 0, 18); vl.Position = UDim2.new(0.6, 0, 0, 4)
            vl.BackgroundTransparency = 1; vl.Font = Theme.FontBold; vl.TextSize = 11
            vl.TextColor3 = Theme.Primary; vl.Text = tostring(defaultValue or min)
            vl.TextXAlignment = Enum.TextXAlignment.Right
            local bg = Instance.new("Frame", h)
            bg.Size = UDim2.new(1, -24, 0, 5); bg.Position = UDim2.new(0, 12, 0, 30)
            bg.BackgroundColor3 = Theme.Surface2; bg.BorderSizePixel = 0
            Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
            local cur = defaultValue or min
            local rel = (cur - min) / (max - min)
            local fill = Instance.new("Frame", bg)
            fill.Size = UDim2.new(rel, 0, 1, 0); fill.BackgroundColor3 = Theme.Primary
            fill.BorderSizePixel = 0
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
            local click = Instance.new("TextButton", h)
            click.Size = UDim2.new(1, -24, 0, 22); click.Position = UDim2.new(0, 12, 0, 22)
            click.BackgroundTransparency = 1; click.Text = ""; click.AutoButtonColor = false; click.ZIndex = 5
            local activeInput = nil
            local function update(posX)
                local p = bg.AbsolutePosition
                local s = bg.AbsoluteSize
                if s.X <= 0 then return end
                local rx = math.clamp((posX - p.X) / s.X, 0, 1)
                local v = math.floor(min + (max - min) * rx)
                cur = v
                fill.Size = UDim2.new(rx, 0, 1, 0)
                vl.Text = tostring(v)
                State[featureId] = v
                if callback then pcall(callback, v) end
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
                    vl.Text = tostring(cur)
                    State[featureId] = cur
                    if callback then pcall(callback, cur) end
                end
            }
            sliderHandles[featureId] = handle
            return handle
        end

        tab.CreateDropdown = function(labelKey, options, featureId, callback)
            local h = Instance.new("Frame", container)
            h.Size = UDim2.new(1, -10, 0, 36)
            h.BackgroundColor3 = Theme.Surface; h.BorderSizePixel = 0
            Instance.new("UICorner", h).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", h)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7
            local lbl = Instance.new("TextLabel", h)
            lbl.Size = UDim2.new(0.4, 0, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.BackgroundTransparency = 1; lbl.Font = Theme.Font; lbl.TextSize = 12
            lbl.TextColor3 = Theme.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left
            registerRefresh(function() lbl.Text = getLabel(labelKey) end)
            local curIdx = State[featureId] or 1
            local sb = Instance.new("TextButton", h)
            sb.Size = UDim2.new(0.55, 0, 0, 22); sb.Position = UDim2.new(0.44, 0, 0.5, -11)
            sb.BackgroundColor3 = Theme.Surface2
            sb.Text = options[curIdx] or "?"
            sb.Font = Theme.FontBold; sb.TextSize = 11
            sb.TextColor3 = Theme.Text; sb.AutoButtonColor = false
            Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 6)
            local dd = Instance.new("Frame", h)
            dd.Size = UDim2.new(0.55, 0, 0, #options * 26 + 4)
            dd.Position = UDim2.new(0.44, 0, 1, 2)
            dd.BackgroundColor3 = Theme.Surface2
            dd.BorderSizePixel = 0; dd.Visible = false; dd.ZIndex = 20
            Instance.new("UICorner", dd).CornerRadius = UDim.new(0, 6)
            local dl = Instance.new("UIListLayout", dd)
            dl.Padding = UDim.new(0, 0)
            for i, opt in ipairs(options) do
                local ob = Instance.new("TextButton", dd)
                ob.Size = UDim2.new(1, 0, 0, 24)
                ob.BackgroundColor3 = Theme.Surface
                ob.Text = opt; ob.Font = Theme.Font; ob.TextSize = 11
                ob.TextColor3 = Theme.Text; ob.AutoButtonColor = false
                ob.ZIndex = 21
                ob.MouseButton1Click:Connect(function()
                    curIdx = i
                    sb.Text = opt
                    State[featureId] = i
                    dd.Visible = false
                    if callback then pcall(callback, i, opt) end
                end)
            end
            sb.MouseButton1Click:Connect(function() dd.Visible = not dd.Visible end)
            local handle = {
                SetValue = function(i)
                    curIdx = math.clamp(i, 1, #options)
                    sb.Text = options[curIdx]
                    State[featureId] = curIdx
                    if callback then pcall(callback, curIdx, options[curIdx]) end
                end,
            }
            dropdownHandles[featureId] = handle
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
            btn.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)
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

        return tab
    end

    STEP(10, "CreateTab OK")

    -- FOV CIRCLE
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Theme.Primary; fovCircle.Thickness = 1.5
    fovCircle.Filled = false; fovCircle.NumSides = 100; fovCircle.Transparency = 1
    fovCircle.Radius = 25; fovCircle.Visible = false

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        if not State.fovCircle then fovCircle.Visible = false; return end
        local m = UserInputService:GetMouseLocation()
        fovCircle.Position = Vector2.new(m.X, m.Y)
        if State.silentAim then
            fovCircle.Visible = true; fovCircle.Radius = State.silentFov / 6
        elseif State.autoShot then
            fovCircle.Visible = true; fovCircle.Radius = State.autoShotFov / 6
        elseif State.aimbot then
            fovCircle.Visible = true; fovCircle.Radius = State.aimbotFov / 6
        elseif State.lockBot then
            fovCircle.Visible = true; fovCircle.Radius = State.lockBotFov / 6
        else
            fovCircle.Visible = false
        end
    end)

    STEP(11, "FOV Circle OK")

    -- TARGETING
    local function getClosestEnemyInFov(fovRange, requireLOS)
        local m = UserInputService:GetMouseLocation()
        local closest, minD = nil, fovRange
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, d = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and d and d > 0 then
                        local dist = (Vector2.new(sp.X, sp.Y) - Vector2.new(m.X, m.Y)).Magnitude
                        if dist and dist < minD then
                            if not requireLOS or hasLineOfSight(Camera.CFrame.Position, part) then
                                minD = dist; closest = p
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    STEP(12, "Targeting OK")

    -- COMBAT
    local silentHolding, silentTarget, silentOrigCF = false, nil, nil

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then silentHolding = false; return end
        local part = getTargetPart(silentTarget)
        if not part then silentHolding = false; return end
        local newCF = CFrame.new(Camera.CFrame.Position, part.Position)
        pcall(function() Camera.CFrame = newCF end)
        if Remotes.Look then pcall(function() Remotes.Look:FireServer(newCF) end) end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.silentAim then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        silentOrigCF = Camera.CFrame
        local target = getClosestEnemyInFov(State.silentFov, State.aimbotWallCheck)
        if not target then return end
        silentTarget = target
        silentHolding = true
        local part = getTargetPart(target)
        if part then
            local newCF = CFrame.new(Camera.CFrame.Position, part.Position)
            pcall(function() Camera.CFrame = newCF end)
            if Remotes.Look then pcall(function() Remotes.Look:FireServer(newCF) end) end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if silentHolding then
            silentHolding = false
            silentTarget = nil
            if silentOrigCF then
                pcall(function() Camera.CFrame = silentOrigCF end)
                if Remotes.Look then pcall(function() Remotes.Look:FireServer(silentOrigCF) end) end
                silentOrigCF = nil
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.aimbot then return end
        local target = getClosestEnemyInFov(State.aimbotFov, State.aimbotWallCheck)
        if target then
            local part = getTargetPart(target)
            if part then
                local myR = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myR then
                    local d3 = (part.Position - myR.Position).Magnitude
                    if d3 <= State.aimbotMaxDist then
                        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local m = UserInputService:GetMouseLocation()
                            if mousemoverel then pcall(function() mousemoverel((sp.X - m.X) * State.aimbotSmoothness, (sp.Y - m.Y) * State.aimbotSmoothness) end) end
                        end
                    end
                end
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.lockBot then return end
        local target = getClosestEnemyInFov(State.lockBotFov, false)
        if target then
            local part = getTargetPart(target)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local m = UserInputService:GetMouseLocation()
                    if mousemoverel then pcall(function() mousemoverel(sp.X - m.X, sp.Y - m.Y) end) end
                end
                fireWeapon()
            end
        end
    end)

    local triggerLast = 0
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.triggerbot then return end
        if tick() - triggerLast < (State.triggerbotDelay / 1000) then return end
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, d = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and d and d > 0 then
                        if (Vector2.new(sp.X, sp.Y) - center).Magnitude < 25 then
                            triggerLast = tick()
                            fireWeapon()
                            break
                        end
                    end
                end
            end
        end
    end)

    local lastAutoShot = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoShot then return end
        if tick() - lastAutoShot < (State.autoShotDelay / 1000) then return end
        local target = getClosestEnemyInFov(State.autoShotFov, State.aimbotWallCheck)
        if target then
            lastAutoShot = tick()
            fireWeapon()
        end
    end)

    STEP(13, "Combat OK")

    -- KILL AURA
    local killAuraActive = false
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.killAura then return end
        if killAuraActive then return end
        local char = LocalPlayer.Character
        if not char then return end
        local myR = getBasePart(char, "HumanoidRootPart")
        if not myR then return end
        killAuraActive = true
        task.spawn(function()
            local origCF = myR.CFrame
            for _, p in ipairs(Players:GetPlayers()) do
                if UNLOADED then break end
                if isEnemy(p) and p.Character then
                    local tR = getBasePart(p.Character, "HumanoidRootPart")
                    if tR then
                        local dist = (tR.Position - origCF.Position).Magnitude
                        if dist <= State.killAuraRange then
                            pcall(function() myR.CFrame = tR.CFrame * CFrame.new(0, 0, 2) end)
                            task.wait(0.02)
                            fireWeapon()
                            task.wait(State.killAuraDelay / 1000)
                        end
                    end
                end
            end
            if myR and myR.Parent then pcall(function() myR.CFrame = origCF end) end
            killAuraActive = false
        end)
    end)

    STEP(14, "Kill Aura OK")

    -- WEAPON MODS
    local reloadOriginals = {}
    local weaponAcc = 0

    RunService.Heartbeat:Connect(function(dt)
        if UNLOADED then return end
        weaponAcc = weaponAcc + dt
        if weaponAcc < 0.25 then return end
        weaponAcc = 0

        if State.instaReload and Remotes.ReloadInstant then
            pcall(function() Remotes.ReloadInstant:FireServer() end)
        end
        if State.infiniteAmmo and Remotes.AmmoMod then
            pcall(function() Remotes.AmmoMod:FireServer("infinite") end)
        end

        local anyMod = State.rapidFire or State.noRecoil or State.fastReload or State.instaReload
            or State.noSpread or State.infiniteAmmo or State.rangeExtender or State.bulletSpeed
            or State.damageMult or State.piercing or State.noGravity or State.noMuzzleFlash

        if not anyMod then
            if next(reloadOriginals) then
                local char = LocalPlayer.Character
                if char then
                    local conts = {char}
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if bp then table.insert(conts, bp) end
                    for _, cont in ipairs(conts) do
                        for _, tool in ipairs(cont:GetChildren()) do
                            if tool:IsA("Tool") then
                                pcall(function()
                                    for _, d in ipairs(tool:GetDescendants()) do
                                        local k = "dmg_" .. tostring(d)
                                        if reloadOriginals[k] and (d:IsA("NumberValue") or d:IsA("IntValue")) then
                                            d.Value = reloadOriginals[k]
                                            reloadOriginals[k] = nil
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            return
        end

        local char = LocalPlayer.Character
        if not char then return end
        local conts = {char}
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then table.insert(conts, bp) end

        for _, cont in ipairs(conts) do
            for _, tool in ipairs(cont:GetChildren()) do
                if tool:IsA("Tool") then
                    pcall(function()
                        local desc = tool:GetDescendants()
                        if State.rapidFire then
                            for _, nm in ipairs({"FireRate", "BFireRate", "RateOfFire", "ShootCooldown", "FireDelay"}) do
                                local f = tool:FindFirstChild(nm)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then f.Value = State.rapidFireValue
                                elseif typeof(tool[nm]) == "number" then tool[nm] = State.rapidFireValue end
                            end
                        end
                        if State.noRecoil or State.noSpread then
                            for _, d in ipairs(desc) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if State.noRecoil and (n:find("recoil") or n:find("kick")) then d.Value = 0 end
                                    if State.noSpread and (n:find("spread") or n:find("accuracy") or n:find("deviation")) then d.Value = 0 end
                                end
                            end
                        end
                        if State.infiniteAmmo then
                            for _, d in ipairs(desc) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("ammo") or n:find("magazine") or n == "mag" then d.Value = 9999 end
                                end
                            end
                        end
                        if State.fastReload and not State.instaReload then
                            for _, d in ipairs(desc) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    if d.Name:lower():find("reload") and not d.Name:lower():find("reloading") then
                                        if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                        d.Value = reloadOriginals[d] * 0.2
                                    end
                                end
                            end
                        end
                        if State.damageMult then
                            for _, d in ipairs(desc) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("damage") or n == "dmg" then
                                        local k = "dmg_" .. tostring(d)
                                        if not reloadOriginals[k] then reloadOriginals[k] = d.Value end
                                        d.Value = reloadOriginals[k] * State.damageMultValue
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
    end)

    local lastAutoReload = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoReload then return end
        if tick() - lastAutoReload < 0.5 then return end
        lastAutoReload = tick()
        local tool = getMyTool()
        if tool then pcall(function() tool:Activate() end) end
    end)

    STEP(15, "Weapon mods OK")

    -- MOVEMENT
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.speed then return end
        local c = LocalPlayer.Character
        if c then
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
        end
    end)

    local flyV, flyG = nil, nil
    local function startFly()
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        if flyV then flyV:Destroy() end
        if flyG then flyG:Destroy() end
        flyV = Instance.new("BodyVelocity")
        flyV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyV.Velocity = Vector3.zero
        flyV.Parent = h
        flyG = Instance.new("BodyGyro")
        flyG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyG.P = 1e4
        flyG.CFrame = h.CFrame
        flyG.Parent = h
    end
    local function stopFly()
        if flyV then flyV:Destroy(); flyV = nil end
        if flyG then flyG:Destroy(); flyG = nil end
    end
    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if not State.fly then
            if flyV then stopFly() end
            return
        end
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        if not flyV then startFly() end
        if not flyV or not flyG then return end
        pcall(function() flyG.CFrame = Camera.CFrame end)
        local mv = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0, 1, 0) end
        if mv.Magnitude > 0 then
            flyV.Velocity = mv.Unit * State.flySpeed
        else
            flyV.Velocity = Vector3.zero
        end
    end)

    local infJumpConn = nil
    local function startInfJump()
        if infJumpConn then infJumpConn:Disconnect() end
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED or not State.infJump then return end
            local c = LocalPlayer.Character
            if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart")
            local hum = c:FindFirstChildOfClass("Humanoid")
            if not h or not hum then return end
            if hum:GetState() == Enum.HumanoidStateType.Dead then return end
            h.Velocity = Vector3.new(h.Velocity.X, State.jumpPower, h.Velocity.Z)
        end)
    end
    local function stopInfJump()
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoBhop then return end
        local c = LocalPlayer.Character
        if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Landed or st == Enum.HumanoidStateType.Running then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then hum.Jump = true end
        end
    end)

    RunService.Stepped:Connect(function()
        if UNLOADED or not State.noclip then return end
        local c = LocalPlayer.Character
        if not c then return end
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                pcall(function() part.CanCollide = false end)
            end
        end
    end)

    STEP(16, "Movement OK")

    -- ESP
    local ESP = {data = {}}
    local function createESP(p)
        if ESP.data[p] or not p.Character then return end
        local data = {}
        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Theme.Primary; chams.FillTransparency = 0.6
        chams.OutlineColor = Color3.fromRGB(255, 255, 255); chams.OutlineTransparency = 0.3
        chams.Parent = p.Character
        data.chams = chams
        local function nd(class, props)
            local d = Drawing.new(class)
            for k, v in pairs(props) do d[k] = v end
            d.Visible = false
            return d
        end
        data.box = nd("Square", {Thickness = 1.5, Color = Theme.Primary, Filled = false, Transparency = 1})
        data.name = nd("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        data.distance = nd("Text", {Size = 12, Center = true, Outline = true, Color = Theme.TitleRed})
        data.health = nd("Line", {Thickness = 3, Color = Color3.fromRGB(0, 255, 0)})
        data.tracer = nd("Line", {Thickness = 1.2, Color = Theme.Primary})
        data.headDot = nd("Circle", {Radius = 4, NumSides = 20, Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255)})
        data.weapon = nd("Text", {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 200, 100)})
        ESP.data[p] = data
    end
    local function removeESP(p)
        local d = ESP.data[p]
        if not d then return end
        if d.chams then pcall(function() d.chams:Destroy() end) end
        for _, k in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon"}) do
            if d[k] then pcall(function() d[k]:Remove() end) end
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
            for _, k in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon"}) do
                if d[k] then d[k].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            for _, k in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon"}) do
                if d[k] then d[k].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local head = getBasePart(char, "Head")
        local hrp = getBasePart(char, "HumanoidRootPart")
        if not head or not hrp then return end
        if d.chams then d.chams.Enabled = State.espChams end
        local hSp, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local rSp, rOn = Camera:WorldToViewportPoint(hrp.Position)
        local fSp, fOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local myR = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myR then return end
        local dist = math.floor((head.Position - myR.Position).Magnitude)
        if dist > State.espMaxDistance then
            for _, k in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon"}) do
                if d[k] then d[k].Visible = false end
            end
            return
        end
        if hOn and fOn and State.espBox then
            local h = math.abs(fSp.Y - hSp.Y)
            local w = h * 0.6
            local cx = (hSp.X + fSp.X) / 2
            local cy = (hSp.Y + fSp.Y) / 2
            d.box.Position = Vector2.new(cx - w / 2, cy - h / 2)
            d.box.Size = Vector2.new(w, h)
            d.box.Visible = true
        else d.box.Visible = false end
        if hOn then
            if State.espName then
                d.name.Position = Vector2.new(hSp.X, hSp.Y - 20)
                d.name.Text = p.Name; d.name.Visible = true
            else d.name.Visible = false end
            if State.espDistance then
                d.distance.Position = Vector2.new(hSp.X, hSp.Y - 6)
                d.distance.Text = dist .. "m"; d.distance.Visible = true
            else d.distance.Visible = false end
            d.headDot.Position = Vector2.new(hSp.X, hSp.Y); d.headDot.Visible = true
            if State.espWeapon then
                local t = char:FindFirstChildOfClass("Tool")
                if t then
                    d.weapon.Position = Vector2.new(hSp.X, hSp.Y - 34)
                    d.weapon.Text = "[" .. t.Name .. "]"; d.weapon.Visible = true
                else d.weapon.Visible = false end
            else d.weapon.Visible = false end
        else
            d.name.Visible = false; d.distance.Visible = false
            d.headDot.Visible = false; d.weapon.Visible = false
        end
        if hOn and fOn and State.espHealth then
            local h = math.abs(fSp.Y - hSp.Y)
            local maxHP = hum.MaxHealth
            local hr = (maxHP and maxHP > 0) and math.clamp(hum.Health / maxHP, 0, 1) or 1
            local bx = hSp.X + (h * 0.6) / 2 + 5
            local by = hSp.Y + h
            d.health.From = Vector2.new(bx, by - h * hr)
            d.health.To = Vector2.new(bx, by)
            if hr > 0.6 then d.health.Color = Color3.fromRGB(0, 255, 0)
            elseif hr > 0.3 then d.health.Color = Color3.fromRGB(255, 200, 0)
            else d.health.Color = Color3.fromRGB(255, 40, 40) end
            d.health.Visible = true
        else d.health.Visible = false end
        if rOn and State.espTracer then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To = Vector2.new(rSp.X, rSp.Y)
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

    -- FULLBRIGHT
    local origB = Lighting.Brightness
    local origA = Lighting.Ambient
    local origOA = Lighting.OutdoorAmbient
    local origCT = Lighting.ClockTime
    local origGS = Lighting.GlobalShadows
    local origAtmos = {}
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then
            table.insert(origAtmos, {obj = c, D = c.Density, H = c.Haze, G = c.Glare})
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
    local function disableFB()
        Lighting.Brightness = origB
        Lighting.Ambient = origA
        Lighting.OutdoorAmbient = origOA
        Lighting.ClockTime = origCT
        Lighting.GlobalShadows = origGS
        for _, d in ipairs(origAtmos) do
            if d.obj and d.obj.Parent then
                pcall(function()
                    d.obj.Density = d.D; d.obj.Haze = d.H; d.obj.Glare = d.G
                end)
            end
        end
    end

    STEP(17, "Visuals OK")

    -- OPTIMIZATIONS
    local optBak = {
        fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart,
        qualityLevel = nil, particles = {},
    }
    pcall(function() optBak.qualityLevel = settings().Rendering.QualityLevel end)

    local function applyLG(v)
        if v then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        elseif optBak.qualityLevel then pcall(function() settings().Rendering.QualityLevel = optBak.qualityLevel end) end
    end
    local function applyNS(v)
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                pcall(function() d.CastShadow = not v end)
            end
        end
    end
    local function applyNF(v)
        if v then
            Lighting.FogEnd = 100000; Lighting.FogStart = 0
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Atmosphere") then c.Density = 0; c.Haze = 0; c.Glare = 0 end
            end
        else
            Lighting.FogEnd = optBak.fogEnd; Lighting.FogStart = optBak.fogStart
        end
    end
    local function applyNP(v)
        if v then
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Trail") then
                    if optBak.particles[d] == nil then optBak.particles[d] = d.Enabled end
                    pcall(function() d.Enabled = false end)
                end
            end
        else
            for obj, orig in pairs(optBak.particles) do
                if obj and obj.Parent then pcall(function() obj.Enabled = orig end) end
            end
            optBak.particles = {}
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
    local BF = "InfiniteZen_Configs"
    local CF = BF .. "/Arsenal"
    local AF = "InfiniteZen_Arsenal_Autoload.txt"
    local function ensureFolder()
        if makefolder then
            if not isfolder(BF) then pcall(function() makefolder(BF) end) end
            if not isfolder(CF) then pcall(function() makefolder(CF) end) end
        end
    end
    local function cfgPath(n) return CF .. "/" .. n .. ".json" end

    local function saveCfg(n)
        ensureFolder()
        local data = {version = GAME_VERSION, state = {}, keybinds = State.keybinds}
        for k, v in pairs(State) do
            if k ~= "keybinds" and type(v) ~= "function" and type(v) ~= "userdata" then
                data.state[k] = v
            end
        end
        local ok, js = pcall(function() return HttpService:JSONEncode(data) end)
        if not ok or not js then Notify("Error", "Encode fail", 4, true); return false end
        local w = pcall(function() writefile(cfgPath(n), js) end)
        if w then Notify("Config", "Saved: " .. n, 3); return true
        else Notify("Error", "Failed", 4, true); return false end
    end

    local function loadCfg(n)
        local ok, c = pcall(function() return readfile(cfgPath(n)) end)
        if not ok or not c then Notify("Error", "Not found", 4, true); return false end
        local suc, data = pcall(function() return HttpService:JSONDecode(c) end)
        if not suc or not data then Notify("Error", "Corrupted", 4, true); return false end
        if data.state then for k, v in pairs(data.state) do State[k] = v end end
        if data.keybinds then for k, v in pairs(data.keybinds) do State.keybinds[k] = v end end
        for fid, h in pairs(toggleHandles) do
            if State[fid] ~= nil then h.SetState(State[fid], true) end
            h.SetKeybind(State.keybinds[fid])
        end
        for fid, h in pairs(sliderHandles) do
            if State[fid] ~= nil then h.SetValue(State[fid]) end
        end
        if State.lowGraphics then applyLG(true) end
        if State.noShadows then applyNS(true) end
        if State.noFog then applyNF(true) end
        if State.noParticles then applyNP(true) end
        if not State.fullbright then disableFB() end
        Notify("Load", "Loaded: " .. n, 3)
        return true
    end

    local function delCfg(n)
        local p = cfgPath(n)
        if isfile and isfile(p) then
            pcall(function() delfile(p) end)
            Notify("Delete", "Deleted", 3); return true
        end
        return false
    end

    local function listCfgs()
        local l = {}
        if listfiles and isfolder and isfolder(CF) then
            for _, f in ipairs(listfiles(CF)) do
                if f:sub(-5) == ".json" then
                    local n = f:match("([^/\\]+)%.json$")
                    if n then table.insert(l, n) end
                end
            end
        end
        return l
    end

    STEP(18, "Config system OK")

    -- TABS
    local CombatTab = CreateTab("Combat", "⚔️")
    CombatTab.CreateToggle("kill_aura", "killAura")
    CombatTab.CreateSlider("kill_aura_range", 5, 100, 30, "killAuraRange")
    CombatTab.CreateSlider("kill_aura_delay", 10, 500, 50, "killAuraDelay")
    CombatTab.CreateToggle("silent_aim", "silentAim")
    CombatTab.CreateSlider("silent_fov", 30, 300, 120, "silentFov")
    CombatTab.CreateToggle("aimbot", "aimbot")
    CombatTab.CreateSlider("aimbot_fov", 30, 300, 100, "aimbotFov")
    CombatTab.CreateSlider("aimbot_smooth", 5, 100, 30, "aimbotSmoothness", function(v)
        State.aimbotSmoothness = v / 100
    end)
    CombatTab.CreateToggle("aimbot_wallcheck", "aimbotWallCheck")
    CombatTab.CreateToggle("lock_bot", "lockBot")
    CombatTab.CreateSlider("lock_bot_fov", 50, 400, 200, "lockBotFov")
    CombatTab.CreateToggle("triggerbot", "triggerbot")
    CombatTab.CreateSlider("triggerbot_delay", 1, 100, 5, "triggerbotDelay")
    CombatTab.CreateToggle("auto_shot", "autoShot")
    CombatTab.CreateSlider("auto_shot_fov", 30, 300, 100, "autoShotFov")
    CombatTab.CreateToggle("fov_circle", "fovCircle")

    local WeaponTab = CreateTab("Weapon", "🔫")
    WeaponTab.CreateToggle("no_recoil", "noRecoil")
    WeaponTab.CreateToggle("no_spread", "noSpread")
    WeaponTab.CreateToggle("rapid_fire", "rapidFire")
    WeaponTab.CreateSlider("rapid_fire_value", 1, 100, 3, "rapidFireValue", function(v)
        State.rapidFireValue = v / 100
    end)
    WeaponTab.CreateToggle("fast_reload", "fastReload")
    WeaponTab.CreateToggle("insta_reload", "instaReload")
    WeaponTab.CreateToggle("auto_reload", "autoReload")
    WeaponTab.CreateToggle("infinite_ammo", "infiniteAmmo")
    WeaponTab.CreateToggle("damage_mult", "damageMult")
    WeaponTab.CreateSlider("damage_mult_value", 1, 20, 2, "damageMultValue")

    local MovementTab = CreateTab("Movement", "🏃")
    MovementTab.CreateToggle("speed", "speed")
    MovementTab.CreateSlider("speed_value", 16, 300, 50, "speedValue")
    MovementTab.CreateToggle("fly", "fly")
    MovementTab.CreateSlider("fly_speed", 10, 500, 60, "flySpeed")
    MovementTab.CreateToggle("inf_jump", "infJump")
    MovementTab.CreateSlider("jump_power", 30, 300, 50, "jumpPower")
    MovementTab.CreateToggle("auto_bhop", "autoBhop")
    MovementTab.CreateToggle("noclip", "noclip")

    local VisualsTab = CreateTab("Visuals", "👁️")
    VisualsTab.CreateToggle("esp", "esp", function(v)
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then createESP(p) end
            end
        else clearAllESP() end
    end)
    VisualsTab.CreateSlider("esp_max_distance", 100, 5000, 1000, "espMaxDistance")
    VisualsTab.CreateToggle("esp_box", "espBox")
    VisualsTab.CreateToggle("esp_name", "espName")
    VisualsTab.CreateToggle("esp_health", "espHealth")
    VisualsTab.CreateToggle("esp_distance", "espDistance")
    VisualsTab.CreateToggle("esp_weapon", "espWeapon")
    VisualsTab.CreateToggle("esp_tracer", "espTracer")
    VisualsTab.CreateToggle("esp_chams", "espChams")
    VisualsTab.CreateToggle("fullbright", "fullbright", function(v)
        if not v then disableFB() end
    end)

    local SettingsTab = CreateTab("Settings", "⚙️")
    SettingsTab.CreateLabel("Configs", Theme.Text)
    local refreshRef = nil
    SettingsTab.CreateTextBox("Config name...", function(n)
        if saveCfg(n) and refreshRef then refreshRef() end
    end)
    local configFrame = Instance.new("Frame", SettingsTab.container)
    configFrame.Size = UDim2.new(1, -10, 0, 140)
    configFrame.BackgroundColor3 = Theme.Surface
    configFrame.BorderSizePixel = 0
    Instance.new("UICorner", configFrame).CornerRadius = UDim.new(0, 6)

    local cScroll = Instance.new("ScrollingFrame", configFrame)
    cScroll.Size = UDim2.new(1, -10, 1, -10)
    cScroll.Position = UDim2.new(0, 5, 0, 5)
    cScroll.BackgroundTransparency = 1
    cScroll.BorderSizePixel = 0
    cScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    cScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    cScroll.ScrollBarThickness = 4
    cScroll.ScrollBarImageColor3 = Theme.Primary
    local cl = Instance.new("UIListLayout", cScroll)
    cl.Padding = UDim.new(0, 4)

    local function refreshList()
        for _, c in ipairs(cScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        local cfgs = listCfgs()
        if #cfgs == 0 then
            local e = Instance.new("TextLabel", cScroll)
            e.Size = UDim2.new(1, 0, 0, 30)
            e.BackgroundTransparency = 1
            e.Font = Theme.Font
            e.TextSize = 11
            e.TextColor3 = Theme.TextDim
            e.Text = "No configs saved."
            return
        end
        for _, cn in ipairs(cfgs) do
            local entry = Instance.new("Frame", cScroll)
            entry.Size = UDim2.new(1, -4, 0, 30)
            entry.BackgroundColor3 = Theme.Surface2
            entry.BorderSizePixel = 0
            Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 4)
            local nl = Instance.new("TextLabel", entry)
            nl.Size = UDim2.new(0.5, 0, 1, 0)
            nl.Position = UDim2.new(0, 8, 0, 0)
            nl.BackgroundTransparency = 1
            nl.Font = Theme.Font
            nl.TextSize = 11
            nl.TextColor3 = Theme.Text
            nl.Text = cn
            nl.TextXAlignment = Enum.TextXAlignment.Left
            local lb = Instance.new("TextButton", entry)
            lb.Size = UDim2.new(0, 50, 0, 22); lb.Position = UDim2.new(1, -80, 0.5, -11)
            lb.BackgroundColor3 = Theme.Primary; lb.Text = "Load"
            lb.Font = Theme.FontBold; lb.TextSize = 10; lb.TextColor3 = Theme.Text
            lb.AutoButtonColor = false
            Instance.new("UICorner", lb).CornerRadius = UDim.new(0, 4)
            lb.MouseButton1Click:Connect(function() loadCfg(cn); refreshList() end)
            local db = Instance.new("TextButton", entry)
            db.Size = UDim2.new(0, 22, 0, 22); db.Position = UDim2.new(1, -28, 0.5, -11)
            db.BackgroundColor3 = Color3.fromRGB(60, 15, 20); db.Text = "X"
            db.Font = Theme.FontBold; db.TextSize = 14; db.TextColor3 = Theme.Danger
            db.AutoButtonColor = false
            Instance.new("UICorner", db).CornerRadius = UDim.new(0, 4)
            db.MouseButton1Click:Connect(function() delCfg(cn); refreshList() end)
        end
    end
    refreshRef = refreshList
    refreshList()

    SettingsTab.CreateButton("Refresh List", function() refreshList() end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateLabel("Optimizations", Theme.Text)
    SettingsTab.CreateToggle("low_graphics", "lowGraphics", function(v) applyLG(v) end)
    SettingsTab.CreateToggle("no_shadows", "noShadows", function(v) applyNS(v) end)
    SettingsTab.CreateToggle("no_fog", "noFog", function(v) applyNF(v) end)
    SettingsTab.CreateToggle("no_particles", "noParticles", function(v) applyNP(v) end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateButton("Unload Script", function()
        UNLOADED = true
        _G.IZ_RefreshLanguage = nil
        clearAllESP()
        stopInfJump()
        stopFly()
        disableFB()
        applyLG(false)
        applyNS(false)
        applyNF(false)
        applyNP(false)
        pcall(function() if fovCircle then fovCircle:Remove() end end)
        GUI:Destroy()
    end, "danger")

    local CreditsTab = CreateTab("Credits", "➕")
    CreditsTab.CreateLabel("Founder: Sr Red", Theme.TitleRed)
    CreditsTab.CreateLabel(" ")
    CreditsTab.CreateLabel(FULL_VERSION, Theme.TextDim)
    CreditsTab.CreateLabel("Arsenal Layered Test", Theme.Warning)

    STEP(19, "Tabs OK")

    -- KEYBINDS
    local MIN_KEY = Enum.KeyCode.K
    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if recordingKeyFor then
            local fid = recordingKeyFor
            if input.KeyCode == Enum.KeyCode.Escape then
                recordingKeyFor = nil
                local h = toggleHandles[fid]
                if h then h.SetKeybind(State.keybinds[fid]) end
                return
            end
            local nk = input.KeyCode.Name
            if nk == "K" then
                Notify("Blocked", "K reserved", 4, true)
                recordingKeyFor = nil
                local h = toggleHandles[fid]
                if h then h.SetKeybind(State.keybinds[fid]) end
                return
            end
            State.keybinds[fid] = nk
            recordingKeyFor = nil
            local h = toggleHandles[fid]
            if h then h.SetKeybind(State.keybinds[fid]) end
            return
        end
        if input.KeyCode == MIN_KEY then setMinimized(not minimized); return end
        local kn = input.KeyCode.Name
        for fid, k in pairs(State.keybinds) do
            if k and k == kn then
                local h = toggleHandles[fid]
                if h then h.Toggle() end
            end
        end
    end)

    STEP(20, "✅ TUDO CARREGADO!")

    task.wait(0.5)
    Notify("🎯 " .. SHORT_VERSION, "Arsenal carregado!", 4)

    print("[Infinite Zen] " .. FULL_VERSION .. " carregado!")
end

return Arsenal