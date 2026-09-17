-- ============================================================
-- INFINITE ZEN - JAILBIRD v1.2 (Bugs + Otimizações mobile)
-- ============================================================

local Jailbird = {}

function Jailbird.Init(ctx)
    local Language = ctx.Language
    local UI       = ctx.UI
    local Compat   = ctx.Compat
    local gameName = ctx.gameName

    local function T(key) return Language.get(key) end

    local GAME_VERSION = "1.2"
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
    -- CENTRO DA TELA (fix do offset da topbar)
    -- ═══════════════════════════════════════════════
    local function getScreenCenter()
        local vp = Camera.ViewportSize
        return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    end

    -- ═══════════════════════════════════════════════
    -- REMOTES (WaitForChild + retry)
    -- ═══════════════════════════════════════════════
    local GameEvents
    task.spawn(function()
        while not UNLOADED and not GameEvents do
            GameEvents = ReplicatedStorage:FindFirstChild("GameEvents")
            if not GameEvents then
                pcall(function() GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 3) end)
            end
            if not GameEvents then task.wait(1) end
        end
    end)

    local Remotes = {}
    local function getRemote(name)
        if Remotes[name] then return Remotes[name] end
        if not GameEvents then return nil end
        local r = GameEvents:FindFirstChild(name)
        if r then Remotes[name] = r end
        return r
    end

    -- ═══════════════════════════════════════════════
    -- TEAM CHECK
    -- ═══════════════════════════════════════════════
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

    -- ═══════════════════════════════════════════════
    -- STATE
    -- ═══════════════════════════════════════════════
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
    }

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

    local function getTargetPart(p)
        if not p.Character then return nil end
        local mode = State.aimbotHitbox
        if mode == 1 then
            return getBasePart(p.Character, "Head")
        elseif mode == 2 then
            return getBasePart(p.Character, "Torso", "UpperTorso")
        else
            local head  = getBasePart(p.Character, "Head")
            local torso = getBasePart(p.Character, "Torso", "UpperTorso")
            if head and torso then
                local camPos = Camera.CFrame.Position
                return (head.Position - camPos).Magnitude <= (torso.Position - camPos).Magnitude and head or torso
            end
            return head or torso
        end
    end

    -- ═══════════════════════════════════════════════
    -- FIRE
    -- ═══════════════════════════════════════════════
    local function fireWeapon()
        local char = LocalPlayer.Character
        if not char then return false end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return false end
        if type(mouse1click) == "function" then
            local ok = pcall(mouse1click)
            if ok then return true end
        end
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.005)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
        return true
    end

    -- ═══════════════════════════════════════════════
    -- FOV CIRCLE
    -- ═══════════════════════════════════════════════
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(230, 40, 40); fovCircle.Thickness = 1.5
    fovCircle.Filled = false; fovCircle.NumSides = 100; fovCircle.Transparency = 1
    fovCircle.Radius = 25; fovCircle.Visible = false

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        fovCircle.Position = getScreenCenter()
        if State.silentHeadshot then
            fovCircle.Visible = true; fovCircle.Radius = State.silentFov
        elseif State.autoShoot then
            fovCircle.Visible = true; fovCircle.Radius = State.autoShootFov
        elseif State.triggerbot then
            fovCircle.Visible = true; fovCircle.Radius = 20
        elseif State.aimbot then
            fovCircle.Visible = true; fovCircle.Radius = State.aimbotFov
        else
            fovCircle.Visible = false
        end
    end)

    -- ═══════════════════════════════════════════════
    -- TARGETING
    -- ═══════════════════════════════════════════════
    local function getClosestEnemyInFov(fovRange)
        local center = getScreenCenter()
        local closest, minDist = nil, fovRange
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local part = getTargetPart(p)
                if part then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d and d < minDist then
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

    -- ═══════════════════════════════════════════════
    -- SILENT HEADSHOT
    -- ═══════════════════════════════════════════════
    local silentHolding, silentTarget = false, nil

    RunService:BindToRenderStep("IZ_JB_Silent", Enum.RenderPriority.Camera.Value + 10, function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then silentHolding = false; return end
        local head = getBasePart(silentTarget.Character, "Head")
        if not head then silentHolding = false; return end
        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.silentHeadshot then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
           and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local target = getClosestEnemyInFov(State.silentFov)
        if not target or not target.Character then return end
        silentTarget = target
        silentHolding = true
        local lr = getRemote("LookRotation")
        if lr then
            local head = getBasePart(target.Character, "Head")
            if head then
                local targetCF = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
                pcall(function() lr:FireServer(targetCF) end)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
           and input.UserInputType ~= Enum.UserInputType.Touch then return end
        silentHolding = false
        silentTarget  = nil
    end)

    -- ═══════════════════════════════════════════════
    -- AIMBOT
    -- ═══════════════════════════════════════════════
    RunService:BindToRenderStep("IZ_JB_Aimbot", Enum.RenderPriority.Camera.Value + 1, function()
        if UNLOADED or not State.aimbot then return end
        local target = getClosestEnemyInFov(State.aimbotFov)
        if not target or not target.Character then return end
        local part = getTargetPart(target)
        if not part then return end
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        if (part.Position - myRoot.Position).Magnitude > State.aimbotMaxDist then return end

        local camPos = Camera.CFrame.Position
        local targetDir = (part.Position - camPos).Unit
        local currentDir = Camera.CFrame.LookVector
        local alpha = math.clamp(State.aimbotSmoothness, 0.02, 1)

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
    local triggerLastFire = 0
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.triggerbot then return end
        if tick() - triggerLastFire < (State.triggerbotDelay / 1000) then return end
        local center = getScreenCenter()
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
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

    -- ═══════════════════════════════════════════════
    -- AUTO SHOOT
    -- ═══════════════════════════════════════════════
    local lastAutoShoot = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoShoot then return end
        if tick() - lastAutoShoot < State.autoShootDelay then return end
        local target = getClosestEnemyInFov(State.autoShootFov)
        if target and target.Character then
            local part = getTargetPart(target)
            if part then
                lastAutoShoot = tick()
                fireWeapon()
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- BACKSTAB
    -- ═══════════════════════════════════════════════
    local backstabLock = {active = false, target = nil, endTime = 0}

    local function getClosestEnemyAnywhere()
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local closest, closestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:IsA("BasePart") then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d and d < closestDist then closestDist = d; closest = p end
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
            if tHRP and mHRP and tHRP:IsA("BasePart") and mHRP:IsA("BasePart") then
                Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
            end
        end
    end)

    local function doBackstab()
        if UNLOADED then return end
        local target = getClosestEnemyAnywhere()
        if not target or not target.Character then
            if Window then Window:Notify("⚔️", T("no_enemy"), 3, "error") end
            return
        end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local mHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP or not mHRP then return end
        if not tHRP:IsA("BasePart") or not mHRP:IsA("BasePart") then return end
        if Window then Window:Notify("⚔️ " .. T("backstab.name"), target.Name, 2, "info") end
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

    -- ═══════════════════════════════════════════════
    -- HEAD EXPANDER
    -- ═══════════════════════════════════════════════
    local hitboxSaved = {}

    local function saveOriginal(player, part)
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
        local head = getBasePart(p.Character, "Head")
        if head then
            saveOriginal(p, head)
            local base = hitboxSaved[p] and hitboxSaved[p][head]
            if base then
                pcall(function()
                    head.Size = Vector3.new(base.X * size, base.Y * math.min(size, 4), base.Z * size)
                    head.Transparency = 0.7; head.CanCollide = false; head.Massless = true
                end)
            end
        end
        local headHB = getBasePart(p.Character, "HeadHB")
        if headHB then
            saveOriginal(p, headHB)
            local base = hitboxSaved[p] and hitboxSaved[p][headHB]
            if base then
                local hbMult = math.min(size * 1.5, 12)
                pcall(function()
                    headHB.Size = Vector3.new(base.X * hbMult, base.Y * hbMult, base.Z * hbMult)
                    headHB.Transparency = 1; headHB.CanCollide = false; headHB.Massless = true
                end)
            end
        end
        local torso = getBasePart(p.Character, "Torso", "UpperTorso")
        if torso then
            saveOriginal(p, torso)
            local base = hitboxSaved[p] and hitboxSaved[p][torso]
            if base then
                local tMult = math.min(size * 0.7, 3)
                pcall(function()
                    torso.Size = Vector3.new(base.X * tMult, base.Y * tMult, base.Z * tMult)
                    torso.Transparency = 0.7; torso.CanCollide = false; torso.Massless = true
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

    -- ═══════════════════════════════════════════════
    -- WEAPON MODS
    -- ═══════════════════════════════════════════════
    local reloadOriginals = {}
    local weaponModsTick = 0

    local function findValueContainer(root, keywords)
        local found = {}
        if not root then return found end
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("NumberValue") or d:IsA("IntValue") then
                local n = d.Name:lower()
                for _, kw in ipairs(keywords) do
                    if n:find(kw) then
                        table.insert(found, d)
                        break
                    end
                end
            end
        end
        return found
    end

    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if not (State.rapidFire or State.noRecoil or State.fastReload or State.instaReload or State.noSpread or State.infiniteAmmo) then return end

        weaponModsTick = weaponModsTick + 1
        if weaponModsTick % 5 ~= 0 then return end

        local roots = {}
        if LocalPlayer.Character then table.insert(roots, LocalPlayer.Character) end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then table.insert(roots, backpack) end
        table.insert(roots, ReplicatedStorage)

        for _, root in ipairs(roots) do
            if State.rapidFire then
                local vals = findValueContainer(root, {"firerate", "rateoffire", "shootcooldown", "firedelay", "cooldown", "equiptime"})
                for _, v in ipairs(vals) do
                    pcall(function() v.Value = 0.01 end)
                end
            end
            if State.noRecoil then
                local vals = findValueContainer(root, {"recoil", "kick", "camerarecoil"})
                for _, v in ipairs(vals) do
                    pcall(function() v.Value = 0 end)
                end
            end
            if State.noSpread then
                local vals = findValueContainer(root, {"spread", "accuracy"})
                for _, v in ipairs(vals) do
                    pcall(function() v.Value = 0 end)
                end
            end
            if State.infiniteAmmo then
                local vals = findValueContainer(root, {"ammo", "magazine"})
                for _, v in ipairs(vals) do
                    local n = v.Name:lower()
                    if n ~= "mag" then
                        pcall(function()
                            if not reloadOriginals["ammo_" .. tostring(v)] then
                                reloadOriginals["ammo_" .. tostring(v)] = v.Value
                            end
                            v.Value = 9999
                        end)
                    end
                end
            end
            if State.fastReload and not State.instaReload then
                local vals = findValueContainer(root, {"reloadtime", "reloadspeed"})
                for _, v in ipairs(vals) do
                    pcall(function()
                        if not reloadOriginals[v] then reloadOriginals[v] = v.Value end
                        v.Value = reloadOriginals[v] * 0.1
                    end)
                end
            end
            if State.instaReload then
                local vals = findValueContainer(root, {"reloadtime", "reloadspeed"})
                for _, v in ipairs(vals) do
                    pcall(function()
                        if not reloadOriginals[v] then reloadOriginals[v] = v.Value end
                        v.Value = 0
                    end)
                end
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- AUTO BHOP
    -- ═══════════════════════════════════════════════
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

    -- ═══════════════════════════════════════════════
    -- ANTI-FLASH
    -- ═══════════════════════════════════════════════
    local flashKeywords = {"flash", "blind", "whiteout", "whitescreen", "flashbang"}
    local function isFlashName(name)
        if type(name) ~= "string" then return false end
        local lower = name:lower()
        for _, kw in ipairs(flashKeywords) do if lower:find(kw) then return true end end
        return false
    end

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.antiFlash then return end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, child in ipairs(pg:GetChildren()) do
                if (child:IsA("ScreenGui") or child:IsA("Frame")) and isFlashName(child.Name) then
                    pcall(function() child:Destroy() end)
                end
            end
        end
        for _, child in ipairs(Lighting:GetChildren()) do
            if (child:IsA("ColorCorrectionEffect") or child:IsA("BlurEffect")) and isFlashName(child.Name) then
                pcall(function() child:Destroy() end)
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- ANTI-VOTEKICK
    -- ═══════════════════════════════════════════════
    local vkKeywords = {"votekick", "voting", "vote_kick", "kickvote"}
    local function blockVoteKickGui(child)
        if not child then return false end
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
            if Window then Window:Notify("🛡️", "Anti-VK", 3, "info") end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- DAMAGE INDICATOR
    -- ═══════════════════════════════════════════════
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
        local center = getScreenCenter()
        local radius = 120
        local px = center.X
        local py = center.Y - radius
        local size = 14
        dmgArrow.PointA = Vector2.new(px, py + size)
        dmgArrow.PointB = Vector2.new(px - size * 0.7, py - size * 0.7)
        dmgArrow.PointC = Vector2.new(px + size * 0.7, py - size * 0.7)
        local alpha = math.clamp((1.5 - (now - lastDamageTime)) / 1.5, 0, 1)
        dmgArrow.Transparency = 0.15 + (1 - alpha) * 0.7
        dmgArrow.Visible = true
    end)

    -- ═══════════════════════════════════════════════
    -- GRENADE ESP
    -- ═══════════════════════════════════════════════
    local grenadeKeywords = {"grenade", "frag", "flashbang", "smoke", "molotov", "impact", "sticky", "decoy"}
    local grenadeDrawings = {}

    local function isGrenade(obj)
        if not obj or not obj.Parent or not obj:IsA("BasePart") then return false end
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
        pcall(function()
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
    end)

    -- ═══════════════════════════════════════════════
    -- ESP
    -- ═══════════════════════════════════════════════
    local ESP = {data = {}}

    local function destroyESPData(d)
        if not d then return end
        if d.chams then pcall(function() d.chams:Destroy() end) end
        for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon", "armor"}) do
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
        chams.FillColor = Color3.fromRGB(255, 30, 40)
        chams.FillTransparency = 0.6
        chams.OutlineColor = Color3.fromRGB(255, 255, 255)
        chams.OutlineTransparency = 0.3
        chams.Parent = p.Character

        local data = {chams = chams, character = p.Character}
        local function nd(class, props)
            local d = Drawing.new(class)
            for k, v in pairs(props) do d[k] = v end
            d.Visible = false
            return d
        end
        data.box      = nd("Square", {Thickness = 1.5, Color = Color3.fromRGB(255, 30, 40), Filled = false, Transparency = 1})
        data.name     = nd("Text",   {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        data.distance = nd("Text",   {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255, 80, 80)})
        data.health   = nd("Line",   {Thickness = 3, Color = Color3.fromRGB(0, 255, 0)})
        data.tracer   = nd("Line",   {Thickness = 1.2, Color = Color3.fromRGB(255, 30, 40)})
        data.headDot  = nd("Circle", {Radius = 4, NumSides = 20, Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255)})
        data.weapon   = nd("Text",   {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 200, 100)})
        data.armor    = nd("Text",   {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(100, 200, 255)})
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

    local function hideESP(d)
        for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot", "weapon", "armor"}) do
            if d[key] then d[key].Visible = false end
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
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then hideESP(d); return end
        if not head:IsA("BasePart") or not hrp:IsA("BasePart") then hideESP(d); return end
        if d.chams then d.chams.Enabled = true end
        local headSp, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpSp, hrpOn   = Camera:WorldToViewportPoint(hrp.Position)
        local footSp, footOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then hideESP(d); return end
        local dist = math.floor((head.Position - myHRP.Position).Magnitude)
        if dist > State.espMaxDistance then hideESP(d); return end

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
            d.name.Text = p.Name; d.name.Visible = true
            d.distance.Position = Vector2.new(headSp.X, headSp.Y - 6)
            d.distance.Text = dist .. "m"; d.distance.Visible = true
            d.headDot.Position = Vector2.new(headSp.X, headSp.Y); d.headDot.Visible = true

            if State.espWeapon then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    d.weapon.Position = Vector2.new(headSp.X, headSp.Y - 34)
                    d.weapon.Text = "[" .. tool.Name .. "]"
                    d.weapon.Visible = true
                else d.weapon.Visible = false end
            else d.weapon.Visible = false end

            if State.espArmor then
                if hum.MaxHealth and hum.MaxHealth > 100 then
                    local armorVal = math.floor(hum.MaxHealth - 100)
                    d.armor.Position = Vector2.new(headSp.X, headSp.Y + 8)
                    d.armor.Text = "🛡 " .. armorVal
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
            local maxHP = hum.MaxHealth
            local hr = 1
            if maxHP and maxHP > 0 then hr = math.clamp(hum.Health / maxHP, 0, 1) end
            local bx = headSp.X + (h * 0.6) / 2 + 5
            local by = headSp.Y + h
            local fy = by - (h * hr)
            d.health.From = Vector2.new(bx, fy)
            d.health.To   = Vector2.new(bx, by)
            if hr > 0.6 then d.health.Color = Color3.fromRGB(0, 255, 0)
            elseif hr > 0.3 then d.health.Color = Color3.fromRGB(255, 200, 0)
            else d.health.Color = Color3.fromRGB(255, 40, 40) end
            d.health.Visible = true
        else d.health.Visible = false end

        if hrpOn then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To   = Vector2.new(hrpSp.X, hrpSp.Y)
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

    -- ═══════════════════════════════════════════════
    -- SPEED
    -- ═══════════════════════════════════════════════
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.speed then return end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- AIR JUMP
    -- ═══════════════════════════════════════════════
    local airJumpConn = nil
    local AIR_JUMP_POWER = 55

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
            hrp.Velocity = Vector3.new(hrp.Velocity.X, AIR_JUMP_POWER, hrp.Velocity.Z)
        end)
    end

    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    -- ═══════════════════════════════════════════════
    -- FULLBRIGHT (originais)
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

    -- ═══════════════════════════════════════════════
    -- OPTIMIZATIONS v2 — Cache + Mobile-friendly
    -- ═══════════════════════════════════════════════
    local optBackup = {
        fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart,
        qualityLevel = nil, particles = {},
    }
    pcall(function() optBackup.qualityLevel = settings().Rendering.QualityLevel end)

    local cachedParts     = nil
    local cachedParticles = nil
    local cacheTimer      = 0
    local CACHE_REFRESH   = IS_MOBILE and 3 or 5

    local function refreshCaches()
        cachedParts     = {}
        cachedParticles = {}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                table.insert(cachedParts, d)
            elseif d:IsA("ParticleEmitter") or d:IsA("Fire")
                or d:IsA("Smoke") or d:IsA("Sparkles")
                or d:IsA("Trail") or d:IsA("Beam") then
                table.insert(cachedParticles, d)
            end
        end
        cacheTimer = 0
    end

    local function batchApply(list, fn)
        if not list then return end
        local count = 0
        for _, obj in ipairs(list) do
            if obj and obj.Parent then
                pcall(fn, obj)
                count = count + 1
                if count % 200 == 0 then task.wait() end
            end
        end
    end

    local function insideCharacter(obj)
        local parent = obj and obj.Parent
        while parent and parent ~= workspace do
            if parent:FindFirstChildOfClass("Humanoid") then return true end
            parent = parent.Parent
        end
        return false
    end

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
        if not v then return end
        task.spawn(function()
            if not cachedParts then refreshCaches() end
            batchApply(cachedParts, function(part)
                if not insideCharacter(part) and part.Name ~= "HumanoidRootPart" then
                    part.CastShadow = false
                end
            end)
        end)
    end

    local function applyNoFog(v)
        if v then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Atmosphere") then
                    c.Density = 0; c.Haze = 0; c.Glare = 0
                end
            end
        else
            Lighting.FogEnd = optBackup.fogEnd
            Lighting.FogStart = optBackup.fogStart
        end
    end

    local function applyNoParticles(v)
        if v then
            task.spawn(function()
                if not cachedParticles then refreshCaches() end
                batchApply(cachedParticles, function(p)
                    if not insideCharacter(p) then
                        if optBackup.particles[p] == nil then
                            optBackup.particles[p] = p.Enabled
                        end
                        p.Enabled = false
                    end
                end)
            end)
        else
            for obj, orig in pairs(optBackup.particles) do
                if obj and obj.Parent then
                    pcall(function() obj.Enabled = orig end)
                end
            end
            optBackup.particles = {}
        end
    end

    -- Loop incremental (throttled por mobile)
    local optTick = 0
    RunService.Heartbeat:Connect(function(dt)
        if UNLOADED then return end
        if not (State.noShadows or State.noParticles) then return end

        cacheTimer = cacheTimer + dt
        if cacheTimer >= CACHE_REFRESH then refreshCaches() end

        optTick = optTick + 1
        if optTick % (IS_MOBILE and 60 or 30) ~= 0 then return end

        if State.noParticles and cachedParticles then
            local applied = 0
            for _, p in ipairs(cachedParticles) do
                if p and p.Parent and p.Enabled then
                    if not insideCharacter(p) then
                        if optBackup.particles[p] == nil then
                            optBackup.particles[p] = p.Enabled
                        end
                        pcall(function() p.Enabled = false end)
                        applied = applied + 1
                        if applied >= 50 then break end
                    end
                end
            end
        end

        if State.noShadows and cachedParts then
            local applied = 0
            for _, part in ipairs(cachedParts) do
                if part and part.Parent and part.CastShadow then
                    if not insideCharacter(part) and part.Name ~= "HumanoidRootPart" then
                        pcall(function() part.CastShadow = false end)
                        applied = applied + 1
                        if applied >= 50 then break end
                    end
                end
            end
        end
    end)

    -- Fullbright throttled
    local fbTick = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.fullbright then return end
        fbTick = fbTick + 1
        if fbTick % (IS_MOBILE and 30 or 15) ~= 0 then return end
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
    end)

    -- Novos objetos entram no cache
    workspace.DescendantAdded:Connect(function(d)
        if UNLOADED then return end
        if d:IsA("BasePart") then
            if cachedParts then table.insert(cachedParts, d) end
        elseif d:IsA("ParticleEmitter") or d:IsA("Fire")
            or d:IsA("Smoke") or d:IsA("Sparkles")
            or d:IsA("Trail") or d:IsA("Beam") then
            if cachedParticles then table.insert(cachedParticles, d) end
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

    -- ═══════════════════════════════════════════════
    -- CONFIG SYSTEM
    -- ═══════════════════════════════════════════════
    local BASE_FOLDER   = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/Jailbird"
    local AUTOLOAD_FILE = "InfiniteZen_Jailbird_Autoload.txt"

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
            "silentHeadshot", "aimbot", "triggerbot", "backstab", "headExpander",
            "noRecoil", "noSpread", "rapidFire", "fastReload", "instaReload", "infiniteAmmo",
            "autoShoot", "speed", "airJump", "autoBhop", "fullbright",
            "esp", "espWeapon", "espArmor", "espGrenades", "damageIndicator",
            "lowGraphics", "noShadows", "noFog", "noParticles",
            "antiFlash", "antiVK",
        }
        for _, k in ipairs(toggles) do
            local el = Elements[k]
            if el and State[k] ~= nil then setToggle(el, State[k]) end
        end
        local sliders = {
            "silentFov", "aimbotFov", "triggerbotDelay", "headExpanderSize",
            "autoShootFov", "speedValue", "espMaxDistance",
        }
        for _, k in ipairs(sliders) do
            local el = Elements[k]
            if el and State[k] ~= nil then setSlider(el, State[k]) end
        end
    end

    local function saveConfigNamed(name)
        ensureFolder()
        local data = {version = GAME_VERSION, state = {}, keybinds = State.keybinds or {}}
        for k, v in pairs(State) do
            if k ~= "keybinds" then data.state[k] = v end
        end
        local ok = pcall(function() writefile(getConfigPath(name), HttpService:JSONEncode(data)) end)
        if ok and Window then Window:Notify("💾", "Saved: " .. name, 3, "success") end
        return ok
    end

    local function loadConfigNamed(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then
            if Window then Window:Notify("⚠️", T("config.empty"), 4, "error") end
            return false
        end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data then
            if Window then Window:Notify("⚠️", "Corrupted", 4, "error") end
            return false
        end
        if data.state then for k, v in pairs(data.state) do State[k] = v end end
        if data.keybinds then for k, v in pairs(data.keybinds) do State.keybinds[k] = v end end
        if State.lowGraphics then applyLowGraphics(true) end
        if State.noShadows then applyNoShadows(true) end
        if State.noFog then applyNoFog(true) end
        if State.noParticles then applyNoParticles(true) end
        if State.airJump then startAirJump() else stopAirJump() end
        if not State.fullbright then disableFullbright() end
        if not State.headExpander then restoreAllHitboxes() end
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

        -- COMBAT
        local CombatTab = Window:CreateTab(T("tab.combat"), "⚔️")
        CombatTab:CreateSection(T("section.aim"))
        reg("silentHeadshot", CombatTab:CreateToggle({
            Name = T("silent.name"), Description = T("silent.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.silentHeadshot = v end,
        }))
        reg("silentFov", CombatTab:CreateSlider({
            Name = T("silentfov.name"), Description = T("silentfov.desc"),
            Icon = "📐", Min = 30, Max = 300, Default = 120,
            Callback = function(v) State.silentFov = v end,
        }))
        reg("aimbot", CombatTab:CreateToggle({
            Name = T("aimbot.name"), Description = T("aimbot.desc"),
            Icon = "🤖", Default = false,
            Callback = function(v) State.aimbot = v end,
        }))
        reg("aimbotFov", CombatTab:CreateSlider({
            Name = T("aimbotfov.name"), Description = T("aimbotfov.desc"),
            Icon = "📐", Min = 30, Max = 300, Default = 100,
            Callback = function(v) State.aimbotFov = v end,
        }))
        reg("aimbotWallCheck", CombatTab:CreateToggle({
            Name = T("aimbotwall.name"), Description = T("aimbotwall.desc"),
            Icon = "🧱", Default = true,
            Callback = function(v) State.aimbotWallCheck = v end,
        }))
        reg("triggerbot", CombatTab:CreateToggle({
            Name = T("triggerbot.name"), Description = T("triggerbot.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.triggerbot = v end,
        }))
        reg("triggerbotDelay", CombatTab:CreateSlider({
            Name = T("triggerbotdelay.name"), Description = T("triggerbotdelay.desc"),
            Icon = "⏱️", Min = 1, Max = 100, Default = 5,
            Callback = function(v) State.triggerbotDelay = v end,
        }))
        CombatTab:CreateSection(T("section.melee"))
        reg("backstab", CombatTab:CreateToggle({
            Name = T("backstab.name"), Description = T("backstab.desc"),
            Icon = "🗡️", Default = false,
            Callback = function(v) State.backstab = v end,
        }))
        CombatTab:CreateSection(T("section.hitbox"))
        reg("headExpander", CombatTab:CreateToggle({
            Name = T("headexp.name"), Description = T("headexp.desc"),
            Icon = "🔴", Default = false,
            Callback = function(v)
                State.headExpander = v
                if not v then restoreAllHitboxes() end
            end,
        }))
        reg("headExpanderSize", CombatTab:CreateSlider({
            Name = T("headsize.name"), Description = T("headsize.desc"),
            Icon = "📏", Min = 1, Max = 8, Default = 3,
            Callback = function(v) State.headExpanderSize = v end,
        }))

        -- WEAPON
        local WeaponTab = Window:CreateTab(T("tab.weapon"), "🔫")
        WeaponTab:CreateSection(T("section.recoil"))
        reg("noRecoil", WeaponTab:CreateToggle({
            Name = T("norecoil.name"), Description = T("norecoil.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.noRecoil = v end,
        }))
        reg("noSpread", WeaponTab:CreateToggle({
            Name = T("nospread.name"), Description = T("nospread.desc"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.noSpread = v end,
        }))
        WeaponTab:CreateSection(T("section.firerate"))
        reg("rapidFire", WeaponTab:CreateToggle({
            Name = T("rapidfire.name"), Description = T("rapidfire.desc"),
            Icon = "⚡", Default = false,
            Callback = function(v) State.rapidFire = v end,
        }))
        reg("fastReload", WeaponTab:CreateToggle({
            Name = T("fastreload.name"), Description = T("fastreload.desc"),
            Icon = "🔄", Default = false,
            Callback = function(v) State.fastReload = v end,
        }))
        reg("instaReload", WeaponTab:CreateToggle({
            Name = T("instareload.name"), Description = T("instareload.desc"),
            Icon = "💨", Default = false,
            Callback = function(v) State.instaReload = v end,
        }))
        WeaponTab:CreateSection(T("section.ammo"))
        reg("infiniteAmmo", WeaponTab:CreateToggle({
            Name = T("infiniteammo.name"), Description = T("infiniteammo.desc"),
            Icon = "🔋", Default = false,
            Callback = function(v) State.infiniteAmmo = v end,
        }))
        WeaponTab:CreateSection(T("section.auto"))
        reg("autoShoot", WeaponTab:CreateToggle({
            Name = T("autoshot.name"), Description = T("autoshot.desc"),
            Icon = "🔥", Default = false,
            Callback = function(v) State.autoShoot = v end,
        }))
        reg("autoShootFov", WeaponTab:CreateSlider({
            Name = T("autoshotfov.name"), Description = T("autoshotfov.desc"),
            Icon = "📐", Min = 30, Max = 300, Default = 100,
            Callback = function(v) State.autoShootFov = v end,
        }))

        -- MOVEMENT
        local MoveTab = Window:CreateTab(T("tab.movement"), "🏃")
        MoveTab:CreateSection(T("section.speed"))
        reg("speed", MoveTab:CreateToggle({
            Name = T("speed.name"), Description = T("speed.desc"),
            Icon = "⚡", Default = false,
            Callback = function(v) State.speed = v end,
        }))
        reg("speedValue", MoveTab:CreateSlider({
            Name = T("speedvalue.name"), Description = T("speedvalue.desc"),
            Icon = "📏", Min = 12, Max = 300, Default = 50,
            Callback = function(v) State.speedValue = v end,
        }))
        MoveTab:CreateSection(T("section.jump"))
        reg("airJump", MoveTab:CreateToggle({
            Name = T("airjump.name"), Description = T("airjump.desc"),
            Icon = "🦘", Default = false,
            Callback = function(v)
                State.airJump = v
                if v then startAirJump() else stopAirJump() end
            end,
        }))
        reg("autoBhop", MoveTab:CreateToggle({
            Name = T("autobhop.name"), Description = T("autobhop.desc"),
            Icon = "🏃", Default = false,
            Callback = function(v) State.autoBhop = v end,
        }))
        reg("fullbright", MoveTab:CreateToggle({
            Name = T("fullbright.name"), Description = T("fullbright.desc"),
            Icon = "💡", Default = false,
            Callback = function(v)
                State.fullbright = v
                if not v then disableFullbright() end
            end,
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
                else clearAllESP() end
            end,
        }))
        reg("espMaxDistance", VisualsTab:CreateSlider({
            Name = T("espdist.name"), Description = T("espdist.desc"),
            Icon = "📐", Min = 100, Max = 5000, Default = 500,
            Callback = function(v) State.espMaxDistance = v end,
        }))
        reg("espWeapon", VisualsTab:CreateToggle({
            Name = T("espweapon.name"), Description = T("espweapon.desc"),
            Icon = "🔫", Default = true,
            Callback = function(v) State.espWeapon = v end,
        }))
        reg("espArmor", VisualsTab:CreateToggle({
            Name = T("jb.esp.armor"), Description = T("jb.esp.armor.desc"),
            Icon = "🛡️", Default = true,
            Callback = function(v) State.espArmor = v end,
        }))
        reg("espGrenades", VisualsTab:CreateToggle({
            Name = T("jb.esp.grenades"), Description = T("jb.esp.grenades.desc"),
            Icon = "💣", Default = false,
            Callback = function(v) State.espGrenades = v end,
        }))
        VisualsTab:CreateSection(T("section.utility"))
        reg("damageIndicator", VisualsTab:CreateToggle({
            Name = T("damageindicator.name"), Description = T("damageindicator.desc"),
            Icon = "🩸", Default = false,
            Callback = function(v) State.damageIndicator = v end,
        }))
        VisualsTab:CreateSection(T("section.environment"))
        reg("lowGraphics", VisualsTab:CreateToggle({
            Name = T("lowgfx.name"), Description = T("lowgfx.desc"),
            Icon = "📉", Default = false,
            Callback = function(v) State.lowGraphics = v; applyLowGraphics(v) end,
        }))
        reg("noShadows", VisualsTab:CreateToggle({
            Name = T("noshadow.name"), Description = T("noshadow.desc"),
            Icon = "🌑", Default = false,
            Callback = function(v) State.noShadows = v; applyNoShadows(v) end,
        }))
        reg("noFog", VisualsTab:CreateToggle({
            Name = T("nofog.name"), Description = T("nofog.desc"),
            Icon = "🌫️", Default = false,
            Callback = function(v) State.noFog = v; applyNoFog(v) end,
        }))
        reg("noParticles", VisualsTab:CreateToggle({
            Name = T("nopart.name"), Description = T("nopart.desc"),
            Icon = "✨", Default = false,
            Callback = function(v) State.noParticles = v; applyNoParticles(v) end,
        }))

        -- SETTINGS
        local SettingsTab = Window:CreateTab(T("tab.settings"), "⚙️")
        SettingsTab:CreateSection(T("section.create_config"))

        local configInput = Instance.new("Frame", SettingsTab.container)
        configInput.Size = UDim2.new(1, 0, 0, 40)
        configInput.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        configInput.BorderSizePixel = 0
        configInput.LayoutOrder = #SettingsTab.container:GetChildren()
        Instance.new("UICorner", configInput).CornerRadius = UDim.new(0, 8)

        local cInput = Instance.new("TextBox", configInput)
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

        SettingsTab:CreateSection(T("section.optimizations"))
        SettingsTab:CreateButton({
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
        SettingsTab:CreateButton({
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

        SettingsTab:CreateSection(T("section.security"))
        reg("antiFlash", SettingsTab:CreateToggle({
            Name = T("antiflash.name"), Description = T("antiflash.desc"),
            Icon = "🛡️", Default = false,
            Callback = function(v) State.antiFlash = v end,
        }))
        reg("antiVK", SettingsTab:CreateToggle({
            Name = T("antivotekick.name"), Description = T("antivotekick.desc"),
            Icon = "🛡️", Default = false,
            Callback = function(v) State.antiVK = v end,
        }))

        SettingsTab:CreateSection(T("section.danger"))
        SettingsTab:CreateButton({
            Name = T("config.unload"),
            Danger = true,
            Callback = function()
                UNLOADED = true
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
                pcall(function() RunService:UnbindFromRenderStep("IZ_JB_Silent") end)
                pcall(function() RunService:UnbindFromRenderStep("IZ_JB_Aimbot") end)
                if Window then Window:Notify("Unload", T("config.unload"), 2, "warning") end
                task.wait(0.3)
                if Window then Window:Destroy() end
            end,
        })

        -- LANGUAGE
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

        -- CREDITS
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
    -- KEYBINDS
    -- ═══════════════════════════════════════════════
    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.E and State.backstab then
            doBackstab()
        end
    end)

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

    Window:Notify("✅ " .. SHORT_VERSION, "Jailbird loaded successfully", 4, "success")
    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
end

return Jailbird