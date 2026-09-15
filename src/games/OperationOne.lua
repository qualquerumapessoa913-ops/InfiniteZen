-- ============================================================
-- INFINITE ZEN - MÓDULO OPERATION ONE v1.0
-- ============================================================

local OperationOne = {}

function OperationOne.Init(ctx)
    local Language = ctx.Language
    local UI = ctx.UI
    local gameName = ctx.gameName

    local GAME_VERSION = "1.0"
    local FULL_VERSION = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    local function STEP(n, msg) pcall(function() print("[IZ OP1 Step " .. n .. "] " .. msg) end) end
    STEP(1, "Init iniciou")

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInput = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    local UNLOADED = false

    -- ============================================
    -- HELPERS
    -- ============================================
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

    STEP(2, "Helpers OK")

    -- ============================================
    -- STATE
    -- ============================================
    local State = {
        silentAim = false, silentFov = 120,
        aimbot = false, aimbotFov = 100, aimbotSmooth = 0.3,
        aimbotMaxDist = 500, aimbotHitbox = 1, aimbotWallCheck = true,
        triggerbot = false, triggerbotDelay = 5,
        autoShoot = false, autoShootFov = 100,
        headExpander = false, headExpanderSize = 3,
        noRecoil = false,
        speed = false, speedValue = 50,
        airJump = false, jumpPower = 50,
        autoBhop = false, noclip = false,
        esp = false, espMaxDistance = 1000,
        espBox = true, espName = true, espHealth = true,
        espDistance = true, espTracer = false,
        fullbright = false,
        lowGraphics = false, noShadows = false, noFog = false, noParticles = false,
    }

    local function getTargetPart(p)
        if not p.Character then return nil end
        local mode = State.aimbotHitbox
        if mode == 1 then
            return getBasePart(p.Character, "HeadHB", "Head")
        elseif mode == 2 then
            return getBasePart(p.Character, "Hitbox", "UpperTorso", "Torso")
        elseif mode == 3 then
            for _, n in ipairs({"Hitbox", "HeadHB", "Head", "UpperTorso", "HumanoidRootPart"}) do
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
            task.wait(0.005)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
        pcall(function() tool:Activate() end)
        return true
    end

    STEP(3, "State + helpers OK")

    -- ============================================
    -- WINDOW
    -- ============================================
    if not UI or type(UI.CreateWindow) ~= "function" then
        warn("[IZ OP1] UI inválida")
        return
    end

    local Window = UI:CreateWindow({
        Title = "INFINITE ZEN",
        Subtitle = SHORT_VERSION,
        ToggleKey = Enum.KeyCode.K,
    })
    if not Window then
        warn("[IZ OP1] Falha ao criar Window")
        return
    end
    STEP(4, "Window OK")

    -- ============================================
    -- FOV CIRCLE
    -- ============================================
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(230, 40, 40); fovCircle.Thickness = 1.5
    fovCircle.Filled = false; fovCircle.NumSides = 100; fovCircle.Transparency = 1
    fovCircle.Radius = 25; fovCircle.Visible = false

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        local mouse = UserInputService:GetMouseLocation()
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
        if State.silentAim then
            fovCircle.Visible = true; fovCircle.Radius = State.silentFov / 6
        elseif State.autoShoot then
            fovCircle.Visible = true; fovCircle.Radius = State.autoShootFov / 6
        elseif State.aimbot then
            fovCircle.Visible = true; fovCircle.Radius = State.aimbotFov / 6
        else
            fovCircle.Visible = false
        end
    end)

    -- ============================================
    -- TARGETING
    -- ============================================
    local function getClosestEnemyInFov(fovRange, requireLOS)
        local mouse = UserInputService:GetMouseLocation()
        local closest, minD = nil, fovRange
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, d = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and d and d > 0 then
                        local dist = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
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

    STEP(5, "Targeting OK")

    -- ============================================
    -- ESP
    -- ============================================
    local ESP = { data = {} }

    local function createESP(p)
        if ESP.data[p] or not p.Character then return end
        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Color3.fromRGB(255, 30, 40)
        chams.FillTransparency = 0.6
        chams.OutlineColor = Color3.fromRGB(255, 255, 255)
        chams.OutlineTransparency = 0.3
        chams.Parent = p.Character
        local data = { chams = chams }
        local function nd(class, props)
            local d = Drawing.new(class)
            for k, v in pairs(props) do d[k] = v end
            d.Visible = false
            return d
        end
        data.box = nd("Square", { Thickness = 1.5, Color = Color3.fromRGB(255, 30, 40), Filled = false, Transparency = 1 })
        data.name = nd("Text", { Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255) })
        data.distance = nd("Text", { Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255, 80, 80) })
        data.health = nd("Line", { Thickness = 3, Color = Color3.fromRGB(0, 255, 0) })
        data.tracer = nd("Line", { Thickness = 1.2, Color = Color3.fromRGB(255, 30, 40) })
        data.headDot = nd("Circle", { Radius = 4, NumSides = 20, Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255) })
        ESP.data[p] = data
    end

    local function removeESP(p)
        local d = ESP.data[p]
        if not d then return end
        if d.chams then pcall(function() d.chams:Destroy() end) end
        for _, key in ipairs({ "box", "name", "distance", "health", "tracer", "headDot" }) do
            if d[key] and d[key].Remove then pcall(function() d[key]:Remove() end) end
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
            for _, key in ipairs({ "box", "name", "distance", "health", "tracer", "headDot" }) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            for _, key in ipairs({ "box", "name", "distance", "health", "tracer", "headDot" }) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then return end
        if d.chams then d.chams.Enabled = true end
        local hSp, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local rSp, rOn = Camera:WorldToViewportPoint(hrp.Position)
        local fSp, fOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local myR = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myR then return end
        local dist = math.floor((head.Position - myR.Position).Magnitude)
        if dist > State.espMaxDistance then
            for _, key in ipairs({ "box", "name", "distance", "health", "tracer", "headDot" }) do
                if d[key] then d[key].Visible = false end
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
        else
            d.box.Visible = false
        end
        if hOn then
            if State.espName then
                d.name.Position = Vector2.new(hSp.X, hSp.Y - 20)
                d.name.Text = p.Name
                d.name.Visible = true
            else
                d.name.Visible = false
            end
            if State.espDistance then
                d.distance.Position = Vector2.new(hSp.X, hSp.Y - 6)
                d.distance.Text = dist .. "m"
                d.distance.Visible = true
            else
                d.distance.Visible = false
            end
            d.headDot.Position = Vector2.new(hSp.X, hSp.Y)
            d.headDot.Visible = true
        else
            d.name.Visible = false
            d.distance.Visible = false
            d.headDot.Visible = false
        end
        if hOn and fOn and State.espHealth then
            local h = math.abs(fSp.Y - hSp.Y)
            local maxHP = hum.MaxHealth
            local hr = 1
            if maxHP and maxHP > 0 then
                hr = math.clamp(hum.Health / maxHP, 0, 1)
            end
            local bx = hSp.X + (h * 0.6) / 2 + 5
            local by = hSp.Y + h
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
        if rOn and State.espTracer then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To = Vector2.new(rSp.X, rSp.Y)
            d.tracer.Visible = true
        else
            d.tracer.Visible = false
        end
    end

    STEP(6, "ESP setup OK")

    -- ============================================
    -- MOVEMENT FUNCTIONS
    -- ============================================
    local airJumpConn = nil
    local function startAirJump()
        if airJumpConn then airJumpConn:Disconnect() end
        airJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED or not State.airJump then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end
            if hum:GetState() == Enum.HumanoidStateType.Dead then return end
            hrp.Velocity = Vector3.new(hrp.Velocity.X, State.jumpPower, hrp.Velocity.Z)
        end)
    end
    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    -- ============================================
    -- OPTIMIZATION FUNCTIONS
    -- ============================================
    local origBrightness = Lighting.Brightness
    local origAmbient = Lighting.Ambient
    local origOutdoorAmbient = Lighting.OutdoorAmbient
    local origClockTime = Lighting.ClockTime
    local origGlobalShadows = Lighting.GlobalShadows
    local origAtmosphere = {}
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then
            table.insert(origAtmosphere, { obj = c, D = c.Density, H = c.Haze, G = c.Glare })
        end
    end

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

    local optBackup = {
        fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart,
        qualityLevel = nil, particles = {},
    }
    pcall(function() optBackup.qualityLevel = settings().Rendering.QualityLevel end)

    local function applyLowGraphics(v)
        if v then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        elseif optBackup.qualityLevel then pcall(function() settings().Rendering.QualityLevel = optBackup.qualityLevel end) end
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

    STEP(7, "Functions OK")

    -- ============================================
    -- TAB COMBAT
    -- ============================================
    local CombatTab = Window:CreateTab("Combat", "⚔️")
    if not CombatTab then
        warn("[IZ OP1] Falha ao criar CombatTab")
        return
    end

    CombatTab:CreateSection("Aim")

    CombatTab:CreateToggle({
        Name = "Silent Aim",
        Description = "Lock aim when holding click",
        Icon = "🎯",
        Default = false,
        Callback = function(v) State.silentAim = v end,
    })
    CombatTab:CreateSlider({
        Name = "Silent FOV",
        Description = "Field of view radius",
        Icon = "📐",
        Min = 30, Max = 300, Default = 120,
        Callback = function(v) State.silentFov = v end,
    })
    CombatTab:CreateToggle({
        Name = "Aimbot",
        Description = "Continuous aim at closest enemy",
        Icon = "🤖",
        Default = false,
        Callback = function(v) State.aimbot = v end,
    })
    CombatTab:CreateSlider({
        Name = "Aimbot FOV",
        Description = "Field of view radius",
        Icon = "📐",
        Min = 30, Max = 300, Default = 100,
        Callback = function(v) State.aimbotFov = v end,
    })
    CombatTab:CreateSlider({
        Name = "Aimbot Smoothness",
        Description = "Lower = snappier",
        Icon = "🎚️",
        Min = 5, Max = 100, Default = 30,
        Callback = function(v) State.aimbotSmooth = v / 100 end,
    })
    CombatTab:CreateSlider({
        Name = "Aimbot Max Distance",
        Description = "Max range",
        Icon = "📏",
        Min = 50, Max = 2000, Default = 500,
        Callback = function(v) State.aimbotMaxDist = v end,
    })
    CombatTab:CreateToggle({
        Name = "Aimbot Wall Check",
        Description = "Only aim if visible",
        Icon = "🧱",
        Default = true,
        Callback = function(v) State.aimbotWallCheck = v end,
    })
    CombatTab:CreateDropdown({
        Name = "Hitbox",
        Description = "Which part to target",
        Icon = "🎯",
        Options = { "Head", "Torso", "Nearest", "Auto" },
        Default = 1,
        Callback = function(opt, idx) State.aimbotHitbox = idx end,
    })

    CombatTab:CreateSection("Auto")

    CombatTab:CreateToggle({
        Name = "Triggerbot",
        Description = "Auto-fire when crosshair over target",
        Icon = "🎯",
        Default = false,
        Callback = function(v) State.triggerbot = v end,
    })
    CombatTab:CreateSlider({
        Name = "Triggerbot Delay",
        Description = "Reaction delay (ms)",
        Icon = "⏱️",
        Min = 1, Max = 100, Default = 5,
        Callback = function(v) State.triggerbotDelay = v end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Shoot",
        Description = "Auto-fire on visible enemies",
        Icon = "🔥",
        Default = false,
        Callback = function(v) State.autoShoot = v end,
    })
    CombatTab:CreateSlider({
        Name = "Auto Shoot FOV",
        Description = "FOV for auto-fire",
        Icon = "📐",
        Min = 30, Max = 300, Default = 100,
        Callback = function(v) State.autoShootFov = v end,
    })

    CombatTab:CreateSection("Hitbox")

    CombatTab:CreateToggle({
        Name = "Head Expander",
        Description = "Enlarge enemy hitboxes",
        Icon = "🔴",
        Default = false,
        Callback = function(v) State.headExpander = v end,
    })
    CombatTab:CreateSlider({
        Name = "Hitbox Size",
        Description = "Multiplier",
        Icon = "📏",
        Min = 1, Max = 5, Default = 3,
        Callback = function(v) State.headExpanderSize = v end,
    })

    STEP(8, "Combat tab OK")

    -- ============================================
    -- TAB WEAPON
    -- ============================================
    local WeaponTab = Window:CreateTab("Weapon", "🔫")
    WeaponTab:CreateSection("Recoil")
    WeaponTab:CreateToggle({
        Name = "No Recoil",
        Description = "Remove weapon recoil",
        Icon = "🎯",
        Default = false,
        Callback = function(v) State.noRecoil = v end,
    })

    -- ============================================
    -- TAB MOVEMENT
    -- ============================================
    local MoveTab = Window:CreateTab("Movement", "🏃")
    MoveTab:CreateSection("Speed")
    MoveTab:CreateToggle({
        Name = "Speed",
        Description = "Custom walkspeed",
        Icon = "⚡",
        Default = false,
        Callback = function(v) State.speed = v end,
    })
    MoveTab:CreateSlider({
        Name = "Speed Value",
        Description = "WalkSpeed value",
        Icon = "📏",
        Min = 16, Max = 300, Default = 50,
        Callback = function(v) State.speedValue = v end,
    })

    MoveTab:CreateSection("Jump")
    MoveTab:CreateToggle({
        Name = "Infinite Jump",
        Description = "Jump mid-air infinitely",
        Icon = "🦘",
        Default = false,
        Callback = function(v)
            State.airJump = v
            if v then startAirJump() else stopAirJump() end
        end,
    })
    MoveTab:CreateSlider({
        Name = "Jump Power",
        Description = "Jump velocity",
        Icon = "📏",
        Min = 30, Max = 300, Default = 50,
        Callback = function(v) State.jumpPower = v end,
    })
    MoveTab:CreateToggle({
        Name = "Auto Bhop",
        Description = "Auto-jump while holding space",
        Icon = "🏃",
        Default = false,
        Callback = function(v) State.autoBhop = v end,
    })
    MoveTab:CreateToggle({
        Name = "Noclip",
        Description = "Walk through walls",
        Icon = "👻",
        Default = false,
        Callback = function(v) State.noclip = v end,
    })

    STEP(9, "Movement tab OK")

    -- ============================================
    -- TAB VISUALS
    -- ============================================
    local VisualsTab = Window:CreateTab("Visuals", "👁️")
    VisualsTab:CreateSection("ESP")

    VisualsTab:CreateToggle({
        Name = "Player ESP",
        Description = "Highlight enemies",
        Icon = "👤",
        Default = false,
        Callback = function(v)
            State.esp = v
            if v then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then createESP(p) end
                end
            else
                clearAllESP()
            end
        end,
    })
    VisualsTab:CreateSlider({
        Name = "ESP Max Distance",
        Description = "Render range",
        Icon = "📐",
        Min = 100, Max = 5000, Default = 1000,
        Callback = function(v) State.espMaxDistance = v end,
    })
    VisualsTab:CreateToggle({
        Name = "ESP Box",
        Description = "Show box around enemies",
        Icon = "⬜",
        Default = true,
        Callback = function(v) State.espBox = v end,
    })
    VisualsTab:CreateToggle({
        Name = "ESP Name",
        Description = "Show player names",
        Icon = "📛",
        Default = true,
        Callback = function(v) State.espName = v end,
    })
    VisualsTab:CreateToggle({
        Name = "ESP Health",
        Description = "Show health bar",
        Icon = "❤️",
        Default = true,
        Callback = function(v) State.espHealth = v end,
    })
    VisualsTab:CreateToggle({
        Name = "ESP Distance",
        Description = "Show distance",
        Icon = "📏",
        Default = true,
        Callback = function(v) State.espDistance = v end,
    })
    VisualsTab:CreateToggle({
        Name = "ESP Tracer",
        Description = "Draw tracer lines",
        Icon = "📡",
        Default = false,
        Callback = function(v) State.espTracer = v end,
    })

    VisualsTab:CreateSection("Environment")

    VisualsTab:CreateToggle({
        Name = "Fullbright",
        Description = "Map always bright",
        Icon = "💡",
        Default = false,
        Callback = function(v)
            State.fullbright = v
            if not v then disableFullbright() end
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Low Graphics",
        Description = "Reduce rendering quality",
        Icon = "📉",
        Default = false,
        Callback = function(v) State.lowGraphics = v; applyLowGraphics(v) end,
    })
    VisualsTab:CreateToggle({
        Name = "No Shadows",
        Description = "Remove all shadows",
        Icon = "🌑",
        Default = false,
        Callback = function(v) State.noShadows = v; applyNoShadows(v) end,
    })
    VisualsTab:CreateToggle({
        Name = "No Fog",
        Description = "Remove fog",
        Icon = "🌫️",
        Default = false,
        Callback = function(v) State.noFog = v; applyNoFog(v) end,
    })
    VisualsTab:CreateToggle({
        Name = "No Particles",
        Description = "Remove particle effects",
        Icon = "✨",
        Default = false,
        Callback = function(v) State.noParticles = v; applyNoParticles(v) end,
    })

    STEP(10, "Visuals tab OK")

    -- ============================================
    -- TAB SETTINGS
    -- ============================================
    local SettingsTab = Window:CreateTab("Settings", "⚙️")
    SettingsTab:CreateSection("Optimizations")

    SettingsTab:CreateButton({
        Name = "⚡ Max FPS Boost",
        Callback = function()
            State.lowGraphics = true; applyLowGraphics(true)
            State.noShadows = true; applyNoShadows(true)
            State.noFog = true; applyNoFog(true)
            State.noParticles = true; applyNoParticles(true)
            Window:Notify("⚡ Boost", "All optimizations ON", 3, "success")
        end,
    })
    SettingsTab:CreateButton({
        Name = "🔄 Reset Optimizations",
        Callback = function()
            State.lowGraphics = false; applyLowGraphics(false)
            State.noShadows = false; applyNoShadows(false)
            State.noFog = false; applyNoFog(false)
            State.noParticles = false; applyNoParticles(false)
            Window:Notify("Reset", "Optimizations reset", 3, "info")
        end,
    })

    SettingsTab:CreateSection("Danger Zone")

    SettingsTab:CreateButton({
        Name = "Unload Script",
        Danger = true,
        Callback = function()
            UNLOADED = true
            clearAllESP()
            stopAirJump()
            disableFullbright()
            applyLowGraphics(false)
            applyNoShadows(false)
            applyNoFog(false)
            applyNoParticles(false)
            if fovCircle then fovCircle:Remove() end
            Window:Notify("Unload", "Script unloaded", 2, "warning")
            task.wait(0.3)
            Window:Destroy()
        end,
    })

    -- ============================================
    -- TAB CREDITS
    -- ============================================
    local CreditsTab = Window:CreateTab("Credits", "➕")
    CreditsTab:CreateSection("Founder & Developer")
    CreditsTab:CreateLabel("Sr Red", Color3.fromRGB(255, 50, 50))
    CreditsTab:CreateSection("Community")
    CreditsTab:CreateLabel("discord.gg/ScZfU2mAGm", Color3.fromRGB(88, 101, 242))
    CreditsTab:CreateButton({
        Name = "📋 Copy Discord Link",
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/ScZfU2mAGm")
                Window:Notify("📋 Copied", "Discord link copied!", 3, "success")
            end
        end,
    })
    CreditsTab:CreateSection("Version")
    CreditsTab:CreateLabel(FULL_VERSION, Color3.fromRGB(140, 140, 155))
    CreditsTab:CreateLabel("© 2026 Sr Red", Color3.fromRGB(90, 90, 105))

    STEP(11, "All tabs OK")

    -- ============================================
    -- COMBAT LOOPS
    -- ============================================
    local silentHolding, silentTarget = false, nil

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then silentHolding = false; return end
        local part = getTargetPart(silentTarget)
        if not part then silentHolding = false; return end
        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.silentAim then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local target = getClosestEnemyInFov(State.silentFov, State.aimbotWallCheck)
        if target then
            silentTarget = target
            silentHolding = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if silentHolding then
            silentHolding = false
            silentTarget = nil
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
                            if mousemoverel then
                                pcall(function()
                                    mousemoverel(
                                        (sp.X - m.X) * State.aimbotSmooth,
                                        (sp.Y - m.Y) * State.aimbotSmooth
                                    )
                                end)
                            end
                        end
                    end
                end
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
        if UNLOADED or not State.autoShoot then return end
        if tick() - lastAutoShot < 0.05 then return end
        local target = getClosestEnemyInFov(State.autoShootFov, State.aimbotWallCheck)
        if target then
            lastAutoShot = tick()
            fireWeapon()
        end
    end)

    STEP(12, "Combat loops OK")

    -- ============================================
    -- HEAD EXPANDER
    -- ============================================
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

    local function expandPlayer(p, size)
        if not p.Character then return end
        local head = getBasePart(p.Character, "Head")
        if head then
            saveOrig(p, head)
            local base = hitboxSaved[p] and hitboxSaved[p][head]
            if base then
                pcall(function()
                    head.Size = Vector3.new(base.X * size, base.Y * math.min(size, 4), base.Z * size)
                    head.Transparency = 0.7
                    head.CanCollide = false
                    head.Massless = true
                end)
            end
        end
        local headHB = getBasePart(p.Character, "HeadHB")
        if headHB then
            saveOrig(p, headHB)
            local base = hitboxSaved[p] and hitboxSaved[p][headHB]
            if base then
                local hbMult = math.min(size * 1.5, 12)
                pcall(function()
                    headHB.Size = Vector3.new(base.X * hbMult, base.Y * hbMult, base.Z * hbMult)
                    headHB.Transparency = 1
                    headHB.CanCollide = false
                    headHB.Massless = true
                end)
            end
        end
        local hitbox = getBasePart(p.Character, "Hitbox")
        if hitbox then
            saveOrig(p, hitbox)
            local base = hitboxSaved[p] and hitboxSaved[p][hitbox]
            if base then
                pcall(function()
                    hitbox.Size = Vector3.new(base.X * size, base.Y * size, base.Z * size)
                    hitbox.Transparency = 0.85
                    hitbox.CanCollide = false
                    hitbox.Massless = true
                end)
            end
        end
        local torso = getBasePart(p.Character, "UpperTorso", "Torso")
        if torso then
            saveOrig(p, torso)
            local base = hitboxSaved[p] and hitboxSaved[p][torso]
            if base then
                local tMult = math.min(size * 0.7, 3)
                pcall(function()
                    torso.Size = Vector3.new(base.X * tMult, base.Y * tMult, base.Z * tMult)
                    torso.Transparency = 0.7
                    torso.CanCollide = false
                    torso.Massless = true
                end)
            end
        end
    end

    local heTick = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.headExpander then return end
        heTick = heTick + 1
        if heTick % 3 ~= 0 then return end
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer then
                elseif isEnemy(p) then
                    if p.Character then expandPlayer(p, State.headExpanderSize) end
                else
                    if hitboxSaved[p] then restorePlayer(p) end
                end
            end
        end)
    end)

    STEP(13, "Head Expander OK")

    -- ============================================
    -- NO RECOIL
    -- ============================================
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.noRecoil then return end
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end
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
        local rsWeapons = ReplicatedStorage:FindFirstChild("Weapons")
        if rsWeapons then
            pcall(function()
                for _, d in ipairs(rsWeapons:GetDescendants()) do
                    if d:IsA("NumberValue") or d:IsA("IntValue") then
                        local n = d.Name:lower()
                        if n:find("recoil") or n:find("kick") or n:find("spread") then
                            d.Value = 0
                        end
                    end
                end
            end)
        end
    end)

    -- ============================================
    -- ESP LOOP
    -- ============================================
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

    -- ============================================
    -- MOVEMENT LOOPS
    -- ============================================
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

    -- ============================================
    -- FULLBRIGHT LOOP
    -- ============================================
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

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.noParticles then return end
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
                pcall(function() d.Enabled = false end)
            end
        end
    end)

    STEP(14, "TUDO CARREGADO")

    Window:Notify("✅ " .. SHORT_VERSION, "Operation One loaded", 4, "success")
    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
end

return OperationOne