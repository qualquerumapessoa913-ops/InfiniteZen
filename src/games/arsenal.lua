-- ============================================================
-- INFINITE ZEN - ARSENAL v1.2 (UI Nova)
-- ============================================================

local Arsenal = {}

function Arsenal.Init(ctx)
    local Language = ctx.Language
    local UI = ctx.UI
    local Compat = ctx.Compat
    local gameName = ctx.gameName

    local GAME_VERSION = "1.2"
    local FULL_VERSION = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("[Infinite Zen] Inicializando " .. FULL_VERSION .. "...")

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInput = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    local UNLOADED = false
    local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    -- ═══════════════════════════════════════════════
    -- TEAM CHECK
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
        silentHeadshot = false,
        silentFov = 120,
        aimbot = false,
        headExpander = false,
        headExpanderSize = 3,
        backstab = false,
        noRecoil = false,
        rapidFire = false,
        fastReload = false,
        instaReload = false,
        autoShoot = false,
        autoShootFov = 100,
        speed = false,
        speedValue = 50,
        airJump = false,
        esp = false,
        espMaxDistance = 500,
        lowGraphics = false,
        noShadows = false,
        noFog = false,
        noParticles = false,
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
        },
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

    -- ═══════════════════════════════════════════════
    -- WINDOW
    -- ═══════════════════════════════════════════════
    local Window = UI:CreateWindow({
        Title = "INFINITE ZEN",
        Subtitle = SHORT_VERSION,
        ToggleKey = Enum.KeyCode.K,
    })

    -- ═══════════════════════════════════════════════
    -- FOV CIRCLE
    -- ═══════════════════════════════════════════════
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(255, 30, 40); fovCircle.Thickness = 1.5
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
        elseif State.aimbot then
            fovCircle.Visible = true; fovCircle.Radius = 25
        else
            fovCircle.Visible = false
        end
    end)

    -- ═══════════════════════════════════════════════
    -- AIMBOT (loop)
    -- ═══════════════════════════════════════════════
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.aimbot then return end
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, 25
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d and d < minDist then minDist = d; closest = p end
                    end
                end
            end
        end
        if closest and closest.Character then
            local head = closest.Character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- SILENT HEADSHOT
    -- ═══════════════════════════════════════════════
    local silentHolding, silentTarget, silentOriginalCam = false, nil, nil

    local function getClosestHeadInFov()
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, State.silentFov
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d and d < minDist then minDist = d; closest = p end
                    end
                end
            end
        end
        return closest
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then silentHolding = false; return end
        local head = silentTarget.Character:FindFirstChild("Head")
        if not head or not head:IsA("BasePart") then silentHolding = false; return end
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.silentHeadshot then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        silentOriginalCam = Camera.CFrame
        local target = getClosestHeadInFov()
        if not target or not target.Character then return end
        silentTarget = target
        silentHolding = true
        local head = target.Character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if silentHolding then
            silentHolding = false; silentTarget = nil
            if silentOriginalCam then
                Camera.CFrame = silentOriginalCam
                silentOriginalCam = nil
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- AUTO SHOOT
    -- ═══════════════════════════════════════════════
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoShoot then return end
        local mouse = UserInputService:GetMouseLocation()
        local targetInFov = false
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d and d < State.autoShootFov and hasLineOfSight(Camera.CFrame.Position, head) then
                            targetInFov = true; break
                        end
                    end
                end
            end
        end
        if targetInFov then
            pcall(function()
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.01)
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            pcall(function() mouse1click() end)
        end
    end)

    -- ═══════════════════════════════════════════════
    -- HEAD EXPANDER
    -- ═══════════════════════════════════════════════
    local hitboxSaved = {}

    local function saveOriginal(player, part)
        if not player or not part then return end
        if not part:IsA("BasePart") then return end
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

    local function restoreAll()
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
                    head.Transparency = 0.7
                    head.CanCollide = false
                    head.Massless = true
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
                    headHB.Transparency = 1
                    headHB.CanCollide = false
                    headHB.Massless = true
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
        if not target or not target.Character then return end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local mHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP or not mHRP then return end
        if not tHRP:IsA("BasePart") or not mHRP:IsA("BasePart") then return end
        mHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2)
        backstabLock.active = true; backstabLock.target = target; backstabLock.endTime = tick() + 0.5
        Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
        task.wait(0.08)
        Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
        task.wait(0.02)
        for _ = 1, 3 do
            pcall(function()
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.02)
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            pcall(function() mouse1click() end)
            task.wait(0.05)
        end
    end

    -- ═══════════════════════════════════════════════
    -- WEAPON MODS
    -- ═══════════════════════════════════════════════
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
                            for _, name in ipairs({"FireRate", "BFireRate", "RateOfFire"}) do
                                local f = tool:FindFirstChild(name)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then f.Value = 0.03
                                elseif typeof(tool[name]) == "number" then tool[name] = 0.03 end
                            end
                            for _, name in ipairs({"Cooldown", "EquipTime", "EquipCooldown", "SwapCooldown", "NextFire"}) do
                                local f = tool:FindFirstChild(name)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then f.Value = 0
                                elseif typeof(tool[name]) == "number" then tool[name] = 0 end
                            end
                        end)
                    end
                    if State.noRecoil then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("recoil") or n:find("kick") or n:find("spread") then d.Value = 0 end
                                end
                            end
                        end)
                    end
                    if State.fastReload and not State.instaReload then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    if d.Name:lower():find("reload") then
                                        if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                        d.Value = reloadOriginals[d] * 0.3
                                    end
                                end
                            end
                        end)
                    end
                    if State.instaReload then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    if d.Name:lower():find("reload") then d.Value = 0 end
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)

    coroutine.wrap(function()
        while true do
            if UNLOADED then return end
            if State.rapidFire or State.noRecoil or State.fastReload or State.instaReload then
                pcall(function()
                    if ReplicatedStorage:FindFirstChild("Weapons") then
                        for _, d in ipairs(ReplicatedStorage.Weapons:GetDescendants()) do
                            if d:IsA("NumberValue") or d:IsA("IntValue") then
                                local n = d.Name:lower()
                                if State.rapidFire and (n == "firerate" or n == "bfirerate" or n == "rateoffire") then d.Value = 0.03
                                elseif State.rapidFire and (n:find("cooldown") or n:find("equip") or n:find("swap")) then d.Value = 0
                                elseif State.noRecoil and (n == "recoilcontrol" or n:find("recoil")) then d.Value = 0
                                elseif State.fastReload and not State.instaReload and n:find("reload") then
                                    if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                    d.Value = reloadOriginals[d] * 0.3
                                elseif State.instaReload and n:find("reload") then d.Value = 0 end
                            end
                        end
                    end
                end)
            end
            task.wait(1)
        end
    end)()

    -- ═══════════════════════════════════════════════
    -- SPEED
    -- ═══════════════════════════════════════════════
    RunService.RenderStepped:Connect(function()
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

    local function startAirJump()
        if airJumpConn then airJumpConn:Disconnect() end
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid")
        hum.JumpPower = 70
        airJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED or not State.airJump then return end
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end

    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    -- ═══════════════════════════════════════════════
    -- ESP
    -- ═══════════════════════════════════════════════
    local ESP = {data = {}}

    local function createESP(p)
        if ESP.data[p] or not p.Character then return end
        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Color3.fromRGB(255, 30, 40); chams.FillTransparency = 0.6
        chams.OutlineColor = Color3.fromRGB(255, 255, 255); chams.OutlineTransparency = 0.3
        chams.Parent = p.Character

        local data = {chams = chams}
        local function newDrawing(class, props)
            local d = Drawing.new(class)
            for k, v in pairs(props) do d[k] = v end
            d.Visible = false
            return d
        end
        data.box = newDrawing("Square", {Thickness = 1.5, Color = Color3.fromRGB(255, 30, 40), Filled = false, Transparency = 1})
        data.name = newDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        data.distance = newDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255, 80, 80)})
        data.health = newDrawing("Line", {Thickness = 3, Color = Color3.fromRGB(0, 255, 0)})
        data.tracer = newDrawing("Line", {Thickness = 1.2, Color = Color3.fromRGB(255, 30, 40)})
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
        if not head:IsA("BasePart") or not hrp:IsA("BasePart") then return end
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
            d.name.Text = p.Name; d.name.Visible = true
            d.distance.Position = Vector2.new(headSp.X, headSp.Y - 6)
            d.distance.Text = dist .. "m"; d.distance.Visible = true
        else
            d.name.Visible = false; d.distance.Visible = false
        end
        if headOn and footOn then
            local h = math.abs(footSp.Y - headSp.Y)
            local maxHP = hum.MaxHealth
            local hr = 1
            if maxHP and maxHP > 0 then
                hr = math.clamp(hum.Health / maxHP, 0, 1)
            end
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
        if headOn then
            d.headDot.Position = Vector2.new(headSp.X, headSp.Y)
            d.headDot.Visible = true
        else d.headDot.Visible = false end
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

    -- ═══════════════════════════════════════════════
    -- OPTIMIZATIONS
    -- ═══════════════════════════════════════════════
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
        local data = {version = GAME_VERSION, state = {}, keybinds = State.keybinds}
        for k, v in pairs(State) do
            if k ~= "keybinds" then data.state[k] = v end
        end
        local json = HttpService:JSONEncode(data)
        local ok = pcall(function() writefile(getConfigPath(name), json) end)
        if ok then Window:Notify("💾 Config", "Saved: " .. name, 3, "success"); return true
        else Window:Notify("⚠️ Error", "Failed to save", 4, "error"); return false end
    end

    local function loadConfigNamed(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then Window:Notify("⚠️ Error", "Config not found", 4, "error"); return false end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data then Window:Notify("⚠️ Error", "Corrupted", 4, "error"); return false end
        if data.state then
            for k, v in pairs(data.state) do State[k] = v end
        end
        if data.keybinds then
            for k, v in pairs(data.keybinds) do State.keybinds[k] = v end
        end
        if State.lowGraphics then applyLowGraphics(true) end
        if State.noShadows then applyNoShadows(true) end
        if State.noFog then applyNoFog(true) end
        if State.noParticles then applyNoParticles(true) end
        Window:Notify("📂 Load", "Loaded: " .. name, 3, "info")
        return true
    end

    local function deleteConfigNamed(name)
        local path = getConfigPath(name)
        if isfile and isfile(path) then
            pcall(function() delfile(path) end)
            Window:Notify("🗑️ Delete", "Deleted: " .. name, 3, "info")
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
        if ok then Window:Notify("⚡ Autoload", "Set: " .. name, 3, "success") end
    end

    local function clearAutoload()
        pcall(function()
            if isfile(getAutoloadPath()) then delfile(getAutoloadPath()) end
        end)
        Window:Notify("🚫 Autoload", "Disabled", 3, "info")
    end

    local function getAutoload()
        local ok, content = pcall(function() return readfile(getAutoloadPath()) end)
        if ok and content and content ~= "" then return content end
        return nil
    end

    -- ═══════════════════════════════════════════════
    -- ABA: COMBAT
    -- ═══════════════════════════════════════════════
    local CombatTab = Window:CreateTab("Combat", "⚔️")
    CombatTab:CreateSection("Aim")

    CombatTab:CreateToggle({
        Name = "Silent Headshot",
        Description = "Auto-lock aim on enemy head when holding click",
        Icon = "🎯",
        Default = false,
        Callback = function(v) State.silentHeadshot = v end,
    })

    CombatTab:CreateSlider({
        Name = "Silent FOV",
        Description = "Field of view radius for silent aim",
        Icon = "📐",
        Min = 30, Max = 300, Default = 120,
        Callback = function(v) State.silentFov = v end,
    })

    CombatTab:CreateToggle({
        Name = "Aimbot",
        Description = "Continuous camera lock on closest enemy",
        Icon = "🤖",
        Default = false,
        Callback = function(v) State.aimbot = v end,
    })

    CombatTab:CreateSection("Hitbox")

    CombatTab:CreateToggle({
        Name = "Head Expander",
        Description = "Enlarge enemy head hitbox (easier to hit)",
        Icon = "🔴",
        Default = false,
        Callback = function(v)
            State.headExpander = v
            if not v then restoreAll() end
        end,
    })

    CombatTab:CreateSlider({
        Name = "Head Size",
        Description = "Multiplier for head size",
        Icon = "📏",
        Min = 1, Max = 8, Default = 3,
        Callback = function(v) State.headExpanderSize = v end,
    })

    CombatTab:CreateSection("Melee")

    CombatTab:CreateToggle({
        Name = "Backstab",
        Description = "Teleport behind closest enemy and attack (keybind: E)",
        Icon = "🗡️",
        Default = false,
        Callback = function(v) State.backstab = v end,
    })

    -- ═══════════════════════════════════════════════
    -- ABA: WEAPON
    -- ═══════════════════════════════════════════════
    local WeaponTab = Window:CreateTab("Weapon", "🔫")
    WeaponTab:CreateSection("Recoil")

    WeaponTab:CreateToggle({
        Name = "No Recoil",
        Description = "Remove all weapon recoil",
        Icon = "🎯",
        Default = false,
        Callback = function(v) State.noRecoil = v end,
    })

    WeaponTab:CreateSection("Fire Rate")

    WeaponTab:CreateToggle({
        Name = "Rapid Fire",
        Description = "Reduce fire delay to minimum",
        Icon = "⚡",
        Default = false,
        Callback = function(v) State.rapidFire = v end,
    })

    WeaponTab:CreateToggle({
        Name = "Fast Reload",
        Description = "Faster reload animation",
        Icon = "🔄",
        Default = false,
        Callback = function(v)
            State.fastReload = v
            if not v then
                for value, original in pairs(reloadOriginals) do
                    pcall(function() value.Value = original end)
                end
                reloadOriginals = {}
            end
        end,
    })

    WeaponTab:CreateToggle({
        Name = "Insta Reload",
        Description = "Instant reload",
        Icon = "💨",
        Default = false,
        Callback = function(v) State.instaReload = v end,
    })

    WeaponTab:CreateSection("Auto")

    WeaponTab:CreateToggle({
        Name = "Auto Shoot",
        Description = "Auto-fire when enemy enters FOV",
        Icon = "🔥",
        Default = false,
        Callback = function(v) State.autoShoot = v end,
    })

    WeaponTab:CreateSlider({
        Name = "Auto Shoot FOV",
        Description = "Radius for auto-fire",
        Icon = "📐",
        Min = 30, Max = 300, Default = 100,
        Callback = function(v) State.autoShootFov = v end,
    })

    -- ═══════════════════════════════════════════════
    -- ABA: MOVEMENT
    -- ═══════════════════════════════════════════════
    local MoveTab = Window:CreateTab("Movement", "🏃")
    MoveTab:CreateSection("Speed")

    MoveTab:CreateToggle({
        Name = "Speed",
        Description = "Custom walkspeed",
        Icon = "⚡",
        Default = false,
        Callback = function(v)
            State.speed = v
            if not v then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = 16 end
                end
            end
        end,
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

    -- ═══════════════════════════════════════════════
    -- ABA: VISUALS
    -- ═══════════════════════════════════════════════
    local VisualsTab = Window:CreateTab("Visuals", "👁️")
    VisualsTab:CreateSection("ESP")

    VisualsTab:CreateToggle({
        Name = "Player ESP",
        Description = "Highlight enemies through walls",
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
        Name = "Max Distance",
        Description = "ESP render range",
        Icon = "📐",
        Min = 100, Max = 10000, Default = 500,
        Callback = function(v) State.espMaxDistance = v end,
    })

    VisualsTab:CreateSection("Environment")

    VisualsTab:CreateToggle({
        Name = "Low Graphics",
        Description = "Reduce rendering quality for FPS",
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
        Description = "Remove fog and atmosphere",
        Icon = "🌫️",
        Default = false,
        Callback = function(v) State.noFog = v; applyNoFog(v) end,
    })

    VisualsTab:CreateToggle({
        Name = "No Particles",
        Description = "Remove all particle effects",
        Icon = "✨",
        Default = false,
        Callback = function(v) State.noParticles = v; applyNoParticles(v) end,
    })

    -- ═══════════════════════════════════════════════
    -- ABA: SETTINGS
    -- ═══════════════════════════════════════════════
    local SettingsTab = Window:CreateTab("Settings", "⚙️")
    SettingsTab:CreateSection("Create Config")

    -- Input pra salvar config
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
    cInput.PlaceholderText = "Config name + Enter to save..."
    cInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
    cInput.Text = ""
    cInput.ClearTextOnFocus = false
    cInput.TextXAlignment = Enum.TextXAlignment.Left

    SettingsTab:CreateSection("Saved Configs")

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
            if child:IsA("TextButton") or child:IsA("Frame") then
                child:Destroy()
            end
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
            empty.Text = "Nenhum config salvo ainda."
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
                loadConfigNamed(name)
                refreshConfigList()
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
                if currentAutoload == name then
                    clearAutoload()
                else
                    setAutoload(name)
                end
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
                deleteConfigNamed(name)
                refreshConfigList()
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
        Name = "🔄 Refresh List",
        Callback = function()
            refreshConfigList()
            Window:Notify("🔄 Refresh", "Config list updated", 2, "info")
        end,
    })

    SettingsTab:CreateButton({
        Name = "🚫 Disable Autoload",
        Callback = function()
            clearAutoload()
            refreshConfigList()
        end,
    })

    refreshConfigList()

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
            restoreAll()
            clearAllESP()
            stopAirJump()
            if fovCircle then fovCircle:Remove() end
            applyLowGraphics(false)
            applyNoShadows(false)
            applyNoFog(false)
            applyNoParticles(false)
            Window:Notify("Unload", "Script unloaded", 2, "warning")
            task.wait(0.3)
            Window:Destroy()
        end,
    })

    -- ═══════════════════════════════════════════════
    -- ABA: CREDITS  ⬅️ AQUI ESTAVA O BUG
    -- ═══════════════════════════════════════════════
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

    -- ═══════════════════════════════════════════════
    -- KEYBIND SYSTEM
    -- ═══════════════════════════════════════════════
    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local keyName = input.KeyCode.Name
        for featId, key in pairs(State.keybinds) do
            if key and key == keyName then
                if featId == "backstab" then
                    if State.backstab then doBackstab() end
                end
            end
        end
    end)

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

    Window:Notify("✅ " .. SHORT_VERSION, "Arsenal loaded successfully", 4, "success")
    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
end

return Arsenal