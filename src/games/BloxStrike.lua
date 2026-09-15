-- ============================================================
-- INFINITE ZEN - MÓDULO BLOX STRIKE v1.0 (UI Nova)
-- Blox Strike (PlaceId 114234929420007)
-- ============================================================

local BloxStrike = {}

function BloxStrike.Init(ctx)
    local Language = ctx.Language
    local UI = ctx.UI
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
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    local UNLOADED = false

    -- ═══════════════════════════════════════════════
    -- REMOTES (baseado no dump)
    -- ═══════════════════════════════════════════════
    local NetworkRemotes = ReplicatedStorage:FindFirstChild("NetworkRemotes")
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

    local Remotes = {
        ShootWeapon = safeFind(NetworkRemotes, "Inventory", "ShootWeapon"),
        ReloadWeapon = safeFind(NetworkRemotes, "Inventory", "ReloadWeapon"),
        PickupWeapon = safeFind(NetworkRemotes, "Inventory", "PickupWeapon"),
        DropWeapon = safeFind(NetworkRemotes, "Inventory", "DropWeapon"),
        MeleeAttack = safeFind(NetworkRemotes, "Melee", "MeleeAttack"),
        FlashPlayer = safeFind(NetworkRemotes, "VFX", "FlashPlayer"),
        CharacterDamaged = safeFind(NetworkRemotes, "Character", "CharacterDamaged"),
        VoteKick_StartVote = safeFind(NetworkRemotes, "VoteKick", "StartVote"),
        VoteKick_CallVote = safeFind(NetworkRemotes, "VoteKick", "CallVote"),
    }

    -- ═══════════════════════════════════════════════
    -- TEAM DETECTION (via Attribute)
    -- ═══════════════════════════════════════════════
    local function getPlayerTeam(player)
        if not player then return nil end
        local ok, team = pcall(function() return player:GetAttribute("Team") end)
        if ok and team then return team end
        return nil
    end

    local function isDead(player)
        if not player then return true end
        local ok, dead = pcall(function() return player:GetAttribute("Dead") end)
        if ok and dead == true then return true end
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then return true end
        end
        return false
    end

    local function isTeammate(player)
        if not player or player == LocalPlayer then return true end
        local myTeam = getPlayerTeam(LocalPlayer)
        local theirTeam = getPlayerTeam(player)
        if not myTeam or not theirTeam then return false end
        return myTeam == theirTeam
    end

    local function isEnemy(player)
        if not player or player == LocalPlayer then return false end
        if not player.Character then return false end
        if isDead(player) then return false end
        return not isTeammate(player)
    end

    -- ═══════════════════════════════════════════════
    -- STATE
    -- ═══════════════════════════════════════════════
    local State = {
        silentAim = false, silentFov = 120,
        aimbot = false, aimbotFov = 100, aimbotSmoothness = 0.3,
        aimbotMaxDist = 500, aimbotHitbox = 1, aimbotWallCheck = true,
        triggerbot = false, triggerbotDelay = 5,
        autoShoot = false, autoShootFov = 100,
        headExpander = false, headExpanderSize = 2,
        speed = false, speedValue = 50,
        fly = false, flySpeed = 60,
        airJump = false, jumpPower = 50,
        autoBhop = false, noclip = false,
        esp = false, espMaxDistance = 500,
        espWeapon = true, espArmor = true,
        damageIndicator = false,
        fullbright = false,
        antiFlash = false, antiVK = false,
        lowGraphics = false, noShadows = false, noFog = false, noParticles = false,
    }

    -- ═══════════════════════════════════════════════
    -- WINDOW
    -- ═══════════════════════════════════════════════
    local Window = UI:CreateWindow({
        Title = "INFINITE ZEN",
        Subtitle = SHORT_VERSION,
        ToggleKey = Enum.KeyCode.K,
    })

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

    local function getTargetPart(p)
        if not p.Character then return nil end
        local mode = State.aimbotHitbox
        if mode == 1 then
            return getBasePart(p.Character, "HeadHB", "Head")
        elseif mode == 2 then
            return getBasePart(p.Character, "Hitbox", "UpperTorso")
        elseif mode == 3 then
            for _, n in ipairs({"Hitbox", "HeadHB", "Head", "UpperTorso", "HumanoidRootPart"}) do
                local bp = getBasePart(p.Character, n)
                if bp then return bp end
            end
        else
            local h = getBasePart(p.Character, "HeadHB", "Head")
            local t = getBasePart(p.Character, "Hitbox", "UpperTorso")
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
        local equipped = LocalPlayer:GetAttribute("CurrentEquipped")
        if not equipped then return false end
        if mouse1click then
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

    -- ═══════════════════════════════════════════════
    -- TARGETING
    -- ═══════════════════════════════════════════════
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

    -- ═══════════════════════════════════════════════
    -- ABA: COMBAT
    -- ═══════════════════════════════════════════════
    local CombatTab = Window:CreateTab("Combat", "⚔️")
    CombatTab:CreateSection("Aim")

    CombatTab:CreateToggle({
        Name = "Silent Aim",
        Description = "Lock aim on target when holding click",
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
        Callback = function(v) State.aimbotSmoothness = v / 100 end,
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
        Options = {"Head (HeadHB)", "Torso (Hitbox)", "Nearest", "Auto"},
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
        Description = "Reaction delay",
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
        Min = 1, Max = 5, Default = 2,
        Callback = function(v) State.headExpanderSize = v end,
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
        Callback = function(v) State.speed = v end,
    })

    MoveTab:CreateSlider({
        Name = "Speed Value",
        Description = "WalkSpeed value",
        Icon = "📏",
        Min = 16, Max = 300, Default = 50,
        Callback = function(v) State.speedValue = v end,
    })

    MoveTab:CreateSection("Fly")

    MoveTab:CreateToggle({
        Name = "Fly",
        Description = "Free-fly (WASD + Space/Ctrl)",
        Icon = "🕊️",
        Default = false,
        Callback = function(v) State.fly = v end,
    })

    MoveTab:CreateSlider({
        Name = "Fly Speed",
        Description = "Flight velocity",
        Icon = "📏",
        Min = 10, Max = 500, Default = 60,
        Callback = function(v) State.flySpeed = v end,
    })

    MoveTab:CreateSection("Jump")

    MoveTab:CreateToggle({
        Name = "Infinite Jump",
        Description = "Jump mid-air infinitely",
        Icon = "🦘",
        Default = false,
        Callback = function(v) State.airJump = v end,
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

    -- ═══════════════════════════════════════════════
    -- ABA: VISUALS
    -- ═══════════════════════════════════════════════
    local VisualsTab = Window:CreateTab("Visuals", "👁️")
    VisualsTab:CreateSection("ESP")

    VisualsTab:CreateToggle({
        Name = "Player ESP",
        Description = "Highlight enemies",
        Icon = "👤",
        Default = false,
        Callback = function(v) State.esp = v end,
    })

    VisualsTab:CreateSlider({
        Name = "ESP Max Distance",
        Description = "Render range",
        Icon = "📐",
        Min = 100, Max = 5000, Default = 500,
        Callback = function(v) State.espMaxDistance = v end,
    })

    VisualsTab:CreateToggle({
        Name = "Weapon ESP",
        Description = "Show equipped weapon",
        Icon = "🔫",
        Default = true,
        Callback = function(v) State.espWeapon = v end,
    })

    VisualsTab:CreateToggle({
        Name = "Armor ESP",
        Description = "Show armor value",
        Icon = "🛡️",
        Default = true,
        Callback = function(v) State.espArmor = v end,
    })

    VisualsTab:CreateSection("Extra")

    VisualsTab:CreateToggle({
        Name = "Damage Indicator",
        Description = "Red arrow when hit",
        Icon = "🩸",
        Default = false,
        Callback = function(v) State.damageIndicator = v end,
    })

    VisualsTab:CreateSection("Environment")

    VisualsTab:CreateToggle({
        Name = "Fullbright",
        Description = "Map always bright",
        Icon = "💡",
        Default = false,
        Callback = function(v) State.fullbright = v end,
    })

    VisualsTab:CreateToggle({
        Name = "Low Graphics",
        Description = "Reduce rendering quality",
        Icon = "📉",
        Default = false,
        Callback = function(v) State.lowGraphics = v end,
    })

    VisualsTab:CreateToggle({
        Name = "No Shadows",
        Description = "Remove all shadows",
        Icon = "🌑",
        Default = false,
        Callback = function(v) State.noShadows = v end,
    })

    VisualsTab:CreateToggle({
        Name = "No Fog",
        Description = "Remove fog and atmosphere",
        Icon = "🌫️",
        Default = false,
        Callback = function(v) State.noFog = v end,
    })

    VisualsTab:CreateToggle({
        Name = "No Particles",
        Description = "Remove all particle effects",
        Icon = "✨",
        Default = false,
        Callback = function(v) State.noParticles = v end,
    })

    -- ═══════════════════════════════════════════════
    -- ABA: SETTINGS
    -- ═══════════════════════════════════════════════
    local SettingsTab = Window:CreateTab("Settings", "⚙️")
    SettingsTab:CreateSection("Security")

    SettingsTab:CreateToggle({
        Name = "Anti-Flash",
        Description = "Blocks flashbang effect",
        Icon = "🛡️",
        Default = false,
        Callback = function(v) State.antiFlash = v end,
    })

    SettingsTab:CreateToggle({
        Name = "Anti-VoteKick",
        Description = "Blocks votekick attempts",
        Icon = "🛡️",
        Default = false,
        Callback = function(v) State.antiVK = v end,
    })

    SettingsTab:CreateSection("Optimizations")

    SettingsTab:CreateButton({
        Name = "⚡ Max FPS Boost",
        Callback = function()
            State.lowGraphics = true
            State.noShadows = true
            State.noFog = true
            State.noParticles = true
            Window:Notify("⚡ Boost", "All optimizations ON", 3, "success")
        end,
    })

    SettingsTab:CreateButton({
        Name = "🔄 Reset Optimizations",
        Callback = function()
            State.lowGraphics = false
            State.noShadows = false
            State.noFog = false
            State.noParticles = false
            Window:Notify("Reset", "Optimizations reset", 3, "info")
        end,
    })

    SettingsTab:CreateSection("Danger Zone")

    SettingsTab:CreateButton({
        Name = "Unload Script",
        Danger = true,
        Callback = function()
            UNLOADED = true
            if fovCircle then fovCircle:Remove() end
            if dmgArrow then dmgArrow:Remove() end
            Window:Notify("Unload", "Script unloaded", 2, "warning")
            task.wait(0.3)
            Window:Destroy()
        end,
    })

    -- ═══════════════════════════════════════════════
    -- ABA: CREDITS
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
    -- COMBAT LOOPS
    -- ═══════════════════════════════════════════════

    -- Silent Aim
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

    -- Aimbot
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
                                    mousemoverel((sp.X - m.X) * State.aimbotSmoothness, (sp.Y - m.Y) * State.aimbotSmoothness)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Triggerbot
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

    -- Auto Shoot
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

    -- Head Expander
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
        local function nd(class, props)
            local d = Drawing.new(class)
            for k, v in pairs(props) do d[k] = v end
            d.Visible = false
            return d
        end
        data.box = nd("Square", {Thickness = 1.5, Color = Color3.fromRGB(255, 30, 40), Filled = false, Transparency = 1})
        data.name = nd("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        data.distance = nd("Text", {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255, 80, 80)})
        data.health = nd("Line", {Thickness = 3, Color = Color3.fromRGB(0, 255, 0)})
        data.headDot = nd("Circle", {Radius = 4, NumSides = 20, Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255)})
        data.weapon = nd("Text", {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 200, 100)})
        data.armor = nd("Text", {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(100, 200, 255)})
        ESP.data[p] = data
    end

    local function removeESP(p)
        local d = ESP.data[p]
        if not d then return end
        if d.chams then d.chams:Destroy() end
        for _, key in ipairs({"box", "name", "distance", "health", "headDot", "weapon", "armor"}) do
            if d[key] and d[key].Remove then d[key]:Remove() end
        end
        ESP.data[p] = nil
    end

    local function clearAllESP()
        for p, _ in pairs(ESP.data) do removeESP(p) end
    end

    local function safeJSONDecode(str)
        if type(str) ~= "string" then return nil end
        local ok, decoded = pcall(function() return HttpService:JSONDecode(str) end)
        if ok then return decoded end
        return nil
    end

    local function updateESP(p, char)
        local d = ESP.data[p]
        if not d then return end
        if not State.esp or not isEnemy(p) then
            for _, key in ipairs({"box", "name", "distance", "health", "headDot", "weapon", "armor"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local head = getBasePart(char, "Head")
        local hrp = getBasePart(char, "HumanoidRootPart")
        if not head or not hrp then return end
        if d.chams then d.chams.Enabled = true end
        local hSp, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local rSp, rOn = Camera:WorldToViewportPoint(hrp.Position)
        local fSp, fOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local myR = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myR then return end
        local dist = math.floor((head.Position - myR.Position).Magnitude)
        if dist > State.espMaxDistance then
            for _, key in ipairs({"box", "name", "distance", "health", "headDot", "weapon", "armor"}) do
                if d[key] then d[key].Visible = false end
            end
            return
        end
        if hOn and fOn then
            local h = math.abs(fSp.Y - hSp.Y)
            local w = h * 0.6
            local cx = (hSp.X + fSp.X) / 2
            local cy = (hSp.Y + fSp.Y) / 2
            d.box.Position = Vector2.new(cx - w / 2, cy - h / 2)
            d.box.Size = Vector2.new(w, h)
            d.box.Visible = true
        else d.box.Visible = false end
        if hOn then
            d.name.Position = Vector2.new(hSp.X, hSp.Y - 20)
            d.name.Text = p.Name; d.name.Visible = true
            d.distance.Position = Vector2.new(hSp.X, hSp.Y - 6)
            d.distance.Text = dist .. "m"; d.distance.Visible = true
            d.headDot.Position = Vector2.new(hSp.X, hSp.Y); d.headDot.Visible = true
            if State.espWeapon then
                local eq = p:GetAttribute("CurrentEquipped")
                if eq then
                    local decoded = safeJSONDecode(eq)
                    local wname = decoded and decoded.Name or "?"
                    d.weapon.Position = Vector2.new(hSp.X, hSp.Y - 34)
                    d.weapon.Text = "[" .. wname .. "]"; d.weapon.Visible = true
                else d.weapon.Visible = false end
            else d.weapon.Visible = false end
            if State.espArmor then
                local armor = p:GetAttribute("Armor")
                if armor then
                    local decoded = safeJSONDecode(armor)
                    local armorVal = decoded and decoded.Health or 0
                    if armorVal > 0 then
                        d.armor.Position = Vector2.new(hSp.X, hSp.Y + 8)
                        d.armor.Text = "🛡 " .. armorVal; d.armor.Visible = true
                    else d.armor.Visible = false end
                else d.armor.Visible = false end
            else d.armor.Visible = false end
        else
            d.name.Visible = false; d.distance.Visible = false
            d.headDot.Visible = false; d.weapon.Visible = false; d.armor.Visible = false
        end
        if hOn and fOn then
            local h = math.abs(fSp.Y - hSp.Y)
            local hp = p:GetAttribute("Health") or 100
            local hr = math.clamp(hp / 100, 0, 1)
            local bx = hSp.X + (h * 0.6) / 2 + 5
            local by = hSp.Y + h
            d.health.From = Vector2.new(bx, by - h * hr)
            d.health.To = Vector2.new(bx, by)
            if hr > 0.6 then d.health.Color = Color3.fromRGB(0, 255, 0)
            elseif hr > 0.3 then d.health.Color = Color3.fromRGB(255, 200, 0)
            else d.health.Color = Color3.fromRGB(255, 40, 40) end
            d.health.Visible = true
        else d.health.Visible = false end
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
    -- DAMAGE INDICATOR
    -- ═══════════════════════════════════════════════
    local dmgArrow = Drawing.new("Triangle")
    dmgArrow.Filled = true
    dmgArrow.Color = Color3.fromRGB(255, 40, 40)
    dmgArrow.Transparency = 0.85
    dmgArrow.Visible = false

    local lastDamageTime = 0
    local lastHealth = 100

    task.spawn(function()
        while not UNLOADED do
            local h = LocalPlayer:GetAttribute("Health")
            if h and lastHealth and h < lastHealth then
                lastDamageTime = tick()
            end
            if h then lastHealth = h end
            task.wait(0.1)
        end
    end)

    if Remotes.CharacterDamaged then
        pcall(function()
            Remotes.CharacterDamaged.OnClientEvent:Connect(function()
                lastDamageTime = tick()
            end)
        end)
    end

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

    -- ═══════════════════════════════════════════════
    -- SECURITY
    -- ═══════════════════════════════════════════════
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

    if Remotes.FlashPlayer then
        pcall(function()
            Remotes.FlashPlayer.OnClientEvent:Connect(function()
                if UNLOADED or not State.antiFlash then return end
            end)
        end)
    end

    local vkKws = {"votekick", "voting", "vote_kick", "kickvote"}
    local function blockVoteKick(child)
        if not child then return false end
        local l = child.Name:lower()
        for _, kw in ipairs(vkKws) do
            if l:find(kw) then
                pcall(function() child:Destroy() end)
                return true
            end
        end
        return false
    end

    PlayerGui.ChildAdded:Connect(function(child)
        if UNLOADED or not State.antiVK then return end
        if blockVoteKick(child) then
            Window:Notify("🛡️ Anti-VK", "Votekick bloqueado", 3, "info")
        end
    end)

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
        local h = char:FindFirstChild("HumanoidRootPart")
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
        local char = LocalPlayer.Character
        if not char then return end
        local h = char:FindFirstChild("HumanoidRootPart")
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
            if UNLOADED or not State.airJump then return end
            local char = LocalPlayer.Character
            if not char then return end
            local h = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
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

    -- ═══════════════════════════════════════════════
    -- FULLBRIGHT / OPTIMIZATIONS
    -- ═══════════════════════════════════════════════
    local origBrightness = Lighting.Brightness
    local origAmbient = Lighting.Ambient
    local origOutdoorAmbient = Lighting.OutdoorAmbient
    local origClockTime = Lighting.ClockTime
    local origGlobalShadows = Lighting.GlobalShadows

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.fullbright then return end
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end)

    local function disableFullbright()
        Lighting.Brightness = origBrightness
        Lighting.Ambient = origAmbient
        Lighting.OutdoorAmbient = origOutdoorAmbient
        Lighting.ClockTime = origClockTime
        Lighting.GlobalShadows = origGlobalShadows
    end

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
        pcall(function() Lighting.GlobalShadows = not v end)
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                pcall(function() d.CastShadow = not v end)
            end
        end
    end
    local function applyNF(v)
        if v then
            Lighting.FogEnd = 100000; Lighting.FogStart = 0
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
        if UNLOADED then return end
        if State.lowGraphics then applyLG(true) end
        if State.noShadows then applyNS(true) end
        if State.noFog then applyNF(true) end
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
    -- AUTOLOAD (config system simples)
    -- ═══════════════════════════════════════════════
    task.defer(function()
        local BASE_FOLDER = "InfiniteZen_Configs"
        local CONFIG_FOLDER = BASE_FOLDER .. "/BloxStrike"
        local AUTOLOAD_FILE = "InfiniteZen_BloxStrike_Autoload.txt"
        if not isfile or not readfile then return end
        local ok, content = pcall(function() return readfile(AUTOLOAD_FILE) end)
        if ok and content and content ~= "" then
            local path = CONFIG_FOLDER .. "/" .. content .. ".json"
            local ok2, data = pcall(function() return readfile(path) end)
            if ok2 and data then
                local success, decoded = pcall(function() return HttpService:JSONDecode(data) end)
                if success and decoded and decoded.state then
                    for k, v in pairs(decoded.state) do State[k] = v end
                    Window:Notify("📂 Autoload", "Loaded: " .. content, 3, "info")
                end
            end
        end
    end)

    Window:Notify("✅ " .. SHORT_VERSION, "Blox Strike loaded successfully", 4, "success")
    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
end

return BloxStrike