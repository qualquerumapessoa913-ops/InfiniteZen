-- ============================================================
-- INFINITE ZEN - MÓDULO ARSENAL v2.0 (DUMP-ACCURATE)
-- ============================================================

local Arsenal = {}

function Arsenal.Init(ctx)
    ctx = ctx or {}
    local Language = ctx.Language
    local gameName = ctx.gameName or "Arsenal"

    local GAME_VERSION = "2.0"
    local FULL_VERSION = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("[Infinite Zen] Iniciando " .. FULL_VERSION)

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
    local MOBILE_SCALE = 0.72

    local function STEP(n, msg) pcall(function() print("[IZ Step " .. n .. "] " .. msg) end) end
    STEP(1, "Base")

    -- ═══════════════════════════════════════════════
    -- SAFE WRAPPERS
    -- ═══════════════════════════════════════════════
    local function safeFind(parent, ...)
        if not parent then return nil end
        local cur = parent
        for _, n in ipairs({...}) do
            if not cur then return nil end
            local ok, nxt = pcall(function() return cur:FindFirstChild(n) end)
            if not ok or not nxt then return nil end
            cur = nxt
        end
        return cur
    end

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
    local function langGetCurrent()
        if not Language or type(Language.getCurrent) ~= "function" then return "en" end
        local ok, res = pcall(Language.getCurrent)
        if ok and res then return res end
        return "en"
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
        local formatted = k:gsub("_", " ")
        formatted = formatted:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b:lower() end)
        return formatted
    end

    -- ═══════════════════════════════════════════════
    -- REMOTES (baseado no dump)
    -- ═══════════════════════════════════════════════
    local Events = safeFind(ReplicatedStorage, "Events")
    local Remotes = {
        -- Combat
        Look = safeFind(Events, "Look"),
        Fire = safeFind(Events, "Fire"),
        HitPart = safeFind(Events, "HitPart"),
        MyHitPart = safeFind(Events, "MyHitPart"),
        -- Weapons
        ReloadInstant = safeFind(Events, "ReloadInstant"),
        AmmoMod = safeFind(Events, "AmmoMod"),
        GetWeapons = safeFind(Events, "GetWeapons"),
        GetInventory = safeFind(Events, "GetInventory"),
        UpdateLoadout = safeFind(Events, "UpdateLoadout"),
        Requip = safeFind(Events, "Requip"),
        EquipTool = safeFind(Events, "EquipTool"),
        AutoEquip = safeFind(Events, "AutoEquip"),
        ApplyGun = safeFind(Events, "ApplyGun"),
        -- SKINS (críticos)
        GunSkinner = safeFind(Events, "GunSkinner"),
        SkinChanged = safeFind(Events, "SkinChanged"),
        -- Votekick
        Votekick = safeFind(Events, "Votekick"),
        DoVotekick = safeFind(Events, "DoVotekick"),
        PromptVotekick = safeFind(Events, "PromptVotekick"),
        -- Team
        JoinTeam = safeFind(Events, "JoinTeam"),
        ForceTeam = safeFind(Events, "ForceTeam"),
        -- MISC
        Crosshair = safeFind(ReplicatedStorage, "Crosshair"),
        PlaySound = safeFind(Events, "PlaySound"),
        CreateProjectile = safeFind(Events, "CreateProjectile"),
    }
    STEP(2, "Remotes loaded")

    -- ═══════════════════════════════════════════════
    -- SKINS FOLDER (para popular o menu)
    -- ═══════════════════════════════════════════════
    local SkinsFolder = safeFind(ReplicatedStorage, "Skins")
    local WeaponSkins = {} -- [name] = assetId
    if SkinsFolder then
        for _, sv in ipairs(SkinsFolder:GetChildren()) do
            if sv:IsA("StringValue") then
                WeaponSkins[sv.Name] = sv.Value
            end
        end
    end
    STEP(3, "Skins loaded: " .. tostring(#SkinsFolder and #SkinsFolder:GetChildren() or 0))

    -- ═══════════════════════════════════════════════
    -- TEAM CHECK (usa Teams nativo do Roblox)
    -- ═══════════════════════════════════════════════
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

    -- ═══════════════════════════════════════════════
    -- STATE
    -- ═══════════════════════════════════════════════
    local State = {
        -- COMBAT
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
        -- WEAPON
        noRecoil = false, noSpread = false,
        rapidFire = false, rapidFireValue = 0.03,
        fastReload = false, instaReload = false, autoReload = false,
        infiniteAmmo = false, instantKill = false,
        damageMult = false, damageMultValue = 2,
        rangeExtender = false, rangeValue = 5000,
        bulletSpeed = false, bulletSpeedValue = 9999,
        noGravity = false, piercing = false, noMuzzleFlash = false,
        ghostWeapon = false, ghostTransparency = 1,
        rainbowWeapon = false, rainbowSpeed = 1,
        customSkin = false, customSkinName = "",
        -- MOVEMENT
        speed = false, speedValue = 50,
        fly = false, flySpeed = 60,
        infJump = false, jumpPower = 50,
        autoBhop = false, noclip = false, teleportCursor = false,
        -- VISUALS
        esp = false, espMaxDistance = 1000, espTeamCheck = true,
        espBox = true, espName = true, espHealth = true,
        espDistance = true, espWeapon = true, espTracer = false, espChams = true,
        grenadeEsp = false, damageIndicator = false, fullbright = false,
        thirdPerson = false, cameraFov = false, cameraFovValue = 90,
        -- EXTRA
        antiFlash = false, antiVK = false, antiAFK = false,
        -- OPT
        lowGraphics = false, noShadows = false, noFog = false, noParticles = false,
        keybinds = {
            killAll = nil, killAura = "G", silentAim = "X",
            lockBot = nil, triggerbot = nil, autoShot = nil,
            aimbot = "C", antiAim = nil,
            speed = nil, fly = "F", infJump = nil, autoBhop = nil,
            esp = "V", fullbright = nil, thirdPerson = nil,
            ghostWeapon = nil, rainbowWeapon = nil,
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
        instantKill = "Instant Kill", damageMult = "Damage Multiplier",
        rangeExtender = "Range Extender", bulletSpeed = "Bullet Speed",
        noGravity = "No Gravity", piercing = "Piercing", noMuzzleFlash = "No Muzzle Flash",
        ghostWeapon = "Ghost Weapon", rainbowWeapon = "Rainbow Weapon",
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
        espChams = "Chams", espTeamCheck = "Team Check",
    }

    -- THEME
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

    -- GUI
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
            if n and n.Parent then
                TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, 20, 0, n.Position.Y.Offset)
                }):Play()
                task.wait(0.35)
                if n.Parent then n:Destroy() end
            end
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
        local rayLen = dist - 2
        if rayLen <= 0 then return true end
        return workspace:Raycast(fromPos + dir.Unit * 2, dir.Unit * rayLen, params) == nil
    end

    -- Foco no Hitbox real do Arsenal
    local function getTargetPart(p)
        if not p.Character then return nil end
        local mode = State.aimbotHitbox
        if mode == 1 then
            return getBasePart(p.Character, "HeadHB", "Head")
        elseif mode == 2 then
            return getBasePart(p.Character, "Hitbox", "UpperTorso", "Torso")
        elseif mode == 3 then
            local order = {"Hitbox", "HeadHB", "Head", "UpperTorso", "Torso", "HumanoidRootPart"}
            for _, n in ipairs(order) do
                local bp = getBasePart(p.Character, n)
                if bp then return bp end
            end
            return nil
        else
            local head = getBasePart(p.Character, "HeadHB", "Head")
            local torso = getBasePart(p.Character, "Hitbox", "UpperTorso", "Torso")
            if head and torso then
                local camPos = Camera.CFrame.Position
                return (head.Position - camPos).Magnitude <= (torso.Position - camPos).Magnitude and head or torso
            end
            return head or torso
        end
    end

    local function getMyTool()
        local char = LocalPlayer.Character
        if not char then return nil end
        return char:FindFirstChildOfClass("Tool")
    end

    local function fireWeapon()
        local tool = getMyTool()
        if not tool then return false end
        if mouse1click then
            local ok = pcall(mouse1click)
            if ok then return true end
        end
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.005)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
        pcall(function() tool:Activate() end)
        return true
    end

    STEP(4, "Helpers ready")

    -- ═══════════════════════════════════════════════
    -- MAIN WINDOW
    -- ═══════════════════════════════════════════════
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
    Subtitle.Size = UDim2.new(0, 250, 0, 18); Subtitle.Position = UDim2.new(0, 20, 0, 25)
    Subtitle.BackgroundTransparency = 1; Subtitle.Font = Theme.Font
    Subtitle.Text = SHORT_VERSION; Subtitle.TextColor3 = Color3.fromRGB(220, 180, 185)
    Subtitle.TextSize = 11; Subtitle.TextXAlignment = Enum.TextXAlignment.Left; Subtitle.ZIndex = 3

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
    local dStr = Instance.new("UIStroke", LangDropdown)
    dStr.Color = Theme.Primary; dStr.Thickness = 1; dStr.Transparency = 0.3
    local dLay = Instance.new("UIListLayout", LangDropdown)
    dLay.Padding = UDim.new(0, 2)

    local availableLangs = langGetAvailable()
    if #availableLangs == 0 then
        availableLangs = { { code = "en", shortCode = "US", displayName = "English" } }
    end
    for _, ld in ipairs(availableLangs) do
        local ob = Instance.new("TextButton", LangDropdown)
        ob.Size = UDim2.new(1, -8, 0, 30); ob.BackgroundColor3 = Theme.Surface
        ob.Text = "  [" .. (ld.shortCode or "??") .. "]  " .. (ld.displayName or ld.code or "Lang")
        ob.Font = Theme.Font; ob.TextSize = 12; ob.TextColor3 = Theme.Text
        ob.TextXAlignment = Enum.TextXAlignment.Left; ob.AutoButtonColor = false; ob.ZIndex = 11
        Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 6)
        ob.MouseButton1Click:Connect(function()
            langSet(ld.code)
            LangDropdown.Visible = false
        end)
    end
    LangDropdown.Size = UDim2.new(0, 140, 0, #availableLangs * 32 + 8)
    local ddOpen = false
    LangBtn.MouseButton1Click:Connect(function()
        ddOpen = not ddOpen
        LangDropdown.Visible = ddOpen
    end)
    registerRefresh(function()
        local d = langGetCurrentData()
        LangBtn.Text = "[" .. (d.shortCode or "US") .. "]"
    end)

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
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
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

    STEP(5, "Window ready")

    -- ═══════════════════════════════════════════════
    -- TABS BUILDER
    -- ═══════════════════════════════════════════════
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
                if not silent and callback then pcall(callback, v) end
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
                    valLbl.Text = tostring(cur)
                    State[featureId] = cur
                    if callback then pcall(callback, cur) end
                end
            }
            sliderHandles[featureId] = handle
            return handle
        end

        tab.CreateDropdown = function(labelKey, options, featureId, callback)
            local holder = Instance.new("Frame", container)
            holder.Size = UDim2.new(1, -10, 0, 36)
            holder.BackgroundColor3 = Theme.Surface; holder.BorderSizePixel = 0
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
            local hs = Instance.new("UIStroke", holder)
            hs.Color = Theme.Border; hs.Thickness = 1; hs.Transparency = 0.7
            local lbl = Instance.new("TextLabel", holder)
            lbl.Size = UDim2.new(0.4, 0, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.BackgroundTransparency = 1; lbl.Font = Theme.Font; lbl.TextSize = 12
            lbl.TextColor3 = Theme.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left
            registerRefresh(function() lbl.Text = getLabel(labelKey) end)
            local curIdx = State[featureId] or 1
            local selBtn = Instance.new("TextButton", holder)
            selBtn.Size = UDim2.new(0.55, 0, 0, 22); selBtn.Position = UDim2.new(0.44, 0, 0.5, -11)
            selBtn.BackgroundColor3 = Theme.Surface2
            selBtn.Text = options[curIdx] or "?"
            selBtn.Font = Theme.FontBold; selBtn.TextSize = 11
            selBtn.TextColor3 = Theme.Text; selBtn.AutoButtonColor = false
            Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 6)
            local dd = Instance.new("Frame", holder)
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
                    selBtn.Text = opt
                    State[featureId] = i
                    dd.Visible = false
                    if callback then pcall(callback, i, opt) end
                end)
            end
            selBtn.MouseButton1Click:Connect(function()
                dd.Visible = not dd.Visible
            end)
            local handle = {
                SetValue = function(i)
                    curIdx = math.clamp(i, 1, #options)
                    selBtn.Text = options[curIdx]
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
                    local t = box.Text
                    box.Text = ""
                    if callback then pcall(callback, t) end
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
            local rl = Instance.new("TextLabel", holder)
            rl.Size = UDim2.new(1, -20, 0, 16); rl.Position = UDim2.new(0, 12, 0, 6)
            rl.BackgroundTransparency = 1; rl.Font = Theme.Font; rl.TextSize = 10
            rl.TextColor3 = Theme.TextDim; rl.Text = role
            rl.TextXAlignment = Enum.TextXAlignment.Left
            local nl = Instance.new("TextLabel", holder)
            nl.Size = UDim2.new(1, -20, 0, 20); nl.Position = UDim2.new(0, 12, 0, 22)
            nl.BackgroundTransparency = 1; nl.Font = Theme.FontBold; nl.TextSize = 14
            nl.TextColor3 = color or Theme.TitleRed; nl.Text = name
            nl.TextXAlignment = Enum.TextXAlignment.Left
            return holder
        end

        return tab
    end

    STEP(6, "CreateTab ready")

    -- ═══════════════════════════════════════════════
    -- FOV CIRCLE
    -- ═══════════════════════════════════════════════
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Theme.Primary; fovCircle.Thickness = 1.5
    fovCircle.Filled = false; fovCircle.NumSides = 100; fovCircle.Transparency = 1
    fovCircle.Radius = 25; fovCircle.Visible = false

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        if not State.fovCircle then fovCircle.Visible = false; return end
        local mouse = UserInputService:GetMouseLocation()
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
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

    -- TARGETING
    local function getClosestEnemyInFov(fovRange, requireLOS)
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, fovRange
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d and d < minDist then
                            if not requireLOS or hasLineOfSight(Camera.CFrame.Position, part) then
                                minDist = d; closest = p
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    STEP(7, "FOV + targeting ready")

    -- ═══════════════════════════════════════════════
    -- COMBAT
    -- ═══════════════════════════════════════════════

    -- SILENT AIM
    local silentHolding, silentTarget, silentOriginalCF = false, nil, nil

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
        silentOriginalCF = Camera.CFrame
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
            if silentOriginalCF then
                pcall(function() Camera.CFrame = silentOriginalCF end)
                if Remotes.Look then pcall(function() Remotes.Look:FireServer(silentOriginalCF) end) end
                silentOriginalCF = nil
            end
        end
    end)

    -- AIMBOT
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.aimbot then return end
        local target = getClosestEnemyInFov(State.aimbotFov, State.aimbotWallCheck)
        if target then
            local part = getTargetPart(target)
            if part then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local d3 = (part.Position - myRoot.Position).Magnitude
                    if d3 <= State.aimbotMaxDist then
                        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local mouse = UserInputService:GetMouseLocation()
                            local dx = sp.X - mouse.X
                            local dy = sp.Y - mouse.Y
                            if mousemoverel then pcall(function() mousemoverel(dx * State.aimbotSmoothness, dy * State.aimbotSmoothness) end) end
                        end
                    end
                end
            end
        end
    end)

    -- LOCK BOT
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.lockBot then return end
        local target = getClosestEnemyInFov(State.lockBotFov, false)
        if target then
            local part = getTargetPart(target)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mouse = UserInputService:GetMouseLocation()
                    if mousemoverel then pcall(function() mousemoverel(sp.X - mouse.X, sp.Y - mouse.Y) end) end
                end
                fireWeapon()
            end
        end
    end)

    -- TRIGGERBOT
    local triggerLastFire = 0
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.triggerbot then return end
        if tick() - triggerLastFire < (State.triggerbotDelay / 1000) then return end
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and depth and depth > 0 then
                        if (Vector2.new(sp.X, sp.Y) - center).Magnitude < 25 then
                            triggerLastFire = tick()
                            fireWeapon()
                            break
                        end
                    end
                end
            end
        end
    end)

    -- AUTO SHOT
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

    -- KILL AURA
    local killAuraActive = false
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.killAura then return end
        if killAuraActive then return end
        local char = LocalPlayer.Character
        if not char then return end
        local myHRP = getBasePart(char, "HumanoidRootPart")
        if not myHRP then return end
        killAuraActive = true
        task.spawn(function()
            local origCF = myHRP.CFrame
            for _, p in ipairs(Players:GetPlayers()) do
                if UNLOADED then break end
                if isEnemy(p) and p.Character then
                    local tHRP = getBasePart(p.Character, "HumanoidRootPart")
                    if tHRP then
                        local dist = (tHRP.Position - origCF.Position).Magnitude
                        if dist <= State.killAuraRange then
                            pcall(function() myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2) end)
                            task.wait(0.02)
                            fireWeapon()
                            task.wait(State.killAuraDelay / 1000)
                        end
                    end
                end
            end
            if myHRP and myHRP.Parent then pcall(function() myHRP.CFrame = origCF end) end
            killAuraActive = false
        end)
    end)

    -- KILL ALL
    local killAllActive = false
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.killAll then return end
        if killAllActive then return end
        local char = LocalPlayer.Character
        if not char then return end
        local myHRP = getBasePart(char, "HumanoidRootPart")
        if not myHRP then return end
        local tool = getMyTool()
        if not tool then return end
        killAllActive = true
        task.spawn(function()
            local origCF = myHRP.CFrame
            for _, p in ipairs(Players:GetPlayers()) do
                if UNLOADED then break end
                if isEnemy(p) and p.Character then
                    local tHead = getBasePart(p.Character, "HeadHB", "Head")
                    if tHead then
                        pcall(function() myHRP.CFrame = CFrame.new(tHead.Position + Vector3.new(0, 0, 2)) end)
                        task.wait(0.01)
                        pcall(function() Camera.CFrame = CFrame.new(myHRP.Position, tHead.Position) end)
                        task.wait(0.01)
                        fireWeapon()
                        pcall(function() tool:Activate() end)
                        task.wait(State.killAllDelay / 1000)
                    end
                end
            end
            if myHRP and myHRP.Parent then pcall(function() myHRP.CFrame = origCF end) end
            killAllActive = false
        end)
    end)

    -- ANTI AIM
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.antiAim then return end
        pcall(function()
            if State.antiAimMode == 1 then
                Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.rad(15), 0)
            elseif State.antiAimMode == 2 then
                Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(math.random(-15, 15)), math.rad(math.random(-15, 15)), 0)
            elseif State.antiAimMode == 3 then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Vector3.new(0, -1, 0))
            end
        end)
    end)

    -- HEAD EXPANDER (usa Hitbox e HeadHB que existem no Arsenal!)
    local hitboxSaved = {}
    local function saveOrig(player, part)
        if not player or not part or not part:IsA("BasePart") then return end
        if not hitboxSaved[player] then hitboxSaved[player] = {} end
        if not hitboxSaved[player][part] then
            local ok, sz = pcall(function() return part.Size end)
            if ok and sz then hitboxSaved[player][part] = sz end
        end
    end
    local function restorePlayer(player)
        if not hitboxSaved[player] then return end
        for part, size in pairs(hitboxSaved[player]) do
            if part and part.Parent and part:IsA("BasePart") then
                pcall(function() part.Size = size end)
            end
        end
        hitboxSaved[player] = nil
    end
    local function restoreAllHitboxes()
        for player, _ in pairs(hitboxSaved) do restorePlayer(player) end
        hitboxSaved = {}
    end
    local function expandPlayer(p, size)
        if not p.Character then return end
        -- Hitbox principal
        local hitbox = getBasePart(p.Character, "Hitbox")
        if hitbox then
            saveOrig(p, hitbox)
            local base = hitboxSaved[p] and hitboxSaved[p][hitbox]
            if base then
                pcall(function()
                    hitbox.Size = Vector3.new(base.X * size, base.Y * size, base.Z * size)
                    hitbox.Transparency = 0.85
                    hitbox.CanCollide = false
                end)
            end
        end
        -- HeadHB
        local headHB = getBasePart(p.Character, "HeadHB")
        if headHB then
            saveOrig(p, headHB)
            local base = hitboxSaved[p] and hitboxSaved[p][headHB]
            if base then
                pcall(function()
                    headHB.Size = Vector3.new(base.X * size, base.Y * size, base.Z * size)
                    headHB.Transparency = 0.85
                    headHB.CanCollide = false
                end)
            end
        end
    end
    local heTick = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.expanderEnabled then return end
        heTick = heTick + 1
        if heTick % 3 ~= 0 then return end
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer then
                elseif isEnemy(p) then
                    if p.Character then expandPlayer(p, State.hitboxSize) end
                else
                    if hitboxSaved[p] then restorePlayer(p) end
                end
            end
        end)
    end)

    STEP(8, "Combat OK")

    -- ═══════════════════════════════════════════════
    -- WEAPON MODS (rate-limited, com remotes nativos)
    -- ═══════════════════════════════════════════════
    local reloadOriginals = {}
    local weaponAcc = 0

    RunService.Heartbeat:Connect(function(dt)
        if UNLOADED then return end
        weaponAcc = weaponAcc + dt
        if weaponAcc < 0.25 then return end
        weaponAcc = 0

        -- Insta Reload via remote nativo
        if State.instaReload and Remotes.ReloadInstant then
            pcall(function() Remotes.ReloadInstant:FireServer() end)
        end
        if State.infiniteAmmo and Remotes.AmmoMod then
            pcall(function() Remotes.AmmoMod:FireServer("infinite") end)
        end

        local anyMod = State.rapidFire or State.noRecoil or State.fastReload or State.instaReload
            or State.noSpread or State.infiniteAmmo or State.rangeExtender or State.bulletSpeed
            or State.damageMult or State.piercing or State.noGravity or State.noMuzzleFlash
            or State.autoReload

        if not anyMod then
            if next(reloadOriginals) then
                local char = LocalPlayer.Character
                if char then
                    for _, cont in ipairs({char, LocalPlayer:FindFirstChild("Backpack")}) do
                        if cont then
                            for _, tool in ipairs(cont:GetChildren()) do
                                if tool:IsA("Tool") then
                                    pcall(function()
                                        for _, d in ipairs(tool:GetDescendants()) do
                                            local key = "dmg_" .. tostring(d)
                                            if reloadOriginals[key] and (d:IsA("NumberValue") or d:IsA("IntValue")) then
                                                d.Value = reloadOriginals[key]
                                                reloadOriginals[key] = nil
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            return
        end

        local char = LocalPlayer.Character
        if not char then return end
        local containers = {char}
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then table.insert(containers, bp) end

        for _, cont in ipairs(containers) do
            for _, tool in ipairs(cont:GetChildren()) do
                if tool:IsA("Tool") then
                    pcall(function()
                        local desc = tool:GetDescendants()
                        if State.rapidFire then
                            for _, name in ipairs({"FireRate", "BFireRate", "RateOfFire", "ShootCooldown", "FireDelay"}) do
                                local f = tool:FindFirstChild(name)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then f.Value = State.rapidFireValue
                                elseif typeof(tool[name]) == "number" then tool[name] = State.rapidFireValue end
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
                        if State.rangeExtender then
                            for _, d in ipairs(desc) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("range") or n:find("distance") then d.Value = State.rangeValue end
                                end
                            end
                        end
                        if State.bulletSpeed then
                            for _, d in ipairs(desc) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("speed") or n:find("velocity") then d.Value = State.bulletSpeedValue end
                                end
                            end
                        end
                        if State.damageMult then
                            for _, d in ipairs(desc) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("damage") or n == "dmg" then
                                        local key = "dmg_" .. tostring(d)
                                        if not reloadOriginals[key] then reloadOriginals[key] = d.Value end
                                        d.Value = reloadOriginals[key] * State.damageMultValue
                                    end
                                end
                            end
                        end
                        if State.piercing then
                            for _, d in ipairs(desc) do
                                if d:IsA("BoolValue") then
                                    local n = d.Name:lower()
                                    if n:find("pierce") or n:find("penetrat") then d.Value = true end
                                end
                            end
                        end
                        if State.noGravity then
                            for _, d in ipairs(desc) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    if d.Name:lower():find("gravity") then d.Value = 0 end
                                end
                            end
                        end
                        if State.noMuzzleFlash then
                            for _, d in ipairs(desc) do
                                if d:IsA("ParticleEmitter") or d:IsA("Fire") then d.Enabled = false end
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

    STEP(9, "Weapon mods OK")

    -- ═══════════════════════════════════════════════
    -- GHOST + RAINBOW (rate-limited)
    -- ═══════════════════════════════════════════════
    local savedWeaponParts = {}
    local rainbowHue = 0
    local lastWeaponKey = nil
    local ghostAcc = 0

    local function restoreAllWeaponParts()
        for part, orig in pairs(savedWeaponParts) do
            if part and part.Parent then
                pcall(function()
                    if part:IsA("BasePart") then
                        part.Transparency = orig.Transparency or 0
                        if orig.Color then part.Color = orig.Color end
                        if orig.Material then part.Material = orig.Material end
                    elseif part:IsA("Decal") or part:IsA("Texture") then
                        part.Transparency = orig.Transparency or 0
                    end
                end)
            end
        end
        savedWeaponParts = {}
    end

    RunService.Heartbeat:Connect(function(dt)
        if UNLOADED then return end
        ghostAcc = ghostAcc + dt
        if ghostAcc < 0.05 then return end
        local delta = ghostAcc
        ghostAcc = 0

        local active = State.ghostWeapon or State.rainbowWeapon
        local tool = getMyTool()
        local toolKey = tool and tool:GetFullName() or nil

        if lastWeaponKey and lastWeaponKey ~= toolKey then
            restoreAllWeaponParts()
        end
        lastWeaponKey = toolKey

        if not active then
            if next(savedWeaponParts) then restoreAllWeaponParts() end
            return
        end
        if not tool then return end

        pcall(function()
            local desc = tool:GetDescendants()
            for _, part in ipairs(desc) do
                if (part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture")) and savedWeaponParts[part] == nil then
                    savedWeaponParts[part] = {
                        Transparency = part.Transparency or 0,
                        Color = part:IsA("BasePart") and part.Color or nil,
                        Material = part:IsA("BasePart") and part.Material or nil,
                    }
                end
            end
            if State.ghostWeapon and not State.rainbowWeapon then
                for _, part in ipairs(desc) do
                    if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
                        part.Transparency = State.ghostTransparency
                    end
                end
            elseif State.rainbowWeapon then
                rainbowHue = (rainbowHue + delta * State.rainbowSpeed) % 1
                local color = Color3.fromHSV(rainbowHue, 1, 1)
                for _, part in ipairs(desc) do
                    if part:IsA("BasePart") then
                        part.Color = color
                        part.Material = Enum.Material.Neon
                        local orig = savedWeaponParts[part]
                        part.Transparency = orig and math.min(orig.Transparency or 0, 0.3) or 0
                    elseif part:IsA("Decal") or part:IsA("Texture") then
                        part.Transparency = 1
                    end
                end
            end
        end)
    end)

    STEP(10, "Ghost/Rainbow OK")

    -- ═══════════════════════════════════════════════
    -- SKIN SYSTEM (usa ReplicatedStorage.Skins)
    -- ═══════════════════════════════════════════════
    local skinList = {}
    local skinButtons = {}

    local function scanSkinsSafe()
        local found = {}
        if SkinsFolder then
            for _, sv in ipairs(SkinsFolder:GetChildren()) do
                if sv:IsA("StringValue") and sv.Name ~= "" then
                    table.insert(found, { name = sv.Name, assetId = sv.Value })
                end
            end
        end
        table.sort(found, function(a, b) return a.name < b.name end)
        return found
    end

    local function applySkinToTool(skinName)
        if not skinName or skinName == "" then
            Notify("🎨 Skin", "Selecione uma skin", 3, true)
            return false
        end
        local tool = getMyTool()
        if not tool then
            Notify("🎨 Skin", "Nenhuma arma equipada", 3, true)
            return false
        end

        local assetId = WeaponSkins[skinName]

        -- Tenta GunSkinner remote
        if Remotes.GunSkinner then
            pcall(function() Remotes.GunSkinner:FireServer(tool.Name, skinName) end)
            pcall(function() Remotes.GunSkinner:FireServer(skinName) end)
        end
        if Remotes.ApplyGun then
            pcall(function() Remotes.ApplyGun:FireServer(skinName) end)
        end

        -- Fallback client-side: aplica Textura
        if assetId and assetId ~= "" then
            pcall(function()
                for _, part in ipairs(tool:GetDescendants()) do
                    if part:IsA("BasePart") then
                        -- remove texturas antigas
                        for _, c in ipairs(part:GetChildren()) do
                            if c:IsA("Texture") or c:IsA("Decal") then
                                c:Destroy()
                            end
                        end
                        -- aplica nova textura
                        local tex = Instance.new("Texture")
                        tex.Texture = assetId
                        tex.Face = Enum.NormalId.Top
                        tex.Parent = part
                    elseif part:IsA("Decal") then
                        part.Texture = assetId
                    end
                end
            end)
        end

        State.customSkinName = skinName
        Notify("🎨 Skin", "Aplicado: " .. skinName, 3)
        return true
    end

    local function buildSkinMenu(tab)
        pcall(function()
            local statusLbl = Instance.new("TextLabel", tab.container)
            statusLbl.Size = UDim2.new(1, -10, 0, 20)
            statusLbl.BackgroundTransparency = 1
            statusLbl.Font = Theme.Font
            statusLbl.TextSize = 11
            statusLbl.TextColor3 = Theme.TextDim
            statusLbl.TextXAlignment = Enum.TextXAlignment.Left
            statusLbl.Text = "Total: " .. #skinList .. " skins"

            local scroll = Instance.new("ScrollingFrame", tab.container)
            scroll.Size = UDim2.new(1, -10, 0, 280)
            scroll.BackgroundColor3 = Theme.Surface
            scroll.BorderSizePixel = 0
            scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            scroll.ScrollBarThickness = 4
            scroll.ScrollBarImageColor3 = Theme.Primary
            Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)
            local sl = Instance.new("UIListLayout", scroll)
            sl.Padding = UDim.new(0, 3)
            local sp = Instance.new("UIPadding", scroll)
            sp.PaddingTop = UDim.new(0, 4)
            sp.PaddingBottom = UDim.new(0, 4)
            sp.PaddingLeft = UDim.new(0, 4)
            sp.PaddingRight = UDim.new(0, 4)

            for _, skin in ipairs(skinList) do
                local btn = Instance.new("TextButton", scroll)
                btn.Size = UDim2.new(1, 0, 0, 26)
                btn.BackgroundColor3 = Theme.Surface2
                btn.Text = "  " .. skin.name
                btn.Font = Theme.Font
                btn.TextSize = 11
                btn.TextColor3 = Theme.Text
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.AutoButtonColor = false
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                btn.MouseButton1Click:Connect(function()
                    applySkinToTool(skin.name)
                    for _, other in ipairs(skinButtons) do
                        if other.Parent then other.BackgroundColor3 = Theme.Surface2 end
                    end
                    btn.BackgroundColor3 = Theme.Success
                end)
                table.insert(skinButtons, btn)
            end

            local abtn = Instance.new("TextButton", tab.container)
            abtn.Size = UDim2.new(1, -10, 0, 30)
            abtn.BackgroundColor3 = Theme.Primary
            abtn.Text = "Apply Current"
            abtn.Font = Theme.FontBold
            abtn.TextSize = 11
            abtn.TextColor3 = Theme.Text
            abtn.AutoButtonColor = false
            Instance.new("UICorner", abtn).CornerRadius = UDim.new(0, 6)
            abtn.MouseButton1Click:Connect(function()
                if State.customSkinName ~= "" then
                    applySkinToTool(State.customSkinName)
                else
                    Notify("🎨 Skin", "Selecione uma skin", 3, true)
                end
            end)
        end)
    end

    skinList = scanSkinsSafe()
    STEP(11, "Skins escaneadas: " .. #skinList)

    -- ═══════════════════════════════════════════════
    -- MOVEMENT
    -- ═══════════════════════════════════════════════
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.speed then return end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
        end
    end)

    local flyV, flyG = nil, nil
    local function startFly()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if flyV then flyV:Destroy() end
        if flyG then flyG:Destroy() end
        flyV = Instance.new("BodyVelocity")
        flyV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyV.Velocity = Vector3.zero
        flyV.Parent = hrp
        flyG = Instance.new("BodyGyro")
        flyG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyG.P = 1e4
        flyG.CFrame = hrp.CFrame
        flyG.Parent = hrp
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
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if not flyV then startFly() end
        if not flyV or not flyG then return end
        pcall(function() flyG.CFrame = Camera.CFrame end)
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
        if move.Magnitude > 0 then
            flyV.Velocity = move.Unit * State.flySpeed
        else
            flyV.Velocity = Vector3.zero
        end
    end)

    local infJumpConn = nil
    local function startInfJump()
        if infJumpConn then infJumpConn:Disconnect() end
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED or not State.infJump then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end
            if hum:GetState() == Enum.HumanoidStateType.Dead then return end
            hrp.Velocity = Vector3.new(hrp.Velocity.X, State.jumpPower, hrp.Velocity.Z)
        end)
    end
    local function stopInfJump()
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end

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

    RunService.Stepped:Connect(function()
        if UNLOADED or not State.noclip then return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                pcall(function() part.CanCollide = false end)
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.teleportCursor then return end
        if input.KeyCode ~= Enum.KeyCode.T then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local mouse = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mouse.X, mouse.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {char}
        local r = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if r then pcall(function() hrp.CFrame = CFrame.new(r.Position + Vector3.new(0, 3, 0)) end) end
    end)

    STEP(12, "Movement OK")

    -- ═══════════════════════════════════════════════
    -- VISUALS
    -- ═══════════════════════════════════════════════
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
        local headSp, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpSp, hrpOn = Camera:WorldToViewportPoint(hrp.Position)
        local footSp, footOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local dist = math.floor((head.Position - myHRP.Position).Magnitude)
        if dist > State.espMaxDistance then
            for _, k in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon"}) do
                if d[k] then d[k].Visible = false end
            end
            return
        end
        if headOn and footOn and State.espBox then
            local h = math.abs(footSp.Y - headSp.Y)
            local w = h * 0.6
            local cx = (headSp.X + footSp.X) / 2
            local cy = (headSp.Y + footSp.Y) / 2
            d.box.Position = Vector2.new(cx - w / 2, cy - h / 2)
            d.box.Size = Vector2.new(w, h)
            d.box.Visible = true
        else d.box.Visible = false end
        if headOn then
            if State.espName then
                d.name.Position = Vector2.new(headSp.X, headSp.Y - 20)
                d.name.Text = p.Name; d.name.Visible = true
            else d.name.Visible = false end
            if State.espDistance then
                d.distance.Position = Vector2.new(headSp.X, headSp.Y - 6)
                d.distance.Text = dist .. "m"; d.distance.Visible = true
            else d.distance.Visible = false end
            d.headDot.Position = Vector2.new(headSp.X, headSp.Y); d.headDot.Visible = true
            if State.espWeapon then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    d.weapon.Position = Vector2.new(headSp.X, headSp.Y - 34)
                    d.weapon.Text = "[" .. tool.Name .. "]"; d.weapon.Visible = true
                else d.weapon.Visible = false end
            else d.weapon.Visible = false end
        else
            d.name.Visible = false; d.distance.Visible = false
            d.headDot.Visible = false; d.weapon.Visible = false
        end
        if headOn and footOn and State.espHealth then
            local h = math.abs(footSp.Y - headSp.Y)
            local maxHP = hum.MaxHealth
            local hr = (maxHP and maxHP > 0) and math.clamp(hum.Health / maxHP, 0, 1) or 1
            local bx = headSp.X + (h * 0.6) / 2 + 5
            local by = headSp.Y + h
            d.health.From = Vector2.new(bx, by - h * hr)
            d.health.To = Vector2.new(bx, by)
            if hr > 0.6 then d.health.Color = Color3.fromRGB(0, 255, 0)
            elseif hr > 0.3 then d.health.Color = Color3.fromRGB(255, 200, 0)
            else d.health.Color = Color3.fromRGB(255, 40, 40) end
            d.health.Visible = true
        else d.health.Visible = false end
        if hrpOn and State.espTracer then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To = Vector2.new(hrpSp.X, hrpSp.Y)
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

    -- GRENADE ESP
    local grenadeKws = {"grenade", "frag", "flashbang", "smoke", "molotov", "impact", "sticky", "decoy"}
    local grenadeDrawings = {}
    local function isGrenade(obj)
        if not obj or not obj.Parent or not obj:IsA("BasePart") then return false end
        local lower = obj.Name:lower()
        for _, kw in ipairs(grenadeKws) do if lower:find(kw) then return true end end
        return false
    end
    local function clearGrenades()
        for _, d in pairs(grenadeDrawings) do
            if d.box then pcall(function() d.box:Remove() end) end
            if d.name then pcall(function() d.name:Remove() end) end
        end
        grenadeDrawings = {}
    end
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.grenadeEsp then clearGrenades(); return end
        pcall(function()
            local active = {}
            for _, obj in ipairs(workspace:GetChildren()) do
                if isGrenade(obj) then
                    active[obj] = true
                    if not grenadeDrawings[obj] then
                        local box = Drawing.new("Square")
                        box.Thickness = 1.5; box.Color = Color3.fromRGB(255, 150, 50)
                        box.Filled = false; box.Transparency = 1
                        local nm = Drawing.new("Text")
                        nm.Size = 12; nm.Center = true; nm.Outline = true
                        nm.Color = Color3.fromRGB(255, 200, 100)
                        nm.Text = obj.Name
                        grenadeDrawings[obj] = {box = box, name = nm}
                    end
                    local d = grenadeDrawings[obj]
                    local sp, onScreen = Camera:WorldToViewportPoint(obj.Position)
                    if onScreen then
                        local size = math.clamp(300 / math.max((Camera.CFrame.Position - obj.Position).Magnitude, 1), 8, 100)
                        d.box.Size = Vector2.new(size, size)
                        d.box.Position = Vector2.new(sp.X - size / 2, sp.Y - size / 2)
                        d.box.Visible = true
                        d.name.Position = Vector2.new(sp.X, sp.Y - size / 2 - 12)
                        d.name.Visible = true
                    else
                        d.box.Visible = false; d.name.Visible = false
                    end
                end
            end
            for obj, d in pairs(grenadeDrawings) do
                if not active[obj] then
                    if d.box then pcall(function() d.box:Remove() end) end
                    if d.name then pcall(function() d.name:Remove() end) end
                    grenadeDrawings[obj] = nil
                end
            end
        end)
    end)

    -- DAMAGE INDICATOR
    local dmgArrow = Drawing.new("Triangle")
    dmgArrow.Filled = true
    dmgArrow.Color = Color3.fromRGB(255, 40, 40)
    dmgArrow.Transparency = 0.85
    dmgArrow.Visible = false
    local lastDamageTime = 0
    task.spawn(function()
        while not UNLOADED do
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local lastHealth = hum.Health
                    local conn
                    conn = hum.HealthChanged:Connect(function(newHealth)
                        if newHealth < lastHealth and newHealth > 0 then lastDamageTime = tick() end
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
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local px, py = center.X, center.Y - 120
        local size = 14
        dmgArrow.PointA = Vector2.new(px, py + size)
        dmgArrow.PointB = Vector2.new(px - size * 0.7, py - size * 0.7)
        dmgArrow.PointC = Vector2.new(px + size * 0.7, py - size * 0.7)
        local alpha = math.clamp((1.5 - (now - lastDamageTime)) / 1.5, 0, 1)
        dmgArrow.Transparency = 0.15 + (1 - alpha) * 0.7
        dmgArrow.Visible = true
    end)

    -- FULLBRIGHT
    local origBrightness = Lighting.Brightness
    local origAmbient = Lighting.Ambient
    local origOutdoorAmbient = Lighting.OutdoorAmbient
    local origClockTime = Lighting.ClockTime
    local origGlobalShadows = Lighting.GlobalShadows
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
    local function disableFullbright()
        Lighting.Brightness = origBrightness
        Lighting.Ambient = origAmbient
        Lighting.OutdoorAmbient = origOutdoorAmbient
        Lighting.ClockTime = origClockTime
        Lighting.GlobalShadows = origGlobalShadows
        for _, d in ipairs(origAtmos) do
            if d.obj and d.obj.Parent then
                pcall(function()
                    d.obj.Density = d.D; d.obj.Haze = d.H; d.obj.Glare = d.G
                end)
            end
        end
    end

    -- THIRD PERSON
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.thirdPerson then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        pcall(function()
            local cur = Camera.CFrame
            Camera.CFrame = CFrame.new(hrp.Position - (cur.LookVector * 8) + Vector3.new(0, 3, 0), hrp.Position + Vector3.new(0, 1.5, 0))
        end)
    end)

    -- CAMERA FOV
    local origFov = Camera.FieldOfView
    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if State.cameraFov then
            if Camera.FieldOfView ~= State.cameraFovValue then
                Camera.FieldOfView = State.cameraFovValue
            end
        end
    end)

    -- ANTI-FLASH
    local flashKws = {"flash", "blind", "whiteout", "whitescreen", "flashbang"}
    local function isFlashName(n)
        if type(n) ~= "string" then return false end
        local l = n:lower()
        for _, kw in ipairs(flashKws) do if l:find(kw) then return true end end
        return false
    end
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.antiFlash then return end
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA("ColorCorrectionEffect") or c:IsA("BlurEffect") then
                if isFlashName(c.Name) then pcall(function() c:Destroy() end) end
            end
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, c in ipairs(pg:GetChildren()) do
                if (c:IsA("ScreenGui") or c:IsA("Frame")) and isFlashName(c.Name) then
                    pcall(function() c:Destroy() end)
                end
            end
        end
    end)

    -- ANTI-VOTEKICK
    if Remotes.PromptVotekick then
        pcall(function()
            Remotes.PromptVotekick.OnClientEvent:Connect(function(...)
                if UNLOADED or not State.antiVK then return end
                local args = {...}
                for _, v in ipairs(args) do
                    if typeof(v) == "Instance" and v:IsA("Player") and v == LocalPlayer then
                        Notify("🛡️ Anti-VK", "Votekick blocked", 3)
                    end
                end
            end)
        end)
    end

    -- ANTI AFK
    task.spawn(function()
        while not UNLOADED do
            if State.antiAFK then
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end
            task.wait(60)
        end
    end)

    STEP(13, "Visuals OK")

    -- ═══════════════════════════════════════════════
    -- OPTIMIZATIONS
    -- ═══════════════════════════════════════════════
    local optBackup = {
        fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart,
        globalShadows = Lighting.GlobalShadows, qualityLevel = nil,
        particles = {},
    }
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

    -- ═══════════════════════════════════════════════
    -- CONFIG SYSTEM
    -- ═══════════════════════════════════════════════
    local BASE_FOLDER = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/Arsenal"
    local AUTOLOAD_FILE = "InfiniteZen_Arsenal_Autoload.txt"
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
        local data = {version = GAME_VERSION, language = langGetCurrent(), state = {}, keybinds = State.keybinds}
        for k, v in pairs(State) do
            if k ~= "keybinds" and type(v) ~= "function" and type(v) ~= "userdata" then
                data.state[k] = v
            end
        end
        local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
        if not ok or not json then Notify("⚠️ Error", "Encode falhou", 4, true); return false end
        local wOk = pcall(function() writefile(getConfigPath(name), json) end)
        if wOk then Notify("💾 Config", "Saved: " .. name, 3); return true
        else Notify("⚠️ Error", "Failed", 4, true); return false end
    end

    local function loadConfigNamed(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then Notify("⚠️ Error", "Config not found", 4, true); return false end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data then Notify("⚠️ Error", "Corrupted", 4, true); return false end
        if data.language then langSet(data.language) end
        if data.state then for k, v in pairs(data.state) do State[k] = v end end
        if data.keybinds then for k, v in pairs(data.keybinds) do State.keybinds[k] = v end end
        for featId, handle in pairs(toggleHandles) do
            if State[featId] ~= nil then handle.SetState(State[featId], true) end
            handle.SetKeybind(State.keybinds[featId])
        end
        for featId, handle in pairs(sliderHandles) do
            if State[featId] ~= nil then handle.SetValue(State[featId]) end
        end
        for featId, handle in pairs(dropdownHandles) do
            if State[featId] ~= nil then handle.SetValue(State[featId]) end
        end
        if State.lowGraphics then applyLowGraphics(true) end
        if State.noShadows then applyNoShadows(true) end
        if State.noFog then applyNoFog(true) end
        if State.noParticles then applyNoParticles(true) end
        if not State.fullbright then disableFullbright() end
        if not State.expanderEnabled then restoreAllHitboxes() end
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
                    local n = file:match("([^/\\]+)%.json$")
                    if n then table.insert(list, n) end
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
        local ok, c = pcall(function() return readfile(getAutoloadPath()) end)
        if ok and c and c ~= "" then return c end
        return nil
    end

    -- ═══════════════════════════════════════════════
    -- ABAS
    -- ═══════════════════════════════════════════════
    local CombatTab = CreateTab("Combat", "⚔️")
    CombatTab.CreateLabel("Rage", Theme.Text)
    CombatTab.CreateToggle("kill_all", "killAll")
    CombatTab.CreateSlider("kill_all_delay", 10, 1000, 100, "killAllDelay")
    CombatTab.CreateToggle("lock_bot", "lockBot")
    CombatTab.CreateSlider("lock_bot_fov", 50, 400, 200, "lockBotFov")
    CombatTab.CreateToggle("kill_aura", "killAura")
    CombatTab.CreateSlider("kill_aura_range", 5, 100, 30, "killAuraRange")
    CombatTab.CreateSlider("kill_aura_delay", 10, 500, 50, "killAuraDelay")
    CombatTab.CreateLabel("Legit", Theme.Text)
    CombatTab.CreateToggle("silent_aim", "silentAim")
    CombatTab.CreateSlider("silent_fov", 30, 300, 120, "silentFov")
    CombatTab.CreateToggle("aimbot", "aimbot")
    CombatTab.CreateSlider("aimbot_fov", 30, 300, 100, "aimbotFov")
    CombatTab.CreateSlider("aimbot_smooth", 5, 100, 30, "aimbotSmoothness", function(v)
        State.aimbotSmoothness = v / 100
    end)
    CombatTab.CreateSlider("aimbot_max_dist", 50, 2000, 500, "aimbotMaxDist")
    CombatTab.CreateToggle("aimbot_wallcheck", "aimbotWallCheck")
    CombatTab.CreateDropdown("aimbot_hitbox", {"Head (HeadHB)", "Torso (Hitbox)", "Nearest", "Auto"}, "aimbotHitbox")
    CombatTab.CreateToggle("triggerbot", "triggerbot")
    CombatTab.CreateSlider("triggerbot_delay", 1, 100, 5, "triggerbotDelay")
    CombatTab.CreateToggle("auto_shot", "autoShot")
    CombatTab.CreateSlider("auto_shot_fov", 30, 300, 100, "autoShotFov")
    CombatTab.CreateSlider("auto_shot_delay", 10, 500, 50, "autoShotDelay")
    CombatTab.CreateLabel("Extra", Theme.Text)
    CombatTab.CreateToggle("anti_aim", "antiAim")
    CombatTab.CreateDropdown("anti_aim_mode", {"Spin", "Jitter", "Down"}, "antiAimMode")
    CombatTab.CreateToggle("head_expander", "expanderEnabled", function(v)
        if not v then restoreAllHitboxes() end
    end)
    CombatTab.CreateSlider("hitbox_size", 1, 5, 2, "hitboxSize")
    CombatTab.CreateToggle("fov_circle", "fovCircle")

    local WeaponTab = CreateTab("Weapon", "🔫")
    WeaponTab.CreateLabel("Recoil / Spread", Theme.Text)
    WeaponTab.CreateToggle("no_recoil", "noRecoil")
    WeaponTab.CreateToggle("no_spread", "noSpread")
    WeaponTab.CreateLabel("Fire Rate / Reload", Theme.Text)
    WeaponTab.CreateToggle("rapid_fire", "rapidFire")
    WeaponTab.CreateSlider("rapid_fire_value", 1, 100, 3, "rapidFireValue", function(v)
        State.rapidFireValue = v / 100
    end)
    WeaponTab.CreateToggle("fast_reload", "fastReload")
    WeaponTab.CreateToggle("insta_reload", "instaReload")
    WeaponTab.CreateToggle("auto_reload", "autoReload")
    WeaponTab.CreateLabel("Ammo / Damage", Theme.Text)
    WeaponTab.CreateToggle("infinite_ammo", "infiniteAmmo")
    WeaponTab.CreateToggle("damage_mult", "damageMult")
    WeaponTab.CreateSlider("damage_mult_value", 1, 20, 2, "damageMultValue")
    WeaponTab.CreateLabel("Bullet Mods", Theme.Text)
    WeaponTab.CreateToggle("range_extender", "rangeExtender")
    WeaponTab.CreateSlider("range_value", 500, 50000, 5000, "rangeValue")
    WeaponTab.CreateToggle("bullet_speed", "bulletSpeed")
    WeaponTab.CreateSlider("bullet_speed_value", 100, 100000, 9999, "bulletSpeedValue")
    WeaponTab.CreateToggle("no_gravity", "noGravity")
    WeaponTab.CreateToggle("piercing", "piercing")
    WeaponTab.CreateToggle("no_muzzle_flash", "noMuzzleFlash")
    WeaponTab.CreateLabel("Visual Mods", Theme.Text)
    WeaponTab.CreateToggle("ghost_weapon", "ghostWeapon")
    WeaponTab.CreateSlider("ghost_transparency", 0, 100, 100, "ghostTransparency", function(v)
        State.ghostTransparency = v / 100
    end)
    WeaponTab.CreateToggle("rainbow_weapon", "rainbowWeapon")
    WeaponTab.CreateSlider("rainbow_speed", 1, 10, 1, "rainbowSpeed", function(v)
        State.rainbowSpeed = v / 10
    end)

    -- SKINS
    local okSk, SkinsTab = pcall(function()
        local t = CreateTab("Skins", "🎨")
        t.CreateLabel("Weapon Skins", Theme.Text)
        t.CreateLabel(#skinList .. " skins encontradas", Theme.TextDim)
        return t
    end)
    if okSk and SkinsTab then
        buildSkinMenu(SkinsTab)
    end

    local MovementTab = CreateTab("Movement", "🏃")
    MovementTab.CreateToggle("speed", "speed")
    MovementTab.CreateSlider("speed_value", 16, 300, 50, "speedValue")
    MovementTab.CreateToggle("fly", "fly")
    MovementTab.CreateSlider("fly_speed", 10, 500, 60, "flySpeed")
    MovementTab.CreateToggle("inf_jump", "infJump")
    MovementTab.CreateSlider("jump_power", 30, 300, 50, "jumpPower")
    MovementTab.CreateToggle("auto_bhop", "autoBhop")
    MovementTab.CreateToggle("noclip", "noclip")
    MovementTab.CreateToggle("teleport_cursor", "teleportCursor")

    local VisualsTab = CreateTab("Visuals", "👁️")
    VisualsTab.CreateToggle("esp", "esp", function(v)
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then createESP(p) end
            end
        else clearAllESP() end
    end)
    VisualsTab.CreateSlider("esp_max_distance", 100, 5000, 1000, "espMaxDistance")
    VisualsTab.CreateLabel("ESP Elements", Theme.Text)
    VisualsTab.CreateToggle("esp_box", "espBox")
    VisualsTab.CreateToggle("esp_name", "espName")
    VisualsTab.CreateToggle("esp_health", "espHealth")
    VisualsTab.CreateToggle("esp_distance", "espDistance")
    VisualsTab.CreateToggle("esp_weapon", "espWeapon")
    VisualsTab.CreateToggle("esp_tracer", "espTracer")
    VisualsTab.CreateToggle("esp_chams", "espChams")
    VisualsTab.CreateLabel("Extra", Theme.Text)
    VisualsTab.CreateToggle("grenade_esp", "grenadeEsp")
    VisualsTab.CreateToggle("damage_indicator", "damageIndicator")
    VisualsTab.CreateToggle("fullbright", "fullbright", function(v)
        if not v then disableFullbright() end
    end)
    VisualsTab.CreateToggle("third_person", "thirdPerson")
    VisualsTab.CreateToggle("camera_fov", "cameraFov")
    VisualsTab.CreateSlider("camera_fov_value", 30, 150, 90, "cameraFovValue")

    local SettingsTab = CreateTab("Settings", "⚙️")
    SettingsTab.CreateLabel("Configs", Theme.Text)
    SettingsTab.CreateLabel("Type name and press Enter", Theme.TextDim)
    local refreshConfigListRef = nil
    SettingsTab.CreateTextBox("Config name...", function(name)
        if saveConfigNamed(name) and refreshConfigListRef then refreshConfigListRef() end
    end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateLabel("Loaded Configs", Theme.Text)

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
        for _, c in ipairs(configScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        local configs = listConfigs()
        local ca = getAutoload()
        if #configs == 0 then
            local e = Instance.new("TextLabel", configScroll)
            e.Size = UDim2.new(1, 0, 0, 30)
            e.BackgroundTransparency = 1
            e.Font = Theme.Font
            e.TextSize = 11
            e.TextColor3 = Theme.TextDim
            e.Text = "No configs saved yet."
            return
        end
        for _, cn in ipairs(configs) do
            local entry = Instance.new("Frame", configScroll)
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
            if ca == cn then
                nl.Text = "⚡ " .. cn
                nl.TextColor3 = Theme.Warning
            end
            local lb = Instance.new("TextButton", entry)
            lb.Size = UDim2.new(0, 50, 0, 22); lb.Position = UDim2.new(1, -110, 0.5, -11)
            lb.BackgroundColor3 = Theme.Primary; lb.Text = "Load"
            lb.Font = Theme.FontBold; lb.TextSize = 10; lb.TextColor3 = Theme.Text
            lb.AutoButtonColor = false
            Instance.new("UICorner", lb).CornerRadius = UDim.new(0, 4)
            lb.MouseButton1Click:Connect(function() loadConfigNamed(cn); refreshConfigList() end)
            local ab = Instance.new("TextButton", entry)
            ab.Size = UDim2.new(0, 22, 0, 22); ab.Position = UDim2.new(1, -55, 0.5, -11)
            ab.BackgroundColor3 = ca == cn and Theme.Warning or Theme.Surface
            ab.Text = "⚡"; ab.Font = Theme.FontBold; ab.TextSize = 12
            ab.TextColor3 = Theme.Text; ab.AutoButtonColor = false
            Instance.new("UICorner", ab).CornerRadius = UDim.new(0, 4)
            ab.MouseButton1Click:Connect(function()
                if ca == cn then clearAutoload() else setAutoload(cn) end
                refreshConfigList()
            end)
            local db = Instance.new("TextButton", entry)
            db.Size = UDim2.new(0, 22, 0, 22); db.Position = UDim2.new(1, -28, 0.5, -11)
            db.BackgroundColor3 = Color3.fromRGB(60, 15, 20); db.Text = "X"
            db.Font = Theme.FontBold; db.TextSize = 14; db.TextColor3 = Theme.Danger
            db.AutoButtonColor = false
            Instance.new("UICorner", db).CornerRadius = UDim.new(0, 4)
            db.MouseButton1Click:Connect(function() deleteConfigNamed(cn); refreshConfigList() end)
        end
    end
    refreshConfigListRef = refreshConfigList
    refreshConfigList()

    SettingsTab.CreateButton("Refresh List", function()
        refreshConfigList()
        Notify("Refresh", "Updated", 2)
    end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateButton("Disable Autoload", function()
        clearAutoload(); refreshConfigList()
    end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateLabel("Optimizations", Theme.Text)
    SettingsTab.CreateToggle("low_graphics", "lowGraphics", function(v) applyLowGraphics(v) end)
    SettingsTab.CreateToggle("no_shadows", "noShadows", function(v) applyNoShadows(v) end)
    SettingsTab.CreateToggle("no_fog", "noFog", function(v) applyNoFog(v) end)
    SettingsTab.CreateToggle("no_particles", "noParticles", function(v) applyNoParticles(v) end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateButton("Max FPS Boost", function()
        toggleHandles.lowGraphics.SetState(true)
        toggleHandles.noShadows.SetState(true)
        toggleHandles.noFog.SetState(true)
        toggleHandles.noParticles.SetState(true)
    end)
    SettingsTab.CreateButton("Reset Optimizations", function()
        toggleHandles.lowGraphics.SetState(false)
        toggleHandles.noShadows.SetState(false)
        toggleHandles.noFog.SetState(false)
        toggleHandles.noParticles.SetState(false)
    end)
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateLabel("Security", Theme.Text)
    SettingsTab.CreateToggle("anti_flash", "antiFlash")
    SettingsTab.CreateToggle("anti_votekick", "antiVK")
    SettingsTab.CreateToggle("anti_afk", "antiAFK")
    SettingsTab.CreateLabel(" ")
    SettingsTab.CreateButton("Unload Script", function()
        UNLOADED = true
        _G.IZ_RefreshLanguage = nil
        clearAllESP()
        clearGrenades()
        stopInfJump()
        stopFly()
        restoreAllHitboxes()
        restoreAllWeaponParts()
        disableFullbright()
        applyLowGraphics(false)
        applyNoShadows(false)
        applyNoFog(false)
        applyNoParticles(false)
        pcall(function() Camera.FieldOfView = origFov end)
        pcall(function() if fovCircle then fovCircle:Remove() end end)
        pcall(function() if dmgArrow then dmgArrow:Remove() end end)
        GUI:Destroy()
    end, "danger")

    local CreditsTab = CreateTab("Credits", "➕")
    CreditsTab.CreateCredit("FOUNDER & DEVELOPER", "Sr Red", Theme.TitleRed)
    CreditsTab.CreateLabel(" ")
    CreditsTab.CreateLabel("Join our Discord", Theme.Text)
    CreditsTab.CreateLabel("https://discord.gg/ScZfU2mAGm", Theme.TextDim)
    local db = CreditsTab.CreateButton("Join Discord Server", function()
        if setclipboard then setclipboard("https://discord.gg/ScZfU2mAGm"); Notify("Copied", "Discord link copied!", 3) end
    end)
    db.BackgroundColor3 = Theme.Discord
    CreditsTab.CreateLabel(" ")
    CreditsTab.CreateLabel(FULL_VERSION, Theme.TextDim)
    CreditsTab.CreateLabel("Arsenal DUMP-Accurate Edition", Theme.Warning)
    CreditsTab.CreateLabel("2026 Sr Red", Theme.TextDim)

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
        local al = getAutoload()
        if al then task.wait(1); loadConfigNamed(al) end
    end)

    -- ═══════════════════════════════════════════════
    -- KEYBINDS
    -- ═══════════════════════════════════════════════
    local MINIMIZE_KEY = Enum.KeyCode.K
    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if recordingKeyFor then
            local featId = recordingKeyFor
            if input.KeyCode == Enum.KeyCode.Escape then
                recordingKeyFor = nil
                local h = toggleHandles[featId]
                if h then h.SetKeybind(State.keybinds[featId]) end
                return
            end
            local nk = input.KeyCode.Name
            if nk == "K" then
                Notify("Blocked", "K reserved", 4, true)
                recordingKeyFor = nil
                local h = toggleHandles[featId]
                if h then h.SetKeybind(State.keybinds[featId]) end
                return
            end
            local conflict = findFeatureWithKeybind(nk)
            if conflict and conflict ~= featId then
                Notify("In Use", nk .. " -> " .. (FeatureLabels[conflict] or conflict), 4, true)
                recordingKeyFor = nil
                local h = toggleHandles[featId]
                if h then h.SetKeybind(State.keybinds[featId]) end
                return
            end
            State.keybinds[featId] = nk
            recordingKeyFor = nil
            local h = toggleHandles[featId]
            if h then h.SetKeybind(State.keybinds[featId]) end
            return
        end
        if input.KeyCode == MINIMIZE_KEY then setMinimized(not minimized); return end
        local kn = input.KeyCode.Name
        for featId, k in pairs(State.keybinds) do
            if k and k == kn then
                local h = toggleHandles[featId]
                if h then h.Toggle() end
            end
        end
    end)

    STEP(14, "Finalizado")

    task.wait(0.5)
    Notify("🎯 " .. SHORT_VERSION, "Arsenal DUMP-ready!", 4)

    print("[Infinite Zen] " .. FULL_VERSION .. " carregado!")
    print("[Infinite Zen] Skins encontradas: " .. #skinList)
end

return Arsenal