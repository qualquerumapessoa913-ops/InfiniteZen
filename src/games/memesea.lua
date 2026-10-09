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

    local RS          = game:GetService("ReplicatedStorage")
    local OtherEvent  = RS:WaitForChild("OtherEvent", 15)
    if not OtherEvent then
        warn("[MemeSea] ❌ OtherEvent not found")
    end
    local MainEvents  = OtherEvent and OtherEvent:FindFirstChild("MainEvents")
    local SkillEvents = OtherEvent and OtherEvent:FindFirstChild("SkillEvents")
    local MiscEvents  = OtherEvent and OtherEvent:FindFirstChild("MiscEvents")
    local QuestEvents = OtherEvent and OtherEvent:FindFirstChild("QuestEvents")

    local SKIP_MOBS = {
        ["Training Log"] = true,
        ["Raid"] = true,
        ["RaidArea"] = true,
        ["Raid_Area"] = true,
    }

    local CLOSE_GUI_KEYWORDS = {"shop", "purchase", "dialog", "questscroll", "quest_scroll", "auracolor", "aura_color"}

    local State = {
        autoAttack = false,
        autoFarmNearest = false,
        farmSelected = false,
        autoQuestFarm = false,
        selectedMob = "Any",
        autoSkill = false,
        collectDrops = false,
        autoQuest = false,
        autoStats = false,
        statPriority = "Melee",
        autoRedeem = false,
        autoPopcat = false,
        autoStartRaid = false,
        autoGacha = false,
        autoLuck = false,
        speed = false, speedValue = 50,
        jumpPower = false, jumpPowerValue = 80,
        antiAfk = false,
        fullbright = false,
        noFog = false,
        bringMob = false,
        autoEquipCombat = true,
        includeTrainingLog = false,
        autoCloseGui = true,
        debugQuest = true,
        maxLevelDiff = 5,
        skillZ_CD = 2.0,
        skillX_CD = 5.0,
        skillC_CD = 8.0,
        skillV_CD = 12.0,
        levelCacheTTL = 3,
        questFarm = {
            currentQuest = "None",
            currentTarget = nil,
            state = "idle",
            lastQuestRequest = 0,
            lastCompleteAttempt = 0,
            lastMobSeen = 0,
            attempts = 0,
            closedGuis = {},
        },
    }

    local MOB_LIST = {
        "Any", "Floppa", "Big Floppa", "Golden Floppa", "Doge", "Cheems",
        "Walter Dog", "Sogga", "Egg Dog", "Gigachad", "Sus Duck", "Banana Cat",
        "Meme Beast", "Training Log", "Killerfish", "Smiling Cat", "Bingus",
    }

    local CODES = {
        "100KFavorites", "100KLikes", "100MVisits", "100KActive",
        "100KMembers", "Update4", "amogus", "rickastley", "SadNoob",
        "Floppa", "Popcat", "MemeSea", "RELEASE",
    }

    local origBrightness = Lighting.Brightness
    local origAmbient    = Lighting.Ambient
    local origOutdoor    = Lighting.OutdoorAmbient
    local origClock      = Lighting.ClockTime
    local origFogEnd     = Lighting.FogEnd
    local origFogStart   = Lighting.FogStart

    local levelCache = {}
    local levelCacheTimes = {}

    local function log(...)
        if State.debugQuest then print("[MemeSea]", ...) end
    end

    local function getPD()
        return LocalPlayer:FindFirstChild("PlayerData")
    end

    local function pdValue(name, default)
        local pd = getPD()
        if not pd then return default end
        local v = pd:FindFirstChild(name)
        if v and v:IsA("ValueBase") then return v.Value end
        return default
    end

    local function getHRP()
        local c = LocalPlayer.Character
        if not c then return nil end
        return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
    end

    local function getMonsterFolder()
        return workspace:FindFirstChild("Monster")
    end

    local function getMonsterHRP(mob)
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
        if hum then return hum.Health > 0 end
        return true
    end

    local function parseLevelFromText(text)
        if not text or text == "" then return 0 end
        local patterns = {
            "[Ll][Vv]%.?%s*(%d+)",
            "[Ll]evel%s*(%d+)",
            "%[%s*(%d+)%s*%]",
            "(%d+)%s*[Ll][Vv]",
        }
        for _, p in ipairs(patterns) do
            local lvl = text:match(p)
            if lvl then return tonumber(lvl) or 0 end
        end
        return 0
    end

    local function getMobLevel(mob)
        if not mob then return 0 end
        local now = tick()
        local cached = levelCache[mob]
        local cacheTime = levelCacheTimes[mob] or 0
        if cached and (now - cacheTime) < State.levelCacheTTL then
            return cached
        end
        local lv = mob:FindFirstChild("Level") or mob:FindFirstChild("LevelValue")
        if lv and lv:IsA("ValueBase") then
            local v = tonumber(lv.Value) or 0
            levelCache[mob] = v
            levelCacheTimes[mob] = now
            return v
        end
        for _, d in ipairs(mob:GetDescendants()) do
            if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
                for _, t in ipairs(d:GetDescendants()) do
                    if t:IsA("TextLabel") and t.Text and t.Text ~= "" then
                        local parsed = parseLevelFromText(t.Text)
                        if parsed > 0 then
                            levelCache[mob] = parsed
                            levelCacheTimes[mob] = now
                            return parsed
                        end
                    end
                end
            end
        end
        levelCache[mob] = 0
        levelCacheTimes[mob] = now
        return 0
    end

    local function mobMatches(mob, forceTarget)
        if not mob then return false end
        local name = mob.Name
        if SKIP_MOBS[name] and not State.includeTrainingLog then return false end
        local target = forceTarget or State.selectedMob
        if target == "Any" or target == nil then return true end
        local nl = name:lower()
        local tl = target:lower()
        if nl == tl then return true end
        if nl:find(tl, 1, true) and #tl >= 4 then return true end
        return false
    end

    local function isMobSafe(mob)
        local myLevel = pdValue("Level", 1)
        local mobLevel = getMobLevel(mob)
        if mobLevel == 0 then return false end
        return mobLevel <= (myLevel + State.maxLevelDiff)
    end

    local function getNearestMob(forceTarget)
        local folder = getMonsterFolder()
        local myHRP = getHRP()
        if not folder or not myHRP then return nil end
        local closest, minDist = nil, math.huge
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and isMobAlive(mob) then
                if mobMatches(mob, forceTarget) and isMobSafe(mob) then
                    local hrp = getMonsterHRP(mob)
                    if hrp then
                        local d = (hrp.Position - myHRP.Position).Magnitude
                        if d < minDist then minDist = d; closest = mob end
                    end
                end
            end
        end
        return closest
    end

    local function equipCombat()
        if not State.autoEquipCombat then return end
        local char = LocalPlayer.Character
        if not char then return end
        if char:FindFirstChild("Combat") then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return end
        local tool = bp:FindFirstChild("Combat")
        if tool and tool:IsA("Tool") then
            pcall(function() hum:EquipTool(tool) end)
        end
    end

    local function fireSword(mob)
        if not MainEvents then return false end
        local sword = MainEvents:FindFirstChild("Sword")
        if not sword then return false end
        local hrp = getMonsterHRP(mob)
        if not hrp then return false end
        local ok = pcall(function() sword:InvokeServer(hrp) end)
        if not ok then
            pcall(function() sword:InvokeServer(hrp.Position) end)
        end
        return true
    end

    local function fireHitbox(mob)
        if not SkillEvents then return false end
        local hb = SkillEvents:FindFirstChild("Server_Hitbox")
        if not hb then return false end
        local hrp = getMonsterHRP(mob)
        if not hrp then return false end
        pcall(function() hb:FireServer(hrp) end)
        return true
    end

    local function useToolActivate()
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
    end

    local lastSkillTimes = {Z = 0, X = 0, C = 0, V = 0}

    local function pressKey(keyName, cooldownSec)
        local now = tick()
        if now - (lastSkillTimes[keyName] or 0) < cooldownSec then return end
        lastSkillTimes[keyName] = now
        local key = Enum.KeyCode[keyName]
        if not key then return end
        pcall(function()
            VirtualInput:SendKeyEvent(true, key, false)
            task.wait(0.05)
            VirtualInput:SendKeyEvent(false, key, false)
        end)
    end

    local function useSkills()
        pressKey("Z", State.skillZ_CD)
        pressKey("X", State.skillX_CD)
        pressKey("C", State.skillC_CD)
        pressKey("V", State.skillV_CD)
    end

    local function attackMob(mob)
        if not mob then return end
        local hrp = getMonsterHRP(mob)
        if not hrp then return end
        local myHRP = getHRP()
        if myHRP then
            local dist = (hrp.Position - myHRP.Position).Magnitude
            if dist > 20 then
                pcall(function()
                    myHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, 6)
                end)
            end
        end
        fireSword(mob)
        fireHitbox(mob)
        useToolActivate()
    end

    local function closeExtraGuis()
        if not State.autoCloseGui then return end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        local qf = State.questFarm
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                local name = gui.Name:lower()
                if name:find("izm") or name:find("infinitezen") then
                elseif name:find("chat") or name:find("core") or name:find("hud") or name:find("main") or name:find("quest") then
                else
                    for _, kw in ipairs(CLOSE_GUI_KEYWORDS) do
                        if name:find(kw, 1, true) then
                            if not qf.closedGuis[gui] then
                                qf.closedGuis[gui] = true
                            end
                            gui.Enabled = false
                            break
                        end
                    end
                end
            end
        end
    end

    local function restoreClosedGuis()
        local qf = State.questFarm
        for gui, _ in pairs(qf.closedGuis) do
            if gui and gui.Parent then
                pcall(function() gui.Enabled = true end)
            end
        end
        qf.closedGuis = {}
    end

    local QUEST_MOB_MAP = {
        ["Floppa"] = "Floppa",
        ["Big Floppa"] = "Big Floppa",
        ["Golden Floppa"] = "Golden Floppa",
        ["Doge"] = "Doge",
        ["Cheems"] = "Cheems",
        ["Walter"] = "Walter Dog",
        ["Walter Dog"] = "Walter Dog",
        ["Sogga"] = "Sogga",
        ["Egg Dog"] = "Egg Dog",
        ["Gigachad"] = "Gigachad",
        ["Sus Duck"] = "Sus Duck",
        ["Banana Cat"] = "Banana Cat",
        ["Meme Beast"] = "Meme Beast",
        ["Killerfish"] = "Killerfish",
        ["Smiling Cat"] = "Smiling Cat",
        ["Bingus"] = "Bingus",
        ["Popcat"] = "Popcat",
    }

    local function parseQuestTarget(questText)
        if not questText or questText == "" or questText == "None" then return nil end
        local lower = questText:lower()
        local bestTarget = nil
        local bestLen = 0
        for keyword, target in pairs(QUEST_MOB_MAP) do
            local kl = keyword:lower()
            if lower:find(kl, 1, true) then
                if #kl > bestLen then
                    bestLen = #kl
                    bestTarget = target
                end
            end
        end
        return bestTarget
    end

    local function scanPDForQuest()
        local pd = getPD()
        if not pd then return nil end
        local keywords = {"floppa", "doge", "cheems", "walter", "sogga", "gigachad",
                          "duck", "banana", "meme", "killerfish", "smiling", "bingus",
                          "popcat", "egg", "golden", "big "}
        for _, v in ipairs(pd:GetDescendants()) do
            if v:IsA("StringValue") then
                local val = tostring(v.Value or "")
                local low = val:lower()
                if low ~= "none" and low ~= "" and #val > 3 then
                    for _, kw in ipairs(keywords) do
                        if low:find(kw, 1, true) then
                            return val
                        end
                    end
                end
            end
        end
        return nil
    end

    local function getCurrentQuest()
        local q = pdValue("Quest_Tracker", "None")
        q = tostring(q or "None")
        if q ~= "None" and q ~= "" then return q end
        local scanned = scanPDForQuest()
        if scanned then return scanned end
        return "None"
    end

    local function requestNewQuest()
        if not QuestEvents then return end
        local q = QuestEvents:FindFirstChild("Quest")
        if q then
            pcall(function() q:FireServer("New") end)
            pcall(function() q:FireServer("Accept") end)
            pcall(function() q:FireServer() end)
        end
        local nq = MiscEvents and MiscEvents:FindFirstChild("NewQuest")
        if nq then pcall(function() nq:FireServer() end) end
        log("Requested new quest")
    end

    local function completeQuest()
        if not QuestEvents then return end
        local q = QuestEvents:FindFirstChild("Quest")
        if q then
            pcall(function() q:FireServer("Complete") end)
        end
        log("Attempted quest completion")
    end

    local questFarmThread = nil
    local function startQuestFarm()
        if questFarmThread then return end
        questFarmThread = task.spawn(function()
            while not UNLOADED do
                task.wait(0.15)
                if not State.autoQuestFarm then
                    State.questFarm.state = "idle"
                    task.wait(0.5)
                else
                    local qf = State.questFarm
                    local now = tick()

                    if qf.state == "idle" then
                        local cur = getCurrentQuest()
                        if cur and cur ~= "None" then
                            qf.currentQuest = cur
                            qf.currentTarget = parseQuestTarget(cur)
                            qf.state = "farming"
                            qf.lastMobSeen = now
                            log("Quest:", cur, "| target:", qf.currentTarget or "ANY")
                        else
                            qf.state = "farming"
                            qf.currentTarget = nil
                            qf.currentQuest = "None"
                            qf.lastMobSeen = now
                            log("No quest detected — farming any mob")
                        end
                    elseif qf.state == "farming" then
                        local cur = getCurrentQuest()
                        if cur and cur ~= "None" and cur ~= qf.currentQuest then
                            qf.currentQuest = cur
                            qf.currentTarget = parseQuestTarget(cur)
                            log("Quest changed:", cur, "| target:", qf.currentTarget or "ANY")
                        end

                        local target = qf.currentTarget
                        local mob = getNearestMob(target)
                        if mob then
                            qf.lastMobSeen = now
                            equipCombat()
                            attackMob(mob)
                            if State.autoSkill then useSkills() end
                        else
                            if qf.currentTarget and now - qf.lastMobSeen > 12 then
                                log("No mobs matching", qf.currentTarget, "— trying complete")
                                qf.state = "complete"
                                qf.lastCompleteAttempt = now
                            elseif not qf.currentTarget and now - qf.lastMobSeen > 20 then
                                log("No mobs at all — re-requesting quest")
                                qf.state = "idle"
                                qf.lastQuestRequest = now
                            end
                        end
                    elseif qf.state == "complete" then
                        if now - qf.lastCompleteAttempt > 3 then
                            qf.lastCompleteAttempt = now
                            completeQuest()
                        end
                        local cur = getCurrentQuest()
                        if not cur or cur == "None" or cur ~= qf.currentQuest then
                            qf.state = "idle"
                            qf.currentQuest = "None"
                            qf.currentTarget = nil
                        elseif now - qf.lastCompleteAttempt > 20 then
                            log("Stuck trying to complete — resetting")
                            qf.state = "idle"
                        end
                    end
                end
            end
        end)
    end

    local lastAttack = 0
    local ATTACK_CD = 0.15

    task.spawn(function()
        while not UNLOADED do
            task.wait(0.1)
            if State.autoQuestFarm then
            elseif State.autoAttack or State.autoFarmNearest or State.farmSelected then
                equipCombat()
                local now = tick()
                if now - lastAttack >= ATTACK_CD then
                    local mob = getNearestMob()
                    if mob then
                        lastAttack = now
                        attackMob(mob)
                        if State.autoSkill then useSkills() end
                    end
                end
            end
        end
    end)

    startQuestFarm()

    task.spawn(function()
        while not UNLOADED do
            task.wait(0.3)
            if State.bringMob then
                local folder = getMonsterFolder()
                local myHRP = getHRP()
                if folder and myHRP then
                    local target = nil
                    if State.autoQuestFarm and State.questFarm.currentTarget then
                        target = State.questFarm.currentTarget
                    end
                    for _, mob in ipairs(folder:GetChildren()) do
                        if mob:IsA("Model") and isMobAlive(mob) and mobMatches(mob, target) and isMobSafe(mob) then
                            local hrp = getMonsterHRP(mob)
                            if hrp then
                                local look = myHRP.CFrame * CFrame.new(0, 3, 15)
                                pcall(function() hrp.CFrame = look end)
                            end
                        end
                    end
                end
            end
        end
    end)

    local statIndex = 0
    task.spawn(function()
        while not UNLOADED do
            task.wait(2)
            if State.autoStats then
                local sp = pdValue("SkillPoint", 0)
                if sp and sp > 0 then
                    local sf = MainEvents and MainEvents:FindFirstChild("StatsFunction")
                    if sf then
                        statIndex = (statIndex % 4) + 1
                        local stats = {"Melee", "Defense", "Sword", "MemePower"}
                        local chosen = stats[statIndex]
                        if State.statPriority ~= "Balanced" and State.statPriority ~= "" then
                            chosen = State.statPriority
                        end
                        pcall(function() sf:InvokeServer(chosen, 1) end)
                    end
                end
            end
        end
    end)

    local codeIndex = 0
    task.spawn(function()
        while not UNLOADED do
            task.wait(1.5)
            if State.autoRedeem then
                codeIndex = codeIndex + 1
                if codeIndex > #CODES then
                    State.autoRedeem = false
                    codeIndex = 0
                else
                    local cf = MainEvents and MainEvents:FindFirstChild("Code")
                    if cf then
                        local code = CODES[codeIndex]
                        pcall(function() cf:InvokeServer(code) end)
                        print("[MemeSea] Redeeming: " .. code)
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(1)
            if State.autoQuest and not State.autoQuestFarm then
                requestNewQuest()
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(5)
            if State.autoPopcat then
                local p = MiscEvents and MiscEvents:FindFirstChild("Popcat")
                if p then
                    pcall(function() p:FireServer() end)
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(8)
            if State.autoStartRaid then
                local sr = MiscEvents and MiscEvents:FindFirstChild("StartRaid")
                if sr then
                    pcall(function() sr:FireServer() end)
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(10)
            if State.autoGacha then
                local g = MainEvents and MainEvents:FindFirstChild("Gacha")
                if g then
                    pcall(function() g:FireServer() end)
                end
            end
            if State.autoLuck then
                local l = MainEvents and MainEvents:FindFirstChild("Luck")
                if l then
                    pcall(function() l:FireServer() end)
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

    task.spawn(function()
        while not UNLOADED do
            task.wait(2)
            if State.autoCloseGui and State.autoQuestFarm then
                closeExtraGuis()
            end
        end
    end)

    local function collectDropsFromFolder(folder, myHRP)
        if not folder or not myHRP then return end
        for _, item in ipairs(folder:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("Handle") then
                local handle = item.Handle
                if handle and (handle.Position - myHRP.Position).Magnitude < 50 then
                    pcall(function() firetouchinterest(myHRP, handle, 0) end)
                    pcall(function() firetouchinterest(myHRP, handle, 1) end)
                end
            elseif item:IsA("Model") then
                local part = item:FindFirstChildWhichIsA("BasePart")
                if part and part.Name:lower():find("handle") then
                    if (part.Position - myHRP.Position).Magnitude < 50 then
                        pcall(function() firetouchinterest(myHRP, part, 0) end)
                        pcall(function() firetouchinterest(myHRP, part, 1) end)
                    end
                end
            end
        end
    end

    task.spawn(function()
        while not UNLOADED do
            task.wait(0.4)
            if State.collectDrops then
                local myHRP = getHRP()
                if myHRP then
                    for _, child in ipairs(workspace:GetChildren()) do
                        if child:IsA("Folder") then
                            collectDropsFromFolder(child, myHRP)
                        end
                    end
                    collectDropsFromFolder(workspace, myHRP)
                end
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
            "autoAttack","autoFarmNearest","farmSelected","autoQuestFarm",
            "autoSkill","collectDrops","autoQuest","autoStats","autoRedeem",
            "autoPopcat","autoStartRaid","autoGacha","autoLuck",
            "speed","jumpPower","antiAfk","fullbright","noFog","bringMob",
            "autoEquipCombat","includeTrainingLog","autoCloseGui","debugQuest",
        }) do
            local el = Elements[k]
            if el and State[k] ~= nil then setToggle(el, State[k]) end
        end
        for _, k in ipairs({
            "speedValue","jumpPowerValue","maxLevelDiff",
            "skillZ_CD","skillX_CD","skillC_CD","skillV_CD",
        }) do
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
        if not s or not data then return false end
        if data.state then
            for k, v in pairs(data.state) do
                if k ~= "questFarm" then State[k] = v end
            end
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
        FarmTab:CreateSection("Auto Quest Farm")
        reg("autoQuestFarm", FarmTab:CreateToggle({
            Name = "Auto Quest Farm",
            Description = "Get quest, kill target mobs, complete, repeat",
            Icon = "🌟", Default = false,
            Callback = function(v)
                State.autoQuestFarm = v
                State.questFarm.state = "idle"
                State.questFarm.attempts = 0
            end,
        }))
        reg("debugQuest", FarmTab:CreateToggle({
            Name = "Debug Quest",
            Description = "Print quest logs to console",
            Icon = "🐛", Default = true,
            Callback = function(v) State.debugQuest = v end,
        }))
        reg("autoCloseGui", FarmTab:CreateToggle({
            Name = "Auto Close NPC GUIs",
            Description = "Close shop/dialog GUIs automatically",
            Icon = "🚪", Default = true,
            Callback = function(v)
                State.autoCloseGui = v
                if not v then restoreClosedGuis() end
            end,
        }))
        FarmTab:CreateSection("Manual Farm")
        reg("autoFarmNearest", FarmTab:CreateToggle({
            Name = "Auto Farm Nearest",
            Description = "Farm the closest valid monster",
            Icon = "📍", Default = false,
            Callback = function(v) State.autoFarmNearest = v end,
        }))
        reg("farmSelected", FarmTab:CreateToggle({
            Name = "Farm Selected Mob",
            Description = "Farm a specific mob type",
            Icon = "🎯", Default = false,
            Callback = function(v) State.farmSelected = v end,
        }))
        FarmTab:CreateDropdown({
            Name = "Select Mob",
            Description = "Which monster to farm",
            Icon = "🐾", Options = MOB_LIST, Default = 1,
            Callback = function(_, idx)
                State.selectedMob = MOB_LIST[idx] or "Any"
            end,
        })
        reg("maxLevelDiff", FarmTab:CreateSlider({
            Name = "Max Level Difference",
            Description = "Skip mobs this many levels above you",
            Icon = "⚖️", Min = 0, Max = 30, Default = 5,
            Callback = function(v) State.maxLevelDiff = v end,
        }))
        reg("includeTrainingLog", FarmTab:CreateToggle({
            Name = "Include Training Log",
            Description = "Also farm the training dummy",
            Icon = "🥊", Default = false,
            Callback = function(v) State.includeTrainingLog = v end,
        }))
        reg("bringMob", FarmTab:CreateToggle({
            Name = "Bring Mob",
            Description = "Teleport monsters in front of you",
            Icon = "🧲", Default = false,
            Callback = function(v) State.bringMob = v end,
        }))
        reg("autoSkill", FarmTab:CreateToggle({
            Name = "Auto Skills",
            Description = "Press Z/X/C/V with cooldowns",
            Icon = "✨", Default = false,
            Callback = function(v) State.autoSkill = v end,
        }))
        reg("collectDrops", FarmTab:CreateToggle({
            Name = "Collect Drops",
            Description = "Pick up items on the ground",
            Icon = "🎁", Default = false,
            Callback = function(v) State.collectDrops = v end,
        }))
        reg("autoEquipCombat", FarmTab:CreateToggle({
            Name = "Auto Equip Combat",
            Description = "Auto equip the Combat tool",
            Icon = "🗡️", Default = true,
            Callback = function(v) State.autoEquipCombat = v end,
        }))

        local SkillTab = Window:CreateTab("Skill Cooldowns", "⏱️")
        SkillTab:CreateSection("Cooldowns (seconds)")
        reg("skillZ_CD", SkillTab:CreateSlider({
            Name = "Skill Z Cooldown", Description = "Z key cooldown",
            Icon = "⚡", Min = 0.5, Max = 30, Default = 2,
            Callback = function(v) State.skillZ_CD = v end,
        }))
        reg("skillX_CD", SkillTab:CreateSlider({
            Name = "Skill X Cooldown", Description = "X key cooldown",
            Icon = "⚡", Min = 0.5, Max = 60, Default = 5,
            Callback = function(v) State.skillX_CD = v end,
        }))
        reg("skillC_CD", SkillTab:CreateSlider({
            Name = "Skill C Cooldown", Description = "C key cooldown",
            Icon = "⚡", Min = 0.5, Max = 90, Default = 8,
            Callback = function(v) State.skillC_CD = v end,
        }))
        reg("skillV_CD", SkillTab:CreateSlider({
            Name = "Skill V Cooldown", Description = "V key cooldown",
            Icon = "⚡", Min = 0.5, Max = 120, Default = 12,
            Callback = function(v) State.skillV_CD = v end,
        }))

        local ProgressTab = Window:CreateTab("Progress", "📈")
        ProgressTab:CreateSection("Quests")
        reg("autoQuest", ProgressTab:CreateToggle({
            Name = "Auto Quest (only accept)",
            Description = "Only request quest, no combat",
            Icon = "📜", Default = false,
            Callback = function(v) State.autoQuest = v end,
        }))
        ProgressTab:CreateSection("Stats")
        reg("autoStats", ProgressTab:CreateToggle({
            Name = "Auto Stats",
            Description = "Spend skill points automatically",
            Icon = "📊", Default = false,
            Callback = function(v) State.autoStats = v end,
        }))
        ProgressTab:CreateDropdown({
            Name = "Stat Priority",
            Description = "Which stat to invest in",
            Icon = "🎯", Options = {"Balanced", "Melee", "Defense", "Sword", "MemePower"}, Default = 1,
            Callback = function(_, idx)
                local opts = {"Balanced", "Melee", "Defense", "Sword", "MemePower"}
                State.statPriority = opts[idx] or "Balanced"
            end,
        })
        ProgressTab:CreateSection("Misc")
        reg("autoRedeem", ProgressTab:CreateToggle({
            Name = "Redeem All Codes",
            Description = "Try to redeem every known code",
            Icon = "🎟️", Default = false,
            Callback = function(v) State.autoRedeem = v end,
        }))
        reg("autoPopcat", ProgressTab:CreateToggle({
            Name = "Auto Popcat",
            Description = "Fire Popcat RemoteEvent",
            Icon = "🐾", Default = false,
            Callback = function(v) State.autoPopcat = v end,
        }))
        reg("autoStartRaid", ProgressTab:CreateToggle({
            Name = "Auto Start Raid",
            Description = "Automatically start raids",
            Icon = "🌋", Default = false,
            Callback = function(v) State.autoStartRaid = v end,
        }))
        reg("autoGacha", ProgressTab:CreateToggle({
            Name = "Auto Gacha",
            Description = "Auto roll gacha",
            Icon = "🎰", Default = false,
            Callback = function(v) State.autoGacha = v end,
        }))
        reg("autoLuck", ProgressTab:CreateToggle({
            Name = "Auto Upgrade Luck",
            Description = "Automatically upgrade luck",
            Icon = "🍀", Default = false,
            Callback = function(v) State.autoLuck = v end,
        }))

        local PlayerTab = Window:CreateTab("Player", "🏃")
        PlayerTab:CreateSection("Movement")
        reg("speed", PlayerTab:CreateToggle({
            Name = "Speed", Description = "Custom walkspeed",
            Icon = "⚡", Default = false,
            Callback = function(v) State.speed = v end,
        }))
        reg("speedValue", PlayerTab:CreateSlider({
            Name = "Speed Value", Description = "WalkSpeed value",
            Icon = "📏", Min = 16, Max = 200, Default = 50,
            Callback = function(v) State.speedValue = v end,
        }))
        reg("jumpPower", PlayerTab:CreateToggle({
            Name = "Jump Power", Description = "Custom jump velocity",
            Icon = "🦘", Default = false,
            Callback = function(v) State.jumpPower = v end,
        }))
        reg("jumpPowerValue", PlayerTab:CreateSlider({
            Name = "Jump Value", Description = "JumpPower value",
            Icon = "📏", Min = 30, Max = 200, Default = 80,
            Callback = function(v) State.jumpPowerValue = v end,
        }))
        reg("antiAfk", PlayerTab:CreateToggle({
            Name = "Anti-AFK", Description = "Prevent kick for inactivity",
            Icon = "🛡️", Default = false,
            Callback = function(v) State.antiAfk = v end,
        }))

        local VisualTab = Window:CreateTab("Visuals", "👁️")
        VisualTab:CreateSection("Environment")
        reg("fullbright", VisualTab:CreateToggle({
            Name = "Fullbright", Description = "Map always bright",
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

        SettingsTab:CreateSection("Debug")
        SettingsTab:CreateButton({
            Name = "Show Quest Status",
            Callback = function()
                local cur = getCurrentQuest()
                local target = parseQuestTarget(cur)
                print("[MemeSea] Quest_Tracker:", tostring(pdValue("Quest_Tracker", "nil")))
                print("[MemeSea] Detected quest:", cur)
                print("[MemeSea] Parsed target:", target or "none")
                print("[MemeSea] Farm state:", State.questFarm.state)
                if Window then Window:Notify("🔍", "Quest: " .. cur, 5, "info") end
            end,
        })
        SettingsTab:CreateButton({
            Name = "Dump PlayerData",
            Callback = function()
                local pd = getPD()
                if not pd then
                    print("[MemeSea] No PlayerData found")
                    return
                end
                print("========== PLAYERDATA DUMP ==========")
                for _, v in ipairs(pd:GetDescendants()) do
                    if v:IsA("ValueBase") then
                        print("  [" .. v.ClassName .. "] " .. v:GetFullName() .. " = " .. tostring(v.Value))
                    end
                end
                print("=====================================")
                if Window then Window:Notify("📋", "PlayerData dumped to console", 3, "info") end
            end,
        })
        SettingsTab:CreateButton({
            Name = "Force Request Quest",
            Callback = function()
                requestNewQuest()
                if Window then Window:Notify("📜", "Quest requested", 2, "info") end
            end,
        })
        SettingsTab:CreateButton({
            Name = "Force Complete Quest",
            Callback = function()
                completeQuest()
                if Window then Window:Notify("✅", "Complete attempted", 2, "info") end
            end,
        })

        SettingsTab:CreateSection("Danger Zone")
        SettingsTab:CreateButton({
            Name = "Unload Script",
            Danger = true,
            Callback = function()
                UNLOADED = true
                restoreEnv()
                restoreClosedGuis()
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