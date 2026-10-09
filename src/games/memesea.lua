-- ============================================================
-- Infinite Zen - MemeSea - v1.0
-- ============================================================

local MemeSea = {}

function MemeSea.Init(ctx)
    local Language = ctx.Language
    local UI       = ctx.UI
    local Compat   = ctx.Compat
    local gameName = ctx.gameName

    local function T(key, fallback)
        if Language and type(Language.get) == "function" then
            local ok, v = pcall(Language.get, key)
            if ok and v and v ~= key then return v end
        end
        return fallback or key
    end

    local GAME_VERSION = "1.0"
    local FULL_VERSION  = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("============================================")
    print("[Infinite Zen] 🇧🇷 Inicializando " .. FULL_VERSION .. "...")
    print("[Infinite Zen] 🇺🇸 Initializing " .. FULL_VERSION .. "...")
    print("============================================")

    local Players          = game:GetService("Players")
    local RunService       = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInput     = game:GetService("VirtualInputManager")
    local HttpService      = game:GetService("HttpService")
    local Lighting         = game:GetService("Lighting")
    local VirtualUser      = game:GetService("VirtualUser")
    local LocalPlayer      = Players.LocalPlayer
    local Camera           = workspace.CurrentCamera

    local UNLOADED  = false
    local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local BASE_FOLDER   = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/MemeSea"
    local AUTOLOAD_FILE = "InfiniteZen_MemeSea_Autoload.txt"

    local State = {
        autoFarmLevel = false,
        autoFarmNearest = false,
        autoFarmSelected = false,
        selectedFarmTarget = "",
        autoAttack = false,
        autoSkill = false,
        collectDrops = false,
        autoStoreFruits = false,
        combatMode = "Both",
        autoStats = false,
        autoBoss = false,
        autoLordSus = false,
        autoGiantPumpkin = false,
        autoEvilNoob = false,
        autoMemeBeast = false,
        autoRaidBoss = false,
        autoFloppa = false,
        autoPopcat = false,
        redeemCodes = false,
        rollColor = false,
        farmFlashStep = false,
        speed = false, speedValue = 50,
        jumpPower = false, jumpPowerValue = 80,
        antiAfk = false,
        fullbright = false,
        noFog = false,
    }

    local origBrightness = Lighting.Brightness
    local origAmbient    = Lighting.Ambient
    local origOutdoor    = Lighting.OutdoorAmbient
    local origClock      = Lighting.ClockTime
    local origFogEnd     = Lighting.FogEnd
    local origFogStart   = Lighting.FogStart

    local function getMonsterFolder()
        return workspace:FindFirstChild("Monster") or workspace:FindFirstChild("Monsters")
    end

    local function getNpcFolder()
        return workspace:FindFirstChild("Npc") or workspace:FindFirstChild("NPCs")
    end

    local function getPlayerData()
        return LocalPlayer:FindFirstChild("PlayerData")
    end

    local function getLevel()
        local pd = getPlayerData()
        if not pd then return 1 end
        local lvl = pd:FindFirstChild("Level")
        if lvl and lvl:IsA("NumberValue") then return lvl.Value end
        return 1
    end

    local function getHRP()
        if not LocalPlayer.Character then return nil end
        return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end

    local function getCombatTool()
        local char = LocalPlayer.Character
        if not char then return nil end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if State.combatMode == "Sword" then
            for _, c in ipairs(char:GetChildren()) do
                if c:IsA("Tool") then return c end
            end
            if backpack then
                for _, c in ipairs(backpack:GetChildren()) do
                    if c:IsA("Tool") and c:FindFirstChild("Sword") then return c end
                end
            end
        end
        return nil
    end

    local function getNearestMonster()
        local folder = getMonsterFolder()
        if not folder then return nil end
        local myHRP = getHRP()
        if not myHRP then return nil end
        local nearest, minDist = nil, math.huge
        for _, mob in ipairs(folder:GetChildren()) do
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            local hum = mob:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < minDist then minDist = d; nearest = mob end
            end
        end
        return nearest
    end

    local function attackMonster(mob)
        if not mob then return end
        local hum = mob:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChildOfClass("RemoteEvent") then
            pcall(function() tool.RemoteEvent:FireServer(mob) end)
        elseif tool and tool:FindFirstChild("Remote") then
            pcall(function() tool.Remote:FireServer(mob) end)
        end
    end

    local function useSkills()
        local char = LocalPlayer.Character
        if not char then return end
        local skills = char:FindFirstChild("Skills") or char:FindFirstChild("Abilities")
        if skills then
            for _, skill in ipairs(skills:GetChildren()) do
                if skill:IsA("RemoteEvent") or skill:IsA("RemoteFunction") then
                    pcall(function() skill:FireServer() end)
                end
            end
        end
    end

    local function teleportTo(pos)
        local hrp = getHRP()
        if hrp then
            pcall(function() hrp.CFrame = CFrame.new(pos) end)
        end
    end

    local attackDebounce = 0
    task.spawn(function()
        while not UNLOADED do
            task.wait(0.15)
            if State.autoAttack or State.autoFarmLevel or State.autoFarmNearest or State.autoBoss then
                local target = getNearestMonster()
                if target then
                    local hrp = target:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local myHRP = getHRP()
                        if myHRP then
                            local dist = (hrp.Position - myHRP.Position).Magnitude
                            if dist > 20 then
                                teleportTo(hrp.Position)
                            end
                        end
                    end
                    attackMonster(target)
                    if State.autoSkill then useSkills() end
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(2)
            if State.autoStats then
                local gui = LocalPlayer:FindFirstChild("PlayerGui")
                if gui then
                    local gameGui = gui:FindFirstChild("GameGui")
                    if gameGui then
                        local stats = gameGui:FindFirstChild("Stats")
                        if stats then
                            local statsInner = stats:FindFirstChild("Stats")
                            if statsInner then
                                local spend = statsInner:FindFirstChild("SpendPoints")
                                if spend and spend:IsA("RemoteFunction") then
                                    pcall(function() spend:InvokeServer("Melee", 1) end)
                                    pcall(function() spend:InvokeServer("Defense", 1) end)
                                    pcall(function() spend:InvokeServer("Sword", 1) end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    local CODES = {
        "100KFavorites", "100KLikes", "100MVisits",
        "100KActive", "100KMembers", "Update4",
        "amogus", "rickastley", "SadNoob",
    }
    local codeIndex = 0
    task.spawn(function()
        while not UNLOADED do
            task.wait(1)
            if State.redeemCodes then
                codeIndex = codeIndex + 1
                if codeIndex > #CODES then
                    State.redeemCodes = false
                    codeIndex = 0
                else
                    local code = CODES[codeIndex]
                    local gui = LocalPlayer:FindFirstChild("PlayerGui")
                    if gui then
                        local gameGui = gui:FindFirstChild("GameGui")
                        if gameGui then
                            local settings = gameGui:FindFirstChild("Settings") or gameGui:FindFirstChild("Menu")
                            if settings then
                                for _, r in ipairs(settings:GetDescendants()) do
                                    if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                                        pcall(function() r:FireServer(code) end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(5)
            if State.autoStoreFruits then
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    for _, item in ipairs(backpack:GetChildren()) do
                        if item:IsA("Tool") and item:FindFirstChild("Fruit") then
                            local char = LocalPlayer.Character
                            if char then
                                pcall(function() item.Parent = char end)
                            end
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(0.2)
            if State.autoPopcat then
                local npcs = getNpcFolder()
                if npcs then
                    for _, npc in ipairs(npcs:GetChildren()) do
                        if npc.Name:lower():find("popcat") then
                            local pp = npc:FindFirstChildOfClass("ProximityPrompt")
                            if pp then
                                pcall(function() fireproximityprompt(pp) end)
                            end
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(60)
            if State.antiAfk then
                pcall(function() VirtualUser:CaptureController() end)
                pcall(function() VirtualUser:ClickButton2(Vector2.new(0, 0)) end)
            end
        end
    end)

    pcall(function()
        RunService.Heartbeat:Connect(function()
            if UNLOADED then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if State.speed and hum.WalkSpeed ~= State.speedValue then
                hum.WalkSpeed = State.speedValue
            end
            if State.jumpPower and hum.UseJumpPower and hum.JumpPower ~= State.jumpPowerValue then
                hum.JumpPower = State.jumpPowerValue
            end
            if State.fullbright then
                Lighting.Brightness = 3
                Lighting.Ambient = Color3.fromRGB(200,200,200)
                Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
                Lighting.ClockTime = 14
            end
            if State.noFog then
                Lighting.FogEnd = 1e6
                Lighting.FogStart = 0
            end
        end)
    end)

    local function restoreEnv()
        pcall(function()
            Lighting.Brightness = origBrightness
            Lighting.Ambient = origAmbient
            Lighting.OutdoorAmbient = origOutdoor
            Lighting.ClockTime = origClock
            Lighting.FogEnd = origFogEnd
            Lighting.FogStart = origFogStart
        end)
    end

    local function ensureFolder()
        if makefolder then
            pcall(function() if not isfolder(BASE_FOLDER) then makefolder(BASE_FOLDER) end end)
            pcall(function() if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end end)
        end
    end

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

    local function syncUIFromState()
        for _, k in ipairs({
            "autoFarmLevel","autoFarmNearest","autoAttack","autoSkill","collectDrops",
            "autoStoreFruits","autoStats","autoBoss","autoLordSus","autoGiantPumpkin",
            "autoEvilNoob","autoMemeBeast","autoRaidBoss","autoFloppa","autoPopcat",
            "redeemCodes","rollColor","farmFlashStep","speed","jumpPower","antiAfk",
            "fullbright","noFog",
        }) do
            local el = Elements[k]
            if el and State[k] ~= nil then setToggle(el, State[k]) end
        end
        for _, k in ipairs({"speedValue","jumpPowerValue"}) do
            local el = Elements[k]
            if el and State[k] ~= nil then setSlider(el, State[k]) end
        end
    end

    local function saveConfigNamed(name)
        ensureFolder()
        local data = {version = GAME_VERSION, state = {}}
        for k, v in pairs(State) do data.state[k] = v end
        local ok = pcall(function() writefile(CONFIG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
        if ok and Window then pcall(function() Window:Notify("💾", "Saved: " .. name, 3, "success") end) end
    end

    local function loadConfigNamed(name)
        local ok, c = pcall(function() return readfile(CONFIG_FOLDER .. "/" .. name .. ".json") end)
        if not ok or not c then return false end
        local s, data = pcall(function() return HttpService:JSONDecode(c) end)
        if not s or not data then return false end
        if data.state then for k, v in pairs(data.state) do State[k] = v end end
        syncUIFromState()
        if Window then pcall(function() Window:Notify("📂", "Loaded: " .. name, 3, "info") end) end
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

    local function buildUI()
        Window = UI:CreateWindow({
            Title = "INFINITE ZEN",
            Subtitle = SHORT_VERSION,
            ToggleKey = Enum.KeyCode.K,
        })
        Elements = {}

        local FarmTab = Window:CreateTab("Auto Farm", "🌾")
        FarmTab:CreateSection("Auto Farm")
        reg("autoFarmLevel", FarmTab:CreateToggle({
            Name = "Auto Farm Level",
            Description = "Farm monsters near your level",
            Icon = "📈", Default = false,
            Callback = function(v) State.autoFarmLevel = v end,
        }))
        reg("autoFarmNearest", FarmTab:CreateToggle({
            Name = "Auto Farm Nearest",
            Description = "Farm closest monster",
            Icon = "📍", Default = false,
            Callback = function(v) State.autoFarmNearest = v end,
        }))
        reg("autoAttack", FarmTab:CreateToggle({
            Name = "Auto Attack",
            Description = "Automatically attack monsters",
            Icon = "⚔️", Default = false,
            Callback = function(v) State.autoAttack = v end,
        }))
        reg("autoSkill", FarmTab:CreateToggle({
            Name = "Auto Use Skills",
            Description = "Automatically use all skills",
            Icon = "✨", Default = false,
            Callback = function(v) State.autoSkill = v end,
        }))
        reg("collectDrops", FarmTab:CreateToggle({
            Name = "Collect Drops",
            Description = "Auto collect items on ground",
            Icon = "🎁", Default = false,
            Callback = function(v) State.collectDrops = v end,
        }))
        reg("autoStoreFruits", FarmTab:CreateToggle({
            Name = "Auto Store Fruits",
            Description = "Automatically store fruits in inventory",
            Icon = "🍎", Default = false,
            Callback = function(v) State.autoStoreFruits = v end,
        }))
        FarmTab:CreateSection("Bosses")
        reg("autoBoss", FarmTab:CreateToggle({
            Name = "Auto Boss (Any)",
            Description = "Farm any boss automatically",
            Icon = "👑", Default = false,
            Callback = function(v) State.autoBoss = v end,
        }))
        reg("autoLordSus", FarmTab:CreateToggle({
            Name = "Auto Lord Sus",
            Description = "Farm Lord Sus boss",
            Icon = "🔴", Default = false,
            Callback = function(v) State.autoLordSus = v end,
        }))
        reg("autoGiantPumpkin", FarmTab:CreateToggle({
            Name = "Auto Giant Pumpkin",
            Description = "Farm Giant Pumpkin boss",
            Icon = "🎃", Default = false,
            Callback = function(v) State.autoGiantPumpkin = v end,
        }))
        reg("autoEvilNoob", FarmTab:CreateToggle({
            Name = "Auto Evil Noob",
            Description = "Farm Evil Noob boss",
            Icon = "👹", Default = false,
            Callback = function(v) State.autoEvilNoob = v end,
        }))
        reg("autoMemeBeast", FarmTab:CreateToggle({
            Name = "Auto Meme Beast",
            Description = "Farm Meme Beast world boss",
            Icon = "🐉", Default = false,
            Callback = function(v) State.autoMemeBeast = v end,
        }))
        reg("autoRaidBoss", FarmTab:CreateToggle({
            Name = "Auto Raid Boss",
            Description = "Farm raid bosses",
            Icon = "⚡", Default = false,
            Callback = function(v) State.autoRaidBoss = v end,
        }))

        local StatsTab = Window:CreateTab("Stats & Misc", "📊")
        StatsTab:CreateSection("Stats")
        reg("autoStats", StatsTab:CreateToggle({
            Name = "Auto Stats",
            Description = "Automatically spend stat points",
            Icon = "📊", Default = false,
            Callback = function(v) State.autoStats = v end,
        }))
        StatsTab:CreateSection("Auto Quest")
        reg("autoFloppa", StatsTab:CreateToggle({
            Name = "Auto Floppa Quest",
            Description = "Automatically complete Floppa quests",
            Icon = "🐱", Default = false,
            Callback = function(v) State.autoFloppa = v end,
        }))
        reg("autoPopcat", StatsTab:CreateToggle({
            Name = "Auto Popcat",
            Description = "Auto click Popcat NPC",
            Icon = "🐾", Default = false,
            Callback = function(v) State.autoPopcat = v end,
        }))
        StatsTab:CreateSection("Codes & Misc")
        reg("redeemCodes", StatsTab:CreateToggle({
            Name = "Redeem All Codes",
            Description = "Try to redeem all active codes",
            Icon = "🎟️", Default = false,
            Callback = function(v) State.redeemCodes = v end,
        }))
        reg("rollColor", StatsTab:CreateToggle({
            Name = "Roll Color",
            Description = "Auto roll colors",
            Icon = "🎨", Default = false,
            Callback = function(v) State.rollColor = v end,
        }))
        reg("farmFlashStep", StatsTab:CreateToggle({
            Name = "Farm Flash Step EXP",
            Description = "Auto farm Flash Step experience",
            Icon = "💨", Default = false,
            Callback = function(v) State.farmFlashStep = v end,
        }))

        local PlayerTab = Window:CreateTab("Player", "🏃")
        PlayerTab:CreateSection("Movement")
        reg("speed", PlayerTab:CreateToggle({
            Name = T("speed.name", "Speed"),
            Description = T("speed.desc", "Custom walkspeed"),
            Icon = "⚡", Default = false,
            Callback = function(v) State.speed = v end,
        }))
        reg("speedValue", PlayerTab:CreateSlider({
            Name = T("speedvalue.name", "Speed Value"),
            Description = T("speedvalue.desc", "WalkSpeed value"),
            Icon = "📏", Min = 16, Max = 200, Default = 50,
            Callback = function(v) State.speedValue = v end,
        }))
        reg("jumpPower", PlayerTab:CreateToggle({
            Name = T("jumppower.name", "Jump Power"),
            Description = T("jumppower.desc", "Custom jump velocity"),
            Icon = "🦘", Default = false,
            Callback = function(v) State.jumpPower = v end,
        }))
        reg("jumpPowerValue", PlayerTab:CreateSlider({
            Name = T("jumppower.value.name", "Jump Value"),
            Description = T("jumppower.value.desc", "JumpPower value"),
            Icon = "📏", Min = 30, Max = 200, Default = 80,
            Callback = function(v) State.jumpPowerValue = v end,
        }))
        reg("antiAfk", PlayerTab:CreateToggle({
            Name = T("antiafk.name", "Anti-AFK"),
            Description = T("antiafk.desc", "Prevent kick for inactivity"),
            Icon = "🛡️", Default = false,
            Callback = function(v) State.antiAfk = v end,
        }))

        local VisualTab = Window:CreateTab("Visuals", "👁️")
        VisualTab:CreateSection("Environment")
        reg("fullbright", VisualTab:CreateToggle({
            Name = T("fullbright.name", "Fullbright"),
            Description = T("fullbright.desc", "Map always bright"),
            Icon = "💡", Default = false,
            Callback = function(v) State.fullbright = v; if not v then restoreEnv() end end,
        }))
        reg("noFog", VisualTab:CreateToggle({
            Name = T("nofog.name", "No Fog"),
            Description = T("nofog.desc", "Remove fog"),
            Icon = "🌫️", Default = false,
            Callback = function(v) State.noFog = v; if not v then restoreEnv() end end,
        }))

        local SettingsTab = Window:CreateTab("Settings", "⚙️")
        SettingsTab:CreateSection("Config")

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
        cInput.PlaceholderText = T("config.placeholder", "Config name + Enter")
        cInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
        cInput.Text = ""
        cInput.ClearTextOnFocus = false
        cInput.TextXAlignment = Enum.TextXAlignment.Left

        local listFrame = Instance.new("Frame", SettingsTab.container)
        listFrame.Size = UDim2.new(1, 0, 0, 140)
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
                e.Text = T("config.empty", "No saved configs yet.")
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

        SettingsTab:CreateButton({ Name = T("config.refresh", "Refresh List"), Callback = function() refreshList() end })
        refreshList()

        SettingsTab:CreateSection("Danger Zone")
        SettingsTab:CreateButton({
            Name = T("config.unload", "Unload Script"),
            Danger = true,
            Callback = function()
                UNLOADED = true
                restoreEnv()
                if Window then pcall(function() Window:Notify("Unload", "Unloaded", 2, "warning") end) end
                task.wait(0.3)
                if Window then pcall(function() Window:Destroy() end) end
            end,
        })

        local LanguageTab = Window:CreateTab("Language", "🌍")
        LanguageTab:CreateSection("Select Language")
        local available = Language.getAvailable()
        local cur = Language.getCurrent()
        local opts = {}
        local defIdx = 1
        for i, info in ipairs(available) do
            table.insert(opts, info.flag .. " " .. info.displayName)
            if info.code == cur then defIdx = i end
        end
        LanguageTab:CreateDropdown({
            Name = T("tab.language", "Language"),
            Description = T("lang.hint", "Pick menu language"),
            Icon = "🌍", Options = opts, Default = defIdx,
            Callback = function(_, idx)
                local info = available[idx]
                if info then Language.setLanguage(info.code) end
            end,
        })

        local CreditsTab = Window:CreateTab("Credits", "➕")
        CreditsTab:CreateSection("Founder")
        CreditsTab:CreateLabel(T("credits.role", "Sr Red"), Color3.fromRGB(255, 50, 50))
        CreditsTab:CreateSection("Community")
        CreditsTab:CreateLabel("discord.gg/ScZfU2mAGm", Color3.fromRGB(88, 101, 242))
        CreditsTab:CreateButton({
            Name = T("credits.copy_discord", "Copy Discord Link"),
            Callback = function()
                if setclipboard then
                    pcall(setclipboard, "https://discord.gg/ScZfU2mAGm")
                    pcall(function() Window:Notify("📋", "Copied!", 2, "success") end)
                end
            end,
        })
        CreditsTab:CreateSection("Version")
        CreditsTab:CreateLabel(FULL_VERSION, Color3.fromRGB(140, 140, 155))
        CreditsTab:CreateLabel("© 2026 Sr Red", Color3.fromRGB(90, 90, 105))
    end

    local rebuilding = false
    _G.IZ_RefreshLanguage_MemeSea = function()
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
    if Language and type(Language.onChange) == "function" then
        pcall(function() Language.onChange(_G.IZ_RefreshLanguage_MemeSea) end)
    end

    buildUI()
    syncUIFromState()

    task.defer(function()
        local a = getAutoload()
        if a then task.wait(1); loadConfigNamed(a) end
    end)

    if Window then
        pcall(function() Window:Notify("✅ " .. SHORT_VERSION, "MemeSea loaded", 4, "success") end)
    end

    print("============================================")
    print("[Infinite Zen] 🇧🇷 " .. FULL_VERSION .. " carregado com sucesso!")
    print("[Infinite Zen] 🇺🇸 " .. FULL_VERSION .. " loaded successfully!")
    print("============================================")
end

return MemeSea