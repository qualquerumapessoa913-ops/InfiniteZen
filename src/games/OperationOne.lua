-- ============================================================
-- INFINITE ZEN - OPERATION ONE v1.3
-- PlaceId: 8307114974  |  Executor: Real
-- ============================================================

local OperationOne = {}

function OperationOne.Init(ctx)
    local UI = ctx.UI
    local gameName = ctx.gameName or "Operation One"
    local GAME_VERSION = "1.0"
    local FULL_VERSION  = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    local function STEP(n, m) pcall(function() print("[IZ OP1 " .. n .. "] " .. m) end) end
    STEP(1, "Init")

    local Players          = game:GetService("Players")
    local RunService       = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInput     = game:GetService("VirtualInputManager")
    local ReplicatedStorage= game:GetService("ReplicatedStorage")
    local Lighting         = game:GetService("Lighting")
    local LocalPlayer      = Players.LocalPlayer
    local Camera           = workspace.CurrentCamera

    local UNLOADED = false
    local HAS_MOUSEMOVEREL = (type(mousemoverel) == "function")
    local GARBAGE = ReplicatedStorage:WaitForChild("Garbage", 10)
    local ITEMS   = GARBAGE and GARBAGE:FindFirstChild("Items")

    -- ═══ HELPERS ═══
    local function getBasePart(parent, ...)
        if not parent then return nil end
        for _, name in ipairs({...}) do
            for _, c in ipairs(parent:GetChildren()) do
                if c.Name == name and c:IsA("BasePart") then return c end
            end
        end
        return nil
    end

    local function hasLineOfSight(fromPos, targetPart)
        if not targetPart or not targetPart.Parent then return false end
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

    -- isEnemy: detecta players hostis OU NPCs zumbis em Garbage
    local function isEnemy(plr)
        if plr == LocalPlayer then return false end
        local char = plr.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        local myTeam = LocalPlayer.Team
        if myTeam and plr.Team then return plr.Team ~= myTeam end
        return true  -- sem team = PvE, todo mundo é target
    end

    local function getScreenCenter()
        local vp = Camera.ViewportSize
        return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    end

    STEP(2, "Helpers OK")

    -- ═══ STATE ═══
    local State = {
        silentAim=false, silentFov=120,
        aimbot=false, aimbotFov=100, aimbotSmooth=30, aimbotMaxDist=500,
        aimbotHitbox=1, aimbotWallCheck=true,
        triggerbot=false, triggerbotDelay=5,
        autoShoot=false, autoShootFov=100,
        headExpander=false, headExpanderSize=3,
        noRecoil=false, infiniteAmmo=false,
        speed=false, speedValue=50,
        airJump=false, jumpPower=50,
        autoBhop=false, noclip=false, fly=false, flySpeed=60,
        esp=false, espMaxDistance=1000,
        espBox=true, espName=true, espHealth=true, espDistance=true, espTracer=false,
        fullbright=false, lowGraphics=false, noShadows=false, noFog=false, noParticles=false,
        crosshair=false,
    }

    local function getTargetPart(p)
        if not p.Character then return nil end
        local m = State.aimbotHitbox
        if m == 1 then
            return getBasePart(p.Character, "HeadHB", "Head")
        elseif m == 2 then
            return getBasePart(p.Character, "Hitbox", "UpperTorso", "Torso")
        elseif m == 3 then
            for _, n in ipairs({"HeadHB","Head","Hitbox","UpperTorso","HumanoidRootPart"}) do
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

    -- fireWeapon - corrigido
    local function fireWeapon()
        local char = LocalPlayer.Character
        if not char then return false end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return false end
        -- 1) tenta activate
        local ok = pcall(function() tool:Activate() end)
        if ok then return true end
        -- 2) mouse1click
        if type(mouse1click) == "function" then pcall(mouse1click); return true end
        -- 3) virtual
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0,0,0,true,game,0)
            task.wait(0.01)
            VirtualInput:SendMouseButtonEvent(0,0,0,false,game,0)
        end)
        return true
    end

    STEP(3, "State OK")

    -- ═══ WINDOW ═══
    if not UI or type(UI.CreateWindow) ~= "function" then
        warn("[IZ OP1] UI inválida"); return
    end
    local Window = UI:CreateWindow({
        Title = "INFINITE ZEN", Subtitle = SHORT_VERSION,
        ToggleKey = Enum.KeyCode.K,
    })
    if not Window then warn("[IZ OP1] Falha Window"); return end
    STEP(4, "Window OK")

    -- ═══ FOV CIRCLE ═══
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(230, 40, 40)
    fovCircle.Thickness = 1.5; fovCircle.Filled = false
    fovCircle.NumSides = 100; fovCircle.Transparency = 1
    fovCircle.Radius = 100; fovCircle.Visible = false

    local fovConn = RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        fovCircle.Position = getScreenCenter()
        if State.silentAim then fovCircle.Visible = true; fovCircle.Radius = State.silentFov
        elseif State.autoShoot then fovCircle.Visible = true; fovCircle.Radius = State.autoShootFov
        elseif State.aimbot then fovCircle.Visible = true; fovCircle.Radius = State.aimbotFov
        else fovCircle.Visible = false end
    end)

    -- ═══ TARGETING (FOV do centro da tela) ═══
    local function getClosestEnemyInFov(fovRange, requireLOS)
        local center = getScreenCenter()
        local closest, minD = nil, fovRange
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, d = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and d and d > 0 then
                        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if dist < minD then
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

    -- ═══ ESP ═══
    local ESP = { data = {} }
    local function hideAll(d)
        for _, k in ipairs({"box","name","distance","health","tracer","headDot"}) do
            if d[k] then d[k].Visible = false end
        end
        if d.chams then d.chams.Enabled = false end
    end

    local function removeESP(p)
        local d = ESP.data[p]; if not d then return end
        if d.chams then pcall(function() d.chams:Destroy() end) end
        for _, k in ipairs({"box","name","distance","health","tracer","headDot"}) do
            if d[k] and d[k].Remove then pcall(function() d[k]:Remove() end) end
        end
        ESP.data[p] = nil
    end

    local function createESP(p)
        if not p.Character then return end
        if ESP.data[p] and ESP.data[p].character == p.Character then return end
        if ESP.data[p] then removeESP(p) end

        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Color3.fromRGB(255, 30, 40)
        chams.FillTransparency = 0.55
        chams.OutlineColor = Color3.fromRGB(255,255,255)
        chams.OutlineTransparency = 0.3
        chams.Parent = p.Character

        local function nd(class, props)
            local d = Drawing.new(class)
            for k,v in pairs(props) do d[k] = v end
            d.Visible = false; return d
        end
        local data = { chams = chams, character = p.Character }
        data.box      = nd("Square", { Thickness=1.5, Color=Color3.fromRGB(255,30,40), Filled=false, Transparency=1 })
        data.name     = nd("Text",   { Size=14, Center=true, Outline=true, Color=Color3.fromRGB(255,255,255) })
        data.distance = nd("Text",   { Size=12, Center=true, Outline=true, Color=Color3.fromRGB(255,80,80) })
        data.health   = nd("Line",   { Thickness=3, Color=Color3.fromRGB(0,255,0) })
        data.tracer   = nd("Line",   { Thickness=1.2, Color=Color3.fromRGB(255,30,40) })
        data.headDot  = nd("Circle", { Radius=4, NumSides=20, Thickness=1, Filled=false, Color=Color3.fromRGB(255,255,255) })
        ESP.data[p] = data
    end

    local function clearAllESP()
        for p in pairs(ESP.data) do removeESP(p) end
    end

    local function updateESP(p)
        local d = ESP.data[p]; if not d then return end
        local char = p.Character
        if not char or not State.esp or not isEnemy(p) then hideAll(d); return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then hideAll(d); return end
        local head = char:FindFirstChild("Head")
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then hideAll(d); return end
        if d.chams then d.chams.Enabled = true end

        local hSp, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
        local rSp, rOn = Camera:WorldToViewportPoint(hrp.Position)
        local fSp, fOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
        local myR = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myR then hideAll(d); return end
        local dist = math.floor((head.Position - myR.Position).Magnitude)
        if dist > State.espMaxDistance then hideAll(d); return end

        if hOn and fOn and State.espBox then
            local h = math.abs(fSp.Y - hSp.Y)
            local w = h * 0.6
            local cx = (hSp.X + fSp.X) * 0.5
            local cy = (hSp.Y + fSp.Y) * 0.5
            d.box.Position = Vector2.new(cx - w*0.5, cy - h*0.5)
            d.box.Size = Vector2.new(w, h); d.box.Visible = true
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
        else
            d.name.Visible = false; d.distance.Visible = false; d.headDot.Visible = false
        end

        if hOn and fOn and State.espHealth then
            local h = math.abs(fSp.Y - hSp.Y)
            local hr = 1
            if hum.MaxHealth > 0 then hr = math.clamp(hum.Health/hum.MaxHealth, 0, 1) end
            local bx = hSp.X + (h*0.6)*0.5 + 5
            local by = hSp.Y + h
            local fy = by - (h*hr)
            d.health.From = Vector2.new(bx, fy)
            d.health.To   = Vector2.new(bx, by)
            if hr > 0.6 then d.health.Color = Color3.fromRGB(0,255,0)
            elseif hr > 0.3 then d.health.Color = Color3.fromRGB(255,200,0)
            else d.health.Color = Color3.fromRGB(255,40,40) end
            d.health.Visible = true
        else d.health.Visible = false end

        if rOn and State.espTracer then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y)
            d.tracer.To   = Vector2.new(rSp.X, rSp.Y); d.tracer.Visible = true
        else d.tracer.Visible = false end
    end

    STEP(5, "ESP setup")

    -- ═══ MOVEMENT + OPTIM ═══
    local airJumpConn = nil
    local function startAirJump()
        if airJumpConn then airJumpConn:Disconnect() end
        airJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED or not State.airJump then return end
            local char = LocalPlayer.Character; if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, State.jumpPower, hrp.Velocity.Z)
            end
        end)
    end
    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    local origBright = Lighting.Brightness
    local origAmb    = Lighting.Ambient
    local origOut    = Lighting.OutdoorAmbient
    local origClock  = Lighting.ClockTime
    local origShadow = Lighting.GlobalShadows
    local origAtm = {}
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then
            table.insert(origAtm, { obj=c, D=c.Density, H=c.Haze, G=c.Glare })
        end
    end
    local function disableFullbright()
        Lighting.Brightness = origBright
        Lighting.Ambient = origAmb
        Lighting.OutdoorAmbient = origOut
        Lighting.ClockTime = origClock
        Lighting.GlobalShadows = origShadow
        for _, d in ipairs(origAtm) do
            if d.obj and d.obj.Parent then
                pcall(function() d.obj.Density=d.D; d.obj.Haze=d.H; d.obj.Glare=d.G end)
            end
        end
    end

    local optBackup = { fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart, quality=nil, particles={} }
    pcall(function() optBackup.quality = settings().Rendering.QualityLevel end)

    local function applyLowGraphics(v)
        if v then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        elseif optBackup.quality then pcall(function() settings().Rendering.QualityLevel = optBackup.quality end) end
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
            Lighting.FogEnd = 1e6; Lighting.FogStart = 0
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Atmosphere") then c.Density=0; c.Haze=0; c.Glare=0 end
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

    STEP(6, "Functions OK")

    -- ═══ TAB COMBAT ═══
    local CombatTab = Window:CreateTab("Combat", "⚔️")
    CombatTab:CreateSection("Aim")
    CombatTab:CreateToggle({ Name="Silent Aim", Description="Camera lock ao atirar", Icon="🎯", Default=false,
        Callback=function(v) State.silentAim = v end })
    CombatTab:CreateSlider({ Name="Silent FOV", Icon="📐", Min=30, Max=400, Default=120,
        Callback=function(v) State.silentFov = v end })
    CombatTab:CreateToggle({ Name="Aimbot", Description="Mira contínua", Icon="🤖", Default=false,
        Callback=function(v) State.aimbot = v end })
    CombatTab:CreateSlider({ Name="Aimbot FOV", Icon="📐", Min=30, Max=400, Default=100,
        Callback=function(v) State.aimbotFov = v end })
    CombatTab:CreateSlider({ Name="Aimbot Smooth", Icon="🎚️", Min=5, Max=100, Default=30,
        Callback=function(v) State.aimbotSmooth = v end })
    CombatTab:CreateSlider({ Name="Aimbot Max Dist", Icon="📏", Min=50, Max=2000, Default=500,
        Callback=function(v) State.aimbotMaxDist = v end })
    CombatTab:CreateToggle({ Name="Wall Check", Icon="🧱", Default=true,
        Callback=function(v) State.aimbotWallCheck = v end })
    CombatTab:CreateDropdown({ Name="Hitbox", Options={"Head","Torso","Nearest","Auto"}, Default=1,
        Callback=function(_,i) State.aimbotHitbox = i end })

    CombatTab:CreateSection("Auto")
    CombatTab:CreateToggle({ Name="Triggerbot", Icon="🎯", Default=false,
        Callback=function(v) State.triggerbot = v end })
    CombatTab:CreateSlider({ Name="Trigger Delay (ms)", Icon="⏱️", Min=1, Max=200, Default=5,
        Callback=function(v) State.triggerbotDelay = v end })
    CombatTab:CreateToggle({ Name="Auto Shoot", Icon="🔥", Default=false,
        Callback=function(v) State.autoShoot = v end })
    CombatTab:CreateSlider({ Name="Auto Shoot FOV", Icon="📐", Min=30, Max=400, Default=100,
        Callback=function(v) State.autoShootFov = v end })

    CombatTab:CreateSection("Hitbox Expand")
    CombatTab:CreateToggle({ Name="Head Expander", Icon="🔴", Default=false,
        Callback=function(v) State.headExpander = v end })
    CombatTab:CreateSlider({ Name="Hitbox Size", Icon="📏", Min=1, Max=5, Default=3,
        Callback=function(v) State.headExpanderSize = v end })

    -- ═══ TAB WEAPON ═══
    local WeaponTab = Window:CreateTab("Weapon", "🔫")
    WeaponTab:CreateSection("Recoil")
    WeaponTab:CreateToggle({ Name="No Recoil", Icon="🎯", Default=false,
        Callback=function(v) State.noRecoil = v end })
    WeaponTab:CreateToggle({ Name="Infinite Ammo (visual)", Icon="🔋", Default=false,
        Callback=function(v) State.infiniteAmmo = v end })

    -- ═══ TAB MOVEMENT ═══
    local MoveTab = Window:CreateTab("Movement", "🏃")
    MoveTab:CreateSection("Speed")
    MoveTab:CreateToggle({ Name="Speed", Icon="⚡", Default=false,
        Callback=function(v) State.speed = v end })
    MoveTab:CreateSlider({ Name="Speed Value", Icon="📏", Min=16, Max=300, Default=50,
        Callback=function(v) State.speedValue = v end })
    MoveTab:CreateSection("Jump")
    MoveTab:CreateToggle({ Name="Infinite Jump", Icon="🦘", Default=false,
        Callback=function(v) State.airJump = v; if v then startAirJump() else stopAirJump() end end })
    MoveTab:CreateSlider({ Name="Jump Power", Icon="📏", Min=30, Max=300, Default=50,
        Callback=function(v) State.jumpPower = v end })
    MoveTab:CreateToggle({ Name="Auto Bhop", Icon="🏃", Default=false,
        Callback=function(v) State.autoBhop = v end })
    MoveTab:CreateToggle({ Name="Noclip", Icon="👻", Default=false,
        Callback=function(v) State.noclip = v end })
    MoveTab:CreateToggle({ Name="Fly", Icon="🕊️", Default=false,
        Callback=function(v) State.fly = v end })
    MoveTab:CreateSlider({ Name="Fly Speed", Icon="📏", Min=20, Max=300, Default=60,
        Callback=function(v) State.flySpeed = v end })

    -- ═══ TAB VISUALS ═══
    local VisualsTab = Window:CreateTab("Visuals", "👁️")
    VisualsTab:CreateSection("ESP")
    VisualsTab:CreateToggle({ Name="Player ESP", Icon="👤", Default=false,
        Callback=function(v)
            State.esp = v
            if v then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then createESP(p) end
                end
            else clearAllESP() end
        end })
    VisualsTab:CreateSlider({ Name="ESP Max Dist", Icon="📐", Min=100, Max=5000, Default=1000,
        Callback=function(v) State.espMaxDistance = v end })
    VisualsTab:CreateToggle({ Name="ESP Box", Icon="⬜", Default=true,
        Callback=function(v) State.espBox = v end })
    VisualsTab:CreateToggle({ Name="ESP Name", Icon="📛", Default=true,
        Callback=function(v) State.espName = v end })
    VisualsTab:CreateToggle({ Name="ESP Health", Icon="❤️", Default=true,
        Callback=function(v) State.espHealth = v end })
    VisualsTab:CreateToggle({ Name="ESP Distance", Icon="📏", Default=true,
        Callback=function(v) State.espDistance = v end })
    VisualsTab:CreateToggle({ Name="ESP Tracer", Icon="📡", Default=false,
        Callback=function(v) State.espTracer = v end })

    VisualsTab:CreateSection("Environment")
    VisualsTab:CreateToggle({ Name="Fullbright", Icon="💡", Default=false,
        Callback=function(v) State.fullbright = v; if not v then disableFullbright() end end })
    VisualsTab:CreateToggle({ Name="Low Graphics", Icon="📉", Default=false,
        Callback=function(v) State.lowGraphics = v; applyLowGraphics(v) end })
    VisualsTab:CreateToggle({ Name="No Shadows", Icon="🌑", Default=false,
        Callback=function(v) State.noShadows = v; applyNoShadows(v) end })
    VisualsTab:CreateToggle({ Name="No Fog", Icon="🌫️", Default=false,
        Callback=function(v) State.noFog = v; applyNoFog(v) end })
    VisualsTab:CreateToggle({ Name="No Particles", Icon="✨", Default=false,
        Callback=function(v) State.noParticles = v; applyNoParticles(v) end })

    -- ═══ TAB SETTINGS ═══
    local SettingsTab = Window:CreateTab("Settings", "⚙️")
    SettingsTab:CreateSection("Optimizations")
    SettingsTab:CreateButton({ Name="⚡ Max FPS Boost",
        Callback=function()
            State.lowGraphics=true; applyLowGraphics(true)
            State.noShadows=true; applyNoShadows(true)
            State.noFog=true; applyNoFog(true)
            State.noParticles=true; applyNoParticles(true)
            Window:Notify("⚡ Boost","ON",3,"success")
        end })
    SettingsTab:CreateButton({ Name="🔄 Reset Optimizations",
        Callback=function()
            State.lowGraphics=false; applyLowGraphics(false)
            State.noShadows=false; applyNoShadows(false)
            State.noFog=false; applyNoFog(false)
            State.noParticles=false; applyNoParticles(false)
            Window:Notify("Reset","OK",3,"info")
        end })
    SettingsTab:CreateSection("Danger Zone")
    SettingsTab:CreateButton({ Name="Unload Script", Danger=true,
        Callback=function()
            UNLOADED = true
            clearAllESP(); stopAirJump(); disableFullbright()
            applyLowGraphics(false); applyNoShadows(false)
            applyNoFog(false); applyNoParticles(false)
            pcall(function() RunService:UnbindFromRenderStep("IZ_Aimbot") end)
            pcall(function() RunService:UnbindFromRenderStep("IZ_Silent") end)
            pcall(function() RunService:UnbindFromRenderStep("IZ_SilentCam") end)
            pcall(function() RunService:UnbindFromRenderStep("IZ_Fly") end)
            if fovConn then fovConn:Disconnect() end
            if fovCircle then pcall(function() fovCircle:Remove() end) end
            Window:Notify("Unload","Unloaded",2,"warning")
            task.wait(0.3); Window:Destroy()
        end })

    -- ═══ TAB CREDITS ═══
    local CreditsTab = Window:CreateTab("Credits", "➕")
    CreditsTab:CreateSection("Founder & Developer")
    CreditsTab:CreateLabel("Sr Red", Color3.fromRGB(255,50,50))
    CreditsTab:CreateSection("Community")
    CreditsTab:CreateLabel("discord.gg/ScZfU2mAGm", Color3.fromRGB(88,101,242))
    CreditsTab:CreateButton({ Name="📋 Copy Discord Link",
        Callback=function()
            if setclipboard then setclipboard("https://discord.gg/ScZfU2mAGm")
                Window:Notify("📋","Copied",3,"success") end
        end })
    CreditsTab:CreateSection("Version")
    CreditsTab:CreateLabel(FULL_VERSION, Color3.fromRGB(140,140,155))
    CreditsTab:CreateLabel("© 2026 Sr Red", Color3.fromRGB(90,90,105))

    STEP(7, "Tabs OK")

    -- ═══════════════════════════════════════════════════════════
    -- COMBAT LOOPS
    -- ═══════════════════════════════════════════════════════════

    -- AIMBOT (prioridade acima da câmera do jogo)
    RunService:BindToRenderStep("IZ_Aimbot", Enum.RenderPriority.Camera.Value + 1, function()
        if UNLOADED or not State.aimbot then return end
        local target = getClosestEnemyInFov(State.aimbotFov, State.aimbotWallCheck)
        if not target then return end
        local part = getTargetPart(target)
        if not part then return end
        local myR = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myR then return end
        if (part.Position - myR.Position).Magnitude > State.aimbotMaxDist then return end

        local camPos = Camera.CFrame.Position
        local targetDir = (part.Position - camPos).Unit
        local currentDir = Camera.CFrame.LookVector
        local alpha = 1 - (State.aimbotSmooth / 100)
        if alpha <= 0 then alpha = 0.02 end
        if alpha > 1 then alpha = 1 end

        if HAS_MOUSEMOVEREL then
            local sp = Camera:WorldToViewportPoint(part.Position)
            local c = getScreenCenter()
            pcall(mousemoverel, (sp.X - c.X) * alpha, (sp.Y - c.Y) * alpha)
        else
            local newDir = currentDir:Lerp(targetDir, alpha)
            pcall(function() Camera.CFrame = CFrame.lookAt(camPos, camPos + newDir) end)
        end
    end)

    -- SILENT AIM (camera override)
    local silentHolding, silentTarget = false, nil

    RunService:BindToRenderStep("IZ_Silent", Enum.RenderPriority.Camera.Value + 2, function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then silentHolding = false; return end
        local part = getTargetPart(silentTarget)
        if not part then silentHolding = false; return end
        pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position) end)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.silentAim then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
           and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local t = getClosestEnemyInFov(State.silentFov, State.aimbotWallCheck)
        if t then silentTarget = t; silentHolding = true end
    end)
    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
           and input.UserInputType ~= Enum.UserInputType.Touch then return end
        silentHolding = false; silentTarget = nil
    end)

    -- TRIGGERBOT
    local triggerLast = 0
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.triggerbot then return end
        if tick() - triggerLast < (State.triggerbotDelay / 1000) then return end
        local c = getScreenCenter()
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, d = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and d and d > 0 and (Vector2.new(sp.X, sp.Y) - c).Magnitude < 25 then
                        triggerLast = tick(); fireWeapon(); break
                    end
                end
            end
        end
    end)

    -- AUTO SHOOT
    local lastAutoShot = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoShoot then return end
        if tick() - lastAutoShot < 0.05 then return end
        local t = getClosestEnemyInFov(State.autoShootFov, State.aimbotWallCheck)
        if t then lastAutoShot = tick(); fireWeapon() end
    end)

    STEP(8, "Combat loops OK")

    -- ═══ HEAD EXPANDER ═══
    local hitboxSaved = {}
    local function saveOrig(p, part)
        if not p or not part or not part:IsA("BasePart") then return end
        if not hitboxSaved[p] then hitboxSaved[p] = {} end
        if not hitboxSaved[p][part] then
            local ok, sz = pcall(function() return part.Size end)
            if ok then hitboxSaved[p][part] = sz end
        end
    end
    local function restorePlayer(p)
        if not hitboxSaved[p] then return end
        for part, sz in pairs(hitboxSaved[p]) do
            if part and part.Parent then pcall(function() part.Size = sz end) end
        end
        hitboxSaved[p] = nil
    end
    local function expandPlayer(p, size)
        if not p.Character then return end
        local parts = {
            { n={"Head"},           mult=size,           trans=0.7 },
            { n={"HeadHB"},         mult=math.min(size*1.5,12), trans=1 },
            { n={"Hitbox"},         mult=size,           trans=0.85 },
            { n={"UpperTorso","Torso"}, mult=math.min(size*0.7,3), trans=0.7 },
        }
        for _, cfg in ipairs(parts) do
            local bp = getBasePart(p.Character, unpack(cfg.n))
            if bp then
                saveOrig(p, bp)
                local base = hitboxSaved[p] and hitboxSaved[p][bp]
                if base then
                    pcall(function()
                        bp.Size = Vector3.new(base.X*cfg.mult, base.Y*cfg.mult, base.Z*cfg.mult)
                        bp.Transparency = cfg.trans
                        bp.CanCollide = false
                        bp.Massless = true
                    end)
                end
            end
        end
    end
    local heTick = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if not State.headExpander then
            for p in pairs(hitboxSaved) do restorePlayer(p) end
            return
        end
        heTick = heTick + 1
        if heTick % 3 ~= 0 then return end
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isEnemy(p) then
                    if p.Character then expandPlayer(p, State.headExpanderSize) end
                else
                    if hitboxSaved[p] then restorePlayer(p) end
                end
            end
        end)
    end)

    -- ═══ NO RECOIL / INF AMMO — hook nos valores de todas as armas ═══
    local function zeroWeaponValues(container)
        for _, d in ipairs(container:GetDescendants()) do
            if d:IsA("NumberValue") or d:IsA("IntValue") then
                local n = d.Name:lower()
                if n:find("recoil") or n:find("kick") or n:find("spread") or n:find("camera") then
                    pcall(function() d.Value = 0 end)
                end
            end
        end
    end
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.noRecoil then return end
        local char = LocalPlayer.Character; if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then zeroWeaponValues(tool) end
        if ITEMS then zeroWeaponValues(ITEMS) end
    end)

    -- ═══ ESP LOOP ═══
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.esp then return end
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    createESP(p)
                    updateESP(p)
                end
            end
        end)
    end)
    Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            if ESP.data[p] then removeESP(p) end
            if State.esp then createESP(p) end
        end)
    end)

    -- ═══ MOVEMENT LOOPS ═══
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
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local st = hum:GetState()
        if (st == Enum.HumanoidStateType.Landed or st == Enum.HumanoidStateType.Running)
           and UserInputService:IsKeyDown(Enum.KeyCode.Space) then hum.Jump = true end
    end)

    RunService.Stepped:Connect(function()
        if UNLOADED or not State.noclip then return end
        local char = LocalPlayer.Character; if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                pcall(function() part.CanCollide = false end)
            end
        end
    end)

    -- FLY
    RunService:BindToRenderStep("IZ_Fly", Enum.RenderPriority.Character.Value + 1, function(dt)
        if UNLOADED or not State.fly then return end
        local char = LocalPlayer.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        hum.PlatformStand = true
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
        hrp.Velocity = move.Magnitude > 0 and (move.Unit * State.flySpeed) or Vector3.zero
    end)

    -- ═══ FULLBRIGHT + PARTICLES ═══
    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if State.fullbright then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(200,200,200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Atmosphere") then c.Density=0; c.Haze=0; c.Glare=0 end
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

    STEP(9, "TUDO CARREGADO")

    Window:Notify("✅ " .. SHORT_VERSION, "Operation One loaded", 4, "success")
    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
end

return OperationOne