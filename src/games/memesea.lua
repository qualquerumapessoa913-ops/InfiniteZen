-- ============================================================
-- Infinite Zen - MemeSea - V1 (BETA TEST)
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

    local GAME_VERSION  = "1"
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
    local VirtualUser       = game:GetService("VirtualUser")
    local GuiService        = game:GetService("GuiService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService       = game:GetService("HttpService")
    local Lighting          = game:GetService("Lighting")
    local LocalPlayer       = Players.LocalPlayer
    local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

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
    local Quests_Npc    = NPCs and NPCs:WaitForChild("Quests_Npc", 15)
    local Shop_Npc      = NPCs and NPCs:WaitForChild("Shop_Npc", 15)
    local EnemyLocation = Location and Location:FindFirstChild("Enemy_Location", 15)
    local QuestLocation = Location and Location:FindFirstChild("QuestLocaion", 15)

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
            if ok then QuestSettings = m end
            local ok2, c = pcall(function() return require(ModuleFolder:WaitForChild("CodeList", 10)) end)
            if ok2 and type(c) == "table" then CodeList = c end
        end
    end)

    local State = {
        autoQuestFarm = false,
        farmWeapon = "Fight",
        bringMobs = true,
        autoHaki = true,
        autoClick = true,
        attackCD = 0.15,
        teleportDistance = 6,

        autoStats = false,
        statPriority = "Melee",
        statPointsPerTick = 1,

        autoRedeem = false,
        autoGacha = false,
        gachaType = "Floppa Gacha",
        gachaRolls = 1,

        sideRaceAwakening = false,
        sideFloppaWeapon = false,
        sidePopcatWeapon = false,
        forcePopcatRedeem = false,
        forceFloppaClaim = false,

        speed = false,
        speedValue = 50,
        jumpPower = false,
        jumpPowerValue = 80,
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

    local mobAdaptHeights  = {}
    local mobAdaptSide     = {}
    local MIN_HEIGHT       = 10.5
    local MARGIN           = 4
    local HEIGHT_INCREMENT = 3
    local MAX_HEIGHT       = 60
    local GACHA_COST       = 25000

    local currentTarget   = nil
    local currentMobName  = nil
    local goingToNpc      = false
    local forcedQuestName = nil
    local redeemIndex     = 0

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

    local function getQuestGiverName(q)
        if not q then return nil end
        local g = q:FindFirstChild("QuestGiver")
        if g and g.Value and g.Value ~= "None" then return g.Value end
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
            local loc = QuestLocation:FindFirstChild(Npc)
            if not loc then
                local n = Npc:lower()
                for _, c in ipairs(QuestLocation:GetChildren()) do
                    if c.Name:lower():find(n, 1, true) or n:find(c.Name:lower(), 1, true) then loc = c; break end
                end
                if not loc and n:find("dancing") then
                    loc = QuestLocation:FindFirstChild("Floppa Quest [Race]")
                end
            end
            if loc then
                local enemyPos = EnemyLocation:FindFirstChild(Q.Target)
                table.insert(list, {
                    RaidBoss = Q.Raid_Boss, SpecialQuest = Q.Special_Quest,
                    QuestPos = loc.CFrame, EnemyPos = enemyPos and enemyPos.CFrame or nil,
                    Level = Q.LevelNeed, Need = Q.Need, Enemy = Q.Target, NpcName = Npc,
                })
            end
        end
        table.sort(list, function(a, b) return a.Level > b.Level end)
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
        if forcedQuestName then
            for _, q in ipairs(Quests) do
                if q.NpcName == forcedQuestName then return q end
            end
            local fLower = forcedQuestName:lower()
            for _, q in ipairs(Quests) do
                if q.NpcName:lower():find(fLower, 1, true) or fLower:find(q.NpcName:lower(), 1, true) then return q end
            end
        end
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
        pcall(function() VirtualUser:CaptureController() end)
        pcall(function() VirtualUser:Button1Down(Vector2.new(1e4, 1e4)) end)
        if State.autoHaki then
            local aura = char:FindFirstChild("AuraColor_Folder")
            if aura and #aura:GetChildren() < 1 and Ability then
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

    local function getAdaptHeight(mob)
        if not mob then return MIN_HEIGHT end
        local name = mob.Name
        if not mobAdaptHeights[name] then
            local radius = getMobHitboxRadius(mob)
            mobAdaptHeights[name] = math.max(radius + MARGIN, MIN_HEIGHT)
        end
        return mobAdaptHeights[name]
    end

    local function getAdaptSide(mob)
        if not mob then return 2, 2 end
        local name = mob.Name
        if not mobAdaptSide[name] then mobAdaptSide[name] = { side = 2, back = 2 } end
        return mobAdaptSide[name].side, mobAdaptSide[name].back
    end

    local function calcDynamicCFrame(mob)
        if not mob then return CFrame.new(2, MIN_HEIGHT, 2) * CFrame.Angles(math.rad(-90), 0, 0) end
        local up = getAdaptHeight(mob)
        local side, back = getAdaptSide(mob)
        return CFrame.new(side, up, back) * CFrame.Angles(math.rad(-90), 0, 0)
    end

    local function onTookDamage(mobName, damage)
        if not mobName then return end
        local old = mobAdaptHeights[mobName] or MIN_HEIGHT
        local new = math.min(old + HEIGHT_INCREMENT, MAX_HEIGHT)
        if new > old then mobAdaptHeights[mobName] = new end
    end

    local function applyAntiDamage()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanQuery = false; part.CanTouch = false end) end
        end
    end

    local function restoreAntiDamage()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanQuery = true; part.CanTouch = true end) end
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
        currentMobName = enemy.Name
        currentTarget = enemy
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
        if not loc then
            local n = npcName:lower()
            for _, c in ipairs(QuestLocation:GetChildren()) do
                if c.Name:lower():find(n, 1, true) or n:find(c.Name:lower(), 1, true) then loc = c; break end
            end
        end
        if loc then
            teleportToCFrame(loc.CFrame + Vector3.new(0, 3, 0))
            task.wait(0.8)
        end
        local npc = nil
        for _ = 1, 15 do
            npc = Quests_Npc and Quests_Npc:FindFirstChild(npcName)
            if not npc and Quests_Npc then
                local n = npcName:lower()
                for _, c in ipairs(Quests_Npc:GetChildren()) do
                    if c.Name:lower():find(n, 1, true) or n:find(c.Name:lower(), 1, true) then npc = c; break end
                end
            end
            if npc then break end
            task.wait(0.3)
        end
        if not npc then return false end
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

    local function goToNpcAndPrompt(npc)
        if not npc then return false end
        local npcPos
        if npc:IsA("Model") then npcPos = npc:GetPivot().Position
        elseif npc:IsA("BasePart") then npcPos = npc.Position end
        if not npcPos then return false end
        local myHRP = getHRP()
        if myHRP and (npcPos - myHRP.Position).Magnitude > 6 then
            teleportToCFrame(CFrame.new(npcPos + Vector3.new(0, 3, 3), npcPos))
            task.wait(0.4)
        end
        local prompt
        for _, d in ipairs(npc:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d; break end
        end
        if prompt then
            pcall(function() prompt.MaxActivationDistance = 100; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false end)
            pcall(function() fireproximityprompt(prompt) end)
            task.wait(0.5)
            pcall(function() fireproximityprompt(prompt) end)
            return true
        end
        return false
    end

    local function findNpcByKeyword(keyword)
        local k = keyword:lower()
        if Quests_Npc then
            for _, c in ipairs(Quests_Npc:GetChildren()) do
                if c.Name:lower() == k then return c end
            end
            for _, c in ipairs(Quests_Npc:GetChildren()) do
                if c.Name:lower():find(k, 1, true) then return c end
            end
        end
        if Shop_Npc then
            for _, c in ipairs(Shop_Npc:GetChildren()) do
                if c.Name:lower() == k then return c end
            end
            for _, c in ipairs(Shop_Npc:GetChildren()) do
                if c.Name:lower():find(k, 1, true) then return c end
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find(k, 1, true) then
                for _, d in ipairs(obj:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then return obj end
                end
            end
        end
        return nil
    end

    local function clickGuiYes()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return false end
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("TextButton") and obj.Visible then
                local t = (obj.Text or ""):lower()
                if t:find("yes", 1, true) or t:find("buy", 1, true) or t:find("confirm", 1, true)
                    or t:find("comprar", 1, true) or t:find("sim", 1, true) or t:find("accept", 1, true) then
                    local inset = GuiService:GetGuiInset()
                    local pos = obj.AbsolutePosition + (obj.AbsoluteSize / 2) + Vector2.new(0, inset.Y)
                    pcall(function() VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1) end)
                    task.wait(0.05)
                    pcall(function() VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1) end)
                    return true
                end
            end
        end
        return false
    end

    local function tryBuyItem(npcKeyword, itemName)
        local npc = findNpcByKeyword(npcKeyword)
        if not npc then return false end
        local npcPos = npc:GetPivot().Position
        local myHRP = getHRP()
        if myHRP and (npcPos - myHRP.Position).Magnitude > 6 then
            teleportToCFrame(CFrame.new(npcPos + Vector3.new(0, 3, 3), npcPos))
            task.wait(0.5)
        end
        local prompt
        for _, d in ipairs(npc:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d; break end
        end
        if not prompt then return false end
        pcall(function() prompt.MaxActivationDistance = 100; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false end)
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(1.2)
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(1.0)
        clickGuiYes()
        return true
    end

    local function findPopcatClickCount()
        if not PlayerData then return 0 end
        local pop = PlayerData:FindFirstChild("Pop")
        if pop and pop:IsA("ValueBase") then return pop.Value end
        return 0
    end

    local function findOhioPopcat()
        if Shop_Npc then
            local ohio = Shop_Npc:FindFirstChild("Ohio Popcat")
            if ohio then return ohio end
        end
        return nil
    end

    local function goToPvpArenaIsland()
        local island = workspace:FindFirstChild("Island")
        local pvp = island and island:FindFirstChild("PvpArena")
        if not pvp then return false end
        local anchor
        for _, obj in ipairs(pvp:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Size.Magnitude > 40 then anchor = obj; break end
        end
        if not anchor then return false end
        local myHRP = getHRP()
        if myHRP and (anchor.Position - myHRP.Position).Magnitude < 50 then return true end
        teleportToCFrame(CFrame.new(anchor.Position + Vector3.new(0, 15, 0)))
        return true
    end

    local function findCoolFloppa()
        if not Quests_Npc then return nil end
        local npc = Quests_Npc:FindFirstChild("Cool Floppa Quest")
        if npc then return npc end
        for _, c in ipairs(Quests_Npc:GetChildren()) do
            local n = c.Name:lower()
            if n:find("cool", 1, true) and n:find("floppa", 1, true) then return c end
        end
        return nil
    end

    local function fireNpcPrompt(npc)
        if not npc then return false end
        local npcPos = npc:GetPivot().Position
        local myHRP = getHRP()
        if myHRP and (npcPos - myHRP.Position).Magnitude > 6 then
            teleportToCFrame(CFrame.new(npcPos + Vector3.new(0, 3, 3), npcPos))
            task.wait(0.4)
        end
        local block = npc:FindFirstChild("Block")
        local prompt = block and block:FindFirstChild("QuestPrompt")
        if prompt then
            pcall(function() prompt.MaxActivationDistance = 100; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false end)
            pcall(function() fireproximityprompt(prompt) end)
            task.wait(0.5)
            pcall(function() fireproximityprompt(prompt) end)
            return true
        end
        return false
    end

    local function findLavaFloppaPrompt()
        local island = workspace:FindFirstChild("Island")
        local fi = island and island:FindFirstChild("FloppaIsland")
        if not fi then return nil end
        local decoration = fi:FindFirstChild("Decoration")
        local others = decoration and decoration:FindFirstChild("Others")
        local lf = others and others:FindFirstChild("Lava Floppa")
        if not lf then
            for _, obj in ipairs(fi:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Lava Floppa" then lf = obj; break end
            end
        end
        if not lf then return nil end
        local cp = lf:FindFirstChild("ClickPart") or lf.PrimaryPart
        local p = cp and cp:FindFirstChild("ProximityPrompt")
        return p, cp
    end

    local function getMoney()
        local v = PlayerData and PlayerData:FindFirstChild("Money")
        return v and v.Value or 0
    end

    local function getOpenGachaGui()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return nil end
        local folder = pg:FindFirstChild("NpcGui_Folder")
        if not folder then return nil end
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("ScreenGui") and child.Enabled then
                local bg = child:FindFirstChild("Background")
                if bg and bg.Visible then return child end
            end
        end
        return nil
    end

    local function getGachaButton(rolls)
        local npcGui = getOpenGachaGui()
        if not npcGui then return nil end
        local bg = npcGui:FindFirstChild("Background")
        local fr = bg and bg:FindFirstChild("Frame")
        if not fr then return nil end
        if rolls == 1 then
            local f = fr:FindFirstChild("ConfirmFrame"); return f and f:FindFirstChild("Confirm")
        elseif rolls == 3 then
            local f = fr:FindFirstChild("TripleFrame"); return f and f:FindFirstChild("Triple")
        elseif rolls == 10 then
            local f = fr:FindFirstChild("DecupleFrame"); return f and f:FindFirstChild("Decuple")
        end
        return nil
    end

    local function isGachaGuiOpen() return getOpenGachaGui() ~= nil end

    local function clickButton(btn)
        if not btn then return false end
        local inset = GuiService:GetGuiInset()
        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2) + Vector2.new(0, inset.Y)
        pcall(function() VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1) end)
        task.wait(0.05)
        pcall(function() VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1) end)
        return true
    end

    local function teleportToGachaNpc()
        if not Shop_Npc then return false end
        local npc = Shop_Npc:FindFirstChild(State.gachaType)
        if not npc then return false end
        local prompt
        for _, d in ipairs(npc:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d; break end
        end
        local anchor = prompt and prompt.Parent or npc:FindFirstChildWhichIsA("BasePart")
        if not anchor then return false end
        local myHRP = getHRP()
        if not myHRP then return false end
        pcall(function() myHRP.CFrame = CFrame.new(anchor.Position + Vector3.new(0, 0, 3), anchor.Position) end)
        task.wait(0.4)
        if prompt then
            pcall(function() prompt.MaxActivationDistance = 100; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false end)
            pcall(function() fireproximityprompt(prompt) end)
        end
        return true
    end

    LocalPlayer.CharacterAdded:Connect(function()
        State.respawnWait = tick() + 3
        restoreAntiDamage()
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(0.15)
            if (State.autoQuestFarm or State.sideRaceAwakening or State.sideFloppaWeapon or State.sidePopcatWeapon) and currentMobName then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local h = hum.Health
                    if hum._izLastHealth and hum._izLastHealth > 0 and h < hum._izLastHealth then
                        local dmg = hum._izLastHealth - h
                        if dmg >= 5 and tick() - (hum._izLastDmgTime or 0) > 0.5 then
                            hum._izLastDmgTime = tick()
                            onTookDamage(currentMobName, dmg)
                        end
                    end
                    hum._izLastHealth = h
                end
            end
        end
    end)

    task.spawn(function()
        local lastState = ""
        local forceNpcUntil = 0
        local takeAttempts = 0
        while not UNLOADED do
            task.wait(0.1)
            local sideBusy = State.sideRaceAwakening or State.sideFloppaWeapon or State.sidePopcatWeapon
            if not State.autoQuestFarm or sideBusy then
                currentTarget = nil
                currentMobName = nil
                lastState = ""
                takeAttempts = 0
                goingToNpc = false
                task.wait(0.4)
            else
                local now = tick()
                if now < (State.respawnWait or 0) then
                    task.wait(0.3)
                else
                    local bestQuest = getBestQuestForLevel()
                    local activeQuest = getActiveQuest()
                    if not bestQuest then
                        task.wait(1)
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
                        else
                            task.wait(0.3)
                        end
                    else
                        if lastState ~= "take_" .. bestQuest.NpcName then
                            lastState = "take_" .. bestQuest.NpcName
                            takeAttempts = 0
                            currentTarget = nil
                            currentMobName = nil
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
                                    lastState = ""
                                    takeAttempts = 0
                                    goingToNpc = false
                                    task.wait(3)
                                end
                            end
                        else
                            task.wait(0.15)
                        end
                    end
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if State.sideRaceAwakening or State.sideFloppaWeapon or State.sidePopcatWeapon then return end
        if not State.autoQuestFarm then return end
        if goingToNpc then return end
        if not currentTarget or not currentTarget.Parent then return end
        if not isAlive(currentTarget) then
            currentTarget = nil
            currentMobName = nil
            return
        end
        applyAntiDamage()
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
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(0.5)
            if State.autoQuestFarm then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health < hum.MaxHealth then pcall(function() hum.Health = hum.MaxHealth end) end
                    if not findFarmTool() then equipFarmTool() end
                end
            end
        end
    end)

    task.spawn(function()
        local wasActive = false
        local phase = "idle"
        local lastAttempt = 0
        local RACE_LOC_NAME = "Floppa Quest [Race]"

        local function teleportToRace()
            if not QuestLocation then return false end
            local loc = QuestLocation:FindFirstChild(RACE_LOC_NAME)
            if not loc then
                for _, c in ipairs(QuestLocation:GetChildren()) do
                    if c.Name:lower():find("race", 1, true) then loc = c; break end
                end
            end
            if not loc then return false end
            teleportToCFrame(loc.CFrame + Vector3.new(0, 5, 0))
            return true
        end

        local function findDancingNpc()
            if not Quests_Npc then return nil end
            for _, npc in ipairs(Quests_Npc:GetChildren()) do
                if npc:IsA("Model") and npc.Name:lower():find("dancing", 1, true) then return npc end
            end
            return nil
        end

        local function getRaceQuest()
            local aq = getActiveQuest()
            if not aq then return nil end
            if getQuestTargetName(aq) == "Sogga" then return aq end
            return nil
        end

        while not UNLOADED do
            task.wait(0.3)
            if not State.sideRaceAwakening then
                if wasActive then
                    wasActive = false
                    forcedQuestName = nil
                    currentTarget = nil
                    currentMobName = nil
                    restoreAntiDamage()
                    phase = "idle"
                end
                task.wait(0.5)
            else
                if not wasActive then
                    wasActive = true
                    forcedQuestName = "Dancing Banana Quest"
                    phase = "going"
                end
                local aq = getRaceQuest()
                if not aq then
                    phase = "going"
                    teleportToRace()
                    task.wait(0.4)
                    local npc = findDancingNpc()
                    if not npc then
                        task.wait(0.5)
                    else
                        local npcPos = npc:GetPivot().Position
                        local myHRP = getHRP()
                        if myHRP and (npcPos - myHRP.Position).Magnitude > 8 then
                            teleportToCFrame(CFrame.new(npcPos + Vector3.new(0, 3, 3), npcPos))
                            task.wait(0.3)
                        end
                        local block = npc:FindFirstChild("Block")
                        local prompt = block and block:FindFirstChild("QuestPrompt")
                        if prompt then
                            pcall(function() prompt.MaxActivationDistance = 100; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false end)
                            pcall(function() fireproximityprompt(prompt) end)
                            task.wait(0.5)
                            pcall(function() fireproximityprompt(prompt) end)
                            task.wait(1.0)
                        else
                            task.wait(1)
                        end
                    end
                else
                    local cur, need = getQuestProgress(aq)
                    if cur >= need then
                        phase = "returning"
                        if tick() - lastAttempt > 3 then
                            lastAttempt = tick()
                            teleportToRace()
                            task.wait(0.4)
                            local npc = findDancingNpc()
                            if npc then
                                local npcPos = npc:GetPivot().Position
                                teleportToCFrame(CFrame.new(npcPos + Vector3.new(0, 3, 3), npcPos))
                                task.wait(0.3)
                                local block = npc:FindFirstChild("Block")
                                local prompt = block and block:FindFirstChild("QuestPrompt")
                                if prompt then
                                    pcall(function() fireproximityprompt(prompt) end)
                                    task.wait(0.5)
                                    pcall(function() fireproximityprompt(prompt) end)
                                end
                            end
                        end
                    else
                        phase = "farming"
                        local sogga = findEnemy("Sogga")
                        if sogga then
                            killMonster("Sogga")
                        else
                            local loc = EnemyLocation and EnemyLocation:FindFirstChild("Sogga")
                            if loc then teleportToCFrame(loc.CFrame + Vector3.new(0, 3, 0)) end
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        local wasActive = false
        local phase = "idle"
        local lastAttempt = 0
        local lastClick = 0

        local function getRealProgress()
            local aq = getActiveQuest()
            if not aq then return nil end
            local target = getQuestTargetName(aq)
            local a = aq:FindFirstChild("Amount")
            local n = aq:FindFirstChild("Need")
            if a and n then return a.Value, n.Value, target end
            return nil
        end

        while not UNLOADED do
            task.wait(0.05)
            if not State.sideFloppaWeapon then
                if wasActive then
                    wasActive = false
                    phase = "idle"
                    State.forceFloppaClaim = false
                end
                task.wait(0.5)
            else
                if not wasActive then
                    wasActive = true
                    if State.forceFloppaClaim then
                        State.forceFloppaClaim = false
                        phase = "turning_in"
                    else
                        phase = "getting_quest"
                    end
                end
                if State.forceFloppaClaim then
                    State.forceFloppaClaim = false
                    phase = "turning_in"
                end
                if phase == "getting_quest" then
                    local npc = findCoolFloppa()
                    if not npc then
                        if tick() - lastAttempt > 2 then
                            lastAttempt = tick()
                            if QuestLocation then
                                local loc = QuestLocation:FindFirstChild("Cool Floppa Quest")
                                if loc then teleportToCFrame(loc.CFrame + Vector3.new(0, 5, 0)) end
                            end
                        end
                        task.wait(0.4)
                    else
                        fireNpcPrompt(npc)
                        task.wait(1.2)
                        phase = "clicking"
                    end
                elseif phase == "clicking" then
                    local cur, need = getRealProgress()
                    if not cur then
                        phase = "getting_quest"
                    elseif cur >= need then
                        phase = "turning_in"
                    else
                        if tick() - lastClick > 0.1 then
                            lastClick = tick()
                            local prompt, clickPart = findLavaFloppaPrompt()
                            if prompt and clickPart then
                                local myHRP = getHRP()
                                if myHRP and (clickPart.Position - myHRP.Position).Magnitude > 6 then
                                    teleportToCFrame(CFrame.new(clickPart.Position + Vector3.new(0, 3, 3), clickPart.Position))
                                    task.wait(0.2)
                                end
                                pcall(function() prompt.MaxActivationDistance = 100; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false end)
                                pcall(function() fireproximityprompt(prompt) end)
                            end
                        else
                            task.wait(0.02)
                        end
                    end
                elseif phase == "turning_in" then
                    if tick() - lastAttempt > 2 then
                        lastAttempt = tick()
                        local npc = findCoolFloppa()
                        if npc then
                            fireNpcPrompt(npc)
                            task.wait(1.5)
                            local cur, need = getRealProgress()
                            if cur and cur < need then
                                phase = "clicking"
                            else
                                phase = "getting_quest"
                            end
                        end
                    else
                        task.wait(0.3)
                    end
                end
            end
        end
    end)

    task.spawn(function()
        local wasActive = false
        local phase = "clicking"
        local lastAttempt = 0
        local GOAL = 10000

        while not UNLOADED do
            task.wait(0.02)
            if not State.sidePopcatWeapon then
                if wasActive then
                    wasActive = false
                    phase = "clicking"
                    State.forcePopcatRedeem = false
                end
                task.wait(0.5)
            else
                if not wasActive then
                    wasActive = true
                    if findPopcatClickCount() >= GOAL then
                        phase = "going_to_ohio"
                    else
                        phase = "clicking"
                    end
                end
                if State.forcePopcatRedeem then
                    State.forcePopcatRedeem = false
                    if findPopcatClickCount() >= GOAL then phase = "going_to_ohio" end
                end
                if phase == "clicking" then
                    local island = workspace:FindFirstChild("Island")
                    local fi = island and island:FindFirstChild("FloppaIsland")
                    local popcat = fi and fi:FindFirstChild("Popcat_Clickable")
                    local part = popcat and popcat:FindFirstChild("Part")
                    local cd = part and part:FindFirstChild("ClickDetector")
                    if cd and part then
                        local myHRP = getHRP()
                        if myHRP and (part.Position - myHRP.Position).Magnitude > 6 then
                            teleportToCFrame(CFrame.new(part.Position + Vector3.new(0, 3, 3), part.Position))
                            task.wait(0.2)
                        end
                        pcall(function() fireclickdetector(cd) end)
                        if findPopcatClickCount() >= GOAL then phase = "going_to_ohio" end
                    else
                        task.wait(0.5)
                    end
                elseif phase == "going_to_ohio" then
                    if tick() - lastAttempt > 2 then
                        lastAttempt = tick()
                        goToPvpArenaIsland()
                        task.wait(2)
                        local npc = findOhioPopcat()
                        if npc then
                            goToNpcAndPrompt(npc)
                            task.wait(1.5)
                        end
                    else
                        task.wait(0.3)
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while not UNLOADED do
            task.wait(2)
            if State.autoGacha then
                local cost = GACHA_COST * State.gachaRolls
                if getMoney() < cost then
                    task.wait(3)
                else
                    if not isGachaGuiOpen() then teleportToGachaNpc(); task.wait(1.5) end
                    local btn = getGachaButton(State.gachaRolls)
                    if btn then
                        clickButton(btn)
                        task.wait(1.5)
                    else
                        teleportToGachaNpc()
                        task.wait(2)
                    end
                end
            else
                task.wait(0.5)
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
                        local stats = {
                            MeleeLevel = PlayerData:FindFirstChild("MeleeLevel"),
                            DefenseLevel = PlayerData:FindFirstChild("DefenseLevel"),
                            SwordLevel = PlayerData:FindFirstChild("SwordLevel"),
                            MemePowerLevel = PlayerData:FindFirstChild("MemePowerLevel"),
                        }
                        local lowest, lname = math.huge, "MeleeLevel"
                        for k, v in pairs(stats) do
                            if v and v.Value < lowest then lowest = v.Value; lname = k end
                        end
                        key = lname
                    else
                        key = STAT_ALIASES[tostring(chosen):lower()]
                    end
                    if key then
                        local sf = MainEvents:FindFirstChild("StatsFunction")
                        if sf then
                            pcall(function()
                                sf:InvokeServer({Target = key, Action = "UpgradeStats", Amount = math.min(sp.Value, State.statPointsPerTick)})
                            end)
                        end
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
                    for k, v in pairs(CodeList) do
                        if v.Status ~= true then table.insert(codes, k) end
                    end
                    redeemIndex = redeemIndex + 1
                    if redeemIndex > #codes then
                        State.autoRedeem = false
                        redeemIndex = 0
                    else
                        pcall(function() cf:InvokeServer(codes[redeemIndex]) end)
                    end
                end
            else
                redeemIndex = 0
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
            if State.speed and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
            if State.jumpPower and hum.UseJumpPower and hum.JumpPower ~= State.jumpPowerValue then hum.JumpPower = State.jumpPowerValue end
            if State.fullbright then
                Lighting.Brightness = 3
                Lighting.Ambient = Color3.fromRGB(200, 200, 200)
                Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
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

    local function getConfigPath(name) return CONFIG_FOLDER .. "/" .. name .. ".json" end
    local function getAutoloadPath()  return AUTOLOAD_FILE end

    local function syncUIFromState()
        local toggles = {
            "autoQuestFarm", "bringMobs", "autoHaki", "autoClick",
            "autoStats", "autoRedeem", "autoGacha",
            "sideRaceAwakening", "sideFloppaWeapon", "sidePopcatWeapon",
            "speed", "jumpPower", "antiAfk", "fullbright", "noFog",
        }
        for _, key in ipairs(toggles) do
            local el = Elements[key]
            if el and State[key] ~= nil then setToggle(el, State[key]) end
        end
        local sliders = { "attackCD", "teleportDistance", "statPointsPerTick", "speedValue", "jumpPowerValue" }
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
        if ok and Window then Window:Notify("💾 Config", "Saved: " .. name, 3, "success") end
        return ok
    end

    local function loadConfigNamed(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then return false end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data or not data.state then return false end
        for k, v in pairs(data.state) do
            if State[k] ~= nil then State[k] = v end
        end
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

    local function buildUI()
        Window = UI:CreateWindow({
            Title = "INFINITE ZEN [BETA]",
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
            Description = T("ms.farmWeapon.desc", "Which tool to use for farming"),
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
            Description = T("ms.autoHaki.desc", "Auto-enable Aura ability"),
            Icon = "✨", Default = true,
            Callback = function(v) State.autoHaki = v end,
        }))
        reg("autoClick", FarmTab:CreateToggle({
            Name = T("ms.autoAttack.name", "Auto Attack"),
            Description = T("ms.autoAttack.desc", "Auto-click to attack"),
            Icon = "⚡", Default = true,
            Callback = function(v) State.autoClick = v end,
        }))
        FarmTab:CreateSection(T("ms.section.tuning", "Tuning"))
        reg("attackCD", FarmTab:CreateSlider({
            Name = T("ms.attackDelay.name", "Attack Delay"),
            Description = T("ms.attackDelay.desc", "Seconds between attacks"),
            Icon = "⏱️",
            Min = 0.05, Max = 1, Default = 0.15,
            Callback = function(v) State.attackCD = v end,
        }))
        reg("teleportDistance", FarmTab:CreateSlider({
            Name = T("ms.teleportDistance.name", "Teleport Distance"),
            Description = T("ms.teleportDistance.desc", "How close to teleport"),
            Icon = "📏",
            Min = 2, Max = 20, Default = 6,
            Callback = function(v) State.teleportDistance = v end,
        }))

        local SideTab = Window:CreateTab(T("ms.tab.side", "Side-Quests"), "🎯")
        SideTab:CreateSection(T("ms.section.race", "Race Awakening (V2)"))
        SideTab:CreateLabel(T("ms.dancingBanana", "Snow Island | 100 Soggas | Awakening Orb"), Color3.fromRGB(140, 140, 155))
        reg("sideRaceAwakening", SideTab:CreateToggle({
            Name = T("ms.autoRace.name", "Auto Race Awakening"),
            Description = T("ms.autoRace.desc", "Farms Sogga x100 and turns in"),
            Icon = "🏃", Default = false,
            Callback = function(v)
                State.sideRaceAwakening = v
                if v then
                    State.sideFloppaWeapon = false
                    State.sidePopcatWeapon = false
                end
            end,
        }))

        SideTab:CreateSection(T("ms.section.floppa", "Floppa Weapon (Loop)"))
        SideTab:CreateLabel(T("ms.coolFloppa", "Cool Floppa + Lava Floppa | 1000 clicks"), Color3.fromRGB(140, 140, 155))
        reg("sideFloppaWeapon", SideTab:CreateToggle({
            Name = T("ms.autoFloppa.name", "Auto Floppa Weapon"),
            Description = T("ms.autoFloppa.desc", "Get quest, click 1000x, turn in, repeat"),
            Icon = "🔥", Default = false,
            Callback = function(v)
                State.sideFloppaWeapon = v
                if v then
                    State.sideRaceAwakening = false
                    State.sidePopcatWeapon = false
                end
            end,
        }))
        SideTab:CreateButton({
            Name = T("ms.skipTurnIn.name", "Skip to Turn-in (Cool Floppa)"),
            Icon = "⚡",
            Callback = function() State.forceFloppaClaim = true end,
        })

        SideTab:CreateSection(T("ms.section.popcat", "Popcat Weapon"))
        SideTab:CreateLabel(T("ms.popcatInfo", "Floppa Island | 10000 clicks | Redeem at PvP Arena"), Color3.fromRGB(140, 140, 155))
        reg("sidePopcatWeapon", SideTab:CreateToggle({
            Name = T("ms.autoPopcat.name", "Auto Popcat Weapon"),
            Description = T("ms.autoPopcat.desc", "Clicks Popcat 10000x then redeems"),
            Icon = "🐱", Default = false,
            Callback = function(v)
                State.sidePopcatWeapon = v
                if v then
                    State.sideRaceAwakening = false
                    State.sideFloppaWeapon = false
                end
            end,
        }))
        SideTab:CreateButton({
            Name = T("ms.skipClicks.name", "Skip Clicks -> Redeem"),
            Icon = "⚡",
            Callback = function()
                if findPopcatClickCount() >= 10000 then
                    State.forcePopcatRedeem = true
                end
            end,
        })

        local ShopTab = Window:CreateTab(T("ms.tab.shop", "Shop"), "🛒")

        ShopTab:CreateSection(T("ms.section.weapons", "Weapons"))
        ShopTab:CreateButton({ Name = "Katana | $5,000 | Doge", Callback = function() tryBuyItem("doge", "Katana") end })
        ShopTab:CreateButton({ Name = "Hanger | $25,000 | Hanger", Callback = function() tryBuyItem("hanger", "Hanger") end })
        ShopTab:CreateButton({ Name = "Flame Katana | $50k + Cheems Cola | Cheems", Callback = function() tryBuyItem("cheems", "Flame Katana") end })
        ShopTab:CreateButton({ Name = "Banana Weapon | $350k + Cat Food | Smiling Cat", Callback = function() tryBuyItem("smiling", "Banana Weapon") end })
        ShopTab:CreateButton({ Name = "Bonk | $1M + 5x Money Bags | Meme Man", Callback = function() tryBuyItem("meme man", "Bonk") end })
        ShopTab:CreateButton({ Name = "Popcat Weapon | 10k Pops | Ohio Popcat", Callback = function() tryBuyItem("ohio", "Popcat Weapon") end })

        ShopTab:CreateSection(T("ms.section.fighting", "Fighting Styles / Abilities"))
        ShopTab:CreateButton({ Name = "Combat | Free | Maxwell", Callback = function() tryBuyItem("maxwell", "Combat") end })
        ShopTab:CreateButton({ Name = "Baller Style | $10M + 10x Balls | Baller", Callback = function() tryBuyItem("baller", "Baller Style") end })
        ShopTab:CreateButton({ Name = "Flash Step | $100,000 | Giga Chad", Callback = function() tryBuyItem("giga", "Flash Step") end })
        ShopTab:CreateButton({ Name = "Instinct | $2,500,000 | Nugget Man", Callback = function() tryBuyItem("nugget", "Instinct") end })
        ShopTab:CreateButton({ Name = "Aura | $10M + 1x Meme Cube | Aura Master", Callback = function() tryBuyItem("aura master", "Aura") end })

        ShopTab:CreateSection(T("ms.section.utilities", "Utilities"))
        ShopTab:CreateButton({ Name = "Quest Scroll | $1,000,000 | Popcat", Callback = function() tryBuyItem("popcat", "Quest Scroll") end })
        ShopTab:CreateButton({ Name = "Race Reroll | 150 Gems | Watermelon Man", Callback = function() tryBuyItem("watermelon man", "Race Reroll") end })

        ShopTab:CreateSection(T("ms.section.cosmetics", "Cosmetics"))
        ShopTab:CreateButton({ Name = "Aura Color Reroll | 10 Gems | Halfed Sorcerer", Callback = function() tryBuyItem("halfed sorcerer", "Aura Color Reroll") end })

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
            Icon = "🔢",
            Min = 1, Max = 50, Default = 1,
            Callback = function(v) State.statPointsPerTick = v end,
        }))

        ProgressTab:CreateSection(T("ms.section.rewards", "Rewards"))
        reg("autoRedeem", ProgressTab:CreateToggle({
            Name = T("ms.autoRedeem.name", "Auto Redeem Codes"),
            Description = T("ms.autoRedeem.desc", "Redeem available codes"),
            Icon = "🎁", Default = false,
            Callback = function(v) State.autoRedeem = v; redeemIndex = 0 end,
        }))

        ProgressTab:CreateSection(T("ms.section.gacha", "Gacha"))
        reg("autoGacha", ProgressTab:CreateToggle({
            Name = T("ms.autoGacha.name", "Auto Gacha"),
            Description = T("ms.autoGacha.desc", "Auto-spin gacha"),
            Icon = "🎰", Default = false,
            Callback = function(v) State.autoGacha = v end,
        }))
        ProgressTab:CreateDropdown({
            Name = T("ms.gachaType.name", "Gacha Type"),
            Description = T("ms.gachaType.desc", "Which gacha machine"),
            Icon = "🎲",
            Options = { "Floppa Gacha", "Doge Gacha" },
            Default = 1,
            Callback = function(opt) State.gachaType = tostring(opt) end,
        })
        ProgressTab:CreateDropdown({
            Name = T("ms.gachaRolls.name", "Gacha Rolls"),
            Description = T("ms.gachaRolls.desc", "Rolls per cycle"),
            Icon = "🔢",
            Options = { "1x", "3x", "10x" },
            Default = 1,
            Callback = function(opt)
                local v = tostring(opt)
                if v == "1x" then State.gachaRolls = 1
                elseif v == "3x" then State.gachaRolls = 3
                elseif v == "10x" then State.gachaRolls = 10 end
            end,
        })

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
            Icon = "📏",
            Min = 16, Max = 200, Default = 50,
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
            Icon = "📏",
            Min = 30, Max = 200, Default = 80,
            Callback = function(v) State.jumpPowerValue = v end,
        }))
        reg("antiAfk", PlayerTab:CreateToggle({
            Name = T("ms.antiAfk.name", "Anti-AFK"),
            Description = T("ms.antiAfk.desc", "Prevent kick for inactivity"),
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
                    Window:Notify("📋", "Copied!", 2, "success")
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

    Window:Notify("✅ " .. SHORT_VERSION, T("ms.loaded", "MemeSea loaded successfully"), 4, "success")

    print("============================================")
    print("[Infinite Zen] 🇧🇷 " .. FULL_VERSION .. " carregado com sucesso!")
    print("[Infinite Zen] 🇺🇸 " .. FULL_VERSION .. " loaded successfully!")
    print("============================================")
end

return MemeSea