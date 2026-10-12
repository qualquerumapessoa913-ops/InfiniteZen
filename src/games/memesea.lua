-- ============================================================
-- Infinite Zen - MemeSea - V1.1
-- ============================================================

local MemeSea = {}

function MemeSea.Init(ctx)
    local Language = ctx.Language
    local UI       = ctx.UI
    local Compat   = ctx.Compat
    local gameName = ctx.gameName

    local function T(key, fallback)
        local v = Language.get(key)
        if not v or v == key then return fallback or key end
        return v
    end

    local GAME_VERSION  = "1.1"
    local FULL_VERSION  = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("============================================")
    print("[Infinite Zen] 🇧🇷 Inicializando " .. FULL_VERSION .. "...")
    print("[Infinite Zen] 🇺🇸 Initializing " .. FULL_VERSION .. "...")
    print("============================================")

    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local UserInputService  = game:GetService("UserInputService")
    local VirtualInput      = game:GetService("VirtualInputManager")
    local GuiService        = game:GetService("GuiService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService       = game:GetService("HttpService")
    local Lighting          = game:GetService("Lighting")
    local LocalPlayer       = Players.LocalPlayer
    local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

    local VirtualUser = nil
    pcall(function() VirtualUser = game:GetService("VirtualUser") end)
    if Compat and Compat.getVirtualUser then
        pcall(function() VirtualUser = Compat.getVirtualUser() end)
    end
    if VirtualUser == nil then
        print("[MemeSea] 🇧🇷 VirtualUser nil — usando mouse1click/firesignal")
        print("[MemeSea] 🇺🇸 VirtualUser nil — falling back to mouse1click/firesignal")
    else
        print("[MemeSea] 🇧🇷 VirtualUser OK")
        print("[MemeSea] 🇺🇸 VirtualUser OK")
    end

    local UNLOADED = false
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

    local RS         = ReplicatedStorage
    local OtherEvent = RS:WaitForChild("OtherEvent", 15)
    local MainEvents = OtherEvent and OtherEvent:FindFirstChild("MainEvents")

    local NPCs          = workspace:WaitForChild("NPCs", 30)
    local Location      = workspace:WaitForChild("Location", 30)
    local Monsters      = workspace:WaitForChild("Monster", 30)
    local IslandFolder  = workspace:WaitForChild("Island", 30)
        or workspace:FindFirstChild("Islands", 5)
        or workspace:FindFirstChild("Map", 5)
    local Quests_Npc    = NPCs and NPCs:WaitForChild("Quests_Npc", 15)
    local Shop_Npc      = NPCs and NPCs:WaitForChild("Shop_Npc", 15)
    local EnemyLocation = Location and Location:FindFirstChild("Enemy_Location", 15)
    local QuestLocation = Location and Location:FindFirstChild("QuestLocaion", 15)
    local TeleportLoc   = Location and Location:FindFirstChild("Teleport", 10)
    local SpawnLocs     = Location and Location:FindFirstChild("SpawnLocations", 10)

    local QuestFolder = LocalPlayer:WaitForChild("QuestFolder", 30)
    local PlayerData  = LocalPlayer:WaitForChild("PlayerData", 30)
    local PlayerLevel = PlayerData and PlayerData:FindFirstChild("Level")
    local Ability     = LocalPlayer:WaitForChild("Ability")

    local QuestSettings = nil
    local CodeList      = nil
    local ModuleFolder  = RS:FindFirstChild("ModuleScript")

    task.spawn(function()
        if ModuleFolder then
            local ok, m = pcall(function() return require(ModuleFolder:WaitForChild("Quest_Settings", 10)) end)
            if ok then
                QuestSettings = m
                print("[MemeSea] 🇧🇷 Quest_Settings carregado")
                print("[MemeSea] 🇺🇸 Quest_Settings loaded")
            end
            local ok2, c = pcall(function() return require(ModuleFolder:WaitForChild("CodeList", 10)) end)
            if ok2 and type(c) == "table" then CodeList = c end
        end
    end)

    local State = {
        autoQuestFarm = false, autoStats = false, autoRedeem = false,
        statPriority = "Melee", statPointsPerTick = 1, farmWeapon = "Fight",
        bringMobs = true, autoHaki = true, autoClick = true, antiDamage = true,
        adaptiveHitbox = true, hitboxMargin = 4, farmDistance = 10.5,
        speed = false, speedValue = 50,
        jumpPower = false, jumpPowerValue = 80,
        antiAfk = false, fullbright = false, noFog = false,
        respawnWait = 0,
    }

    local origBrightness = Lighting.Brightness
    local origAmbient    = Lighting.Ambient
    local origOutdoor    = Lighting.OutdoorAmbient
    local origClock      = Lighting.ClockTime
    local origFogEnd     = Lighting.FogEnd
    local origFogStart   = Lighting.FogStart

    local currentTarget  = nil
    local goingToNpc     = false
    local hoverActive    = false
    local redeemIndex    = 0
    local currentMobName = nil

    local function isFarmActive() return State.autoQuestFarm end

    local function getHRP()
        local c = LocalPlayer.Character
        if not c then return nil end
        return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
    end

    local function isAlive(m)
        if not m or not m:IsA("Model") then return false end
        local hum = m:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end

    local function teleportToCFrame(cf)
        local char = LocalPlayer.Character
        if char then pcall(function() char:PivotTo(cf) end) end
    end

    local function normalizeName(s)
        return tostring(s):lower():gsub("[%s_%-]", "")
    end

    local function findChildFuzzy(parent, targetName)
        if not parent or not targetName then return nil end
        local exact = parent:FindFirstChild(targetName)
        if exact then return exact end
        local targetNorm = normalizeName(targetName)
        for _, c in ipairs(parent:GetChildren()) do
            if normalizeName(c.Name) == targetNorm then return c end
        end
        for _, c in ipairs(parent:GetChildren()) do
            local n = normalizeName(c.Name)
            if n:find(targetNorm, 1, true) or targetNorm:find(n, 1, true) then
                return c
            end
        end
        return nil
    end

    local function findIslandAnchor(islandModel)
        if not islandModel then return nil end

        if TeleportLoc then
            local tp = findChildFuzzy(TeleportLoc, islandModel.Name)
            if tp then
                if tp:IsA("BasePart") then return tp.Position end
                if tp:IsA("Model") then
                    local pp = tp.PrimaryPart or tp:FindFirstChildWhichIsA("BasePart")
                    if pp then return pp.Position end
                end
                if tp:IsA("Folder") then
                    local bp = tp:FindFirstChildWhichIsA("BasePart", true)
                    if bp then return bp.Position end
                end
            end
        end

        if islandModel:IsA("Model") and islandModel.PrimaryPart then
            return islandModel.PrimaryPart.Position
        end

        for _, part in ipairs(islandModel:GetDescendants()) do
            if part:IsA("BasePart") then
                local n = part.Name:lower()
                if n:find("anchor") or n:find("teleport") or n:find("spawn") then
                    return part.Position
                end
            end
        end

        local best, bestSize = nil, 0
        for _, obj in ipairs(islandModel:GetDescendants()) do
            if obj:IsA("BasePart") then
                local s = obj.Size.Magnitude
                if s > bestSize then best = obj; bestSize = s end
            end
        end
        if best then return best.Position end

        if islandModel:IsA("Model") then
            local ok, pivot = pcall(function() return islandModel:GetPivot() end)
            if ok and pivot then return pivot.Position end
        end

        return nil
    end

    local function teleportToIsland(islandName)
        local island = findChildFuzzy(IslandFolder, islandName)
        if not island then
            island = findChildFuzzy(workspace, islandName)
        end
        if not island then
            if Window then Window:Notify("Warning", islandName .. " not found", 3, "error") end
            warn("[TP] Island not found:", islandName)
            return false
        end

        local pos = findIslandAnchor(island)
        if not pos then
            if Window then Window:Notify("Warning", "No anchor in " .. island.Name, 3, "error") end
            warn("[TP] No anchor for:", island.Name)
            return false
        end

        teleportToCFrame(CFrame.new(pos + Vector3.new(0, 15, 0)))
        if Window then Window:Notify("Teleport", "Teleported to " .. island.Name, 2, "success") end
        return true
    end

    local function teleportToFolderTarget(folder, name, yOffset)
        if not folder then return false end
        local target = findChildFuzzy(folder, name)
        if not target then
            if Window then Window:Notify("Warning", name .. " not found", 2, "error") end
            return false
        end
        local pos
        if target:IsA("BasePart") then
            pos = target.Position
        elseif target:IsA("Model") then
            pos = target:GetPivot().Position
        elseif target:IsA("Folder") then
            local first = target:FindFirstChildWhichIsA("BasePart", true)
            if first then pos = first.Position
            else
                local firstM = target:FindFirstChildWhichIsA("Model")
                if firstM then pos = firstM:GetPivot().Position end
            end
        end
        if not pos then
            if Window then Window:Notify("Warning", "No position for " .. name, 2, "error") end
            return false
        end
        teleportToCFrame(CFrame.new(pos + Vector3.new(0, yOffset or 5, 0)))
        if Window then Window:Notify("Teleport", "Teleported to " .. name, 2, "success") end
        return true
    end

    local function teleportToSpawn()
        if SpawnLocs then
            local first = SpawnLocs:GetChildren()[1]
            if first then
                local pos = first.Position or (first:GetPivot() and first:GetPivot().Position)
                if pos then
                    teleportToCFrame(CFrame.new(pos + Vector3.new(0, 5, 0)))
                    if Window then Window:Notify("Spawn", "Teleported to Spawn", 2, "success") end
                    return true
                end
            end
        end
        if Window then Window:Notify("Warning", "Spawn not found", 2, "error") end
        return false
    end

    local function getPlayerLevel()
        if not PlayerLevel then return nil end
        return PlayerLevel.Value
    end

    local function getActiveQuest()
        if not QuestFolder then return nil end
        for _, v in ipairs(QuestFolder:GetChildren()) do
            local t = v:FindFirstChild("Target")
            if t and t.Value and t.Value ~= "None" then return v end
        end
        return nil
    end

    local function getQuestTargetName(q)
        if not q then return nil end
        local t = q:FindFirstChild("Target")
        if t and t.Value and t.Value ~= "None" then return t.Value end
        return nil
    end

    local function getQuestProgress(q)
        if not q then return 0, 0 end
        local a = q:FindFirstChild("Amount")
        local n = q:FindFirstChild("Need")
        return (a and a.Value) or 0, (n and n.Value) or 0
    end

    local function buildQuests()
        local list = {}
        if not QuestSettings or not QuestLocation or not EnemyLocation then return list end
        for Npc, Q in pairs(QuestSettings) do
            if QuestLocation:FindFirstChild(Npc) then
                local enemyPos = EnemyLocation:FindFirstChild(Q.Target)
                table.insert(list, {
                    RaidBoss = Q.Raid_Boss, SpecialQuest = Q.Special_Quest,
                    QuestPos = QuestLocation[Npc].CFrame,
                    EnemyPos = enemyPos and enemyPos.CFrame or nil,
                    Level = Q.LevelNeed, Need = Q.Need, Enemy = Q.Target, NpcName = Npc,
                })
            end
        end
        table.sort(list, function(a, b) return a.Level > b.Level end)
        print("[MemeSea] 🇧🇷 Quests construídas: " .. #list)
        print("[MemeSea] 🇺🇸 Quests built: " .. #list)
        return list
    end

    local Quests = {}
    task.spawn(function()
        for _ = 1, 30 do
            if QuestSettings and QuestLocation and EnemyLocation then Quests = buildQuests(); break end
            task.wait(1)
        end
    end)

    local function getBestQuestForLevel()
        local lvl = getPlayerLevel()
        if not lvl then return nil end
        for _, q in ipairs(Quests) do
            if q.Level <= lvl and not q.RaidBoss and not q.SpecialQuest then return q end
        end
        return nil
    end

    local function findFarmTool()
        local char = LocalPlayer.Character
        if not char then return nil end
        local wanted = State.farmWeapon or "Fight"
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t.ToolTip and t.ToolTip:lower():find(wanted:lower(), 1, true) then return t end
        end
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then return t end
        end
        return nil
    end

    local function equipFarmTool()
        local char = LocalPlayer.Character
        if not char then return nil end
        local existing = findFarmTool()
        if existing then return existing end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return nil end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        local wanted = State.farmWeapon or "Fight"
        local tool = nil
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.ToolTip and t.ToolTip:lower():find(wanted:lower(), 1, true) then tool = t; break end
        end
        if not tool then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then tool = t; break end
            end
        end
        if tool then pcall(function() hum:EquipTool(tool) end); return tool end
        return nil
    end

    local function playerClick()
        if not State.autoClick then return end
        local char = LocalPlayer.Character
        if not char then return end

        if VirtualUser then
            pcall(function() VirtualUser:CaptureController() end)
            pcall(function() VirtualUser:Button1Down(Vector2.new(1e4, 1e4)) end)
        end

        if not VirtualUser then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and firesignal and tool.Activated then
                pcall(function() firesignal(tool.Activated) end)
            elseif type(mouse1click) == "function" then
                pcall(mouse1click)
            end
        end

        if State.autoHaki then
            local aura = char:FindFirstChild("AuraColor_Folder")
            if aura and #aura:GetChildren() < 1 and Ability and MainEvents then
                local ab = Ability:FindFirstChild("Aura")
                if ab and ab.Value then pcall(function() MainEvents.Ability:InvokeServer("Aura") end) end
            end
        end
    end

    local function findEnemy(name)
        if not Monsters then return nil end
        for _, m in ipairs(Monsters:GetChildren()) do
            if (not name or m.Name == name) and isAlive(m) then return m end
        end
        return nil
    end

    local function getMobHitboxRadius(mob)
        if not mob then return 0 end
        local maxSize = 0
        for _, part in ipairs(mob:GetDescendants()) do
            if part:IsA("BasePart") then
                local maxDim = math.max(part.Size.X, part.Size.Y, part.Size.Z)
                if maxDim > maxSize then maxSize = maxDim end
            end
        end
        return maxSize / 2
    end

    local function calcDynamicCFrame(mob)
        local radius = getMobHitboxRadius(mob)
        local margin = State.hitboxMargin or 4
        if not State.adaptiveHitbox then
            return CFrame.new(3, State.farmDistance, 2) * CFrame.Angles(math.rad(-90), 0, 0)
        end
        local dist = math.max(radius + margin, State.farmDistance)
        local up = dist * 0.6
        local back = dist * 0.4
        local side = dist * 0.3
        return CFrame.new(side, up, back) * CFrame.Angles(math.rad(-90), 0, 0)
    end

    local function applyAntiDamage()
        if not State.antiDamage then return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanQuery = false; part.CanTouch = false end)
            end
        end
    end

    local function restoreAntiDamage()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanQuery = true; part.CanTouch = true end)
            end
        end
    end

    local function bringMobsTo(enemyName, cf)
        if not State.bringMobs or not Monsters then return end
        for _, m in ipairs(Monsters:GetChildren()) do
            if m.Name == enemyName and isAlive(m) then
                local pp = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
                local hum = m:FindFirstChildOfClass("Humanoid")
                if pp and hum and (pp.Position - cf.Position).Magnitude < 500 then
                    pcall(function()
                        hum.WalkSpeed = 0
                        hum:ChangeState(14)
                        pp.CFrame = cf
                        pp.CanCollide = false
                        pp.Transparency = 1
                    end)
                end
            end
        end
    end

    local function killMonster(enemyName)
        if goingToNpc then return false end
        local enemy = findEnemy(enemyName)
        if not enemy then return false end
        local pp = enemy.PrimaryPart or enemy:FindFirstChild("HumanoidRootPart")
        if not pp then return false end
        currentTarget = enemy
        currentMobName = enemy.Name
        teleportToCFrame(pp.CFrame * calcDynamicCFrame(enemy))
        applyAntiDamage()
        equipFarmTool()
        playerClick()
        if State.bringMobs then bringMobsTo(enemyName, pp.CFrame) end
        return true
    end

    local function takeQuest(npcName)
        if not QuestLocation then return false end
        local loc = QuestLocation:FindFirstChild(npcName)
        if loc then
            teleportToCFrame(loc.CFrame + Vector3.new(0, 3, 0))
            task.wait(0.8)
        end
        local npc = nil
        for i = 1, 15 do
            npc = Quests_Npc and Quests_Npc:FindFirstChild(npcName)
            if npc then break end
            task.wait(0.3)
        end
        if not npc then
            print("[MemeSea] 🇧🇷 NPC '" .. npcName .. "' não spawnou")
            print("[MemeSea] 🇺🇸 NPC '" .. npcName .. "' did not spawn")
            return false
        end
        local block = npc:FindFirstChild("Block")
        local prompt = block and block:FindFirstChild("QuestPrompt")
        if not prompt then return false end
        local npcPos = npc:GetPivot().Position
        local myHRP = getHRP()
        if myHRP and (npcPos - myHRP.Position).Magnitude > 6 then
            teleportToCFrame(CFrame.new(npcPos + Vector3.new(0, 3, 3), npcPos))
            task.wait(0.3)
        end
        pcall(function() prompt.MaxActivationDistance = 100; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false end)
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.5)
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.3)
        return true
    end

    task.spawn(function()
        local lastState = ""
        local forceNpcUntil = 0
        local takeAttempts = 0

        while not UNLOADED do
            task.wait(0.1)
            if not isFarmActive() then
                currentTarget = nil; lastState = ""; takeAttempts = 0; goingToNpc = false
                restoreAntiDamage()
                task.wait(0.4)
            else
                local now = tick()
                if now < State.respawnWait then task.wait(0.3)
                else
                    local bestQuest = getBestQuestForLevel()
                    local activeQuest = getActiveQuest()

                    if not bestQuest then task.wait(1)
                    elseif activeQuest then
                        goingToNpc = false
                        takeAttempts = 0
                        local targetMob = getQuestTargetName(activeQuest)
                        if targetMob then
                            if not killMonster(targetMob) then
                                local enemyLoc = EnemyLocation and EnemyLocation:FindFirstChild(targetMob)
                                if enemyLoc then teleportToCFrame(enemyLoc.CFrame + Vector3.new(0, 3, 0)) end
                                task.wait(0.3)
                            end
                        else task.wait(0.3) end
                    else
                        if lastState ~= "take_"..bestQuest.NpcName then
                            lastState = "take_"..bestQuest.NpcName
                            takeAttempts = 0
                            currentTarget = nil
                            goingToNpc = true
                        end
                        if now > forceNpcUntil then
                            local got = takeQuest(bestQuest.NpcName)
                            takeAttempts = takeAttempts + 1
                            if got then
                                forceNpcUntil = tick() + 2
                                takeAttempts = 0
                                goingToNpc = false
                            else
                                forceNpcUntil = tick() + 1
                                if takeAttempts > 10 then
                                    lastState = ""; takeAttempts = 0; goingToNpc = false
                                    task.wait(3)
                                end
                            end
                        else task.wait(0.15) end
                    end
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if not isFarmActive() then return end
        if goingToNpc then return end
        if not currentTarget or not currentTarget.Parent then return end
        if not isAlive(currentTarget) then
            currentTarget = nil
            currentMobName = nil
            return
        end
        if State.antiDamage then applyAntiDamage() end
        if State.adaptiveHitbox then
            local pp = currentTarget.PrimaryPart or currentTarget:FindFirstChild("HumanoidRootPart")
            if pp then
                pcall(function()
                    local myHRP = getHRP()
                    if myHRP then
                        myHRP.CFrame = pp.CFrame * calcDynamicCFrame(currentTarget)
                        myHRP.Velocity = Vector3.new(0, 0, 0)
                        myHRP.RotVelocity = Vector3.new(0, 0, 0)
                        myHRP.CanCollide = false
                    end
                end)
                hoverActive = true
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(0.5)
            if isFarmActive() then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health < hum.MaxHealth then pcall(function() hum.Health = hum.MaxHealth end) end
                    if not findFarmTool() then equipFarmTool() end
                end
            end
        end
    end)

    local STAT_ALIASES = {["melee"]="MeleeLevel",["defense"]="DefenseLevel",["health"]="DefenseLevel",["sword"]="SwordLevel",["weapon"]="SwordLevel",["memepower"]="MemePowerLevel",["power"]="MemePowerLevel"}
    task.spawn(function()
        while not UNLOADED do
            task.wait(1.5)
            if State.autoStats and PlayerData and MainEvents then
                local sp = PlayerData:FindFirstChild("SkillPoint")
                if sp and sp.Value > 0 then
                    local chosen = State.statPriority
                    if type(chosen) == "table" then chosen = chosen[1] end
                    local key
                    if chosen == "Balanced" then
                        local stats = {MeleeLevel=PlayerData:FindFirstChild("MeleeLevel"),DefenseLevel=PlayerData:FindFirstChild("DefenseLevel"),SwordLevel=PlayerData:FindFirstChild("SwordLevel"),MemePowerLevel=PlayerData:FindFirstChild("MemePowerLevel")}
                        local lowest, lname = math.huge, "MeleeLevel"
                        for k, v in pairs(stats) do if v and v.Value < lowest then lowest = v.Value; lname = k end end
                        key = lname
                    else key = STAT_ALIASES[tostring(chosen):lower()] end
                    if key then
                        local sf = MainEvents:FindFirstChild("StatsFunction")
                        if sf then pcall(function() sf:InvokeServer({Target=key, Action="UpgradeStats", Amount=math.min(sp.Value, State.statPointsPerTick)}) end) end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(1.5)
            if State.autoRedeem and CodeList and MainEvents then
                local cf = MainEvents:FindFirstChild("Code")
                if cf then
                    local codes = {}
                    for k, v in pairs(CodeList) do if v.Status ~= true then table.insert(codes, k) end end
                    redeemIndex = redeemIndex + 1
                    if redeemIndex > #codes then State.autoRedeem = false; redeemIndex = 0
                    else pcall(function() cf:InvokeServer(codes[redeemIndex]) end) end
                end
            else redeemIndex = 0 end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(60)
            if State.antiAfk then
                if VirtualUser then
                    pcall(function() VirtualUser:CaptureController() end)
                    pcall(function() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
                elseif type(mouse1click) == "function" then
                    pcall(mouse1click)
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
            if State.noFog then Lighting.FogEnd = 1e6; Lighting.FogStart = 0 end
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

    LocalPlayer.CharacterAdded:Connect(function()
        State.respawnWait = tick() + 3
        restoreAntiDamage()
        currentTarget = nil
        currentMobName = nil
    end)

    local BASE_FOLDER   = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/MemeSea"
    local AUTOLOAD_FILE = "InfiniteZen_MemeSea_Autoload.txt"

    local function ensureFolder()
        if makefolder then
            pcall(function() if not isfolder(BASE_FOLDER) then makefolder(BASE_FOLDER) end end)
            pcall(function() if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end end)
        end
    end

    local function getConfigPath(name) return CONFIG_FOLDER .. "/" .. name .. ".json" end
    local function getAutoloadPath()  return AUTOLOAD_FILE end

    local function syncUIFromState()
        local toggles = {
            "autoQuestFarm", "bringMobs", "autoHaki", "autoClick", "antiDamage", "adaptiveHitbox",
            "autoStats", "autoRedeem",
            "speed", "jumpPower", "antiAfk", "fullbright", "noFog",
        }
        for _, key in ipairs(toggles) do
            local el = Elements[key]
            if el and State[key] ~= nil then setToggle(el, State[key]) end
        end
        local sliders = { "hitboxMargin", "farmDistance", "statPointsPerTick", "speedValue", "jumpPowerValue" }
        for _, key in ipairs(sliders) do
            local el = Elements[key]
            if el and State[key] ~= nil then setSlider(el, State[key]) end
        end
    end

    local function saveConfigNamed(name)
        ensureFolder()
        local data = { version = GAME_VERSION, state = {} }
        for k, v in pairs(State) do data.state[k] = v end
        local ok = pcall(function() writefile(getConfigPath(name), HttpService:JSONEncode(data)) end)
        if ok and Window then Window:Notify("Config", "Saved: " .. name, 3, "success") end
        return ok
    end

    local function loadConfigNamed(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then return false end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data or not data.state then return false end
        for k, v in pairs(data.state) do if State[k] ~= nil then State[k] = v end end
        syncUIFromState()
        if Window then Window:Notify("Load", "Loaded: " .. name, 3, "info") end
        return true
    end

    local function deleteConfigNamed(name)
        local path = getConfigPath(name)
        if isfile and isfile(path) then pcall(function() delfile(path) end); return true end
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

    local function buildUI()
        Window = UI:CreateWindow({
            Title = "INFINITE ZEN",
            Subtitle = SHORT_VERSION,
            ToggleKey = Enum.KeyCode.K,
        })
        Elements = {}

        local FarmTab = Window:CreateTab(T("ms.tab.farm", "Auto Farm"), "🌾")
        FarmTab:CreateSection(T("ms.section.quest", "Quest"))
        reg("autoQuestFarm", FarmTab:CreateToggle({
            Name = T("ms.autoQuestFarm.name", "Auto Quest Farm"),
            Description = T("ms.autoQuestFarm.desc", "Grab quest, kill mobs, complete, repeat"),
            Icon = "🌟", Default = false,
            Callback = function(v) State.autoQuestFarm = v end,
        }))
        FarmTab:CreateDropdown({
            Name = T("ms.farmWeapon.name", "Farm Weapon"),
            Description = T("ms.farmWeapon.desc", "Which tool to use"),
            Icon = "⚔️",
            Options = { "Fight", "Power", "Weapon" },
            Default = 1,
            Callback = function(opt) State.farmWeapon = tostring(opt) end,
        })
        FarmTab:CreateSection(T("ms.section.combat", "Combat"))
        reg("bringMobs", FarmTab:CreateToggle({
            Name = T("ms.bringMobs.name", "Bring Mobs"),
            Description = T("ms.bringMobs.desc", "Teleport mobs to you"),
            Icon = "🧲", Default = true,
            Callback = function(v) State.bringMobs = v end,
        }))
        reg("autoHaki", FarmTab:CreateToggle({
            Name = T("ms.autoHaki.name", "Auto Haki (Aura)"),
            Description = T("ms.autoHaki.desc", "Auto-enable Aura"),
            Icon = "✨", Default = true,
            Callback = function(v) State.autoHaki = v end,
        }))
        reg("autoClick", FarmTab:CreateToggle({
            Name = T("ms.autoAttack.name", "Auto Attack"),
            Description = T("ms.autoAttack.desc", "Auto-click to attack"),
            Icon = "⚡", Default = true,
            Callback = function(v) State.autoClick = v end,
        }))
        reg("antiDamage", FarmTab:CreateToggle({
            Name = "Anti-Damage",
            Description = "CanQuery=false / CanTouch=false on the character",
            Icon = "🛡️", Default = true,
            Callback = function(v) State.antiDamage = v; if not v then restoreAntiDamage() end end,
        }))

        FarmTab:CreateSection("Adaptive Hitbox")
        reg("adaptiveHitbox", FarmTab:CreateToggle({
            Name = "Adaptive Positioning",
            Description = "Calculates position based on mob hitbox size",
            Icon = "🎯", Default = true,
            Callback = function(v) State.adaptiveHitbox = v end,
        }))
        reg("hitboxMargin", FarmTab:CreateSlider({
            Name = "Hitbox Margin",
            Description = "Extra distance from mob",
            Icon = "📏", Min = 1, Max = 15, Default = 4,
            Callback = function(v) State.hitboxMargin = v end,
        }))
        reg("farmDistance", FarmTab:CreateSlider({
            Name = "Farm Distance",
            Description = "Minimum distance from mob",
            Icon = "📐", Min = 5, Max = 30, Default = 10.5,
            Callback = function(v) State.farmDistance = v end,
        }))

        local TeleTab = Window:CreateTab("Teleport", "🌀")

        TeleTab:CreateSection("Main")
        TeleTab:CreateButton({
            Name = "🏠 Spawn",
            Callback = function() teleportToSpawn() end,
        })

        TeleTab:CreateSection("Islands")

        task.spawn(function()
            local tries = 0
            while not IslandFolder and tries < 30 do
                task.wait(0.5)
                IslandFolder = workspace:FindFirstChild("Island")
                    or workspace:FindFirstChild("Islands")
                    or workspace:FindFirstChild("Map")
                tries = tries + 1
            end

            local DISPLAY = {
                FloppaIsland    = "Floppa Island",
                GorillaIsland   = "Gorilla Island",
                SussyIsland     = "Sussy Island",
                MoaiIsland      = "Moai Island",
                PumpkinIsland   = "Pumpkin Island",
                MrBeastIsland   = "MrBeast Island",
                ForgottenIsland = "Forgotten Island",
                SnowIsland      = "Snow Island",
                DesertIsland    = "Desert Island",
                RockIsland      = "Rock Island",
                PvpArena        = "PvP Arena",
                PvPArena        = "PvP Arena",
            }

            if not IslandFolder then
                warn("[MemeSea] IslandFolder not found - using hardcoded fallback")
                local fallback = {
                    "FloppaIsland","GorillaIsland","SussyIsland","MoaiIsland",
                    "PumpkinIsland","MrBeastIsland","ForgottenIsland","SnowIsland",
                    "DesertIsland","RockIsland","PvpArena",
                }
                for _, name in ipairs(fallback) do
                    local display = DISPLAY[name] or name
                    TeleTab:CreateButton({
                        Name = "🏝️ " .. display,
                        Callback = function() teleportToIsland(name) end,
                    })
                end
                return
            end

            local children = IslandFolder:GetChildren()
            table.sort(children, function(a, b) return a.Name < b.Name end)

            for _, child in ipairs(children) do
                local cname = child.Name
                local display = DISPLAY[cname] or cname
                TeleTab:CreateButton({
                    Name = "🏝️ " .. display,
                    Callback = function() teleportToIsland(cname) end,
                })
            end

            print("[MemeSea] 🇧🇷 " .. #children .. " botões de ilha adicionados")
            print("[MemeSea] 🇺🇸 " .. #children .. " island buttons added")
        end)

        task.spawn(function()
            task.wait(6)
            local alreadyAdded = false
            if IslandFolder then
                for _, c in ipairs(IslandFolder:GetChildren()) do
                    if c.Name:lower():find("pvp") then alreadyAdded = true; break end
                end
            end
            if not alreadyAdded then
                local pvp = workspace:FindFirstChild("PvpArena")
                    or workspace:FindFirstChild("PvPArena")
                    or workspace:FindFirstChild("Pvp_Arena")
                if pvp then
                    TeleTab:CreateButton({
                        Name = "⚔️ PvP Arena",
                        Callback = function() teleportToIsland(pvp.Name) end,
                    })
                end
            end
        end)

        task.spawn(function()
            task.wait(3)
            if QuestLocation then
                local added = 0
                for _, child in ipairs(QuestLocation:GetChildren()) do
                    added = added + 1
                    local cname = child.Name
                    TeleTab:CreateButton({
                        Name = "💬 " .. cname,
                        Callback = function() teleportToFolderTarget(QuestLocation, cname, 5) end,
                    })
                end
                if added > 0 then
                    print("[MemeSea] 🇧🇷 " .. added .. " teleports de NPC de quest adicionados")
                    print("[MemeSea] 🇺🇸 " .. added .. " quest NPC teleports added")
                end
            end
        end)

        task.spawn(function()
            task.wait(4)
            if EnemyLocation then
                local added = 0
                for _, child in ipairs(EnemyLocation:GetChildren()) do
                    added = added + 1
                    local cname = child.Name
                    TeleTab:CreateButton({
                        Name = "⚔️ " .. cname,
                        Callback = function() teleportToFolderTarget(EnemyLocation, cname, 5) end,
                    })
                end
                if added > 0 then
                    print("[MemeSea] 🇧🇷 " .. added .. " teleports de inimigos adicionados")
                    print("[MemeSea] 🇺🇸 " .. added .. " enemy teleports added")
                end
            end
        end)

        local ProgressTab = Window:CreateTab(T("ms.tab.progress", "Progress"), "📈")
        ProgressTab:CreateSection(T("ms.section.stats", "Stats"))
        reg("autoStats", ProgressTab:CreateToggle({
            Name = T("ms.autoStats.name", "Auto Stats"),
            Description = T("ms.autoStats.desc", "Spend points automatically"),
            Icon = "📊", Default = false,
            Callback = function(v) State.autoStats = v end,
        }))
        ProgressTab:CreateDropdown({
            Name = T("ms.statPriority.name", "Stat Priority"),
            Description = T("ms.statPriority.desc", "Which stat to upgrade"),
            Icon = "🎯",
            Options = { "Balanced", "Melee", "Health", "Weapon", "Power" },
            Default = 2,
            Callback = function(opt) State.statPriority = tostring(opt) end,
        })
        reg("statPointsPerTick", ProgressTab:CreateSlider({
            Name = T("ms.pointsPerCycle.name", "Points Per Cycle"),
            Description = T("ms.pointsPerCycle.desc", "Points per cycle"),
            Icon = "🔢", Min = 1, Max = 50, Default = 1,
            Callback = function(v) State.statPointsPerTick = v end,
        }))

        ProgressTab:CreateSection(T("ms.section.rewards", "Rewards"))
        reg("autoRedeem", ProgressTab:CreateToggle({
            Name = T("ms.autoRedeem.name", "Auto Redeem Codes"),
            Description = T("ms.autoRedeem.desc", "Redeem available codes"),
            Icon = "🎁", Default = false,
            Callback = function(v) State.autoRedeem = v; redeemIndex = 0 end,
        }))

        local PlayerTab = Window:CreateTab(T("ms.tab.player", "Player"), "🏃")
        PlayerTab:CreateSection(T("ms.section.movement", "Movement"))
        reg("speed", PlayerTab:CreateToggle({
            Name = T("ms.speed.name", "Speed"),
            Description = T("ms.speed.desc", "Custom walkspeed"),
            Icon = "⚡", Default = false,
            Callback = function(v) State.speed = v end,
        }))
        reg("speedValue", PlayerTab:CreateSlider({
            Name = T("ms.speedValue.name", "Speed Value"),
            Description = T("ms.speedValue.desc", "WalkSpeed"),
            Icon = "📏", Min = 16, Max = 200, Default = 50,
            Callback = function(v) State.speedValue = v end,
        }))
        reg("jumpPower", PlayerTab:CreateToggle({
            Name = T("ms.jumpPower.name", "Jump Power"),
            Description = T("ms.jumpPower.desc", "Custom jump"),
            Icon = "🦘", Default = false,
            Callback = function(v) State.jumpPower = v end,
        }))
        reg("jumpPowerValue", PlayerTab:CreateSlider({
            Name = T("ms.jumpValue.name", "Jump Value"),
            Description = T("ms.jumpValue.desc", "JumpPower"),
            Icon = "📏", Min = 30, Max = 200, Default = 80,
            Callback = function(v) State.jumpPowerValue = v end,
        }))
        reg("antiAfk", PlayerTab:CreateToggle({
            Name = T("ms.antiAfk.name", "Anti-AFK"),
            Description = T("ms.antiAfk.desc", "Prevent kick"),
            Icon = "🛡️", Default = false,
            Callback = function(v) State.antiAfk = v end,
        }))

        local VisualTab = Window:CreateTab(T("ms.tab.visuals", "Visuals"), "👁️")
        VisualTab:CreateSection(T("ms.section.environment", "Environment"))
        reg("fullbright", VisualTab:CreateToggle({
            Name = T("ms.fullbright.name", "Fullbright"),
            Description = T("ms.fullbright.desc", "Bright map"),
            Icon = "💡", Default = false,
            Callback = function(v) State.fullbright = v; if not v then restoreEnv() end end,
        }))
        reg("noFog", VisualTab:CreateToggle({
            Name = T("ms.noFog.name", "No Fog"),
            Description = T("ms.noFog.desc", "Remove fog"),
            Icon = "🌫️", Default = false,
            Callback = function(v) State.noFog = v; if not v then restoreEnv() end end,
        }))

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
                loadBtn.MouseButton1Click:Connect(function() loadConfigNamed(name); refreshConfigList() end)

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
                delBtn.MouseButton1Click:Connect(function() deleteConfigNamed(name); refreshConfigList() end)
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
            Callback = function() refreshConfigList(); Window:Notify("Refresh", T("config.refresh", "Refresh List"), 2, "info") end,
        })

        SettingsTab:CreateButton({
            Name = T("config.disable_autoload", "🚫 Disable Autoload"),
            Callback = function() clearAutoload(); refreshConfigList() end,
        })

        refreshConfigList()

        SettingsTab:CreateSection(T("section.danger", "Danger Zone"))
        SettingsTab:CreateButton({
            Name = T("config.unload", "Unload Script"),
            Danger = true,
            Callback = function()
                UNLOADED = true
                restoreAntiDamage()
                restoreEnv()
                Window:Notify("Unload", T("config.unload", "Unload Script"), 2, "warning")
                task.wait(0.3)
                Window:Destroy()
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
                    Window:Notify("Clipboard", "Copied!", 2, "success")
                end
            end,
        })
        CreditsTab:CreateSection(T("section.version", "Version"))
        CreditsTab:CreateLabel(FULL_VERSION, Color3.fromRGB(140, 140, 155))
        CreditsTab:CreateLabel("© 2026 Sr Red", Color3.fromRGB(90, 90, 105))
    end

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

    Window:Notify("Ready", T("ms.loaded", "MemeSea loaded successfully"), 4, "success")

    print("============================================")
    print("[Infinite Zen] 🇧🇷 " .. FULL_VERSION .. " carregado com sucesso!")
    print("[Infinite Zen] 🇺🇸 " .. FULL_VERSION .. " loaded successfully!")
    print("============================================")
end

return MemeSea