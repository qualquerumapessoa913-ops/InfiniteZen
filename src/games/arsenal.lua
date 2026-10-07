-- ============================================================
-- INFINITE ZEN - ARSENAL (v1.8) — Rainbow Gun + Ghost Gun
-- ============================================================

local Arsenal = {}

function Arsenal.Init(ctx)
    local Language = ctx.Language
    local UI       = ctx.UI
    local Compat   = ctx.Compat
    local gameName = ctx.gameName

    local function T(key, fallback)
        local v = Language.get(key)
        if not v or v == key then return fallback or key end
        return v
    end

    local GAME_VERSION = "1.8"
    local FULL_VERSION = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("============================================")
    print("[Infinite Zen] 🇧🇷 Inicializando " .. FULL_VERSION .. "...")
    print("[Infinite Zen] 🇺🇸 Initializing " .. FULL_VERSION .. "...")
    print("============================================")

    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local UserInputService  = game:GetService("UserInputService")
    local VirtualInput      = game:GetService("VirtualInputManager")
    local VirtualUser       = game:GetService("VirtualUser")
    local GuiService        = game:GetService("GuiService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService       = game:GetService("HttpService")
    local Lighting          = game:GetService("Lighting")
    local LocalPlayer       = Players.LocalPlayer
    local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
    local Camera            = workspace.CurrentCamera

    local UNLOADED = false
    local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local GUI_INSET = GuiService:GetGuiInset()
    local function getMouseViewportPos()
        local m = UserInputService:GetMouseLocation()
        return Vector2.new(m.X, m.Y - GUI_INSET.Y)
    end
    local function getMouseScreenPos()
        return UserInputService:GetMouseLocation()
    end

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

    local State = {
        aimbot = false,
        headExpander = false, headExpanderSize = 3,
        backstab = false,
        noRecoil = false, rapidFire = false,
        fastReload = false, instaReload = false,
        rainbowGun = false, rainbowSpeed = 0.05,
        ghostGun = false, ghostTransparency = 0.7,
        speed = false, speedValue = 50,
        airJump = false,
        jumpPower = 70,
        noclip = false,
        antiAfk = false,
        fullbright = false,
        cameraFov = 70,
        esp = false, espMaxDistance = 500,
        lowGraphics = false, noShadows = false, noFog = false, noParticles = false,
        debugHeadExp = false,
        debugWeapon = false,
        keybinds = {
            aimbot = nil, headExpander = nil,
            backstab = "E", noRecoil = nil, rapidFire = nil,
            fastReload = nil, instaReload = nil,
            speed = nil, airJump = nil, esp = nil, noclip = nil,
        },
    }

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

    local function getClosestEnemyInFov(fov, useLOS)
        local mouse = getMouseViewportPos()
        local closest, minDist = nil, fov
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                        if d < minDist then
                            if useLOS and not hasLineOfSight(Camera.CFrame.Position, head) then
                            else
                                minDist = d; closest = p
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    -- FOV CIRCLE
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(255, 30, 40); fovCircle.Thickness = 1.5
    fovCircle.Filled = false; fovCircle.NumSides = 100; fovCircle.Transparency = 1
    fovCircle.Radius = 25; fovCircle.Visible = false

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        local mouse = getMouseScreenPos()
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
        if State.aimbot then
            fovCircle.Visible = true; fovCircle.Radius = 25
        else
            fovCircle.Visible = false
        end
    end)

    -- AIMBOT (natural, sem Scriptable)
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.aimbot then return end
        local target = getClosestEnemyInFov(25, false)
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end)

    -- ═══════════════════════════════════════════════════════════
    -- 🎨 WEAPON VISUAL MODS (Rainbow + Ghost)
    -- ═══════════════════════════════════════════════════════════

    -- Acha a arma ativa (Camera.Arms do Arsenal OU Tool no Character)
    local function getActiveWeapon()
        local cam = workspace.CurrentCamera
        if cam then
            for _, child in ipairs(cam:GetChildren()) do
                if child:IsA("Model") or child:IsA("Tool") then
                    local n = child.Name:lower()
                    -- Ignora efeitos visuais (BulletHoles, etc)
                    if not n:find("bullet") and not n:find("hole")
                        and not n:find("particle") and not n:find("effect")
                        and not n:find("debris") then
                        -- Confirma que tem BasePart dentro
                        for _, d in ipairs(child:GetDescendants()) do
                            if d:IsA("BasePart") then
                                return child
                            end
                        end
                    end
                end
            end
        end

        -- Fallback: Tool no Character
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then return tool end
        end

        return nil
    end

    -- Pega TODAS as BaseParts da arma (MeshPart incluso). Pula braços (CSSArms).
    local function getWeaponParts(weapon)
        local parts = {}
        if not weapon then return parts end
        for _, d in ipairs(weapon:GetDescendants()) do
            if d:IsA("BasePart") then
                -- Verifica se é dos braços (CSSArms) → pula
                local skip = false
                local p = d
                while p and p ~= weapon do
                    if p.Name == "CSSArms" or p.Name == "Arms" then
                        -- Só pula se for uma parte DENTRO de CSSArms (braços)
                        if p.Name == "CSSArms" then skip = true end
                        break
                    end
                    p = p.Parent
                end
                if not skip then
                    table.insert(parts, d)
                end
            end
        end
        return parts
    end

    -- Guarda o "último weapon" pra detectar troca
    local trackedWeapon = nil
    local rainbowOriginals = {}  -- part -> {color, material, reflectance}
    local ghostOriginals = {}    -- part -> {ltm, canCollide}

    -- ─── RAINBOW ───
    local function saveRainbowOriginal(part)
        if rainbowOriginals[part] then return end
        rainbowOriginals[part] = {
            color = part.Color,
            material = part.Material,
            reflectance = part.Reflectance,
        }
    end

    local function restoreRainbowOriginal(part)
        local orig = rainbowOriginals[part]
        if not orig then return end
        pcall(function()
            part.Color = orig.color
            part.Material = orig.material
            part.Reflectance = orig.reflectance
        end)
        rainbowOriginals[part] = nil
    end

    local function restoreAllRainbow()
        for part, _ in pairs(rainbowOriginals) do
            restoreRainbowOriginal(part)
        end
        rainbowOriginals = {}
    end

    local function applyRainbowGun()
        local weapon = getActiveWeapon()
        if not weapon then return end
        local parts = getWeaponParts(weapon)

        local hue = (tick() * 0.5) % 1
        local color = Color3.fromHSV(hue, 1, 1)

        for _, part in ipairs(parts) do
            saveRainbowOriginal(part)
            pcall(function()
                part.Color = color
                part.Material = Enum.Material.Neon
                part.Reflectance = 0.15
            end)
        end
    end

    task.spawn(function()
        while not UNLOADED do
            task.wait(State.rainbowSpeed or 0.05)
            if State.rainbowGun then
                pcall(applyRainbowGun)
            end
        end
    end)

    -- ─── GHOST ───
    local function saveGhostOriginal(part)
        if ghostOriginals[part] then return end
        ghostOriginals[part] = {
            ltm = part.LocalTransparencyModifier,
            canCollide = part.CanCollide,
        }
    end

    local function restoreGhostOriginal(part)
        local orig = ghostOriginals[part]
        if not orig then return end
        pcall(function()
            part.LocalTransparencyModifier = orig.ltm
            part.CanCollide = orig.canCollide
        end)
        ghostOriginals[part] = nil
    end

    local function restoreAllGhost()
        for part, _ in pairs(ghostOriginals) do
            restoreGhostOriginal(part)
        end
        ghostOriginals = {}
    end

    local function applyGhostGun()
        local weapon = getActiveWeapon()
        if not weapon then return end
        local parts = getWeaponParts(weapon)
        for _, part in ipairs(parts) do
            saveGhostOriginal(part)
            pcall(function()
                part.LocalTransparencyModifier = State.ghostTransparency
            end)
        end
    end

    task.spawn(function()
        while not UNLOADED do
            task.wait(0.1)
            if State.ghostGun then
                pcall(applyGhostGun)
            end
        end
    end)

    -- Detecta troca de arma → limpa originals antigos
    task.spawn(function()
        while not UNLOADED do
            task.wait(1)
            local current = getActiveWeapon()
            if current ~= trackedWeapon then
                if not State.rainbowGun then restoreAllRainbow() end
                if not State.ghostGun then restoreAllGhost() end
                trackedWeapon = current

                if State.debugWeapon then
                    print("[WEAPON-DEBUG] Troca → " .. (current and current:GetFullName() or "NIL"))
                end
            end
        end
    end)

    -- Debug: log da arma atual
    task.spawn(function()
        while not UNLOADED do
            task.wait(3)
            if State.debugWeapon then
                local w = getActiveWeapon()
                if w then
                    local p = getWeaponParts(w)
                    print(string.format("[WEAPON-DEBUG] %s | parts=%d", w:GetFullName(), #p))
                else
                    print("[WEAPON-DEBUG] Arma NIL")
                end
            end
        end
    end)

    -- Restore helpers pros callbacks
    local function stopRainbowGun() restoreAllRainbow() end
    local function stopGhostGun()   restoreAllGhost()   end

    -- ═══════════════════════════════════════════════════════════
    -- HEAD EXPANDER v2
    -- ═══════════════════════════════════════════════════════════

    local hitboxSaved = {}
    local expandStats = {applied = 0, failed = 0}

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

    local function restoreAll()
        for player, _ in pairs(hitboxSaved) do restorePlayer(player) end
        hitboxSaved = {}
    end

    local HB_NAMES = {
        "Head", "HeadHB", "Hitbox", "HeadHitbox", "Head_HB", "headHitbox",
        "Torso", "UpperTorso", "TorsoHB", "TorsoHitbox", "UpperTorso_HB",
    }

    local function getHitboxParts(char)
        if not char then return {} end
        local parts = {}
        for _, n in ipairs(HB_NAMES) do
            local p = char:FindFirstChild(n)
            if p and p:IsA("BasePart") then
                table.insert(parts, p)
            end
        end
        return parts
    end

    local function expandPlayer(p, size)
        if not p.Character then return end
        local parts = getHitboxParts(p.Character)
        if #parts == 0 then
            expandStats.failed = expandStats.failed + 1
            return
        end
        for _, part in ipairs(parts) do
            saveOriginal(p, part)
            local base = hitboxSaved[p] and hitboxSaved[p][part]
            if base then
                local nm = part.Name:lower()
                local isHead = nm:find("head") ~= nil
                local isTorso = nm:find("torso") ~= nil
                local multX, multY, multZ
                if isHead then
                    multX = size
                    multY = math.min(size, 8)
                    multZ = size
                elseif isTorso then
                    local t = math.min(size * 0.7, 6)
                    multX, multY, multZ = t, t, t
                else
                    local t = math.min(size, 4)
                    multX, multY, multZ = t, t, t
                end
                local ok = pcall(function()
                    part.Size = Vector3.new(base.X * multX, base.Y * multY, base.Z * multZ)
                    if part.CanCollide then part.CanCollide = false end
                    if not part.Massless then part.Massless = true end
                    part.CanQuery = true
                end)
                if ok then
                    expandStats.applied = expandStats.applied + 1
                else
                    expandStats.failed = expandStats.failed + 1
                end
            end
        end
    end

    local heTick = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.headExpander then return end
        heTick = heTick + 1
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
        if State.debugHeadExp and heTick % 120 == 0 then
            local tracked = 0
            for _ in pairs(hitboxSaved) do tracked = tracked + 1 end
            print(string.format("[HEADEXP-DEBUG] applied=%d | failed=%d | players=%d",
                expandStats.applied, expandStats.failed, tracked))
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
            pcall(function() mouse1click() end)
            task.wait(0.05)
        end
    end

    -- WEAPON MODS
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

    -- SPEED
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.speed then return end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
        end
    end)

    -- JUMP POWER
    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.UseJumpPower and hum.JumpPower ~= State.jumpPower then
            hum.JumpPower = State.jumpPower
        end
    end)

    -- AIR JUMP
    local airJumpConn = nil
    local function startAirJump()
        if airJumpConn then airJumpConn:Disconnect() end
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid")
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

    -- NOCLIP
    local noclipConn = nil
    local function startNoclip()
        if noclipConn then noclipConn:Disconnect() end
        noclipConn = RunService.Stepped:Connect(function()
            if UNLOADED or not State.noclip then return end
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
    local function stopNoclip()
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    pcall(function() part.CanCollide = true end)
                end
            end
        end
    end

    -- ANTI-AFK
    task.spawn(function()
        while true do
            task.wait(60)
            if UNLOADED then return end
            if State.antiAfk then
                pcall(function() VirtualUser:CaptureController() end)
                pcall(function() VirtualUser:ClickButton2(Vector2.new(0, 0)) end)
            end
        end
    end)

    -- ESP
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
        data.box      = newDrawing("Square", {Thickness = 1.5, Color = Color3.fromRGB(255, 30, 40), Filled = false, Transparency = 1})
        data.name     = newDrawing("Text",   {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        data.distance = newDrawing("Text",   {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255, 80, 80)})
        data.health   = newDrawing("Line",   {Thickness = 3, Color = Color3.fromRGB(0, 255, 0)})
        data.tracer   = newDrawing("Line",   {Thickness = 1.2, Color = Color3.fromRGB(255, 30, 40)})
        data.headDot  = newDrawing("Circle", {Radius = 4, NumSides = 20, Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255)})
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
            if maxHP and maxHP > 0 then hr = math.clamp(hum.Health / maxHP, 0, 1) end
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

    -- OPTIMIZATIONS + FULLBRIGHT
    local optBackup = {
        fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart,
        globalShadows = Lighting.GlobalShadows, qualityLevel = nil,
        atmosphereData = {}, particles = {},
        brightness = Lighting.Brightness,
        ambient = Lighting.Ambient,
        outdoorAmbient = Lighting.OutdoorAmbient,
    }
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then
            table.insert(optBackup.atmosphereData, {obj = c, D = c.Density, H = c.Haze, G = c.Glare})
        end
    end
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

    local function applyFullbright(v)
        if v then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
            Lighting.ClockTime = 12
        else
            Lighting.Brightness = optBackup.brightness or 2
            Lighting.Ambient = optBackup.ambient or Color3.fromRGB(0, 0, 0)
            Lighting.OutdoorAmbient = optBackup.outdoorAmbient or Color3.fromRGB(128, 128, 128)
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

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        if Camera.FieldOfView ~= State.cameraFov then
            Camera.FieldOfView = State.cameraFov
        end
    end)

    -- CONFIG SYSTEM
    local BASE_FOLDER   = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/Arsenal"
    local AUTOLOAD_FILE = "InfiniteZen_Arsenal_Autoload.txt"

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
            "aimbot", "headExpander", "backstab",
            "noRecoil", "rapidFire", "fastReload", "instaReload",
            "rainbowGun", "ghostGun",
            "speed", "airJump", "noclip", "antiAfk",
            "esp", "lowGraphics", "noShadows", "noFog", "noParticles",
            "fullbright", "debugHeadExp", "debugWeapon",
        }
        for _, key in ipairs(toggles) do
            local el = Elements[key]
            if el and State[key] ~= nil then setToggle(el, State[key]) end
        end
        local sliders = {
            "headExpanderSize", "rainbowSpeed", "ghostTransparency",
            "speedValue", "espMaxDistance", "jumpPower", "cameraFov",
        }
        for _, key in ipairs(sliders) do
            local el = Elements[key]
            if el and State[key] ~= nil then setSlider(el, State[key]) end
        end
    end

    local function saveConfigNamed(name)
        ensureFolder()
        local data = {version = GAME_VERSION, state = {}, keybinds = State.keybinds}
        for k, v in pairs(State) do
            if k ~= "keybinds" then data.state[k] = v end
        end
        local ok = pcall(function() writefile(getConfigPath(name), HttpService:JSONEncode(data)) end)
        if ok and Window then Window:Notify("💾 Config", "Saved: " .. name, 3, "success") end
        return ok
    end

    local function loadConfigNamed(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then return false end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data then return false end
        if data.state then for k, v in pairs(data.state) do State[k] = v end end
        if data.keybinds then for k, v in pairs(data.keybinds) do State.keybinds[k] = v end end
        if State.lowGraphics then applyLowGraphics(true) end
        if State.noShadows then applyNoShadows(true) end
        if State.noFog then applyNoFog(true) end
        if State.noParticles then applyNoParticles(true) end
        if State.fullbright then applyFullbright(true) end
        if State.noclip then startNoclip() end
        syncUIFromState()
        if Window then Window:Notify("📂 Load", "Loaded: " .. name, 3, "info") end
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

    -- UI
    local function buildUI()
        Window = UI:CreateWindow({
            Title = "INFINITE ZEN",
            Subtitle = SHORT_VERSION,
            ToggleKey = Enum.KeyCode.K,
        })
        Elements = {}

        -- COMBAT
        local CombatTab = Window:CreateTab(T("tab.combat", "Combat"), "⚔️")
        CombatTab:CreateSection(T("section.aim", "Aim"))
        reg("aimbot", CombatTab:CreateToggle({
            Name = T("aimbot.name", "Aimbot"), Description = T("aimbot.desc", "Locks camera on nearest enemy"),
            Icon = "🤖", Default = false,
            Callback = function(v) State.aimbot = v end,
        }))
        CombatTab:CreateSection(T("section.hitbox", "Hitbox"))
        reg("headExpander", CombatTab:CreateToggle({
            Name = T("headexp.name", "Head Expander"), Description = T("headexp.desc", "Expand head hitbox"),
            Icon = "🔴", Default = false,
            Callback = function(v) State.headExpander = v; if not v then restoreAll() end end,
        }))
        reg("headExpanderSize", CombatTab:CreateSlider({
            Name = T("headsize.name", "Head Size"), Description = T("headsize.desc", "Size multiplier"),
            Icon = "📏", Min = 1, Max = 18, Default = 3,
            Callback = function(v) State.headExpanderSize = v end,
        }))
        CombatTab:CreateSection(T("section.melee", "Melee"))
        reg("backstab", CombatTab:CreateToggle({
            Name = T("backstab.name", "Backstab"), Description = T("backstab.desc", "Teleports behind enemy (E)"),
            Icon = "🗡️", Default = false,
            Callback = function(v) State.backstab = v end,
        }))

        -- WEAPON
        local WeaponTab = Window:CreateTab(T("tab.weapon", "Weapon"), "🔫")
        WeaponTab:CreateSection(T("section.recoil", "Recoil"))
        reg("noRecoil", WeaponTab:CreateToggle({
            Name = T("norecoil.name", "No Recoil"), Description = T("norecoil.desc", "Removes all recoil"),
            Icon = "🎯", Default = false,
            Callback = function(v) State.noRecoil = v end,
        }))
        WeaponTab:CreateSection(T("section.firerate", "Fire Rate"))
        reg("rapidFire", WeaponTab:CreateToggle({
            Name = T("rapidfire.name", "Rapid Fire"), Description = T("rapidfire.desc", "Minimize fire delay"),
            Icon = "⚡", Default = false,
            Callback = function(v) State.rapidFire = v end,
        }))
        reg("fastReload", WeaponTab:CreateToggle({
            Name = T("fastreload.name", "Fast Reload"), Description = T("fastreload.desc", "Faster reload"),
            Icon = "🔄", Default = false,
            Callback = function(v)
                State.fastReload = v
                if not v then
                    for value, original in pairs(reloadOriginals) do
                        pcall(function() value.Value = original end)
                    end
                    reloadOriginals = {}
                end
            end,
        }))
        reg("instaReload", WeaponTab:CreateToggle({
            Name = T("instareload.name", "Insta Reload"), Description = T("instareload.desc", "Instant reload"),
            Icon = "💨", Default = false,
            Callback = function(v) State.instaReload = v end,
        }))

        WeaponTab:CreateSection("🎨 Visual Mods")
        reg("rainbowGun", WeaponTab:CreateToggle({
            Name = T("rainbowgun.name", "🌈 Rainbow Gun"), Description = T("rainbowgun.desc", "Cycles weapon colors like a rainbow"),
            Icon = "🌈", Default = false,
            Callback = function(v)
                State.rainbowGun = v
                if not v then stopRainbowGun() end
            end,
        }))
        reg("rainbowSpeed", WeaponTab:CreateSlider({
            Name = T("rainbowspeed.name", "Rainbow Speed"), Description = T("rainbowspeed.desc", "Delay between color changes"),
            Icon = "⚡", Min = 0.01, Max = 0.3, Default = 0.05,
            Callback = function(v) State.rainbowSpeed = v end,
        }))
        reg("ghostGun", WeaponTab:CreateToggle({
            Name = T("ghostgun.name", "👻 Ghost Gun"), Description = T("ghostgun.desc", "Makes weapon semi-transparent"),
            Icon = "👻", Default = false,
            Callback = function(v)
                State.ghostGun = v
                if not v then stopGhostGun() end
            end,
        }))
        reg("ghostTransparency", WeaponTab:CreateSlider({
            Name = T("ghosttrans.name", "Ghost Transparency"), Description = T("ghosttrans.desc", "0 = invisible, 1 = opaque"),
            Icon = "👻", Min = 0, Max = 1, Default = 0.7,
            Callback = function(v) State.ghostTransparency = v end,
        }))

        -- MOVEMENT
        local MoveTab = Window:CreateTab(T("tab.movement", "Movement"), "🏃")
        MoveTab:CreateSection(T("section.speed", "Speed"))
        reg("speed", MoveTab:CreateToggle({
            Name = T("speed.name", "Speed"), Description = T("speed.desc", "Custom speed"),
            Icon = "⚡", Default = false,
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
        }))
        reg("speedValue", MoveTab:CreateSlider({
            Name = T("speedvalue.name", "Speed Value"), Description = T("speedvalue.desc", "WalkSpeed value"),
            Icon = "📏", Min = 16, Max = 300, Default = 50,
            Callback = function(v) State.speedValue = v end,
        }))
        MoveTab:CreateSection(T("section.jump", "Jump"))
        reg("jumpPower", MoveTab:CreateSlider({
            Name = T("jumppower.name", "Jump Power"), Description = T("jumppower.desc", "Jump speed"),
            Icon = "🦘", Min = 50, Max = 500, Default = 70,
            Callback = function(v) State.jumpPower = v end,
        }))
        reg("airJump", MoveTab:CreateToggle({
            Name = T("airjump.name", "Infinite Jump"), Description = T("airjump.desc", "Jump in the air infinitely"),
            Icon = "🦘", Default = false,
            Callback = function(v)
                State.airJump = v
                if v then startAirJump() else stopAirJump() end
            end,
        }))
        reg("noclip", MoveTab:CreateToggle({
            Name = T("noclip.name", "Noclip"), Description = T("noclip.desc", "Go through walls"),
            Icon = "👻", Default = false,
            Callback = function(v)
                State.noclip = v
                if v then startNoclip() else stopNoclip() end
            end,
        }))
        reg("antiAfk", MoveTab:CreateToggle({
            Name = T("antiafk.name", "Anti-AFK"), Description = T("antiafk.desc", "Not kicked for inactivity"),
            Icon = "🛡️", Default = false,
            Callback = function(v) State.antiAfk = v end,
        }))

        -- VISUALS
        local VisualsTab = Window:CreateTab(T("tab.visuals", "Visuals"), "👁️")
        VisualsTab:CreateSection(T("section.esp", "ESP"))
        reg("esp", VisualsTab:CreateToggle({
            Name = T("esp.name", "Player ESP"), Description = T("esp.desc", "Highlight enemies through walls"),
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
            Name = T("espdist.name", "Max Distance"), Description = T("espdist.desc", "ESP range"),
            Icon = "📐", Min = 100, Max = 10000, Default = 500,
            Callback = function(v) State.espMaxDistance = v end,
        }))
        VisualsTab:CreateSection(T("section.camera", "Camera"))
        reg("cameraFov", VisualsTab:CreateSlider({
            Name = T("camerafov.name", "Camera FOV"), Description = T("camerafov.desc", "Field of view"),
            Icon = "🎥", Min = 30, Max = 120, Default = 70,
            Callback = function(v) State.cameraFov = v end,
        }))
        VisualsTab:CreateSection(T("section.environment", "Environment"))
        reg("lowGraphics", VisualsTab:CreateToggle({
            Name = T("lowgfx.name", "Low Graphics"), Description = T("lowgfx.desc", "Reduce quality for FPS"),
            Icon = "📉", Default = false,
            Callback = function(v) State.lowGraphics = v; applyLowGraphics(v) end,
        }))
        reg("noShadows", VisualsTab:CreateToggle({
            Name = T("noshadow.name", "No Shadows"), Description = T("noshadow.desc", "Remove all shadows"),
            Icon = "🌑", Default = false,
            Callback = function(v) State.noShadows = v; applyNoShadows(v) end,
        }))
        reg("noFog", VisualsTab:CreateToggle({
            Name = T("nofog.name", "No Fog"), Description = T("nofog.desc", "Remove fog"),
            Icon = "🌫️", Default = false,
            Callback = function(v) State.noFog = v; applyNoFog(v) end,
        }))
        reg("noParticles", VisualsTab:CreateToggle({
            Name = T("nopart.name", "No Particles"), Description = T("nopart.desc", "Remove particle effects"),
            Icon = "✨", Default = false,
            Callback = function(v) State.noParticles = v; applyNoParticles(v) end,
        }))
        reg("fullbright", VisualsTab:CreateToggle({
            Name = T("fullbright.name", "Fullbright"), Description = T("fullbright.desc", "Map always bright"),
            Icon = "☀️", Default = false,
            Callback = function(v) State.fullbright = v; applyFullbright(v) end,
        }))

        -- SETTINGS
        local SettingsTab = Window:CreateTab(T("tab.settings", "Settings"), "⚙️")
        SettingsTab:CreateSection(T("section.create_config", "Create Config"))

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
        cInput.PlaceholderText = T("config.placeholder", "Config name + Enter to save...")
        cInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
        cInput.Text = ""
        cInput.ClearTextOnFocus = false
        cInput.TextXAlignment = Enum.TextXAlignment.Left

        SettingsTab:CreateSection(T("section.saved_configs", "Saved Configs"))

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
                empty.Text = T("config.empty", "No saved configs yet.")
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
            Name = T("config.refresh", "🔄 Refresh List"),
            Callback = function()
                refreshConfigList()
                Window:Notify("🔄", T("config.refresh", "Refresh List"), 2, "info")
            end,
        })

        SettingsTab:CreateButton({
            Name = T("config.disable_autoload", "🚫 Disable Autoload"),
            Callback = function()
                clearAutoload(); refreshConfigList()
            end,
        })

        refreshConfigList()

        SettingsTab:CreateSection(T("section.optimizations", "Optimizations"))
        SettingsTab:CreateButton({
            Name = T("config.fps_boost", "⚡ Max FPS Boost"),
            Callback = function()
                State.lowGraphics = true; applyLowGraphics(true)
                State.noShadows = true; applyNoShadows(true)
                State.noFog = true; applyNoFog(true)
                State.noParticles = true; applyNoParticles(true)
                State.fullbright = true; applyFullbright(true)
                syncUIFromState()
                Window:Notify("⚡", T("config.fps_boost", "Max FPS Boost"), 3, "success")
            end,
        })

        SettingsTab:CreateButton({
            Name = T("config.reset_opt", "🔄 Reset Optimizations"),
            Callback = function()
                State.lowGraphics = false; applyLowGraphics(false)
                State.noShadows = false; applyNoShadows(false)
                State.noFog = false; applyNoFog(false)
                State.noParticles = false; applyNoParticles(false)
                State.fullbright = false; applyFullbright(false)
                syncUIFromState()
                Window:Notify("🔄", T("config.reset_opt", "Reset Optimizations"), 3, "info")
            end,
        })

        SettingsTab:CreateSection("🐛 Debug")

        reg("debugHeadExp", SettingsTab:CreateToggle({
            Name = "Debug Head Expander",
            Description = "Logs applied/failed + real size",
            Icon = "🔴", Default = false,
            Callback = function(v) State.debugHeadExp = v end,
        }))

        reg("debugWeapon", SettingsTab:CreateToggle({
            Name = "Debug Weapon",
            Description = "Logs current weapon + parts count",
            Icon = "🔫", Default = false,
            Callback = function(v) State.debugWeapon = v end,
        }))

        SettingsTab:CreateSection(T("section.danger", "Danger Zone"))
        SettingsTab:CreateButton({
            Name = T("config.unload", "Unload Script"),
            Danger = true,
            Callback = function()
                UNLOADED = true
                stopRainbowGun()
                stopGhostGun()
                restoreAll(); clearAllESP(); stopAirJump(); stopNoclip()
                if fovCircle then fovCircle:Remove() end
                applyLowGraphics(false); applyNoShadows(false); applyNoFog(false)
                applyNoParticles(false); applyFullbright(false)
                Camera.FieldOfView = 70
                Window:Notify("Unload", T("config.unload", "Unload Script"), 2, "warning")
                task.wait(0.3); Window:Destroy()
            end,
        })

        local LanguageTab = Window:CreateTab(T("tab.language", "Language"), "🌍")
        LanguageTab:CreateSection(T("section.language_select", "Language"))

        local available = Language.getAvailable()
        local currentCode = Language.getCurrent()
        local currentInfo = nil
        for _, info in ipairs(available) do
            if info.code == currentCode then currentInfo = info; break end
        end

        LanguageTab:CreateLabel(
            T("lang.current", "🌐 Current: ") .. (currentInfo and (currentInfo.flag .. " " .. currentInfo.displayName) or currentCode),
            Color3.fromRGB(230, 40, 40)
        )
        LanguageTab:CreateLabel(T("lang.hint", "Pick menu language"), Color3.fromRGB(140, 140, 155))

        local opts = {}
        local defaultIdx = 1
        for i, info in ipairs(available) do
            table.insert(opts, info.flag .. " " .. info.displayName)
            if info.code == currentCode then defaultIdx = i end
        end

        LanguageTab:CreateDropdown({
            Name = T("tab.language", "Language"),
            Description = T("lang.hint", "Pick menu language"),
            Icon = "🌍",
            Options = opts,
            Default = defaultIdx,
            Callback = function(_, idx)
                local info = available[idx]
                if not info then return end
                Language.setLanguage(info.code)
            end,
        })

        LanguageTab:CreateSection(T("section.language_info", "Info"))
        LanguageTab:CreateLabel(T("lang.saved_to", "Language saved to: ") .. " InfiniteZen_Language.txt", Color3.fromRGB(140, 140, 155))
        LanguageTab:CreateLabel(T("lang.auto_restore", "Auto-restored on open."), Color3.fromRGB(90, 90, 105))

        local CreditsTab = Window:CreateTab(T("tab.credits", "Credits"), "➕")
        CreditsTab:CreateSection(T("section.founder", "Founder"))
        CreditsTab:CreateLabel(T("credits.role", "Sr Red"), Color3.fromRGB(255, 50, 50))
        CreditsTab:CreateSection(T("section.community", "Community"))
        CreditsTab:CreateLabel("discord.gg/ScZfU2mAGm", Color3.fromRGB(88, 101, 242))
        CreditsTab:CreateButton({
            Name = T("credits.copy_discord", "📋 Copy Discord Link"),
            Callback = function()
                if setclipboard then
                    setclipboard("https://discord.gg/ScZfU2mAGm")
                    Window:Notify("📋", "Copied!", 2, "success")
                end
            end,
        })
        CreditsTab:CreateSection(T("section.version", "Version"))
        CreditsTab:CreateLabel(FULL_VERSION, Color3.fromRGB(140, 140, 155))
        CreditsTab:CreateLabel("© 2026 Sr Red", Color3.fromRGB(90, 90, 105))
    end

    -- KEYBINDS
    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local keyName = input.KeyCode.Name
        for featId, key in pairs(State.keybinds) do
            if key and key == keyName then
                if featId == "backstab" and State.backstab then doBackstab() end
            end
        end
    end)

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
        local autoloadName = getAutoload()
        if autoloadName then
            task.wait(1)
            loadConfigNamed(autoloadName)
        end
    end)

    Window:Notify("✅ " .. SHORT_VERSION, "Arsenal loaded successfully", 4, "success")

    print("============================================")
    print("[Infinite Zen] 🇧🇷 " .. FULL_VERSION .. " carregado com sucesso!")
    print("[Infinite Zen] 🇺🇸 " .. FULL_VERSION .. " loaded successfully!")
    print("============================================")
end

return Arsenal