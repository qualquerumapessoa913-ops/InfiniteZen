-- ============================================================
-- Infinite Zen - MemeSea - V1.0
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

    local GAME_VERSION  = "1.0"
    local FULL_VERSION  = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("============================================")
    print("[Infinite Zen] 🇧🇷 Inicializando " .. FULL_VERSION .. "...")
    print("[Infinite Zen] 🇺🇸 Initializing " .. FULL_VERSION .. "...")
    print("============================================")

    local Players     = game:GetService("Players")
    local RunService  = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local Lighting    = game:GetService("Lighting")
    local VirtualUser = game:GetService("VirtualUser")
    local LocalPlayer = Players.LocalPlayer

    local UNLOADED = false

    local RS         = game:GetService("ReplicatedStorage")
    local OtherEvent = RS:WaitForChild("OtherEvent", 15)
    if not OtherEvent then warn("[MemeSea] OtherEvent not found") end
    local MainEvents  = OtherEvent and OtherEvent:FindFirstChild("MainEvents")
    local MiscEvents  = OtherEvent and OtherEvent:FindFirstChild("MiscEvents")
    local QuestEvents = OtherEvent and OtherEvent:FindFirstChild("QuestEvents")

    local PlayerData = LocalPlayer:WaitForChild("PlayerData", 30)
    local QuestTracker = PlayerData and PlayerData:WaitForChild("Quest_Tracker", 15)

    local ModuleFolder    = RS:FindFirstChild("ModuleScript")
    local QuestSettings   = nil
    local MonsterSettings = nil

    task.spawn(function()
        if ModuleFolder then
            local ok, m
            ok, m = pcall(function() return require(ModuleFolder:WaitForChild("Quest_Settings", 10)) end)
            if ok then QuestSettings = m end
            ok, m = pcall(function() return require(ModuleFolder:WaitForChild("MonsterSettings", 10)) end)
            if ok then MonsterSettings = m end
        end
    end)

    local State = {
        autoQuestFarm = false,
        autoBoss = false,
        fastAttack = false,
        autoStats = false,
        statPriority = "Melee",
        statPointsPerTick = 1,
        speed = false, speedValue = 50,
        jumpPower = false, jumpPowerValue = 80,
        antiAfk = false,
        fullbright = false,
        noFog = false,
        debugQuest = false,
        debugStats = false,
        attackCD = 0.15,
        teleportDistance = 6,
        questFarm = {
            state = "idle",
            currentQuest = nil,
            currentTarget = nil,
            lastMobSeen = 0,
            lastNpcVisit = 0,
        },
    }

    local origBrightness = Lighting.Brightness
    local origAmbient    = Lighting.Ambient
    local origOutdoor    = Lighting.OutdoorAmbient
    local origClock      = Lighting.ClockTime
    local origFogEnd     = Lighting.FogEnd
    local origFogStart   = Lighting.FogStart

    local function log(...)
        if State.debugQuest then print("[MemeSea]", ...) end
    end

    local function logStats(...)
        if State.debugStats then print("[MemeSea][STATS]", ...) end
    end

    local function getHRP()
        local c = LocalPlayer.Character
        if not c then return nil end
        return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
    end

    local function getMobHRP(mob)
        if not mob then return nil end
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then return hrp end
        local ut = mob:FindFirstChild("UpperTorso") or mob:FindFirstChild("Torso")
        if ut and ut:IsA("BasePart") then return ut end
        local head = mob:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
        if mob:IsA("Model") and mob.PrimaryPart then return mob.PrimaryPart end
        return nil
    end

    local function isMobAlive(mob)
        if not mob or not mob.Parent then return false end
        local hum = mob:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end

    local function equipCombat()
        local char = LocalPlayer.Character
        if not char then return nil end
        if char:FindFirstChild("Combat") then return char:FindFirstChild("Combat") end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return nil end
        local tool = bp:FindFirstChild("Combat")
        if tool and tool:IsA("Tool") then
            pcall(function() hum:EquipTool(tool) end)
            return tool
        end
        return nil
    end

    local function doAttack()
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChild("Combat") or equipCombat()
        if not tool then return end
        pcall(function() tool:Activate() end)
    end

    local function faceMob(mob)
        local hrp = getMobHRP(mob)
        local myHRP = getHRP()
        if not hrp or not myHRP then return end
        local myPos = myHRP.Position
        local mobPos = hrp.Position
        local target = CFrame.lookAt(myPos, Vector3.new(mobPos.X, myPos.Y, mobPos.Z))
        local dist = (mobPos - myPos).Magnitude
        if dist > State.teleportDistance then
            local newPos = mobPos - (target.LookVector * State.teleportDistance)
            target = CFrame.new(newPos, Vector3.new(mobPos.X, newPos.Y, mobPos.Z))
        end
        pcall(function() myHRP.CFrame = target end)
    end

    local function attackMob(mob)
        if not mob or not mob.Parent then return end
        local hrp = getMobHRP(mob)
        local myHRP = getHRP()
        if not hrp or not myHRP then return end
        local dist = (hrp.Position - myHRP.Position).Magnitude
        if dist > State.teleportDistance then
            faceMob(mob)
            task.wait(0.05)
        end
        doAttack()
    end

    -- ============================================================
    -- FAST ATTACK
    -- ============================================================
    local function zeroDebounce()
        local char = LocalPlayer.Character
        if not char then return end
        local stun = char:FindFirstChild("Stun")
        if stun and stun:IsA("NumberValue") and stun.Value > 0 then
            pcall(function() stun.Value = 0 end)
        end
        local deb = char:FindFirstChild("Attacks_Debounce")
        if deb then
            for _, v in ipairs(deb:GetChildren()) do
                pcall(function()
                    if v:IsA("NumberValue") or v:IsA("IntValue") then
                        if v.Value > 0 then v.Value = 0 end
                    elseif v:IsA("BoolValue") then
                        if v.Value then v.Value = false end
                    end
                end)
            end
        end
    end

    local fastAttackThread = nil
    local function startFastAttack()
        if fastAttackThread then return end
        fastAttackThread = task.spawn(function()
            while not UNLOADED do
                task.wait(0.05)
                if State.fastAttack then
                    -- Layer 1: attributes visuais
                    pcall(function()
                        LocalPlayer:SetAttribute("NoCooldown", true)
                        LocalPlayer:SetAttribute("No_CooldownBar", true)
                    end)
                    -- Layer 2: zerar debounce/stun
                    zeroDebounce()
                    -- Layer 3: spam do tool Combat
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChild("Combat")
                        if tool then
                            pcall(function() tool:Activate() end)
                        end
                    end
                end
            end
        end)
    end
    startFastAttack()

    local function restoreFastAttack()
        pcall(function()
            LocalPlayer:SetAttribute("NoCooldown", nil)
            LocalPlayer:SetAttribute("No_CooldownBar", nil)
        end)
    end

    -- ============================================================
    -- AUTO STATS
    -- ============================================================
    local STAT_OPTIONS = {"Balanced", "Melee", "Defense", "Sword", "MemePower"}
    local STAT_TARGETS = {
        Melee     = "MeleeLevel",
        Defense   = "DefenseLevel",
        Sword     = "SwordLevel",
        MemePower = "MemePowerLevel",
    }

    local function getSkillPoints()
        local v = PlayerData and PlayerData:FindFirstChild("SkillPoint")
        return v and v.Value or 0
    end

    local function tryUpgrade(targetKey, amount)
        local sf = MainEvents and MainEvents:FindFirstChild("StatsFunction")
        if not sf then
            logStats("StatsFunction not found")
            return false
        end

        local formats = {
            { Action = "UpgradeStats", Target = targetKey, Amount = amount },
            { Action = "UpgradeStats", Target = targetKey, amount = amount },
        }

        for i, payload in ipairs(formats) do
            local ok = pcall(function() sf:InvokeServer(payload) end)
            logStats("Format " .. i .. " (" .. targetKey .. " x" .. amount .. ") → " .. tostring(ok))
            if ok then return true end
        end
        return false
    end

    task.spawn(function()
        while not UNLOADED do
            task.wait(1.5)
            if State.autoStats then
                local sp = getSkillPoints()
                logStats("SkillPoint = " .. tostring(sp))
                if sp and sp > 0 then
                    local chosen = State.statPriority
                    local chosenKey

                    if chosen == "Balanced" then
                        local lowest = nil
                        local lowestVal = math.huge
                        for name, key in pairs(STAT_TARGETS) do
                            local val = PlayerData:FindFirstChild(key)
                            if val and val.Value < lowestVal then
                                lowestVal = val.Value
                                lowest = name
                            end
                        end
                        chosenKey = STAT_TARGETS[lowest or "Melee"]
                    else
                        chosenKey = STAT_TARGETS[chosen]
                    end

                    if chosenKey then
                        local amount = math.min(sp, State.statPointsPerTick)
                        if amount < 1 then amount = 1 end
                        tryUpgrade(chosenKey, amount)
                    end
                end
            end
        end
    end)

    -- ============================================================
    -- AUTO QUEST FARM / AUTO BOSS
    -- ============================================================
    local function getActiveQuest()
        if not QuestTracker then return nil end
        local v = tostring(QuestTracker.Value or "None")
        if v == "None" or v == "" then return nil end
        return v
    end

    local function getQuestInfo(name)
        if not QuestSettings or not name then return nil end
        return QuestSettings[name]
    end

    local function isBossQuest(name)
        local info = getQuestInfo(name)
        return info and info.Raid_Boss == true
    end

    local function mobNameMatches(mobName, targetName)
        if not mobName or not targetName then return false end
        if mobName == targetName then return true end
        local a = mobName:lower()
        local b = targetName:lower()
        if a == b then return true end
        if a:find(b, 1, true) or b:find(a, 1, true) then return true end
        return false
    end

    local function findTargetMob(targetName)
        local folder = workspace:FindFirstChild("Monster")
        if not folder then return nil end
        local myHRP = getHRP()
        if not myHRP then return nil end
        local best, bestDist = nil, math.huge
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and isMobAlive(mob) then
                if mobNameMatches(mob.Name, targetName) then
                    local hrp = getMobHRP(mob)
                    if hrp then
                        local d = (hrp.Position - myHRP.Position).Magnitude
                        if d < bestDist then bestDist = d; best = mob end
                    end
                end
            end
        end
        return best
    end

    local function findAnyMob()
        local folder = workspace:FindFirstChild("Monster")
        if not folder then return nil end
        local myHRP = getHRP()
        if not myHRP then return nil end
        local best, bestDist = nil, math.huge
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and isMobAlive(mob) then
                local hrp = getMobHRP(mob)
                if hrp then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d < bestDist then bestDist = d; best = mob end
                end
            end
        end
        return best
    end

    local function teleportToQuestNpc()
        local npcs = workspace:FindFirstChild("NPCs")
        if not npcs then return false end
        local qf = npcs:FindFirstChild("Quests_Npc") or npcs:FindFirstChild("Quest_Npc")
        if not qf then
            for _, sub in ipairs(npcs:GetChildren()) do
                if sub:IsA("Folder") and sub.Name:lower():find("quest") then
                    qf = sub
                    break
                end
            end
        end
        if not qf then return false end
        local myHRP = getHRP()
        if not myHRP then return false end
        for _, npc in ipairs(qf:GetChildren()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
            if hrp then
                pcall(function()
                    myHRP.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 0, 3), hrp.Position)
                end)
                task.wait(0.3)
                for _, d in ipairs(npc:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        pcall(function() fireproximityprompt(d) end)
                    end
                end
                return true
            end
        end
        return false
    end

    task.spawn(function()
        while not UNLOADED do
            task.wait(0.2)
            local active = State.autoQuestFarm or State.autoBoss

            if not active then
                State.questFarm.state = "idle"
                task.wait(0.5)
            else
                local qf = State.questFarm
                local now = tick()
                local cur = getActiveQuest()

                if qf.state == "idle" then
                    if cur then
                        local info = getQuestInfo(cur)
                        if State.autoBoss and not isBossQuest(cur) then
                            qf.state = "getQuest"
                            log("Not boss quest, rolling")
                        else
                            qf.currentQuest = cur
                            qf.currentTarget = info and info.Target or nil
                            qf.state = "farming"
                            qf.lastMobSeen = now
                            log("Farming:", cur, "| target:", qf.currentTarget or "ANY")
                        end
                    else
                        qf.state = "getQuest"
                        log("No quest - grabbing")
                    end

                elseif qf.state == "getQuest" then
                    if now - qf.lastNpcVisit > 4 then
                        qf.lastNpcVisit = now
                        log("Teleporting to NPC")
                        teleportToQuestNpc()
                        task.wait(2)
                        local newCur = getActiveQuest()
                        if newCur then
                            local info = getQuestInfo(newCur)
                            qf.currentQuest = newCur
                            qf.currentTarget = info and info.Target or nil
                            qf.state = "farming"
                            qf.lastMobSeen = tick()
                            log("Quest grabbed:", newCur, "| target:", qf.currentTarget or "ANY")
                        end
                    else
                        task.wait(0.5)
                    end

                elseif qf.state == "farming" then
                    if not cur then
                        qf.state = "idle"
                        task.wait(0.5)
                    else
                        if cur ~= qf.currentQuest then
                            local info = getQuestInfo(cur)
                            qf.currentQuest = cur
                            qf.currentTarget = info and info.Target or nil
                            log("Quest changed:", cur, "| target:", qf.currentTarget or "ANY")
                        end

                        local mob = nil
                        if qf.currentTarget then
                            mob = findTargetMob(qf.currentTarget)
                        end

                        if not mob and (now - qf.lastMobSeen > 5) then
                            mob = findAnyMob()
                        end

                        if mob then
                            qf.lastMobSeen = now
                            attackMob(mob)
                        else
                            if now - qf.lastMobSeen > 15 then
                                qf.state = "complete"
                                log("No mobs - completing")
                            end
                        end
                    end
                    task.wait(State.attackCD)

                elseif qf.state == "complete" then
                    log("Completing quest")
                    teleportToQuestNpc()
                    task.wait(2)
                    local afterCur = getActiveQuest()
                    if not afterCur or afterCur ~= qf.currentQuest then
                        qf.state = "idle"
                        qf.currentQuest = nil
                        qf.currentTarget = nil
                        log("Quest completed")
                    else
                        qf.state = "farming"
                        qf.lastMobSeen = tick()
                    end
                    task.wait(1)
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(1)
            local char = LocalPlayer.Character
            if char and not char:FindFirstChild("Combat") then equipCombat() end
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
            if State.speed and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
            if State.jumpPower and hum.UseJumpPower and hum.JumpPower ~= State.jumpPowerValue then hum.JumpPower = State.jumpPowerValue end
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

    local BASE_FOLDER   = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/MemeSea"
    local AUTOLOAD_FILE = "InfiniteZen_MemeSea_Autoload.txt"

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
            "autoQuestFarm","autoBoss","fastAttack","autoStats",
            "speed","jumpPower","antiAfk","fullbright","noFog",
            "debugQuest","debugStats",
        }) do
            local el = Elements[k]
            if el and State[k] ~= nil then setToggle(el, State[k]) end
        end
        for _, k in ipairs({"speedValue","jumpPowerValue","attackCD","teleportDistance","statPointsPerTick"}) do
            local el = Elements[k]
            if el and State[k] ~= nil then setSlider(el, State[k]) end
        end
    end

    local function saveConfigNamed(name)
        ensureFolder()
        local data = {version = GAME_VERSION, state = {}}
        for k, v in pairs(State) do
            if k ~= "questFarm" then data.state[k] = v end
        end
        local ok = pcall(function() writefile(CONFIG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
        if ok and Window then pcall(function() Window:Notify("💾", "Saved: " .. name, 3, "success") end) end
    end

    local function loadConfigNamed(name)
        local ok, c = pcall(function() return readfile(CONFIG_FOLDER .. "/" .. name .. ".json") end)
        if not ok or not c then return false end
        local s, data = pcall(function() return HttpService:JSONDecode(c) end)
        if not s or not data or not data.state then return false end
        for k, v in pairs(data.state) do
            if State[k] ~= nil and k ~= "questFarm" then State[k] = v end
        end
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
        FarmTab:CreateSection("Quest")
        reg("autoQuestFarm", FarmTab:CreateToggle({
            Name = "Auto Quest Farm",
            Description = "Grab quest, kill mobs, complete, repeat",
            Icon = "🌟", Default = false,
            Callback = function(v) State.autoQuestFarm = v; State.questFarm.state = "idle" end,
        }))
        reg("autoBoss", FarmTab:CreateToggle({
            Name = "Auto Boss",
            Description = "Only farm boss quests",
            Icon = "👹", Default = false,
            Callback = function(v) State.autoBoss = v; State.questFarm.state = "idle" end,
        }))
        reg("fastAttack", FarmTab:CreateToggle({
            Name = "Fast Attack",
            Description = "Remove melee cooldown",
            Icon = "⚡", Default = false,
            Callback = function(v)
                State.fastAttack = v
                if not v then restoreFastAttack() end
            end,
        }))
        reg("debugQuest", FarmTab:CreateToggle({
            Name = "Debug Quest",
            Description = "Print quest logs",
            Icon = "🐛", Default = false,
            Callback = function(v) State.debugQuest = v end,
        }))
        FarmTab:CreateSection("Tuning")
        reg("attackCD", FarmTab:CreateSlider({
            Name = "Attack Delay",
            Description = "Seconds between attacks",
            Icon = "⏱️", Min = 0.05, Max = 1, Default = 0.15,
            Callback = function(v) State.attackCD = v end,
        }))
        reg("teleportDistance", FarmTab:CreateSlider({
            Name = "Teleport Distance",
            Description = "How close to teleport",
            Icon = "📏", Min = 2, Max = 20, Default = 6,
            Callback = function(v) State.teleportDistance = v end,
        }))

        local ProgressTab = Window:CreateTab("Progress", "📈")
        ProgressTab:CreateSection("Stats")
        reg("autoStats", ProgressTab:CreateToggle({
            Name = "Auto Stats",
            Description = "Spend points automatically",
            Icon = "📊", Default = false,
            Callback = function(v) State.autoStats = v end,
        }))
        ProgressTab:CreateDropdown({
            Name = "Stat Priority",
            Description = "Which stat to upgrade",
            Icon = "🎯", Options = STAT_OPTIONS, Default = 1,
            Callback = function(_, idx)
                State.statPriority = STAT_OPTIONS[idx] or "Balanced"
            end,
        })
        reg("statPointsPerTick", ProgressTab:CreateSlider({
            Name = "Points Per Cycle",
            Description = "How many points to spend each cycle",
            Icon = "🔢", Min = 1, Max = 50, Default = 1,
            Callback = function(v) State.statPointsPerTick = v end,
        }))
        reg("debugStats", ProgressTab:CreateToggle({
            Name = "Debug Stats",
            Description = "Print stats logs",
            Icon = "🐛", Default = false,
            Callback = function(v) State.debugStats = v end,
        }))

        local PlayerTab = Window:CreateTab("Player", "🏃")
        PlayerTab:CreateSection("Movement")
        reg("speed", PlayerTab:CreateToggle({
            Name = "Speed", Description = "Custom walkspeed",
            Icon = "⚡", Default = false,
            Callback = function(v) State.speed = v end,
        }))
        reg("speedValue", PlayerTab:CreateSlider({
            Name = "Speed Value", Description = "WalkSpeed",
            Icon = "📏", Min = 16, Max = 200, Default = 50,
            Callback = function(v) State.speedValue = v end,
        }))
        reg("jumpPower", PlayerTab:CreateToggle({
            Name = "Jump Power", Description = "Custom jump",
            Icon = "🦘", Default = false,
            Callback = function(v) State.jumpPower = v end,
        }))
        reg("jumpPowerValue", PlayerTab:CreateSlider({
            Name = "Jump Value", Description = "JumpPower",
            Icon = "📏", Min = 30, Max = 200, Default = 80,
            Callback = function(v) State.jumpPowerValue = v end,
        }))
        reg("antiAfk", PlayerTab:CreateToggle({
            Name = "Anti-AFK", Description = "Prevent kick",
            Icon = "🛡️", Default = false,
            Callback = function(v) State.antiAfk = v end,
        }))

        local VisualTab = Window:CreateTab("Visuals", "👁️")
        VisualTab:CreateSection("Environment")
        reg("fullbright", VisualTab:CreateToggle({
            Name = "Fullbright", Description = "Bright map",
            Icon = "💡", Default = false,
            Callback = function(v) State.fullbright = v; if not v then restoreEnv() end end,
        }))
        reg("noFog", VisualTab:CreateToggle({
            Name = "No Fog", Description = "Remove fog",
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
        cInput.PlaceholderText = "Config name + Enter"
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
                e.Text = "No saved configs yet."
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

        SettingsTab:CreateButton({ Name = "Refresh List", Callback = function() refreshList() end })
        refreshList()

        SettingsTab:CreateSection("Danger Zone")
        SettingsTab:CreateButton({
            Name = "Unload Script",
            Danger = true,
            Callback = function()
                UNLOADED = true
                restoreFastAttack()
                restoreEnv()
                if Window then pcall(function() Window:Notify("Unload", "Unloaded", 2, "warning") end) end
                task.wait(0.3)
                if Window then Window:Destroy() end
            end,
        })

        local CreditsTab = Window:CreateTab("Credits", "➕")
        CreditsTab:CreateSection("Founder")
        CreditsTab:CreateLabel("Sr Red", Color3.fromRGB(255, 50, 50))
        CreditsTab:CreateSection("Community")
        CreditsTab:CreateLabel("discord.gg/ScZfU2mAGm", Color3.fromRGB(88, 101, 242))
        CreditsTab:CreateButton({
            Name = "Copy Discord Link",
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