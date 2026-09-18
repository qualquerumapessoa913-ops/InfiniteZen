-- ============================================================
-- INFINITE ZEN - BLOXSTRIKE v1.2 (R15 + Remotes corretos)
-- ============================================================

local BloxStrike = {}

function BloxStrike.Init(ctx)
    local Language = ctx.Language
    local UI       = ctx.UI
    local Compat   = ctx.Compat
    local gameName = ctx.gameName

    local function T(key) return Language.get(key) end

    local GAME_VERSION = "1.0"
    local FULL_VERSION  = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("[Infinite Zen] Inicializando " .. FULL_VERSION .. "...")

    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local UserInputService  = game:GetService("UserInputService")
    local VirtualInput      = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService       = game:GetService("HttpService")
    local Lighting          = game:GetService("Lighting")
    local LocalPlayer       = Players.LocalPlayer
    local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
    local Camera            = workspace.CurrentCamera

    local UNLOADED  = false
    local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    -- ═══════════════════════════════════════════════
    -- UI REGISTRY
    -- ═══════════════════════════════════════════════
    local Elements = {}
    local Window   = nil

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

    local function getScreenCenter()
        local vp = Camera.ViewportSize
        return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    end

    -- ═══════════════════════════════════════════════
    -- REMOTES
    -- ═══════════════════════════════════════════════
    local function getRemote(service, name)
        local nr = ReplicatedStorage:FindFirstChild("NetworkRemotes")
        if not nr then return nil end
        local s = nr:FindFirstChild(service)
        if not s then return nil end
        return s:FindFirstChild(name)
    end

    -- ═══════════════════════════════════════════════
    -- STATE
    -- ═══════════════════════════════════════════════
    local State = {
        silentAim = false, silentFov = 120,
        aimbot = false, aimbotFov = 100, aimbotSmooth = 30,
        aimbotMaxDist = 500, aimbotWallCheck = true,
        triggerbot = false, triggerbotDelay = 5,
        autoShoot = false, autoShootFov = 100,
        headExpander = false, headExpanderSize = 2,
        esp = false, espMaxDistance = 1000,
        espBox = true, espName = true, espHealth = true, espDistance = true,
        espWeapon = true, espArmor = true, espTracer = false,
        speed = false, speedValue = 50,
        jumpPower = false, jumpPowerValue = 80,
        fullbright = false,
        noShadows = false, noFog = false, noParticles = false,
        lowGraphics = false,
    }

    -- ═══════════════════════════════════════════════
    -- TEAM CHECK
    -- ═══════════════════════════════════════════════
    local function getTeam(p)
        local ok, t = pcall(function() return p:GetAttribute("Team") end)
        if ok then return t end
        return nil
    end

    local function isDead(p)
        local ok, d = pcall(function() return p:GetAttribute("Dead") end)
        if ok and d == true then return true end
        if p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then return true end
        end
        return false
    end

    local function isEnemy(p)
        if p == LocalPlayer then return false end
        if not p.Character then return false end
        if isDead(p) then return false end
        local myTeam = getTeam(LocalPlayer)
        local theirTeam = getTeam(p)
        if not myTeam or not theirTeam then return false end
        return myTeam ~= theirTeam
    end

    -- ═══════════════════════════════════════════════
    -- HELPERS
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
        local ex = {}
        if LocalPlayer.Character then table.insert(ex, LocalPlayer.Character) end
        table.insert(ex, targetPart.Parent)
        params.FilterDescendantsInstances = ex
        local dir = targetPart.Position - fromPos
        local dist = dir.Magnitude
        if dist < 0.1 then return true end
        local unitDir = dir.Unit
        return workspace:Raycast(fromPos + unitDir * 2, unitDir * (dist - 2), params) == nil
    end

    local function getTargetPart(p)
        if not p.Character then return nil end
        return getBasePart(p.Character, "Head")
    end

    -- ═══════════════════════════════════════════════
    -- FIRE
    -- ═══════════════════════════════════════════════
    local function fireWeapon()
        if type(mouse1click) == "function" then
            local ok = pcall(mouse1click)
            if ok then return true end
        end
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
        return true
    end

    -- ═══════════════════════════════════════════════
    -- FOV CIRCLE
    -- ═══════════════════════════════════════════════
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(230, 40, 40)
    fovCircle.Thickness = 1.5
    fovCircle.Filled = false
    fovCircle.NumSides = IS_MOBILE and 48 or 72
    fovCircle.Transparency = 1
    fovCircle.Visible = false

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        fovCircle.Position = getScreenCenter()
        if State.silentAim then
            fovCircle.Visible = true; fovCircle.Radius = State.silentFov
        elseif State.autoShoot then
            fovCircle.Visible = true; fovCircle.Radius = State.autoShootFov
        elseif State.aimbot then
            fovCircle.Visible = true; fovCircle.Radius = State.aimbotFov
        else
            fovCircle.Visible = false
        end
    end)

    -- ═══════════════════════════════════════════════
    -- TARGETING
    -- ═══════════════════════════════════════════════
    local losCache = {}
    local LOS_TIME = 0.12

    local function hasLOSCached(p, part)
        local e = losCache[p]
        local now = tick()
        if e and (now - e.time) < LOS_TIME then return e.visible end
        local v = hasLineOfSight(Camera.CFrame.Position, part)
        losCache[p] = {visible = v, time = now}
        return v
    end

    Players.PlayerRemoving:Connect(function(p) losCache[p] = nil end)

    local function getClosestEnemyInFov(fovRange)
        local center = getScreenCenter()
        local closest, minDist = nil, fovRange
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < minDist then
                            if not State.aimbotWallCheck or hasLOSCached(p, part) then
                                minDist = d; closest = p
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    -- ═══════════════════════════════════════════════
    -- SILENT AIM (via ShootWeapon remote)
    -- ═══════════════════════════════════════════════
    local silentHolding, silentTarget = false, nil
    local silentOriginalCF = nil

    RunService:BindToRenderStep("IZ_BS_Silent", Enum.RenderPriority.Camera.Value + 10, function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then silentHolding = false; return end
        local head = getTargetPart(silentTarget)
        if not head then silentHolding = false; return end
        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.silentAim then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        silentOriginalCF = Camera.CFrame
        local target = getClosestEnemyInFov(State.silentFov)
        if not target then return end
        silentTarget = target
        silentHolding = true
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        silentHolding = false
        silentTarget = nil
    end)

    -- ═══════════════════════════════════════════════
    -- AIMBOT
    -- ═══════════════════════════════════════════════
    local aimbotFrames = 0
    local AIMBOT_SKIP = IS_MOBILE and 2 or 1

    RunService:BindToRenderStep("IZ_BS_Aimbot", Enum.RenderPriority.Camera.Value + 1, function()
        if UNLOADED or not State.aimbot then return end
        aimbotFrames = aimbotFrames + 1
        if aimbotFrames % AIMBOT_SKIP ~= 0 then return end
        local target = getClosestEnemyInFov(State.aimbotFov)
        if not target then return end
        local part = getTargetPart(target)
        if not part then return end
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        if (part.Position - myHRP.Position).Magnitude > State.aimbotMaxDist then return end
        local camPos = Camera.CFrame.Position
        local targetDir = (part.Position - camPos).Unit
        local currentDir = Camera.CFrame.LookVector
        local alpha = math.clamp(State.aimbotSmooth / 100, 0.02, 1)
        if type(mousemoverel) == "function" then
            local sp = Camera:WorldToViewportPoint(part.Position)
            local c = getScreenCenter()
            pcall(function() mousemoverel((sp.X - c.X) * alpha, (sp.Y - c.Y) * alpha) end)
        else
            local newDir = currentDir:Lerp(targetDir, alpha)
            pcall(function() Camera.CFrame = CFrame.lookAt(camPos, camPos + newDir) end)
        end
    end)

    -- ═══════════════════════════════════════════════
    -- TRIGGERBOT
    -- ═══════════════════════════════════════════════
    local triggerLast = 0
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.triggerbot then return end
        if tick() - triggerLast < (State.triggerbotDelay / 1000) then return end
        local c = getScreenCenter()
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and depth and depth > 0 and (Vector2.new(sp.X, sp.Y) - c).Magnitude < 25 then
                        triggerLast = tick()
                        fireWeapon()
                        break
                    end
                end
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- AUTO SHOOT
    -- ═══════════════════════════════════════════════
    local lastAuto = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoShoot then return end
        if tick() - lastAuto < 0.05 then return end
        local target = getClosestEnemyInFov(State.autoShootFov)
        if target then
            lastAuto = tick()
            fireWeapon()
        end
    end)

    -- ═══════════════════════════════════════════════
    -- HEAD EXPANDER (R15 normal — sem Hitbox custom)
    -- ═══════════════════════════════════════════════
    local headSaved = {}

    local function expandHead(p, size)
        if not p.Character then return end
        local head = getBasePart(p.Character, "Head")
        if not head then return end
        if not headSaved[p] then headSaved[p] = head.Size end
        local base = headSaved[p]
        pcall(function()
            head.Size = Vector3.new(base.X * size, base.Y * size, base.Z * size)
            head.CanCollide = false
            head.Massless = true
        end)
    end

    local function restoreHead(p)
        if not p.Character or not headSaved[p] then return end
        local head = getBasePart(p.Character, "Head")
        if head then
            pcall(function() head.Size = headSaved[p] end)
        end
        headSaved[p] = nil
    end

    local function restoreAllHeads()
        for p in pairs(headSaved) do restoreHead(p) end
        headSaved = {}
    end

    local heTick = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if not State.headExpander then
            if next(headSaved) then restoreAllHeads() end
            return
        end
        heTick = heTick + 1
        if heTick % 5 ~= 0 then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then
                expandHead(p, State.headExpanderSize)
            else
                if headSaved[p] then restoreHead(p) end
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- ESP
    -- ═══════════════════════════════════════════════
    local ESP = {data = {}}

    local function createESP(p)
        if ESP.data[p] then return end
        if not p.Character then return end
        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Color3.fromRGB(255, 30, 40)
        chams.FillTransparency = 0.6
        chams.OutlineColor = Color3.fromRGB(255, 255, 255)
        chams.OutlineTransparency = 0.3
        chams.Parent = p.Character

        local d = {chams = chams, character = p.Character}
        local function nd(c, props)
            local x = Drawing.new(c)
            for k, v in pairs(props) do x[k] = v end
            x.Visible = false
            return x
        end
        d.box      = nd("Square", {Thickness = 1.5, Color = Color3.fromRGB(255, 30, 40), Filled = false, Transparency = 1})
        d.name     = nd("Text",   {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        d.distance = nd("Text",   {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255, 80, 80)})
        d.health   = nd("Line",   {Thickness = 3, Color = Color3.fromRGB(0, 255, 0)})
        d.tracer   = nd("Line",   {Thickness = 1.2, Color = Color3.fromRGB(255, 30, 40)})
        d.weapon   = nd("Text",   {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 200, 100)})
        d.armor    = nd("Text",   {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(100, 200, 255)})
        ESP.data[p] = d
    end

    local function destroyESP(p)
        local d = ESP.data[p]
        if not d then return end
        if d.chams then d.chams:Destroy() end
        for _, k in ipairs({"box","name","distance","health","tracer","weapon","armor"}) do
            if d[k] and d[k].Remove then d[k]:Remove() end
        end
        ESP.data[p] = nil
    end

    local function clearESP()
        for p in pairs(ESP.data) do destroyESP(p) end
    end

    local function getArmorText(p)
        local ok, a = pcall(function() return p:GetAttribute("Armor") end)
        if not ok or not a then return nil end
        local ok2, dec = pcall(function() return HttpService:JSONDecode(a) end)
        if ok2 and dec and dec.Health then return dec.Health end
        return nil
    end

    local function getWeaponName(p)
        if not p.Character then return nil end
        local wm = p.Character:FindFirstChild("WeaponModel")
        if wm and wm:IsA("Folder") then
            for _, c in ipairs(wm:GetChildren()) do
                if c:IsA("Model") or c:IsA("Tool") then return c.Name end
            end
        end
        return nil
    end

    local function hideESP(d)
        for _, k in ipairs({"box","name","distance","health","tracer","weapon","armor"}) do
            if d[k] then d[k].Visible = false end
        end
        if d.chams then d.chams.Enabled = false end
    end

    local function updateESP(p, char)
        local d = ESP.data[p]
        if not d then return end
        if not State.esp or not isEnemy(p) then hideESP(d); return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then hideESP(d); return end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then hideESP(d); return end
        if d.chams then d.chams.Enabled = true end

        local headSp, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpSp, hrpOn = Camera:WorldToViewportPoint(hrp.Position)
        local footSp, footOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then hideESP(d); return end
        local dist = math.floor((head.Position - myHRP.Position).Magnitude)
        if dist > State.espMaxDistance then hideESP(d); return end

        if State.espBox and headOn and footOn then
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
                d.name.Text = p.Name
                d.name.Visible = true
            else d.name.Visible = false end
            if State.espDistance then
                d.distance.Position = Vector2.new(headSp.X, headSp.Y - 6)
                d.distance.Text = dist .. "m"
                d.distance.Visible = true
            else d.distance.Visible = false end

            if State.espWeapon then
                local wn = getWeaponName(p)
                if wn then
                    d.weapon.Position = Vector2.new(headSp.X, headSp.Y - 34)
                    d.weapon.Text = "[" .. wn .. "]"
                    d.weapon.Visible = true
                else d.weapon.Visible = false end
            else d.weapon.Visible = false end

            if State.espArmor then
                local av = getArmorText(p)
                if av then
                    d.armor.Position = Vector2.new(headSp.X, headSp.Y + 8)
                    d.armor.Text = "🛡 " .. tostring(av)
                    d.armor.Visible = true
                else d.armor.Visible = false end
            else d.armor.Visible = false end
        else
            d.name.Visible = false
            d.distance.Visible = false
            d.weapon.Visible = false
            d.armor.Visible = false
        end

        if State.espHealth and headOn and footOn then
            local h = math.abs(footSp.Y - headSp.Y)
            local maxHP = hum.MaxHealth
            local hr = (maxHP > 0) and math.clamp(hum.Health / maxHP, 0, 1) or 1
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

        if State.espTracer and hrpOn then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To = Vector2.new(hrpSp.X, hrpSp.Y)
            d.tracer.Visible = true
        else d.tracer.Visible = false end
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.esp then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                createESP(p)
                updateESP(p, p.Character)
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(p) destroyESP(p) end)
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            if ESP.data[p] then destroyESP(p) end
        end)
    end)

    -- ═══════════════════════════════════════════════
    -- FULLBRIGHT / OPTIMIZATIONS
    -- ═══════════════════════════════════════════════
    local origBrightness = Lighting.Brightness
    local origAmbient    = Lighting.Ambient
    local origOutdoor    = Lighting.OutdoorAmbient
    local origClock      = Lighting.ClockTime
    local origShadows    = Lighting.GlobalShadows
    local origFogEnd     = Lighting.FogEnd
    local origFogStart   = Lighting.FogStart

    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if State.fullbright then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(200,200,200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
        end
        if State.noFog then
            Lighting.FogEnd = 1e6
            Lighting.FogStart = 0
        end
    end)

    local function restoreEnv()
        Lighting.Brightness = origBrightness
        Lighting.Ambient = origAmbient
        Lighting.OutdoorAmbient = origOutdoor
        Lighting.ClockTime = origClock
        Lighting.GlobalShadows = origShadows
        Lighting.FogEnd = origFogEnd
        Lighting.FogStart = origFogStart
    end

    -- ═══════════════════════════════════════════════
    -- CONFIG
    -- ═══════════════════════════════════════════════
    local BASE_FOLDER   = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/BloxStrike"
    local AUTOLOAD_FILE = "InfiniteZen_BloxStrike_Autoload.txt"

    local function ensureFolder()
        if makefolder then
            if not isfolder(BASE_FOLDER)   then pcall(function() makefolder(BASE_FOLDER) end) end
            if not isfolder(CONFIG_FOLDER) then pcall(function() makefolder(CONFIG_FOLDER) end) end
        end
    end

    local function syncUIFromState()
        for _, k in ipairs({
            "silentAim","aimbot","triggerbot","autoShoot","headExpander",
            "esp","espBox","espName","espHealth","espDistance","espWeapon","espArmor","espTracer",
            "speed","jumpPower","fullbright","noShadows","noFog","noParticles","lowGraphics",
        }) do
            local el = Elements[k]
            if el and State[k] ~= nil then setToggle(el, State[k]) end
        end
        for _, k in ipairs({
            "silentFov","aimbotFov","aimbotSmooth","aimbotMaxDist",
            "triggerbotDelay","autoShootFov","headExpanderSize","espMaxDistance",
            "speedValue","jumpPowerValue",
        }) do
            local el = Elements[k]
            if el and State[k] ~= nil then setSlider(el, State[k]) end
        end
    end

    local function saveConfigNamed(name)
        ensureFolder()
        local data = {version = GAME_VERSION, state = {}}
        for k, v in pairs(State) do data.state[k] = v end
        local ok = pcall(function() writefile(CONFIG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
        if ok and Window then Window:Notify("💾", "Saved: " .. name, 3, "success") end
    end

    local function loadConfigNamed(name)
        local ok, c = pcall(function() return readfile(CONFIG_FOLDER .. "/" .. name .. ".json") end)
        if not ok or not c then return false end
        local s, data = pcall(function() return HttpService:JSONDecode(c) end)
        if not s or not data then return false end
        if data.state then for k, v in pairs(data.state) do State[k] = v end end
        syncUIFromState()
        if Window then Window:Notify("📂", "Loaded: " .. name, 3, "info") end
        return true
    end

    local function listConfigs()
        local list = {}
        if listfiles and isfolder and isfolder(CONFIG_FOLDER) then
            for _, f in ipairs(listfiles(CONFIG_FOLDER)) do
                if f:sub(-5) == ".json" then
                    local n = f:match("([^/\\]+)%.json$")
                    if n then table.insert(list, n) end
                end
            end
        end
        return list
    end

    local function getAutoload()
        local ok, c = pcall(function() return readfile(AUTOLOAD_FILE) end)
        if ok and c and c ~= "" then return c end
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

        -- COMBAT
        local CombatTab = Window:CreateTab(T("tab.combat"), "⚔️")
        CombatTab:CreateSection(T("section.aim"))
        reg("silentAim", CombatTab:CreateToggle({
            Name = T("silent.name"), Description = T("silent.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.silentAim = v end,
        }))
        reg("silentFov", CombatTab:CreateSlider({
            Name = T("silentfov.name"), Description = T("silentfov.desc"),
            Icon = "📐", Min = 30, Max = 400, Default = 120,
            Callback = function(v) State.silentFov = v end,
        }))
        reg("aimbot", CombatTab:CreateToggle({
            Name = T("aimbot.name"), Description = T("aimbot.desc"),
            Icon = "🤖", Default = false,
            Callback = function(v) State.aimbot = v end,
        }))
        reg("aimbotFov", CombatTab:CreateSlider({
            Name = T("aimbotfov.name"), Description = T("aimbotfov.desc"),
            Icon = "📐", Min = 30, Max = 400, Default = 100,
            Callback = function(v) State.aimbotFov = v end,
        }))
        reg("aimbotSmooth", CombatTab:CreateSlider({
            Name = T("aimbotsmooth.name"), Description = T("aimbotsmooth.desc"),
            Icon = "🎚️", Min = 5, Max = 100, Default = 30,
            Callback = function(v) State.aimbotSmooth = v end,
        }))
        reg("aimbotMaxDist", CombatTab:CreateSlider({
            Name = T("aimbotdist.name"), Description = T("aimbotdist.desc"),
            Icon = "📏", Min = 50, Max = 2000, Default = 500,
            Callback = function(v) State.aimbotMaxDist = v end,
        }))
        reg("aimbotWallCheck", CombatTab:CreateToggle({
            Name = T("aimbotwall.name"), Description = T("aimbotwall.desc"),
            Icon = "🧱", Default = true,
            Callback = function(v) State.aimbotWallCheck = v end,
        }))
        CombatTab:CreateSection(T("section.auto"))
        reg("triggerbot", CombatTab:CreateToggle({
            Name = T("triggerbot.name"), Description = T("triggerbot.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.triggerbot = v end,
        }))
        reg("triggerbotDelay", CombatTab:CreateSlider({
            Name = T("triggerbotdelay.name"), Description = T("triggerbotdelay.desc"),
            Icon = "⏱️", Min = 1, Max = 200, Default = 5,
            Callback = function(v) State.triggerbotDelay = v end,
        }))
        reg("autoShoot", CombatTab:CreateToggle({
            Name = T("autoshot.name"), Description = T("autoshot.desc"),
            Icon = "🔥", Default = false,
            Callback = function(v) State.autoShoot = v end,
        }))
        reg("autoShootFov", CombatTab:CreateSlider({
            Name = T("autoshotfov.name"), Description = T("autoshotfov.desc"),
            Icon = "📐", Min = 30, Max = 400, Default = 100,
            Callback = function(v) State.autoShootFov = v end,
        }))
        CombatTab:CreateSection(T("section.hitbox"))
        reg("headExpander", CombatTab:CreateToggle({
            Name = T("headexp.name"), Description = T("headexp.desc"),
            Icon = "🔴", Default = false,
            Callback = function(v) State.headExpander = v; if not v then restoreAllHeads() end end,
        }))
        reg("headExpanderSize", CombatTab:CreateSlider({
            Name = T("headsize.name"), Description = T("headsize.desc"),
            Icon = "📏", Min = 1, Max = 5, Default = 2,
            Callback = function(v) State.headExpanderSize = v end,
        }))

        -- MOVEMENT
        local MoveTab = Window:CreateTab(T("tab.movement"), "🏃")
        MoveTab:CreateSection(T("section.movement"))
        reg("speed", MoveTab:CreateToggle({
            Name = T("speed.name"), Description = T("speed.desc") .. " ⚠️ may not work",
            Icon = "⚡", Default = false,
            Callback = function(v) State.speed = v end,
        }))
        reg("speedValue", MoveTab:CreateSlider({
            Name = T("speedvalue.name"), Description = T("speedvalue.desc"),
            Icon = "📏", Min = 16, Max = 200, Default = 50,
            Callback = function(v) State.speedValue = v end,
        }))
        reg("jumpPower", MoveTab:CreateToggle({
            Name = T("jumppower.name"), Description = T("jumppower.desc"),
            Icon = "🦘", Default = false,
            Callback = function(v) State.jumpPower = v end,
        }))
        reg("jumpPowerValue", MoveTab:CreateSlider({
            Name = T("jumppower.value.name"), Description = T("jumppower.value.desc"),
            Icon = "📏", Min = 30, Max = 200, Default = 80,
            Callback = function(v) State.jumpPowerValue = v end,
        }))

        -- VISUALS
        local VisualsTab = Window:CreateTab(T("tab.visuals"), "👁️")
        VisualsTab:CreateSection(T("section.esp"))
        reg("esp", VisualsTab:CreateToggle({
            Name = T("esp.name"), Description = T("esp.desc"),
            Icon = "👤", Default = false,
            Callback = function(v)
                State.esp = v
                if v then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then createESP(p) end
                    end
                else clearESP() end
            end,
        }))
        reg("espMaxDistance", VisualsTab:CreateSlider({
            Name = T("espdist.name"), Description = T("espdist.desc"),
            Icon = "📐", Min = 100, Max = 5000, Default = 1000,
            Callback = function(v) State.espMaxDistance = v end,
        }))
        reg("espBox", VisualsTab:CreateToggle({
            Name = "ESP Box", Description = "",
            Icon = "⬜", Default = true,
            Callback = function(v) State.espBox = v end,
        }))
        reg("espName", VisualsTab:CreateToggle({
            Name = "ESP Name", Description = "",
            Icon = "📛", Default = true,
            Callback = function(v) State.espName = v end,
        }))
        reg("espHealth", VisualsTab:CreateToggle({
            Name = "ESP Health", Description = "",
            Icon = "❤️", Default = true,
            Callback = function(v) State.espHealth = v end,
        }))
        reg("espDistance", VisualsTab:CreateToggle({
            Name = "ESP Distance", Description = "",
            Icon = "📏", Default = true,
            Callback = function(v) State.espDistance = v end,
        }))
        reg("espWeapon", VisualsTab:CreateToggle({
            Name = "ESP Weapon", Description = "",
            Icon = "🔫", Default = true,
            Callback = function(v) State.espWeapon = v end,
        }))
        reg("espArmor", VisualsTab:CreateToggle({
            Name = "ESP Armor", Description = "",
            Icon = "🛡️", Default = true,
            Callback = function(v) State.espArmor = v end,
        }))
        reg("espTracer", VisualsTab:CreateToggle({
            Name = "ESP Tracer", Description = "",
            Icon = "📡", Default = false,
            Callback = function(v) State.espTracer = v end,
        }))
        VisualsTab:CreateSection(T("section.environment"))
        reg("fullbright", VisualsTab:CreateToggle({
            Name = T("fullbright.name"), Description = T("fullbright.desc"),
            Icon = "💡", Default = false,
            Callback = function(v) State.fullbright = v; if not v then restoreEnv() end end,
        }))
        reg("noFog", VisualsTab:CreateToggle({
            Name = T("nofog.name"), Description = T("nofog.desc"),
            Icon = "🌫️", Default = false,
            Callback = function(v) State.noFog = v; if not v then restoreEnv() end end,
        }))

        -- SETTINGS
        local SettingsTab = Window:CreateTab(T("tab.settings"), "⚙️")
        SettingsTab:CreateSection(T("section.create_config"))

        local cFrame = Instance.new("Frame", SettingsTab.container)
        cFrame.Size = UDim2.new(1, 0, 0, 40)
        cFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        cFrame.BorderSizePixel = 0
        cFrame.LayoutOrder = #SettingsTab.container:GetChildren()
        Instance.new("UICorner", cFrame).CornerRadius = UDim.new(0, 8)

        local cInput = Instance.new("TextBox", cFrame)
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

        local listFrame = Instance.new("Frame", SettingsTab.container)
        listFrame.Size = UDim2.new(1, 0, 0, 160)
        listFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        listFrame.BorderSizePixel = 0
        listFrame.LayoutOrder = #SettingsTab.container:GetChildren()
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)

        local listScroll = Instance.new("ScrollingFrame", listFrame)
        listScroll.Size = UDim2.new(1, -12, 1, -12)
        listScroll.Position = UDim2.new(0, 6, 0, 6)
        listScroll.BackgroundTransparency = 1
        listScroll.BorderSizePixel = 0
        listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listScroll.ScrollBarThickness = 3
        listScroll.ScrollBarImageColor3 = Color3.fromRGB(230, 40, 40)
        Instance.new("UIListLayout", listScroll).Padding = UDim.new(0, 4)

        local function refreshList()
            for _, c in ipairs(listScroll:GetChildren()) do
                if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
            end
            local configs = listConfigs()
            if #configs == 0 then
                local e = Instance.new("TextLabel", listScroll)
                e.Size = UDim2.new(1, 0, 0, 30)
                e.BackgroundTransparency = 1
                e.Font = Enum.Font.Gotham
                e.TextSize = 11
                e.TextColor3 = Color3.fromRGB(90, 90, 105)
                e.Text = T("config.empty")
                return
            end
            for _, name in ipairs(configs) do
                local entry = Instance.new("Frame", listScroll)
                entry.Size = UDim2.new(1, -4, 0, 32)
                entry.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
                entry.BorderSizePixel = 0
                Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)

                local lbl = Instance.new("TextLabel", entry)
                lbl.Size = UDim2.new(0.5, 0, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 11
                lbl.TextColor3 = Color3.fromRGB(240, 240, 245)
                lbl.Text = name
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local lb = Instance.new("TextButton", entry)
                lb.Size = UDim2.new(0, 50, 0, 22)
                lb.Position = UDim2.new(1, -110, 0.5, -11)
                lb.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
                lb.Text = "Load"
                lb.Font = Enum.Font.GothamBold
                lb.TextSize = 10
                lb.TextColor3 = Color3.fromRGB(240, 240, 245)
                lb.AutoButtonColor = false
                Instance.new("UICorner", lb).CornerRadius = UDim.new(0, 4)
                lb.MouseButton1Click:Connect(function() loadConfigNamed(name); refreshList() end)

                local ab = Instance.new("TextButton", entry)
                ab.Size = UDim2.new(0, 22, 0, 22)
                ab.Position = UDim2.new(1, -55, 0.5, -11)
                ab.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                ab.Text = "⚡"
                ab.Font = Enum.Font.GothamBold
                ab.TextSize = 11
                ab.TextColor3 = Color3.fromRGB(240, 240, 245)
                ab.AutoButtonColor = false
                Instance.new("UICorner", ab).CornerRadius = UDim.new(0, 4)
                ab.MouseButton1Click:Connect(function()
                    pcall(function() writefile(AUTOLOAD_FILE, name) end)
                    refreshList()
                end)

                local db = Instance.new("TextButton", entry)
                db.Size = UDim2.new(0, 22, 0, 22)
                db.Position = UDim2.new(1, -28, 0.5, -11)
                db.BackgroundColor3 = Color3.fromRGB(60, 15, 20)
                db.Text = "×"
                db.Font = Enum.Font.GothamBold
                db.TextSize = 14
                db.TextColor3 = Color3.fromRGB(255, 40, 40)
                db.AutoButtonColor = false
                Instance.new("UICorner", db).CornerRadius = UDim.new(0, 4)
                db.MouseButton1Click:Connect(function()
                    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
                    if isfile and isfile(path) then pcall(function() delfile(path) end) end
                    refreshList()
                end)
            end
        end

        cInput.FocusLost:Connect(function(ent)
            if ent and cInput.Text ~= "" then
                saveConfigNamed(cInput.Text)
                cInput.Text = ""
                refreshList()
            end
        end)

        SettingsTab:CreateButton({ Name = T("config.refresh"), Callback = function() refreshList() end })
        refreshList()

        SettingsTab:CreateSection(T("section.danger"))
        SettingsTab:CreateButton({
            Name = T("config.unload"),
            Danger = true,
            Callback = function()
                UNLOADED = true
                clearESP()
                restoreAllHeads()
                restoreEnv()
                if fovCircle then fovCircle:Remove() end
                pcall(function() RunService:UnbindFromRenderStep("IZ_BS_Silent") end)
                pcall(function() RunService:UnbindFromRenderStep("IZ_BS_Aimbot") end)
                if Window then Window:Notify("Unload", T("config.unload"), 2, "warning") end
                task.wait(0.3)
                if Window then Window:Destroy() end
            end,
        })

        -- LANGUAGE
        local LanguageTab = Window:CreateTab(T("tab.language"), "🌍")
        LanguageTab:CreateSection(T("section.language_select"))
        local available = Language.getAvailable()
        local cur = Language.getCurrent()
        local opts = {}
        local defIdx = 1
        for i, info in ipairs(available) do
            table.insert(opts, info.flag .. " " .. info.displayName)
            if info.code == cur then defIdx = i end
        end
        LanguageTab:CreateDropdown({
            Name = T("tab.language"), Description = T("lang.hint"),
            Icon = "🌍", Options = opts, Default = defIdx,
            Callback = function(_, idx)
                local info = available[idx]
                if info then Language.setLanguage(info.code) end
            end,
        })

        -- CREDITS
        local CreditsTab = Window:CreateTab(T("tab.credits"), "➕")
        CreditsTab:CreateSection(T("section.founder"))
        CreditsTab:CreateLabel(T("credits.role"), Color3.fromRGB(255, 50, 50))
        CreditsTab:CreateSection(T("section.community"))
        CreditsTab:CreateLabel("discord.gg/ScZfU2mAGm", Color3.fromRGB(88, 101, 242))
        CreditsTab:CreateButton({
            Name = T("credits.copy_discord"),
            Callback = function()
                if setclipboard then setclipboard("https://discord.gg/ScZfU2mAGm"); Window:Notify("📋", "Copied!", 2, "success") end
            end,
        })
        CreditsTab:CreateSection(T("section.version"))
        CreditsTab:CreateLabel(FULL_VERSION, Color3.fromRGB(140, 140, 155))
        CreditsTab:CreateLabel("© 2026 Sr Red", Color3.fromRGB(90, 90, 105))
    end

    -- ═══════════════════════════════════════════════
    -- REBUILD ON LANGUAGE CHANGE
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

    buildUI()
    syncUIFromState()

    task.defer(function()
        local a = getAutoload()
        if a then task.wait(1); loadConfigNamed(a) end
    end)

    Window:Notify("✅ " .. SHORT_VERSION, "BloxStrike loaded", 4, "success")
    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
end

return BloxStrike