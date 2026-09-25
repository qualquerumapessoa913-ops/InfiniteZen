-- ============================================================
-- INFINITE ZEN - WEAPONS CATALOG v1.0
-- Real Roblox catalog items — pick and receive
-- ============================================================

local Weapons = {}

function Weapons.Init(ctx)
    local UI     = ctx.UI
    local Compat = ctx.Compat
    local Window = ctx.Window  -- recebe a janela do universal

    if not UI or not Window then
        warn("[Weapons] UI ou Window não fornecidos")
        return
    end

    local Players       = game:GetService("Players")
    local InsertService = game:GetService("InsertService")
    local LocalPlayer   = Players.LocalPlayer

    local function getChar() return LocalPlayer.Character end
    local function getBackpack() return LocalPlayer:FindFirstChild("Backpack") end

    -- ═══════════════════════════════════════════════
    -- CATALOG (REAL ROBLOX IDS)
    -- ═══════════════════════════════════════════════
    local CATALOG = {
        -- ═══ ⚔️ CLASSIC SWORDS ═══
        ["⚔️ Linked Sword"]       = { id = 125013769,  cat = "Swords" },
        ["🗡️ Katana"]              = { id = 1222213,    cat = "Swords" },
        ["💜 Darkheart"]           = { id = 126468259,  cat = "Swords" },
        ["🔥 Fiery Blade"]         = { id = 29807009,   cat = "Swords" },
        ["❄️ Ice Dagger"]          = { id = 1034568,    cat = "Swords" },
        ["👻 Ghostwalker"]         = { id = 170327249,  cat = "Swords" },
        ["🌑 Shadow Blade"]        = { id = 117341978,  cat = "Swords" },
        ["🌸 Bluesteel Katana"]    = { id = 158718358,  cat = "Swords" },
        ["🩸 Vampire Killer"]      = { id = 32354510,   cat = "Swords" },
        ["⚡ Golden Sword"]        = { id = 125013769,  cat = "Swords" },

        -- ═══ 🔫 FIREARMS ═══
        ["🔫 Paintball Gun"]       = { id = 89453184,   cat = "Firearms" },
        ["🚀 Rocket Launcher"]     = { id = 1278391,    cat = "Firearms" },
        ["🎯 BB Gun"]              = { id = 43156470,   cat = "Firearms" },
        ["🏹 Slingshot"]           = { id = 135147252,  cat = "Firearms" },

        -- ═══ 🧰 TOOLS ═══
        ["🔦 Flashlight"]          = { id = 1235237,    cat = "Tools" },
        ["🧱 Trowel"]              = { id = 33024170,   cat = "Tools" },
        ["💣 Bomb"]                = { id = 135079609,  cat = "Tools" },
        ["🪝 Grappling Hook"]      = { id = 135300292,  cat = "Tools" },
        ["⚽ Superball"]           = { id = 1038599,    cat = "Tools" },
        ["🥷 Ninja Star"]          = { id = 1092173,    cat = "Tools" },

        -- ═══ 🌀 COILS ═══
        ["⚡ Speed Coil"]          = { id = 1062751,    cat = "Coils" },
        ["🌌 Gravity Coil"]        = { id = 1057753,    cat = "Coils" },
        ["💠 Fusion Coil"]         = { id = 16688966,   cat = "Coils" },
        ["💚 Regeneration Coil"]   = { id = 357912,     cat = "Coils" },
        ["🥷 Ninja Coil"]          = { id = 144919722,  cat = "Coils" },

        -- ═══ 😭 FUN ═══
        ["📻 Boombox"]             = { id = 136250,     cat = "Fun" },
        ["🎵 Harmonica"]           = { id = 1045027,    cat = "Fun" },
        ["🎸 Guitar"]              = { id = 1097829,    cat = "Fun" },
        ["❄️ Snowball"]            = { id = 1287330,    cat = "Fun" },

        -- ═══ 👑 ADMIN / OP ═══
        ["👑 Admin Bat"]           = { id = nil,        cat = "Admin" },
        ["🌟 God Sword"]           = { id = nil,        cat = "Admin" },
        ["🔱 Golden Trident"]      = { id = nil,        cat = "Admin" },
        ["💀 Reaper's Scythe"]     = { id = nil,        cat = "Admin" },
    }

    -- ═══════════════════════════════════════════════
    -- FALLBACK (custom tool creation)
    -- ═══════════════════════════════════════════════
    local FALLBACKS = {
        ["👑 Admin Bat"]      = { size = Vector3.new(0.8, 0.8, 5), color = Color3.fromRGB(255, 215, 0),  mat = Enum.Material.Neon, dmg = 999 },
        ["🌟 God Sword"]      = { size = Vector3.new(1, 1, 7),     color = Color3.fromRGB(255, 100, 255), mat = Enum.Material.Neon, dmg = 500 },
        ["🔱 Golden Trident"] = { size = Vector3.new(0.5, 0.5, 8), color = Color3.fromRGB(255, 215, 0),  mat = Enum.Material.Neon, dmg = 75 },
        ["💀 Reaper's Scythe"]= { size = Vector3.new(0.5, 0.5, 6), color = Color3.fromRGB(30, 30, 30),   mat = Enum.Material.Neon, dmg = 200 },
    }

    local function createFallback(name)
        local cfg = FALLBACKS[name]
        if not cfg then cfg = { size = Vector3.new(1, 1, 3), color = Color3.fromRGB(150,150,150), mat = Enum.Material.Metal, dmg = 20 } end

        local backpack = getBackpack()
        if not backpack then return false end

        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = cfg.size
        handle.Color = cfg.color
        handle.Material = cfg.mat
        handle.CanCollide = false
        handle.TopSurface = Enum.SurfaceType.Smooth
        handle.BottomSurface = Enum.SurfaceType.Smooth

        local tool = Instance.new("Tool")
        tool.Name = name:gsub("^[^ ]+ ", "")
        tool.RequiresHandle = true
        tool.CanBeDropped = true
        tool.ToolTip = "IZM " .. name
        handle.Parent = tool

        if cfg.dmg and cfg.dmg > 0 then
            local char = getChar()
            handle.Touched:Connect(function(hit)
                if hit.Parent and hit.Parent ~= char then
                    local h = hit.Parent:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then pcall(function() h:TakeDamage(cfg.dmg) end) end
                end
            end)
        end

        tool.Parent = backpack
        return true
    end

    -- ═══════════════════════════════════════════════
    -- GIVE FUNCTION
    -- ═══════════════════════════════════════════════
    local function giveItem(name)
        local data = CATALOG[name]
        if not data then
            if Window.Notify then Window:Notify("❌", "Unknown item", 2, "error") end
            return
        end

        -- Custom fallback only
        if not data.id then
            local ok = createFallback(name)
            if ok then
                if Window.Notify then Window:Notify("🎁", name .. " (custom)", 2, "success") end
            else
                if Window.Notify then Window:Notify("❌", "Failed", 2, "error") end
            end
            return
        end

        -- Try real catalog
        local ok, model = pcall(function()
            return InsertService:LoadAsset(data.id)
        end)

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
                    if Window.Notify then Window:Notify("✅", name .. " (real)", 2, "success") end
                    return
                end
            end
        end

        -- Fallback
        local fb = createFallback(name)
        if fb and Window.Notify then
            Window:Notify("🎁", name .. " (visual)", 2, "info")
        end
    end

    -- ═══════════════════════════════════════════════
    -- BUILD UI
    -- ═══════════════════════════════════════════════
    local WeaponsTab = Window:CreateTab("Weapons", "🗡️")

    WeaponsTab:CreateSection("📖 Roblox Catalog")
    WeaponsTab:CreateLabel("Pick an item from the dropdown, then click Give", Color3.fromRGB(140,140,155))

    -- Organize by category
    local categories = { "Swords", "Firearms", "Tools", "Coils", "Fun", "Admin" }
    local catIcons = {
        Swords   = "⚔️",
        Firearms = "🔫",
        Tools    = "🧰",
        Coils    = "🌀",
        Fun      = "😭",
        Admin    = "👑",
    }

    -- Build dropdowns per category
    for _, cat in ipairs(categories) do
        WeaponsTab:CreateSection(catIcons[cat] .. " " .. cat)

        local names = {}
        for name, data in pairs(CATALOG) do
            if data.cat == cat then table.insert(names, name) end
        end
        table.sort(names)

        local dropdown
        dropdown = WeaponsTab:CreateDropdown({
            Name = cat .. " Items",
            Description = "Select and give",
            Icon = catIcons[cat] or "🎁",
            Options = names,
            Default = 1,
            Callback = function() end,
        })

        WeaponsTab:CreateButton({
            Name = "🎁 Give Selected " .. cat,
            Callback = function()
                local _, idx = dropdown:GetValue()
                local name = names[idx or 1]
                if name then giveItem(name) end
            end,
        })
    end

    -- Custom Asset ID
    WeaponsTab:CreateSection("🔧 Custom Asset ID")
    WeaponsTab:CreateLabel("Paste any Roblox asset ID", Color3.fromRGB(140,140,155))

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
        Name = "🎁 Load Custom ID",
        Callback = function()
            local id = tonumber(assetBox.Text)
            if not id then
                if Window.Notify then Window:Notify("❌", "Invalid ID", 2, "error") end
                return
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
                        if Window.Notify then Window:Notify("✅", "Loaded: " .. id, 2, "success") end
                        return
                    end
                end
            end

            if Window.Notify then Window:Notify("❌", "Asset blocked / invalid", 2, "error") end
        end,
    })

    WeaponsTab:CreateSection("📦 Bulk")
    WeaponsTab:CreateButton({
        Name = "🎁 Give ALL Real Weapons",
        Callback = function()
            local count = 0
            for name, data in pairs(CATALOG) do
                if data.id then
                    giveItem(name)
                    count = count + 1
                    task.wait(0.2)
                end
            end
            if Window.Notify then Window:Notify("📦", "Gave " .. count .. " items", 3, "success") end
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
            if Window.Notify then Window:Notify("🧹", "Backpack cleared", 2, "info") end
        end,
    })

    print("[Infinite Zen] [Weapons] ✅ Catalog v1.0 carregado")
end

return Weapons