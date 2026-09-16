-- ============================================================
-- INFINITE ZEN - MURDER MYSTERY 2 (Refatorado v1.1)
-- ============================================================

local MM2 = {}

function MM2.Init(ctx)
    local Language = ctx.Language
    local UI       = ctx.UI
    local Compat   = ctx.Compat
    local gameName = ctx.gameName

    local function T(key) return Language.get(key) end

    local GAME_VERSION = "1.1"
    local FULL_VERSION = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("[Infinite Zen] Inicializando " .. FULL_VERSION .. "...")

    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local UserInputService  = game:GetService("UserInputService")
    local VirtualInput      = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService       = game:GetService("HttpService")
    local Lighting          = game:GetService("Lighting")
    local SoundService      = game:GetService("SoundService")
    local LocalPlayer       = Players.LocalPlayer
    local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
    local Camera            = workspace.CurrentCamera

    local UNLOADED = false

    -- ═══════════════════════════════════════════════
    -- UI ELEMENTS REGISTRY
    -- ═══════════════════════════════════════════════
    local Elements = {}
    local Window = nil

    local function setToggle(el, val)
        if not el or type(el.SetState) ~= "function" then return false end
        return pcall(function() el.SetState(val) end)
    end

    local function setSlider(el, val)
        if not el or type(el.SetValue) ~= "function" then return false end
        return pcall(function() el.SetValue(val) end)
    end

    local function reg(id, el)
        if id and el then Elements[id] = el end
        return el
    end

    -- ═══════════════════════════════════════════════
    -- REMOTES
    -- ═══════════════════════════════════════════════
    local GE = ReplicatedStorage:FindFirstChild("GameEvents")
    local Remotes = {
        KillEvent = GE and GE:FindFirstChild("KillEvent"),
        Hit       = GE and GE:FindFirstChild("Hit"),
        Damage    = GE and GE:FindFirstChild("Damage"),
    }

    -- ═══════════════════════════════════════════════
    -- ROLE DETECTION
    -- ═══════════════════════════════════════════════
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
        return checkContainer(char) or checkContainer(backpack) or "Innocent"
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

    Players.PlayerRemoving:Connect(function(p)
        roleCache[p] = nil
    end)

    local function isAlive(player)
        if not player or not player.Character then return false end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end

    local function isEnemy(player)
        if player == LocalPlayer then return false end
        return isAlive(player)
    end

    -- ═══════════════════════════════════════════════
    -- STATE
    -- ═══════════════════════════════════════════════
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
        gunLocator = false,
        autoCoin = false, autoCoinSpeed = 65,
        autoGrabGun = false, autoGrabGunRange = 300,
        speed = false, speedValue = 30,
        airJump = false, autoBhop = false, fullbright = false,
        lowGraphics = false, noShadows = false, noFog = false, noParticles = false,
    }

    -- ═══════════════════════════════════════════════
    -- HELPERS (definidos antes de tudo)
    -- ═══════════════════════════════════════════════
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

    local function getClosestEnemyInFov(fovRange, filterRole, useWallCheck)
        if useWallCheck == nil then useWallCheck = State.sheriffWallCheck end
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
                                if not useWallCheck or hasLineOfSight(Camera.CFrame.Position, head) then
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
        if type(mouse1click) == "function" and pcall(mouse1click) then return true end
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
        pcall(function() tool:Activate() end)
        return true
    end

    -- ═══════════════════════════════════════════════
    -- KINFE HELPERS
    -- ═══════════════════════════════════════════════
    local function getKnife()
        local char = LocalPlayer.Character
        if not char then return nil end
        local equipped = char:FindFirstChildOfClass("Tool")
        if equipped and equipped.Name:lower():find("knife") then return equipped end
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("knife") then return t end
        end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, t in ipairs(backpack:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("knife") then return t end
            end
        end
        return nil
    end

    local function equipKnife()
        local char = LocalPlayer.Character
        if not char then return nil end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        local knife = getKnife()
        if not knife then return nil end
        if knife.Parent ~= char then
            pcall(function() hum:EquipTool(knife) end)
            task.wait(0.1)
        end
        if knife.Parent == char then return knife end
        return nil
    end

    -- ═══════════════════════════════════════════════
    -- ENVIRONMENT BACKUP (movido pra cima)
    -- ═══════════════════════════════════════════════
    local origBrightness     = Lighting.Brightness
    local origAmbient        = Lighting.Ambient
    local origOutdoorAmbient = Lighting.OutdoorAmbient
    local origClockTime      = Lighting.ClockTime
    local origGlobalShadows  = Lighting.GlobalShadows
    local origAtmosphere     = {}
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then
            table.insert(origAtmosphere, {obj = c, D = c.Density, H = c.Haze, G = c.Glare})
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

    -- ═══════════════════════════════════════════════
    -- AIR JUMP (movido pra cima)
    -- ═══════════════════════════════════════════════
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
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 55, hrp.Velocity.Z)
        end)
    end

    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    -- ═══════════════════════════════════════════════
    -- ESP
    -- ═══════════════════════════════════════════════
    local ESP = {data = {}}
    local DRAW_KEYS = {"box", "name", "role", "distance", "weapon", "tracer", "headDot"}

    local function destroyESPData(d)
        if not d then return end
        if d.chams then pcall(function() d.chams:Destroy() end) end
        for _, key in ipairs(DRAW_KEYS) do
            if d[key] and d[key].Remove then pcall(function() d[key]:Remove() end) end
        end
    end

    local function createESP(p)
        if not p.Character then return end
        local existing = ESP.data[p]
        if existing then
            if existing.character == p.Character then return end
            destroyESPData(existing)
            ESP.data[p] = nil
        end

        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Color3.fromRGB(255, 30, 40); chams.FillTransparency = 0.6
        chams.OutlineColor = Color3.fromRGB(255, 255, 255); chams.OutlineTransparency = 0.3
        chams.Parent = p.Character

        local data = {chams = chams, character = p.Character}
        local function newDrawing(class, props)
            local d = Drawing.new(class)
            for k, v in pairs(props) do d[k] = v end
            d.Visible = false
            return d
        end
        data.box      = newDrawing("Square", {Thickness=1.5, Color=Color3.fromRGB(255, 30, 40), Filled=false, Transparency=1})
        data.name     = newDrawing("Text",   {Size=14, Center=true, Outline=true, Color=Color3.fromRGB(255, 255, 255)})
        data.role     = newDrawing("Text",   {Size=12, Center=true, Outline=true, Color=Color3.fromRGB(255, 255, 255)})
        data.distance = newDrawing("Text",   {Size=12, Center=true, Outline=true, Color=Color3.fromRGB(255, 80, 80)})
        data.weapon   = newDrawing("Text",   {Size=11, Center=true, Outline=true, Color=Color3.fromRGB(255, 200, 100)})
        data.tracer   = newDrawing("Line",   {Thickness=1.2, Color=Color3.fromRGB(255, 30, 40)})
        data.headDot  = newDrawing("Circle", {Radius=4, NumSides=20, Thickness=1, Filled=false, Color=Color3.fromRGB(255, 255, 255)})
        ESP.data[p] = data
    end

    local function removeESP(p)
        local d = ESP.data[p]
        if not d then return end
        destroyESPData(d)
        ESP.data[p] = nil
    end

    local function clearAllESP()
        for p, _ in pairs(ESP.data) do removeESP(p) end
    end

    local function hideAll(d)
        for _, key in ipairs(DRAW_KEYS) do
            if d[key] then d[key].Visible = false end
        end
        if d.chams then d.chams.Enabled = false end
    end

    local function updateESP(p, char)
        local d = ESP.data[p]
        if not d then return end
        if not State.esp or not isEnemy(p) then hideAll(d); return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then hideAll(d); return end

        local role = roleCache[p] or "Innocent"
        if role == "Murderer" and not State.showMurderer then hideAll(d); return end
        if role == "Sheriff"  and not State.showSheriff  then hideAll(d); return end
        if role == "Innocent" and not State.showInnocent then hideAll(d); return end

        local color = Color3.fromRGB(0, 220, 130)
        if role == "Murderer" then color = Color3.fromRGB(255, 40, 40)
        elseif role == "Sheriff" then color = Color3.fromRGB(80, 150, 255) end

        if d.chams then
            d.chams.Enabled = true
            d.chams.FillColor = color
            d.chams.OutlineColor = color
        end

        local head = getBasePart(char, "Head")
        local hrp  = getBasePart(char, "HumanoidRootPart")
        if not head or not hrp then hideAll(d); return end

        local headSp, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpSp,  hrpOn  = Camera:WorldToViewportPoint(hrp.Position)
        local footPos = hrp.Position - Vector3.new(0, 3, 0)
        local footSp, footOn = Camera:WorldToViewportPoint(footPos)

        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then hideAll(d); return end
        local dist = math.floor((head.Position - myHRP.Position).Magnitude)
        if dist > State.espMaxDistance then hideAll(d); return end

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
                    createESP(p)
                    updateESP(p, p.Character)
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

    -- ═══════════════════════════════════════════════
    -- COMBAT LOOPS
    -- ═══════════════════════════════════════════════

    -- SHERIFF SILENT AIM (BindToRenderStep)
    local sheriffSilentTarget = nil
    local sheriffSilentHolding = false

    RunService:BindToRenderStep("IZ_MM2_SheriffSilent", Enum.RenderPriority.Camera.Value + 10, function()
        if UNLOADED or not sheriffSilentHolding then return end
        if not sheriffSilentTarget or not sheriffSilentTarget.Character then sheriffSilentHolding = false; return end
        local head = getBasePart(sheriffSilentTarget.Character, "Head")
        if not head then sheriffSilentHolding = false; return end
        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.sheriffSilentAim then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local target = getClosestEnemyInFov(State.sheriffSilentFov, "Murderer", State.sheriffWallCheck)
        if target and target.Character then
            sheriffSilentTarget = target
            sheriffSilentHolding = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        sheriffSilentHolding = false
        sheriffSilentTarget = nil
    end)

    -- TRIGGERBOT
    local sheriffTriggerLast = 0
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.sheriffTriggerbot then return end
        if tick() - sheriffTriggerLast < (State.sheriffTriggerbotDelay / 1000) then return end
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character and roleCache[p] == "Murderer" then
                local head = getBasePart(p.Character, "Head")
                if head then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth and depth > 0 then
                        if (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude < 20 and hasLineOfSight(Camera.CFrame.Position, head) then
                            sheriffTriggerLast = tick()
                            fireWeapon()
                            break
                        end
                    end
                end
            end
        end
    end)

    -- AUTO SHOOT
    local sheriffAutoLast = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.sheriffAutoShoot then return end
        if tick() - sheriffAutoLast < 0.05 then return end
        local target = getClosestEnemyInFov(State.sheriffAutoShootFov, "Murderer", State.sheriffWallCheck)
        if target and target.Character then
            local head = getBasePart(target.Character, "Head")
            if head and hasLineOfSight(Camera.CFrame.Position, head) then
                sheriffAutoLast = tick()
                fireWeapon()
            end
        end
    end)

    -- SHERIFF AIMBOT
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.sheriffAimbot then return end
        local target = getClosestEnemyInFov(State.sheriffSilentFov, "Murderer", State.sheriffWallCheck)
        if target and target.Character then
            local head = getBasePart(target.Character, "Head")
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local mouse = UserInputService:GetMouseLocation()
                    local dx = sp.X - mouse.X
                    local dy = sp.Y - mouse.Y
                    if type(mousemoverel) == "function" then
                        pcall(function() mousemoverel(dx * State.sheriffAimbotSmooth, dy * State.sheriffAimbotSmooth) end)
                    end
                end
            end
        end
    end)

    -- MURDERER SILENT AIM
    local murdererSilentTarget = nil
    local murdererSilentHolding = false

    RunService:BindToRenderStep("IZ_MM2_MurdererSilent", Enum.RenderPriority.Camera.Value + 10, function()
        if UNLOADED or not murdererSilentHolding then return end
        if not murdererSilentTarget or not murdererSilentTarget.Character then murdererSilentHolding = false; return end
        local head = getBasePart(murdererSilentTarget.Character, "Head")
        if not head then murdererSilentHolding = false; return end
        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.murdererSilentAim then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local target = getClosestEnemyInFov(State.murdererSilentFov, nil, false)
        if target and target.Character then
            murdererSilentTarget = target
            murdererSilentHolding = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        murdererSilentHolding = false
        murdererSilentTarget = nil
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

        killAuraActive = true
        task.spawn(function()
            local knife = equipKnife()
            if not knife then killAuraActive = false; return end

            local originalCF = myHRP.CFrame
            local originalPlatformStand = hum.PlatformStand

            for _, p in ipairs(Players:GetPlayers()) do
                if UNLOADED then break end
                if isEnemy(p) and p.Character then
                    local tHRP = getBasePart(p.Character, "HumanoidRootPart")
                    if tHRP then
                        local dist = (tHRP.Position - originalCF.Position).Magnitude
                        if dist <= State.killAuraRange then
                            myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2.5)
                            task.wait(0.03)
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
            if myHRP and myHRP.Parent then
                myHRP.CFrame = originalCF
                hum.PlatformStand = originalPlatformStand
            end
            killAuraActive = false
        end)
    end)

    -- AUTO BACKSTAB
    local backstabLast = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoBackstab then return end
        if tick() - backstabLast < 0.15 then return end
        local char = LocalPlayer.Character
        if not char then return end
        local myHRP = getBasePart(char, "HumanoidRootPart")
        if not myHRP then return end
        local knife = equipKnife()
        if not knife then return end

        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local tHRP = getBasePart(p.Character, "HumanoidRootPart")
                if tHRP then
                    local delta = myHRP.Position - tHRP.Position
                    local dist = delta.Magnitude
                    if dist < 12 and dist > 0.1 then
                        if delta.Unit:Dot(tHRP.CFrame.LookVector) < 0 then
                            myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2)
                            task.wait(0.03)
                            pcall(function() knife:Activate() end)
                            pcall(function() mouse1click() end)
                            backstabLast = tick()
                            task.wait(0.1)
                            break
                        end
                    end
                end
            end
        end
    end)

    -- MURDERER ALERT
    local lastAlertTime = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.murdererAlert then return end
        if myRole == "Murderer" then return end
        if tick() - lastAlertTime < 3 then return end
        local myHRP = getBasePart(LocalPlayer.Character, "HumanoidRootPart")
        if not myHRP then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and roleCache[p] == "Murderer" then
                local tHRP = getBasePart(p.Character, "HumanoidRootPart")
                if tHRP then
                    local dist = (tHRP.Position - myHRP.Position).Magnitude
                    if dist <= State.murdererAlertRange then
                        lastAlertTime = tick()
                        if Window then Window:Notify("⚠️ " .. T("mm2.murderer.alert"), math.floor(dist) .. "m", 3, "error") end
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
    end)

    -- GUN LOCATOR
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
        if gunScanTick % 10 ~= 0 then return end
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
            gunDrawing.Color = Color3.fromRGB(80, 150, 255)
            gunTextDrawing = Drawing.new("Text")
            gunTextDrawing.Size = 14; gunTextDrawing.Center = true
            gunTextDrawing.Outline = true; gunTextDrawing.Color = Color3.fromRGB(80, 150, 255)
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
                gunDistDrawing.Position = Vector2.new(sp.X, sp.Y + 26)
                gunDistDrawing.Text = math.floor((gunPart.Position - myHRP.Position).Magnitude) .. "m"
                gunDistDrawing.Visible = true
            end
        else
            gunDrawing.Visible = false
            gunTextDrawing.Visible = false
            gunDistDrawing.Visible = false
        end
    end)

    -- AUTO COIN FARM
    local coinDrawings = {}
    local coinCache = {}
    local coinCacheTimer = 0
    local coinCollectCooldown = {}
    local coinMoveActive = false

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
        return coins
    end

    local function fireTouch(a, b)
        if type(firetouchinterest) == "function" then
            pcall(function()
                firetouchinterest(a, b, 0)
                firetouchinterest(a, b, 1)
            end)
        end
    end

    RunService.Heartbeat:Connect(function(dt)
        if UNLOADED then return end
        if not State.autoCoin then
            if coinMoveActive then
                coinMoveActive = false
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.PlatformStand = false end
                end
            end
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
        if not hrp or not hum or hum.Health <= 0 then return end

        coinCacheTimer = coinCacheTimer + dt
        if coinCacheTimer >= 0.5 or #coinCache == 0 then
            coinCacheTimer = 0
            coinCache = findCoins()
        end

        local nearest, minDist = nil, math.huge
        local now = tick()
        for _, c in ipairs(coinCache) do
            if c and c.Parent then
                local last = coinCollectCooldown[c] or 0
                if now - last > 0.5 then
                    local d = (c.Position - hrp.Position).Magnitude
                    if d < minDist then minDist = d; nearest = c end
                end
            end
        end

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
                    d.text.Text = math.floor((coin.Position - hrp.Position).Magnitude) .. "m"
                    d.text.Visible = true
                    if coin == nearest then
                        d.box.Color = Color3.fromRGB(0, 255, 130); d.box.Radius = 14
                    else
                        d.box.Color = Color3.fromRGB(255, 220, 100); d.box.Radius = 10
                    end
                else
                    d.box.Visible = false; d.text.Visible = false
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

        if not nearest then
            if coinMoveActive then
                coinMoveActive = false
                hum.PlatformStand = false
            end
            return
        end

        local targetPos = nearest.Position + Vector3.new(0, 2.5, 0)
        local dist = (targetPos - hrp.Position).Magnitude

        if dist <= 4 then
            if coinMoveActive then
                coinMoveActive = false
                hum.PlatformStand = false
            end
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)

            local last = coinCollectCooldown[nearest] or 0
            if tick() - last > 0.4 then
                coinCollectCooldown[nearest] = tick()
                local parts = {hrp}
                for _, n in ipairs({"RightHand", "LeftHand", "Right Arm", "Left Arm", "Torso", "UpperTorso", "LowerTorso"}) do
                    local bp = char:FindFirstChild(n)
                    if bp and bp:IsA("BasePart") then table.insert(parts, bp) end
                end
                for _, part in ipairs(parts) do fireTouch(part, nearest) end
            end
            return
        end

        if not coinMoveActive then
            coinMoveActive = true
            hum.PlatformStand = true
        end

        local speed = tonumber(State.autoCoinSpeed) or 65
        local alpha = math.clamp((speed * dt) / dist, 0, 1)
        hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, targetPos), alpha)
    end)

    -- AUTO GRAB GUN
    local function playerHasGun()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local function checkContainer(container)
            if not container then return false end
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") then
                    local n = t.Name:lower()
                    if n:find("gun") or n:find("revolver") or n:find("pistol") then
                        return true
                    end
                end
            end
            return false
        end
        return checkContainer(char) or checkContainer(backpack)
    end

    local function isGunTool(obj)
        if not obj or not obj:IsA("Tool") then return false end
        local n = obj.Name:lower()
        if n:find("gun") or n:find("revolver") or n:find("pistol") then
            return true
        end
        return false
    end

    -- Procura em VÁRIOS lugares, não só workspace direto
    local function findDroppedGun()
        local containers = {workspace}
        -- Adiciona pastas comuns
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Model") then
                local n = child.Name:lower()
                if n:find("item") or n:find("drop") or n:find("tool") or n:find("weapon") then
                    table.insert(containers, child)
                end
            end
        end

        for _, container in ipairs(containers) do
            for _, obj in ipairs(container:GetChildren()) do
                if isGunTool(obj) then
                    local handle = obj:FindFirstChild("Handle")
                    if handle and handle:IsA("BasePart") then
                        -- Ignora se tá na mão de alguém
                        if not obj.Parent:IsA("Model") or not Players:GetPlayerFromCharacter(obj.Parent) then
                            return obj, handle
                        end
                    end
                end
            end
        end
        return nil
    end

    -- Dispara touch em TODAS as partes do character
    local function forceTouchGun(handle)
        local char = LocalPlayer.Character
        if not char or not handle or not handle.Parent then return end

        local parts = {}
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then table.insert(parts, hrp) end
        for _, n in ipairs({
            "RightHand", "LeftHand", "Right Arm", "Left Arm",
            "RightUpperArm", "LeftUpperArm", "RightLowerArm", "LeftLowerArm",
            "RightFoot", "LeftFoot", "Right Leg", "Left Leg",
            "Torso", "UpperTorso", "LowerTorso", "Head"
        }) do
            local bp = char:FindFirstChild(n)
            if bp and bp:IsA("BasePart") then table.insert(parts, bp) end
        end

        for _, part in ipairs(parts) do
            pcall(function()
                firetouchinterest(part, handle, 0)
                task.wait(0.003)
                firetouchinterest(part, handle, 1)
            end)
        end
    end

    local autoGrabCooldown = 0
    local autoGrabActive   = false
    local autoGrabLastTarget = nil

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoGrabGun then return end
        if autoGrabActive then return end
        if tick() < autoGrabCooldown then return end
        if playerHasGun() then return end

        local gun, handle = findDroppedGun()
        if not gun or not handle then return end

        local char = LocalPlayer.Character
        if not char then return end
        local hrp = getBasePart(char, "HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local dist = (handle.Position - hrp.Position).Magnitude
        if dist > (tonumber(State.autoGrabGunRange) or 300) then return end

        autoGrabActive = true
        autoGrabCooldown = tick() + 1.5
        autoGrabLastTarget = gun

        local originalCF = hrp.CFrame
        local originalPlatform = hum.PlatformStand
        local originalCanCollide = hrp.CanCollide

        task.spawn(function()
            hum.PlatformStand = true
            hrp.CanCollide = false

            local grabbed = false
            local maxTries = 12

            for attempt = 1, maxTries do
                if UNLOADED then break end
                if not handle or not handle.Parent then break end
                if playerHasGun() then grabbed = true; break end

                -- Teleporta pra cima do handle
                pcall(function()
                    hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0, 1.5, 0))
                end)

                task.wait(0.04)
                forceTouchGun(handle)

                -- Checa se pegou
                task.wait(0.08)
                if playerHasGun() then grabbed = true; break end
            end

            -- Restaura
            if hrp and hrp.Parent then
                pcall(function() hrp.CFrame = originalCF end)
                pcall(function() hrp.CanCollide = originalCanCollide end)
                hum.PlatformStand = originalPlatform
            end

            if grabbed and Window then
                Window:Notify("🔫", T("mm2.autograb.name"), 2, "success")
            end

            task.wait(0.2)
            autoGrabActive = false
        end)
    end)
    
    -- ═══════════════════════════════════════════════
    -- MOVEMENT LOOPS
    -- ═══════════════════════════════════════════════
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

    -- FULLBRIGHT LOOP
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

    -- ═══════════════════════════════════════════════
    -- CONFIG SYSTEM
    -- ═══════════════════════════════════════════════
    local BASE_FOLDER   = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/MM2"
    local AUTOLOAD_FILE = "InfiniteZen_MM2_Autoload.txt"

    local function ensureFolder()
        if makefolder then
            if not isfolder(BASE_FOLDER)   then pcall(function() makefolder(BASE_FOLDER) end) end
            if not isfolder(CONFIG_FOLDER) then pcall(function() makefolder(CONFIG_FOLDER) end) end
        end
    end

    local function getConfigPath(name) return CONFIG_FOLDER .. "/" .. name .. ".json" end
    local function getAutoloadPath()  return AUTOLOAD_FILE end

    local function syncUIFromState()
        local toggles = {
            "sheriffSilentAim","sheriffTriggerbot","sheriffAutoShoot","sheriffAimbot","sheriffWallCheck",
            "murdererSilentAim","killAura","autoBackstab",
            "esp","showMurderer","showSheriff","showInnocent","showWeaponESP","showDistanceESP","showTracerESP",
            "murdererAlert","gunLocator","autoCoin","autoGrabGun",
            "speed","airJump","autoBhop","fullbright",
            "lowGraphics","noShadows","noFog","noParticles",
        }
        for _, k in ipairs(toggles) do
            local el = Elements[k]
            if el and State[k] ~= nil then setToggle(el, State[k]) end
        end
        local sliders = {
            "sheriffSilentFov","sheriffTriggerbotDelay","sheriffAutoShootFov",
            "murdererSilentFov","killAuraRange","killAuraDelay",
            "espMaxDistance","murdererAlertRange","autoCoinSpeed","autoGrabGunRange","speedValue",
        }
        for _, k in ipairs(sliders) do
            local el = Elements[k]
            if el and State[k] ~= nil then setSlider(el, State[k]) end
        end
    end

    local function saveConfigNamed(name)
        ensureFolder()
        local data = {version = GAME_VERSION, state = {}}
        for k, v in pairs(State) do data.state[k] = v end
        local ok = pcall(function() writefile(getConfigPath(name), HttpService:JSONEncode(data)) end)
        if ok and Window then Window:Notify("💾", "Saved: " .. name, 3, "success") end
    end

    local function loadConfigNamed(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then return false end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data then return false end
        if data.state then for k, v in pairs(data.state) do State[k] = v end end
        if State.lowGraphics then applyLowGraphics(true) end
        if State.noShadows then applyNoShadows(true) end
        if State.noFog then applyNoFog(true) end
        if State.noParticles then applyNoParticles(true) end
        if State.airJump then startAirJump() else stopAirJump() end
        if not State.fullbright then disableFullbright() end
        syncUIFromState()
        if Window then Window:Notify("📂", "Loaded: " .. name, 3, "info") end
        return true
    end

    local function deleteConfigNamed(name)
        local path = getConfigPath(name)
        if isfile and isfile(path) then
            pcall(function() delfile(path) end)
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
        pcall(function() writefile(getAutoloadPath(), name) end)
    end

    local function clearAutoload()
        pcall(function() if isfile(getAutoloadPath()) then delfile(getAutoloadPath()) end end)
    end

    local function getAutoload()
        local ok, content = pcall(function() return readfile(getAutoloadPath()) end)
        if ok and content and content ~= "" then return content end
        return nil
    end

    -- ═══════════════════════════════════════════════
    -- BUILD UI
    -- ═══════════════════════════════════════════════
    local function buildUI()
        Window = UI:CreateWindow({
            Title = "INFINITE ZEN",
            Subtitle = SHORT_VERSION,
            ToggleKey = Enum.KeyCode.K,
        })
        Elements = {}

        -- ═══ SHERIFF ═══
        local SheriffTab = Window:CreateTab(T("tab.sheriff"), "🔫")
        SheriffTab:CreateSection(T("section.aim"))
        reg("sheriffSilentAim", SheriffTab:CreateToggle({
            Name = T("silent.name"), Description = T("silent.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.sheriffSilentAim = v end,
        }))
        reg("sheriffSilentFov", SheriffTab:CreateSlider({
            Name = T("silentfov.name"), Description = T("silentfov.desc"),
            Icon = "📐", Min = 30, Max = 300, Default = 100,
            Callback = function(v) State.sheriffSilentFov = v end,
        }))
        reg("sheriffWallCheck", SheriffTab:CreateToggle({
            Name = T("wallcheck.name"), Description = T("wallcheck.desc"),
            Icon = "🧱", Default = true,
            Callback = function(v) State.sheriffWallCheck = v end,
        }))
        reg("sheriffAimbot", SheriffTab:CreateToggle({
            Name = T("aimbot.name"), Description = T("aimbot.desc"),
            Icon = "🤖", Default = false,
            Callback = function(v) State.sheriffAimbot = v end,
        }))
        SheriffTab:CreateSection(T("section.auto"))
        reg("sheriffTriggerbot", SheriffTab:CreateToggle({
            Name = T("triggerbot.name"), Description = T("triggerbot.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.sheriffTriggerbot = v end,
        }))
        reg("sheriffTriggerbotDelay", SheriffTab:CreateSlider({
            Name = T("triggerbotdelay.name"), Description = T("triggerbotdelay.desc"),
            Icon = "⏱️", Min = 1, Max = 100, Default = 5,
            Callback = function(v) State.sheriffTriggerbotDelay = v end,
        }))
        reg("sheriffAutoShoot", SheriffTab:CreateToggle({
            Name = T("autoshot.name"), Description = T("autoshot.desc"),
            Icon = "🔥", Default = false,
            Callback = function(v) State.sheriffAutoShoot = v end,
        }))
        reg("sheriffAutoShootFov", SheriffTab:CreateSlider({
            Name = T("autoshotfov.name"), Description = T("autoshotfov.desc"),
            Icon = "📐", Min = 30, Max = 300, Default = 100,
            Callback = function(v) State.sheriffAutoShootFov = v end,
        }))

        -- ═══ MURDERER ═══
        local MurdererTab = Window:CreateTab(T("tab.murderer"), "🔪")
        MurdererTab:CreateSection(T("section.aim"))
        reg("murdererSilentAim", MurdererTab:CreateToggle({
            Name = T("silent.name"), Description = T("silent.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.murdererSilentAim = v end,
        }))
        reg("murdererSilentFov", MurdererTab:CreateSlider({
            Name = T("silentfov.name"), Description = T("silentfov.desc"),
            Icon = "📐", Min = 30, Max = 300, Default = 100,
            Callback = function(v) State.murdererSilentFov = v end,
        }))
        MurdererTab:CreateSection(T("section.melee"))
        reg("killAura", MurdererTab:CreateToggle({
            Name = T("killaura.name"), Description = T("killaura.desc"),
            Icon = "⚔️", Default = false,
            Callback = function(v) State.killAura = v end,
        }))
        reg("killAuraRange", MurdererTab:CreateSlider({
            Name = T("killaurarange.name"), Description = "",
            Icon = "📏", Min = 5, Max = 500, Default = 30,
            Callback = function(v) State.killAuraRange = v end,
        }))
        reg("killAuraDelay", MurdererTab:CreateSlider({
            Name = T("killauradelay.name"), Description = "",
            Icon = "⏱️", Min = 10, Max = 500, Default = 50,
            Callback = function(v) State.killAuraDelay = v end,
        }))
        reg("autoBackstab", MurdererTab:CreateToggle({
            Name = T("autobackstab.name"), Description = T("autobackstab.desc"),
            Icon = "🗡️", Default = false,
            Callback = function(v) State.autoBackstab = v end,
        }))

        -- ═══ INNOCENT ═══
        local InnocentTab = Window:CreateTab(T("tab.innocent"), "❓")
        InnocentTab:CreateSection(T("section.esp"))
        reg("esp", InnocentTab:CreateToggle({
            Name = T("esp.name"), Description = T("esp.desc"),
            Icon = "👤", Default = false,
            Callback = function(v)
                State.esp = v
                if v then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then createESP(p) end
                    end
                else clearAllESP() end
            end,
        }))
        reg("espMaxDistance", InnocentTab:CreateSlider({
            Name = T("espdist.name"), Description = T("espdist.desc"),
            Icon = "📐", Min = 100, Max = 5000, Default = 2000,
            Callback = function(v) State.espMaxDistance = v end,
        }))
        reg("showMurderer", InnocentTab:CreateToggle({
            Name = T("mm2.show.murderer"), Description = "",
            Icon = "🔪", Default = true,
            Callback = function(v) State.showMurderer = v end,
        }))
        reg("showSheriff", InnocentTab:CreateToggle({
            Name = T("mm2.show.sheriff"), Description = "",
            Icon = "🔫", Default = true,
            Callback = function(v) State.showSheriff = v end,
        }))
        reg("showInnocent", InnocentTab:CreateToggle({
            Name = T("mm2.show.innocent"), Description = "",
            Icon = "❓", Default = true,
            Callback = function(v) State.showInnocent = v end,
        }))
        reg("showWeaponESP", InnocentTab:CreateToggle({
            Name = T("espweapon.name"), Description = T("espweapon.desc"),
            Icon = "🔫", Default = true,
            Callback = function(v) State.showWeaponESP = v end,
        }))
        reg("showDistanceESP", InnocentTab:CreateToggle({
            Name = T("espdist.name"), Description = "",
            Icon = "📏", Default = true,
            Callback = function(v) State.showDistanceESP = v end,
        }))
        reg("showTracerESP", InnocentTab:CreateToggle({
            Name = T("esptracer.name"), Description = T("esptracer.desc"),
            Icon = "📡", Default = false,
            Callback = function(v) State.showTracerESP = v end,
        }))
        InnocentTab:CreateSection(T("section.alert"))
        reg("murdererAlert", InnocentTab:CreateToggle({
            Name = T("mm2.murderer.alert"), Description = T("mm2.murderer.alert.desc"),
            Icon = "⚠️", Default = false,
            Callback = function(v) State.murdererAlert = v end,
        }))
        reg("murdererAlertRange", InnocentTab:CreateSlider({
            Name = T("mm2.murderer.alert.range"), Description = "",
            Icon = "📏", Min = 10, Max = 200, Default = 40,
            Callback = function(v) State.murdererAlertRange = v end,
        }))
        InnocentTab:CreateSection(T("section.utility"))
        reg("gunLocator", InnocentTab:CreateToggle({
            Name = T("mm2.gunlocator.name"), Description = T("mm2.gunlocator.desc"),
            Icon = "🔫", Default = false,
            Callback = function(v) State.gunLocator = v end,
        }))
        reg("autoCoin", InnocentTab:CreateToggle({
            Name = T("mm2.autocoin.name"), Description = T("mm2.autocoin.desc"),
            Icon = "🪙", Default = false,
            Callback = function(v) State.autoCoin = v end,
        }))
        reg("autoCoinSpeed", InnocentTab:CreateSlider({
            Name = T("mm2.autocoin.speed"), Description = "",
            Icon = "📏", Min = 15, Max = 200, Default = 65,
            Callback = function(v) State.autoCoinSpeed = v end,
        }))
        reg("autoGrabGun", InnocentTab:CreateToggle({
            Name = T("mm2.autograb.name"), Description = T("mm2.autograb.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.autoGrabGun = v end,
        }))
        reg("autoGrabGunRange", InnocentTab:CreateSlider({
            Name = T("mm2.autograb.range"), Description = "",
            Icon = "📏", Min = 50, Max = 1000, Default = 300,
            Callback = function(v) State.autoGrabGunRange = v end,
        }))

        -- ═══ UTILS ═══
        local UtilsTab = Window:CreateTab(T("tab.utils"), "🌑")
        UtilsTab:CreateSection(T("section.speed"))
        reg("speed", UtilsTab:CreateToggle({
            Name = T("speed.name"), Description = T("speed.desc"),
            Icon = "⚡", Default = false,
            Callback = function(v) State.speed = v end,
        }))
        reg("speedValue", UtilsTab:CreateSlider({
            Name = T("speedvalue.name"), Description = T("speedvalue.desc"),
            Icon = "📏", Min = 16, Max = 200, Default = 30,
            Callback = function(v) State.speedValue = v end,
        }))
        UtilsTab:CreateSection(T("section.jump"))
        reg("airJump", UtilsTab:CreateToggle({
            Name = T("airjump.name"), Description = T("airjump.desc"),
            Icon = "🦘", Default = false,
            Callback = function(v)
                State.airJump = v
                if v then startAirJump() else stopAirJump() end
            end,
        }))
        reg("autoBhop", UtilsTab:CreateToggle({
            Name = T("autobhop.name"), Description = T("autobhop.desc"),
            Icon = "🏃", Default = false,
            Callback = function(v) State.autoBhop = v end,
        }))
        UtilsTab:CreateSection(T("section.environment"))
        reg("fullbright", UtilsTab:CreateToggle({
            Name = T("fullbright.name"), Description = T("fullbright.desc"),
            Icon = "💡", Default = false,
            Callback = function(v)
                State.fullbright = v
                if not v then disableFullbright() end
            end,
        }))
        UtilsTab:CreateSection(T("section.optimizations"))
        reg("lowGraphics", UtilsTab:CreateToggle({
            Name = T("lowgfx.name"), Description = T("lowgfx.desc"),
            Icon = "📉", Default = false,
            Callback = function(v) State.lowGraphics = v; applyLowGraphics(v) end,
        }))
        reg("noShadows", UtilsTab:CreateToggle({
            Name = T("noshadow.name"), Description = T("noshadow.desc"),
            Icon = "🌑", Default = false,
            Callback = function(v) State.noShadows = v; applyNoShadows(v) end,
        }))
        reg("noFog", UtilsTab:CreateToggle({
            Name = T("nofog.name"), Description = T("nofog.desc"),
            Icon = "🌫️", Default = false,
            Callback = function(v) State.noFog = v; applyNoFog(v) end,
        }))
        reg("noParticles", UtilsTab:CreateToggle({
            Name = T("nopart.name"), Description = T("nopart.desc"),
            Icon = "✨", Default = false,
            Callback = function(v) State.noParticles = v; applyNoParticles(v) end,
        }))
        UtilsTab:CreateButton({
            Name = T("config.fps_boost"),
            Callback = function()
                State.lowGraphics = true; applyLowGraphics(true)
                State.noShadows = true; applyNoShadows(true)
                State.noFog = true; applyNoFog(true)
                State.noParticles = true; applyNoParticles(true)
                syncUIFromState()
                Window:Notify("⚡", T("config.fps_boost"), 3, "success")
            end,
        })
        UtilsTab:CreateButton({
            Name = T("config.reset_opt"),
            Callback = function()
                State.lowGraphics = false; applyLowGraphics(false)
                State.noShadows = false; applyNoShadows(false)
                State.noFog = false; applyNoFog(false)
                State.noParticles = false; applyNoParticles(false)
                syncUIFromState()
                Window:Notify("🔄", T("config.reset_opt"), 3, "info")
            end,
        })

        -- ═══ SETTINGS ═══
        local SettingsTab = Window:CreateTab(T("tab.settings"), "⚙️")
        SettingsTab:CreateSection(T("section.create_config"))

        local configInputFrame = Instance.new("Frame", SettingsTab.container)
        configInputFrame.Size = UDim2.new(1, 0, 0, 40)
        configInputFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        configInputFrame.BorderSizePixel = 0
        configInputFrame.LayoutOrder = #SettingsTab.container:GetChildren()
        Instance.new("UICorner", configInputFrame).CornerRadius = UDim.new(0, 8)

        local cInput = Instance.new("TextBox", configInputFrame)
        cInput.Size = UDim2.new(1, -20, 1, -10)
        cInput.Position = UDim2.new(0, 10, 0, 5)
        cInput.BackgroundTransparency = 1
        cInput.Font = Enum.Font.GothamMedium
        cInput.TextSize = 12
        cInput.TextColor3 = Color3.fromRGB(240, 240, 245)
        cInput.PlaceholderText = T("config.placeholder")
        cInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
        cInput.Text = ""
        cInput.ClearTextOnFocus = false
        cInput.TextXAlignment = Enum.TextXAlignment.Left

        SettingsTab:CreateSection(T("section.saved_configs"))
        local configListFrame = Instance.new("Frame", SettingsTab.container)
        configListFrame.Size = UDim2.new(1, 0, 0, 160)
        configListFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        configListFrame.BorderSizePixel = 0
        configListFrame.LayoutOrder = #SettingsTab.container:GetChildren()
        Instance.new("UICorner", configListFrame).CornerRadius = UDim.new(0, 8)

        local configScroll = Instance.new("ScrollingFrame", configListFrame)
        configScroll.Size = UDim2.new(1, -12, 1, -12)
        configScroll.Position = UDim2.new(0, 6, 0, 6)
        configScroll.BackgroundTransparency = 1
        configScroll.BorderSizePixel = 0
        configScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        configScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        configScroll.ScrollBarThickness = 3
        configScroll.ScrollBarImageColor3 = Color3.fromRGB(230, 40, 40)

        local configListLayout = Instance.new("UIListLayout", configScroll)
        configListLayout.Padding = UDim.new(0, 4)

        local function refreshConfigList()
            for _, child in ipairs(configScroll:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
            end
            local configs = listConfigs()
            local currentAutoload = getAutoload()
            if #configs == 0 then
                local empty = Instance.new("TextLabel", configScroll)
                empty.Size = UDim2.new(1, 0, 0, 30)
                empty.BackgroundTransparency = 1
                empty.Font = Enum.Font.Gotham
                empty.TextSize = 11
                empty.TextColor3 = Color3.fromRGB(90, 90, 105)
                empty.Text = T("config.empty")
                return
            end
            for _, name in ipairs(configs) do
                local entry = Instance.new("Frame", configScroll)
                entry.Size = UDim2.new(1, -4, 0, 32)
                entry.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
                entry.BorderSizePixel = 0
                Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)

                local nameLbl = Instance.new("TextLabel", entry)
                nameLbl.Size = UDim2.new(0.5, 0, 1, 0)
                nameLbl.Position = UDim2.new(0, 10, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 11
                nameLbl.TextColor3 = (currentAutoload == name) and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(240, 240, 245)
                nameLbl.Text = (currentAutoload == name and "⚡ " or "") .. name
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left

                local loadBtn = Instance.new("TextButton", entry)
                loadBtn.Size = UDim2.new(0, 50, 0, 22)
                loadBtn.Position = UDim2.new(1, -110, 0.5, -11)
                loadBtn.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
                loadBtn.Text = "Load"
                loadBtn.Font = Enum.Font.GothamBold
                loadBtn.TextSize = 10
                loadBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
                loadBtn.AutoButtonColor = false
                Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
                loadBtn.MouseButton1Click:Connect(function()
                    loadConfigNamed(name); refreshConfigList()
                end)

                local autoBtn = Instance.new("TextButton", entry)
                autoBtn.Size = UDim2.new(0, 22, 0, 22)
                autoBtn.Position = UDim2.new(1, -55, 0.5, -11)
                autoBtn.BackgroundColor3 = (currentAutoload == name) and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(35, 35, 45)
                autoBtn.Text = "⚡"
                autoBtn.Font = Enum.Font.GothamBold
                autoBtn.TextSize = 11
                autoBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
                autoBtn.AutoButtonColor = false
                Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 4)
                autoBtn.MouseButton1Click:Connect(function()
                    if currentAutoload == name then clearAutoload() else setAutoload(name) end
                    refreshConfigList()
                end)

                local delBtn = Instance.new("TextButton", entry)
                delBtn.Size = UDim2.new(0, 22, 0, 22)
                delBtn.Position = UDim2.new(1, -28, 0.5, -11)
                delBtn.BackgroundColor3 = Color3.fromRGB(60, 15, 20)
                delBtn.Text = "×"
                delBtn.Font = Enum.Font.GothamBold
                delBtn.TextSize = 14
                delBtn.TextColor3 = Color3.fromRGB(255, 40, 40)
                delBtn.AutoButtonColor = false
                Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
                delBtn.MouseButton1Click:Connect(function()
                    deleteConfigNamed(name); refreshConfigList()
                end)
            end
        end

        cInput.FocusLost:Connect(function(enterPressed)
            if enterPressed and cInput.Text ~= "" then
                saveConfigNamed(cInput.Text)
                cInput.Text = ""
                refreshConfigList()
            end
        end)

        SettingsTab:CreateButton({
            Name = T("config.refresh"),
            Callback = function() refreshConfigList() end,
        })
        SettingsTab:CreateButton({
            Name = T("config.disable_autoload"),
            Callback = function() clearAutoload(); refreshConfigList() end,
        })
        refreshConfigList()

        SettingsTab:CreateSection(T("section.danger"))
        SettingsTab:CreateButton({
            Name = T("config.unload"),
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
                if gunDrawing then gunDrawing:Remove() end
                if gunTextDrawing then gunTextDrawing:Remove() end
                if gunDistDrawing then gunDistDrawing:Remove() end
                pcall(function() RunService:UnbindFromRenderStep("IZ_MM2_SheriffSilent") end)
                pcall(function() RunService:UnbindFromRenderStep("IZ_MM2_MurdererSilent") end)
                if Window then Window:Notify("Unload", T("config.unload"), 2, "warning") end
                task.wait(0.3)
                if Window then Window:Destroy() end
            end,
        })

        -- ═══ LANGUAGE ═══
        local LanguageTab = Window:CreateTab(T("tab.language"), "🌍")
        LanguageTab:CreateSection(T("section.language_select"))
        local available = Language.getAvailable()
        local currentCode = Language.getCurrent()
        local currentInfo = nil
        for _, info in ipairs(available) do
            if info.code == currentCode then currentInfo = info; break end
        end
        LanguageTab:CreateLabel(
            T("lang.current") .. (currentInfo and (currentInfo.flag .. " " .. currentInfo.displayName) or currentCode),
            Color3.fromRGB(230, 40, 40)
        )
        LanguageTab:CreateLabel(T("lang.hint"), Color3.fromRGB(140, 140, 155))
        local opts = {}
        local defaultIdx = 1
        for i, info in ipairs(available) do
            table.insert(opts, info.flag .. " " .. info.displayName)
            if info.code == currentCode then defaultIdx = i end
        end
        LanguageTab:CreateDropdown({
            Name = T("tab.language"), Description = T("lang.hint"),
            Icon = "🌍", Options = opts, Default = defaultIdx,
            Callback = function(_, idx)
                local info = available[idx]
                if not info then return end
                Language.setLanguage(info.code)
            end,
        })
        LanguageTab:CreateSection(T("section.language_info"))
        LanguageTab:CreateLabel(T("lang.saved_to") .. " InfiniteZen_Language.txt", Color3.fromRGB(140, 140, 155))
        LanguageTab:CreateLabel(T("lang.auto_restore"), Color3.fromRGB(90, 90, 105))

        -- ═══ CREDITS ═══
        local CreditsTab = Window:CreateTab(T("tab.credits"), "➕")
        CreditsTab:CreateSection(T("section.founder"))
        CreditsTab:CreateLabel(T("credits.role"), Color3.fromRGB(255, 50, 50))
        CreditsTab:CreateSection(T("section.community"))
        CreditsTab:CreateLabel("discord.gg/ScZfU2mAGm", Color3.fromRGB(88, 101, 242))
        CreditsTab:CreateButton({
            Name = T("credits.copy_discord"),
            Callback = function()
                if setclipboard then
                    setclipboard("https://discord.gg/ScZfU2mAGm")
                    Window:Notify("📋", "Copied!", 2, "success")
                end
            end,
        })
        CreditsTab:CreateSection(T("section.version"))
        CreditsTab:CreateLabel(FULL_VERSION, Color3.fromRGB(140, 140, 155))
        CreditsTab:CreateLabel("© 2026 Sr Red", Color3.fromRGB(90, 90, 105))
    end

    -- ═══════════════════════════════════════════════
    -- REBUILD AO TROCAR IDIOMA
    -- ═══════════════════════════════════════════════
    local rebuilding = false
    _G.IZ_RefreshLanguage = function()
        if UNLOADED or rebuilding then return end
        rebuilding = true
        task.defer(function()
            if Window then pcall(function() Window:Destroy() end) end
            Window = nil
            Elements = {}
            buildUI()
            syncUIFromState()
            rebuilding = false
        end)
    end
    Language.onChange(_G.IZ_RefreshLanguage)

    -- ═══════════════════════════════════════════════
    -- BUILD + SYNC
    -- ═══════════════════════════════════════════════
    buildUI()
    syncUIFromState()

    -- ═══════════════════════════════════════════════
    -- AUTOLOAD
    -- ═══════════════════════════════════════════════
    task.defer(function()
        local autoloadName = getAutoload()
        if autoloadName then
            task.wait(1)
            loadConfigNamed(autoloadName)
        end
    end)

    Window:Notify("✅ " .. SHORT_VERSION, "MM2 loaded successfully", 4, "success")
    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
end

return MM2