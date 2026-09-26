-- ============================================================
-- INFINITE ZEN - WEAPONS CATALOG v2.0
-- Visual weapons + real damage (sandbox) + auto-hit
-- ============================================================

local Weapons = {}

function Weapons.Init(ctx)
    local UI     = ctx.UI
    local Compat = ctx.Compat
    local Window = ctx.Window

    if not UI or not Window then
        warn("[Weapons] UI ou Window não fornecidos")
        return
    end

    local Players         = game:GetService("Players")
    local RunService      = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local InsertService   = game:GetService("InsertService")
    local Debris          = game:GetService("Debris")
    local LocalPlayer     = Players.LocalPlayer

    local function getChar() return LocalPlayer.Character end
    local function getHRP()
        local c = getChar(); if not c then return nil end
        return c:FindFirstChild("HumanoidRootPart")
    end
    local function getBackpack() return LocalPlayer:FindFirstChild("Backpack") end

    local function isAlive(p)
        if not p or not p.Character then return false end
        local h = p.Character:FindFirstChildOfClass("Humanoid")
        return h and h.Health > 0
    end

    -- ═══════════════════════════════════════════════
    -- STATE
    -- ═══════════════════════════════════════════════
    local State = {
        autoHit = false,
        autoHitRange = 15,
        autoHitDelay = 0.15,
        showHitEffects = true,
    }

    -- ═══════════════════════════════════════════════
    -- WEAPON VISUAL PRESETS
    -- ═══════════════════════════════════════════════
    local WEAPON_VISUALS = {
        sword = {
            { size = Vector3.new(0.15, 2.8, 0.25), offset = CFrame.new(0, 1.55, 0),  color = Color3.fromRGB(220,220,220), mat = Enum.Material.Metal },
            { size = Vector3.new(0.8, 0.15, 0.2),  offset = CFrame.new(0, 0.15, 0),   color = Color3.fromRGB(100,100,100), mat = Enum.Material.Metal },
            { size = Vector3.new(0.2, 0.2, 0.2),   offset = CFrame.new(0, -0.35, 0),  color = Color3.fromRGB(200,180,80),  mat = Enum.Material.Metal },
        },
        katana = {
            { size = Vector3.new(0.1, 3.2, 0.22),  offset = CFrame.new(0, 1.75, 0),   color = Color3.fromRGB(240,240,240), mat = Enum.Material.Metal },
            { size = Vector3.new(0.4, 0.1, 0.4),   offset = CFrame.new(0, 0.15, 0),   color = Color3.fromRGB(40,40,40),    mat = Enum.Material.Metal },
        },
        bat = {
            { size = Vector3.new(0.3, 2.4, 0.3),   offset = CFrame.new(0, 1.3, 0),    color = Color3.fromRGB(139,69,19),   mat = Enum.Material.Wood },
            { size = Vector3.new(0.5, 0.7, 0.5),   offset = CFrame.new(0, 2.8, 0),    color = Color3.fromRGB(139,69,19),   mat = Enum.Material.Wood },
        },
        hammer = {
            { size = Vector3.new(0.2, 2, 0.2),     offset = CFrame.new(0, 1, 0),      color = Color3.fromRGB(139,69,19),   mat = Enum.Material.Wood },
            { size = Vector3.new(1, 0.6, 0.6),     offset = CFrame.new(0, 2.2, 0),    color = Color3.fromRGB(100,100,100), mat = Enum.Material.Metal },
        },
        gun = {
            { size = Vector3.new(0.3, 0.4, 1.2),   offset = CFrame.new(0, 0.2, -0.6), color = Color3.fromRGB(40,40,40),    mat = Enum.Material.Metal },
            { size = Vector3.new(0.15, 0.15, 0.8), offset = CFrame.new(0, 0.2, -1.6), color = Color3.fromRGB(30,30,30),    mat = Enum.Material.Metal },
            { size = Vector3.new(0.2, 0.5, 0.2),   offset = CFrame.new(0, -0.2, 0),   color = Color3.fromRGB(20,20,20),    mat = Enum.Material.Metal },
        },
        trident = {
            { size = Vector3.new(0.2, 4, 0.2),     offset = CFrame.new(0, 2, 0),      color = Color3.fromRGB(180,140,60),  mat = Enum.Material.Metal },
            { size = Vector3.new(0.9, 0.3, 0.2),   offset = CFrame.new(0, 4.2, 0),    color = Color3.fromRGB(255,215,0),   mat = Enum.Material.Neon },
            { size = Vector3.new(0.15, 0.7, 0.15), offset = CFrame.new(-0.35, 4.75, 0),color = Color3.fromRGB(255,215,0),  mat = Enum.Material.Neon },
            { size = Vector3.new(0.15, 0.7, 0.15), offset = CFrame.new(0, 4.75, 0),   color = Color3.fromRGB(255,215,0),   mat = Enum.Material.Neon },
            { size = Vector3.new(0.15, 0.7, 0.15), offset = CFrame.new(0.35, 4.75, 0),color = Color3.fromRGB(255,215,0),   mat = Enum.Material.Neon },
        },
        banana = {
            { size = Vector3.new(0.4, 0.4, 1.3),   offset = CFrame.new(0, 0.7, 0),    color = Color3.fromRGB(255,220,50),  mat = Enum.Material.SmoothPlastic },
        },
        bomb = {
            { size = Vector3.new(0.8, 0.8, 0.8),   offset = CFrame.new(0, 0.6, 0),    color = Color3.fromRGB(20,20,20),    mat = Enum.Material.Metal },
            { size = Vector3.new(0.1, 0.4, 0.1),   offset = CFrame.new(0, 1.2, 0),    color = Color3.fromRGB(200,200,100), mat = Enum.Material.SmoothPlastic },
        },
        guitar = {
            { size = Vector3.new(0.3, 1, 0.5),     offset = CFrame.new(0, 0.5, 0),    color = Color3.fromRGB(150,50,30),   mat = Enum.Material.Wood },
            { size = Vector3.new(0.15, 2, 0.2),    offset = CFrame.new(0, 2, 0),      color = Color3.fromRGB(80,40,20),    mat = Enum.Material.Wood },
        },
        scythe = {
            { size = Vector3.new(0.2, 4, 0.2),     offset = CFrame.new(0, 2, 0),      color = Color3.fromRGB(30,30,30),    mat = Enum.Material.Metal },
            { size = Vector3.new(0.15, 1.5, 0.4),  offset = CFrame.new(0, 4, 0.7),    color = Color3.fromRGB(200,40,40),   mat = Enum.Material.Neon },
        },
        godsword = {
            { size = Vector3.new(0.3, 3.5, 0.4),   offset = CFrame.new(0, 1.9, 0),    color = Color3.fromRGB(255,100,255), mat = Enum.Material.Neon },
            { size = Vector3.new(1, 0.2, 0.3),     offset = CFrame.new(0, 0.15, 0),   color = Color3.fromRGB(255,215,0),   mat = Enum.Material.Neon },
            { size = Vector3.new(0.25, 0.25, 0.25),offset = CFrame.new(0, -0.35, 0),  color = Color3.fromRGB(255,100,255), mat = Enum.Material.Neon },
        },
        adminbat = {
            { size = Vector3.new(0.4, 3, 0.4),     offset = CFrame.new(0, 1.6, 0),    color = Color3.fromRGB(255,215,0),   mat = Enum.Material.Neon },
            { size = Vector3.new(0.7, 0.7, 0.7),   offset = CFrame.new(0, 3.2, 0),    color = Color3.fromRGB(255,215,0),   mat = Enum.Material.Neon },
        },
    }

    -- ═══════════════════════════════════════════════
    -- CATALOG (agora com damage + range)
    -- ═══════════════════════════════════════════════
    local CATALOG = {
        -- ═══ ⚔️ SWORDS (dano 30-60) ═══
        ["⚔️ Linked Sword"]    = { id = 125013769, cat = "Swords",   type = "sword",    damage = 35,  range = 6 },
        ["🗡️ Katana"]           = { id = 1222213,   cat = "Swords",   type = "katana",   damage = 40,  range = 7 },
        ["💜 Darkheart"]        = { id = 126468259, cat = "Swords",   type = "sword",    damage = 55,  range = 7 },
        ["🔥 Fiery Blade"]      = { id = 29807009,  cat = "Swords",   type = "sword",    damage = 50,  range = 6 },
        ["❄️ Ice Dagger"]       = { id = 1034568,   cat = "Swords",   type = "sword",    damage = 30,  range = 5 },
        ["👻 Ghostwalker"]      = { id = 170327249, cat = "Swords",   type = "sword",    damage = 45,  range = 7 },
        ["🌑 Shadow Blade"]     = { id = 117341978, cat = "Swords",   type = "sword",    damage = 60,  range = 7 },
        ["🌸 Bluesteel Katana"] = { id = 158718358, cat = "Swords",   type = "katana",   damage = 50,  range = 7 },
        ["🩸 Vampire Killer"]   = { id = 32354510,  cat = "Swords",   type = "sword",    damage = 65,  range = 7 },

        -- ═══ 🔫 FIREARMS (dano 40-100) ═══
        ["🔫 Paintball Gun"]    = { id = 89453184,  cat = "Firearms", type = "gun",      damage = 25,  range = 30 },
        ["🚀 Rocket Launcher"]  = { id = 1278391,   cat = "Firearms", type = "gun",      damage = 100, range = 40 },
        ["🎯 BB Gun"]           = { id = 43156470,  cat = "Firearms", type = "gun",      damage = 15,  range = 20 },
        ["🏹 Slingshot"]        = { id = 135147252, cat = "Firearms", type = "gun",      damage = 20,  range = 25 },

        -- ═══ 🧰 TOOLS ═══
        ["🔦 Flashlight"]       = { id = 1235237,   cat = "Tools",    type = "sword",    damage = 5,   range = 4 },
        ["🧱 Trowel"]           = { id = 33024170,  cat = "Tools",    type = "sword",    damage = 10,  range = 5 },
        ["💣 Bomb"]             = { id = 135079609, cat = "Tools",    type = "bomb",     damage = 200, range = 20 },
        ["🪝 Grappling Hook"]   = { id = 135300292, cat = "Tools",    type = "gun",      damage = 0,   range = 50 },
        ["⚽ Superball"]        = { id = 1038599,   cat = "Tools",    type = "banana",   damage = 15,  range = 6 },
        ["🥷 Ninja Star"]       = { id = 1092173,   cat = "Tools",    type = "banana",   damage = 30,  range = 8 },

        -- ═══ 🌀 COILS (utility) ═══
        ["⚡ Speed Coil"]       = { id = 1062751,   cat = "Coils",    type = "banana",   damage = 0,   range = 3 },
        ["🌌 Gravity Coil"]     = { id = 1057753,   cat = "Coils",    type = "banana",   damage = 0,   range = 3 },
        ["💠 Fusion Coil"]      = { id = 16688966,  cat = "Coils",    type = "banana",   damage = 0,   range = 3 },
        ["💚 Regeneration Coil"]= { id = 357912,    cat = "Coils",    type = "banana",   damage = 0,   range = 3 },
        ["🥷 Ninja Coil"]       = { id = 144919722, cat = "Coils",    type = "banana",   damage = 0,   range = 3 },

        -- ═══ 😭 FUN ═══
        ["📻 Boombox"]          = { id = 136250,    cat = "Fun",      type = "bomb",     damage = 25,  range = 10 },
        ["🎵 Harmonica"]        = { id = 1045027,   cat = "Fun",      type = "banana",   damage = 0,   range = 3 },
        ["🎸 Guitar"]           = { id = 1097829,   cat = "Fun",      type = "guitar",   damage = 30,  range = 6 },
        ["❄️ Snowball"]         = { id = 1287330,   cat = "Fun",      type = "banana",   damage = 10,  range = 10 },

        -- ═══ 👑 ADMIN (DANO 50000) ═══
        ["👑 Admin Bat"]        = { id = nil,       cat = "Admin",    type = "adminbat", damage = 50000, range = 15 },
        ["🌟 God Sword"]        = { id = nil,       cat = "Admin",    type = "godsword", damage = 50000, range = 12 },
        ["🔱 Golden Trident"]   = { id = nil,       cat = "Admin",    type = "trident",  damage = 50000, range = 12 },
        ["💀 Reaper's Scythe"]  = { id = nil,       cat = "Admin",    type = "scythe",   damage = 50000, range = 12 },
        ["🔨 Hammer"]           = { id = nil,       cat = "Admin",    type = "hammer",   damage = 50000, range = 8 },
    }

    -- ═══════════════════════════════════════════════
    -- DAMAGE HELPERS
    -- ═══════════════════════════════════════════════
    local function applyDamage(humanoid, amount)
        if not humanoid or humanoid.Health <= 0 then return end
        pcall(function()
            humanoid:TakeDamage(amount)
        end)
    end

    local function spawnHitEffect(position, color)
        if not State.showHitEffects then return end
        color = color or Color3.fromRGB(255, 50, 50)

        local part = Instance.new("Part")
        part.Size = Vector3.new(0.5, 0.5, 0.5)
        part.Shape = Enum.PartType.Ball
        part.Color = color
        part.Material = Enum.Material.Neon
        part.Anchored = true
        part.CanCollide = false
        part.Position = position
        part.Parent = workspace

        local tween = game:GetService("TweenService"):Create(
            part,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = Vector3.new(3, 3, 3), Transparency = 1 }
        )
        tween:Play()

        Debris:AddItem(part, 0.4)
    end

    -- ═══════════════════════════════════════════════
    -- WEAPON CREATION
    -- ═══════════════════════════════════════════════
    local activeTools = {}  -- rastreia tools criadas

    local function createCustomWeapon(name, weaponData, displayName)
        local backpack = getBackpack()
        if not backpack then return false end

        local visuals = WEAPON_VISUALS[weaponData.type] or WEAPON_VISUALS.sword
        local damage = weaponData.damage or 25
        local range = weaponData.range or 6

        -- Handle PEQUENO
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.2, 0.4, 0.2)
        handle.Color = Color3.fromRGB(60, 60, 60)
        handle.Material = Enum.Material.Metal
        handle.CanCollide = false
        handle.CanTouch = false
        handle.Massless = true
        handle.TopSurface = Enum.SurfaceType.Smooth
        handle.BottomSurface = Enum.SurfaceType.Smooth

        local tool = Instance.new("Tool")
        tool.Name = displayName or name:gsub("^[^ ]+ ", "")
        tool.RequiresHandle = true
        tool.CanBeDropped = true
        tool.ToolTip = "IZM • DMG " .. damage
        tool.Grip = CFrame.new(0, -0.2, 0)
        handle.Parent = tool

        -- Peças visuais soldadas
        for _, v in ipairs(visuals) do
            local part = Instance.new("Part")
            part.Size = v.size
            part.Color = v.color
            part.Material = v.mat
            part.CanCollide = false
            part.CanTouch = false
            part.Massless = true
            part.TopSurface = Enum.SurfaceType.Smooth
            part.BottomSurface = Enum.SurfaceType.Smooth
            part.Parent = tool

            local weld = Instance.new("Weld")
            weld.Part0 = handle
            weld.Part1 = part
            weld.C0 = v.offset
            weld.Parent = handle
        end

        -- ═══════════════════════════════════════════════
        -- DAMAGE SYSTEM
        -- ═══════════════════════════════════════════════
        local lastHit = {}
        local HIT_COOLDOWN = 0.5

        local function tryDamage(targetChar)
            if not targetChar or targetChar == getChar() then return end
            local hum = targetChar:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end

            local now = tick()
            if lastHit[targetChar] and (now - lastHit[targetChar]) < HIT_COOLDOWN then return end
            lastHit[targetChar] = now

            -- Aplica dano
            applyDamage(hum, damage)

            -- Efeito visual
            local hrp = targetChar:FindFirstChild("HumanoidRootPart")
            if hrp then spawnHitEffect(hrp.Position, Color3.fromRGB(255, 50, 50)) end

            -- Som de hit
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://138186576"
            sound.Volume = 1
            sound.Parent = handle
            sound:Play()
            Debris:AddItem(sound, 2)
        end

        -- 1. Touched (funciona em sandbox)
        handle.Touched:Connect(function(hit)
            if hit.Parent and hit.Parent ~= getChar() then
                local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
                if hum then tryDamage(hit.Parent) end
            end
        end)

        -- 2. Activated (clicar)
        tool.Activated:Connect(function()
            local char = getChar()
            if not char then return end
            local myHRP = char:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end

            -- Acha players perto
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isAlive(p) and p.Character then
                    local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    if tHRP then
                        local dist = (tHRP.Position - myHRP.Position).Magnitude
                        if dist <= range then
                            tryDamage(p.Character)
                        end
                    end
                end
            end
        end)

        -- Registra pra auto-hit
        activeTools[tool] = {
            damage = damage,
            range = range,
            tryDamage = tryDamage,
            lastHit = lastHit,
        }

        -- Remove do registro quando sair
        tool.AncestryChanged:Connect(function()
            if not tool.Parent then
                activeTools[tool] = nil
            end
        end)

        tool.Parent = backpack
        return true
    end

    -- ═══════════════════════════════════════════════
    -- AUTO-HIT LOOP
    -- ═══════════════════════════════════════════════
    task.spawn(function()
        while true do
            task.wait(State.autoHitDelay)

            if State.autoHit then
                local char = getChar()
                if char then
                    local myHRP = char:FindFirstChild("HumanoidRootPart")
                    if myHRP then
                        local equipped = char:FindFirstChildOfClass("Tool")
                        if equipped and activeTools[equipped] then
                            local info = activeTools[equipped]

                            -- Acha players dentro do range
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= LocalPlayer and isAlive(p) and p.Character then
                                    local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                                    if tHRP then
                                        local dist = (tHRP.Position - myHRP.Position).Magnitude
                                        if dist <= State.autoHitRange then
                                            info.tryDamage(p.Character)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    -- ═══════════════════════════════════════════════
    -- GIVE ITEM
    -- ═══════════════════════════════════════════════
    local function giveItem(name)
        local data = CATALOG[name]
        if not data then
            if Window.Notify then Window:Notify("❌", "Unknown item", 2, "error") end
            return
        end

        local displayName = name:gsub("^[^ ]+ ", "")

        -- Sem ID → cria custom
        if not data.id then
            local ok = createCustomWeapon(name, data, displayName)
            if Window.Notify then
                Window:Notify(ok and "🎁" or "❌",
                    ok and (displayName .. " • DMG " .. (data.damage or 0)) or "Failed",
                    2, ok and "success" or "error")
            end
            return
        end

        -- Tenta catalog real
        local ok, model = pcall(function() return InsertService:LoadAsset(data.id) end)
        local realGiven = false

        if ok and model then
            local backpack = getBackpack()
            if backpack then
                for _, child in ipairs(model:GetDescendants()) do
                    if child:IsA("Tool") then
                        child.Parent = backpack
                        realGiven = true
                    end
                end
                task.delay(1, function() if model then pcall(function() model:Destroy() end) end end)
            end
        end

        if realGiven then
            if Window.Notify then Window:Notify("✅", displayName .. " (real)", 2, "success") end
            return
        end

        -- Fallback: cria custom com dano
        local okFb = createCustomWeapon(name, data, displayName)
        if Window.Notify then
            Window:Notify(okFb and "🎁" or "❌",
                okFb and (displayName .. " • DMG " .. (data.damage or 0)) or "Failed",
                2, okFb and "info" or "error")
        end
    end

    -- ═══════════════════════════════════════════════
    -- BUILD UI
    -- ═══════════════════════════════════════════════
    local WeaponsTab = Window:CreateTab("Weapons", "🗡️")

    WeaponsTab:CreateSection("⚙️ Auto-Hit")
    WeaponsTab:CreateToggle({
        Name = "Auto Hit",
        Description = "Auto-damage players nearby",
        Icon = "⚔️", Default = false,
        Callback = function(v) State.autoHit = v end,
    })
    WeaponsTab:CreateSlider({
        Name = "Auto Hit Range",
        Icon = "📏", Min = 5, Max = 50, Default = 15,
        Callback = function(v) State.autoHitRange = v end,
    })
    WeaponsTab:CreateSlider({
        Name = "Auto Hit Delay (ms)",
        Icon = "⏱️", Min = 50, Max = 1000, Default = 150,
        Callback = function(v) State.autoHitDelay = v / 1000 end,
    })
    WeaponsTab:CreateToggle({
        Name = "Hit Effects",
        Description = "Show hit particles",
        Icon = "💥", Default = true,
        Callback = function(v) State.showHitEffects = v end,
    })

    WeaponsTab:CreateSection("📖 Roblox Catalog")

    local categories = { "Swords", "Firearms", "Tools", "Coils", "Fun", "Admin" }
    local catIcons = {
        Swords = "⚔️", Firearms = "🔫", Tools = "🧰",
        Coils = "🌀", Fun = "😭", Admin = "👑",
    }

    for _, cat in ipairs(categories) do
        WeaponsTab:CreateSection(catIcons[cat] .. " " .. cat)

        local names = {}
        for name, data in pairs(CATALOG) do
            if data.cat == cat then table.insert(names, name) end
        end
        table.sort(names)

        local dropdown
        dropdown = WeaponsTab:CreateDropdown({
            Name = cat, Description = "Select item",
            Icon = catIcons[cat], Options = names, Default = 1,
            Callback = function() end,
        })

        WeaponsTab:CreateButton({
            Name = "🎁 Give " .. cat,
            Callback = function()
                local _, idx = dropdown:GetValue()
                local n = names[idx or 1]
                if n then giveItem(n) end
            end,
        })
    end

    -- Custom Asset ID
    WeaponsTab:CreateSection("🔧 Custom Asset ID")

    local assetFrame = Instance.new("Frame", WeaponsTab.container)
    assetFrame.Size = UDim2.new(1, 0, 0, 40)
    assetFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    assetFrame.BorderSizePixel = 0
    assetFrame.LayoutOrder = #WeaponsTab.container:GetChildren()
    Instance.new("UICorner", assetFrame).CornerRadius = UDim.new(0, 8)

    local assetBox = Instance.new("TextBox", assetFrame)
    assetBox.Size = UDim2.new(1, -20, 1, -10)
    assetBox.Position = UDim2.new(0, 10, 0, 5)
    assetBox.BackgroundTransparency = 1
    assetBox.Font = Enum.Font.Code
    assetBox.TextSize = 12
    assetBox.TextColor3 = Color3.fromRGB(240,240,245)
    assetBox.PlaceholderText = "Asset ID (ex: 125013769)"
    assetBox.PlaceholderColor3 = Color3.fromRGB(90,90,105)
    assetBox.Text = ""
    assetBox.ClearTextOnFocus = false
    assetBox.TextXAlignment = Enum.TextXAlignment.Left

    WeaponsTab:CreateButton({
        Name = "🎁 Load Custom",
        Callback = function()
            local id = tonumber(assetBox.Text)
            if not id then
                Window:Notify("❌", "Invalid ID", 2, "error"); return
            end
            local ok, model = pcall(function() return InsertService:LoadAsset(id) end)
            if ok and model then
                local backpack = getBackpack()
                if backpack then
                    local found = false
                    for _, child in ipairs(model:GetDescendants()) do
                        if child:IsA("Tool") then
                            child.Parent = backpack
                            found = true
                        end
                    end
                    task.delay(1, function() if model then pcall(function() model:Destroy() end) end end)
                    if found then
                        Window:Notify("✅", "Loaded!", 2, "success"); return
                    end
                end
            end
            Window:Notify("❌", "Blocked / invalid", 2, "error")
        end,
    })

    WeaponsTab:CreateSection("📦 Bulk")
    WeaponsTab:CreateButton({
        Name = "🎁 Give ALL Admin Weapons",
        Callback = function()
            for name, data in pairs(CATALOG) do
                if data.cat == "Admin" then
                    giveItem(name)
                    task.wait(0.1)
                end
            end
            Window:Notify("👑", "All admin weapons given!", 2, "success")
        end,
    })
    WeaponsTab:CreateButton({
        Name = "🧹 Clear Backpack",
        Callback = function()
            local backpack = getBackpack()
            if not backpack then return end
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then pcall(function() tool:Destroy() end) end
            end
            Window:Notify("🧹", "Backpack cleared", 2, "info")
        end,
    })

    print("[Infinite Zen] [Weapons] ✅ Catalog v2.0 (with damage)")
end

return Weapons